import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/credential_store.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo, this._store, {Future<void> Function()? beforeLogout})
    : _beforeLogout = beforeLogout, // ignore: prefer_initializing_formals
      super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(
      (e, emit) => _login(emit, e.email, e.password, remember: e.remember),
    );
    on<AuthBiometricLoginRequested>(_onBiometricLogin);
    on<AuthMfaSubmitted>(_onMfaSubmitted);
    on<AuthMfaEnrollmentRequested>(_onEnrollmentRequested);
    on<AuthMfaActivationSubmitted>(_onActivation);
    on<AuthRecoveryCodesAcknowledged>(_onRecoveryCodesAcknowledged);
    on<AuthPasswordChangeSubmitted>(_onPasswordChange);
    on<AuthConcessionSelected>(_onConcession);
    on<AuthRecoveryRequested>(_onRecovery);
    on<AuthRecoveryOpened>(
      (e, emit) => emit(state.copyWith(recoverySent: false, clearError: true)),
    );
    on<AuthPasswordResetReturned>(_onPasswordResetReturned);
    on<AuthBiometricOfferAnswered>(_onOfferAnswered);
    on<AuthBiometricDisabled>((e, emit) async {
      await _store.disableBiometric();
      emit(state.copyWith(biometricEnabled: _store.biometricEnabled));
    });
    on<AuthBiometricEnableRequested>(_onBiometricEnable);
    on<AuthPasswordUpdated>((e, emit) => _password = e.password);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthRequirementReceived>(_onRequirement);
    _expiredSub = _repo.sessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
    _requirementSub = _repo.sessionRequirements.listen(
      (r) => add(AuthRequirementReceived(r)),
    );
  }

  final AuthRepository _repo;
  final CredentialStore _store;

  /// Se ejecuta antes de cerrar la sesion, con ella todavia abierta.
  final Future<void> Function()? _beforeLogout;
  late final StreamSubscription<void> _expiredSub;
  late final StreamSubscription<SessionRequirement> _requirementSub;

  // Se conservan solo en memoria mientras dura la sesion (nunca en disco, salvo
  // cifrados si se recuerda o se activa la biometria): para ofrecer y activar la
  // biometria. Se borran al cerrar sesion.
  String? _email;
  String? _password;

  @override
  Future<void> close() {
    _expiredSub.cancel();
    _requirementSub.cancel();
    return super.close();
  }

  AuthState _withOffer(AuthState s) => s.copyWith(
    offerBiometric:
        s.step == AuthStep.signedIn &&
        _password != null &&
        s.biometricAvailable &&
        !_store.biometricEnabled &&
        !_store.biometricOfferDeclined,
  );

  /// Estado de salida: sin sesion, conservando lo que se muestra en el login.
  Future<AuthState> _signedOut({bool expired = false}) async {
    _email = null;
    _password = null;
    return AuthState(
      sessionExpired: expired,
      rememberedEmail: _store.rememberedEmail,
      rememberedPassword: await _store.readRememberedPassword(),
      biometricAvailable: state.biometricAvailable,
      biometricEnabled: _store.biometricEnabled,
    );
  }

  /// Termina cuando se leyo lo guardado al arrancar. Un regreso del navegador
  /// con la app recien abierta espera aqui para no ser pisado por esa lectura.
  Future<void>? _starting;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final done = Completer<void>();
    _starting = done.future;
    try {
      emit(
        state.copyWith(
          rememberedEmail: _store.rememberedEmail,
          rememberedPassword: await _store.readRememberedPassword(),
          biometricEnabled: _store.biometricEnabled,
        ),
      );
      final available = await _store.deviceSupportsBiometrics();
      emit(state.copyWith(biometricAvailable: available));
    } finally {
      done.complete();
    }
  }

  Future<void> _login(
    Emitter<AuthState> emit,
    String email,
    String password, {
    required bool remember,
    bool viaBiometric = false,
  }) async {
    emit(state.copyWith(busy: true, clearError: true, sessionExpired: false));
    try {
      final r = await _repo.login(email.trim(), password);
      await _store.setRemembered(
        remember: remember,
        credentials: (email: email.trim(), password: password),
      );
      _email = email.trim();
      _password = password;
      emit(
        _withOffer(
          AuthState(
            user: r.user,
            concessions: r.concessions,
            activeConcessionId: r.activeConcessionId,
            idleTimeoutMinutes: r.idleTimeoutMinutes,
            mfaRequired: r.mfaRequired,
            mfaEnrollmentRequired: r.mfaEnrollmentRequired,
            mfaActive: r.mfaRequired || r.mfaEnrollmentRequired,
            passwordChangeRequired: r.forcePasswordChange,
            rememberedEmail: _store.rememberedEmail,
            biometricAvailable: state.biometricAvailable,
            biometricEnabled: _store.biometricEnabled,
          ),
        ),
      );
    } on AuthException catch (e) {
      // La contrasena guardada para biometria ya no sirve: se deja de usar.
      if (viaBiometric && e.error == AuthError.invalidCredentials) {
        await _store.disableBiometric();
      }
      emit(
        state.copyWith(
          busy: false,
          error: e.error,
          biometricEnabled: _store.biometricEnabled,
        ),
      );
    }
  }

  Future<void> _onBiometricLogin(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_store.biometricEnabled) {
      emit(state.copyWith(error: AuthError.biometricNotConfigured));
      return;
    }
    final creds = await _store.readWithBiometric(event.reason);
    if (creds == null) return;
    await _login(
      emit,
      creds.email,
      creds.password,
      remember: _store.rememberEnabled,
      viaBiometric: true,
    );
  }

  /// Ejecuta un paso del flujo; en fallo emite el error (o cierra si la sesion termino).
  Future<void> _step(
    Emitter<AuthState> emit,
    Future<AuthState> Function() action,
  ) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      emit(_withOffer(await action()));
    } on AuthException catch (e) {
      if (e.error == AuthError.sessionExpired) {
        emit(await _signedOut(expired: true));
      } else {
        emit(
          state.copyWith(busy: false, error: e.error, errorDetails: e.details),
        );
      }
    }
  }

  Future<void> _onMfaSubmitted(AuthMfaSubmitted e, Emitter<AuthState> emit) =>
      _step(emit, () async {
        await _repo.verifyMfa(e.code.trim());
        return state.copyWith(busy: false, mfaRequired: false);
      });

  Future<void> _onEnrollmentRequested(
    AuthMfaEnrollmentRequested e,
    Emitter<AuthState> emit,
  ) => _step(emit, () async {
    final enrollment = await _repo.startMfaEnrollment();
    return state.copyWith(busy: false, mfaEnrollment: enrollment);
  });

  Future<void> _onActivation(
    AuthMfaActivationSubmitted e,
    Emitter<AuthState> emit,
  ) => _step(emit, () async {
    final codes = await _repo.activateMfa(e.code.trim());
    return state.copyWith(
      busy: false,
      mfaEnrollmentRequired: false,
      mfaActive: true,
      recoveryCodes: codes,
    );
  });

  /// La persona confirmo que guardo los codigos: no se vuelven a mostrar.
  void _onRecoveryCodesAcknowledged(
    AuthRecoveryCodesAcknowledged e,
    Emitter<AuthState> emit,
  ) => emit(state.copyWith(recoveryCodes: const []));

  Future<void> _onPasswordChange(
    AuthPasswordChangeSubmitted e,
    Emitter<AuthState> emit,
  ) async {
    if (e.next != e.confirm) {
      emit(state.copyWith(error: AuthError.passwordMismatch));
      return;
    }
    await _step(emit, () async {
      await _repo.changePassword(
        current: e.current,
        next: e.next,
        confirm: e.confirm,
      );
      _password = e.next;
      await _store.refreshStoredPassword(e.next);
      return state.copyWith(busy: false, passwordChangeRequired: false);
    });
  }

  Future<void> _onConcession(
    AuthConcessionSelected e,
    Emitter<AuthState> emit,
  ) => _step(emit, () async {
    await _repo.selectConcession(e.concessionId);
    return state.copyWith(busy: false, activeConcessionId: e.concessionId);
  });

  Future<void> _onRecovery(
    AuthRecoveryRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearError: true, recoverySent: false));
    try {
      await _repo.requestPasswordRecovery(e.email.trim());
      emit(state.copyWith(busy: false, recoverySent: true));
    } on AuthException catch (ex) {
      emit(state.copyWith(busy: false, error: ex.error));
    }
  }

  /// Volvio del navegador con la contrasena ya cambiada: la guardada (para
  /// recordar o para biometria) dejo de servir y se descarta.
  Future<void> _onPasswordResetReturned(
    AuthPasswordResetReturned e,
    Emitter<AuthState> emit,
  ) async {
    await _starting;
    await _store.forgetPassword();
    emit(
      state.copyWith(
        passwordResetDone: state.user == null,
        clearRememberedPassword: true,
        biometricEnabled: _store.biometricEnabled,
        recoverySent: false,
        clearError: true,
      ),
    );
  }

  /// Activa la biometria con la sesion abierta: usa la contrasena con la que se
  /// entro (se conserva en memoria hasta cerrar sesion) y pide la huella o el
  /// rostro antes de guardarla cifrada.
  Future<void> _onBiometricEnable(
    AuthBiometricEnableRequested e,
    Emitter<AuthState> emit,
  ) async {
    final email = _email;
    final password = _password;
    if (email == null || password == null) return;
    await _store.enableBiometric(e.reason, (email: email, password: password));
    emit(state.copyWith(biometricEnabled: _store.biometricEnabled));
  }

  Future<void> _onOfferAnswered(
    AuthBiometricOfferAnswered e,
    Emitter<AuthState> emit,
  ) async {
    final email = _email;
    final password = _password;
    if (e.accepted && email != null && password != null) {
      await _store.enableBiometric(e.reason, (
        email: email,
        password: password,
      ));
    } else if (!e.accepted && e.persistDecline) {
      await _store.declineBiometricOffer();
    }
    // La contrasena se conserva en memoria hasta cerrar sesion: permite activar
    // la biometria despues desde la cuenta, sin volver a entrar.
    emit(
      state.copyWith(
        offerBiometric: false,
        biometricEnabled: _store.biometricEnabled,
      ),
    );
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    // Lo que debe hacerse con la sesion todavia abierta (retirar el dispositivo
    // push). Un fallo no impide cerrar la sesion.
    try {
      await _beforeLogout?.call();
    } catch (_) {}
    await _repo.logout();
    emit(await _signedOut());
  }

  /// El servidor exige un paso a mitad de sesion: el router lleva a su pantalla.
  void _onRequirement(AuthRequirementReceived e, Emitter<AuthState> emit) {
    if (state.user == null) return;
    emit(switch (e.requirement) {
      SessionRequirement.mfa => state.copyWith(
        mfaRequired: true,
        mfaActive: true,
      ),
      SessionRequirement.mfaEnrollment => state.copyWith(
        mfaEnrollmentRequired: true,
        mfaActive: true,
      ),
      SessionRequirement.passwordChange => state.copyWith(
        passwordChangeRequired: true,
      ),
      SessionRequirement.concession => state.copyWith(
        clearActiveConcession: true,
      ),
    });
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired e,
    Emitter<AuthState> emit,
  ) async {
    emit(await _signedOut(expired: true));
  }
}
