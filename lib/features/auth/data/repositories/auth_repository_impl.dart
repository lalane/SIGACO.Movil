import 'dart:async';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/auth_mappers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api) {
    _api.onUnauthorized = () {
      _api.accessToken = null;
      _expired.add(null);
    };
    _api.onForbiddenCode = (code) {
      final requirement = requirementForCode(code);
      if (requirement != null) _requirements.add(requirement);
    };
  }

  final ApiClient _api;
  final _expired = StreamController<void>.broadcast();
  final _requirements = StreamController<SessionRequirement>.broadcast();
  final _revalidations = StreamController<SessionRevalidation>.broadcast();

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Stream<SessionRequirement> get sessionRequirements => _requirements.stream;

  @override
  DateTime? get lastActivityAt => _api.lastActivityAt;

  DateTime? _expiresAt;
  Duration _clockOffset = Duration.zero;

  @override
  Stream<SessionRevalidation> get revalidations => _revalidations.stream;

  @override
  DateTime? get sessionExpiresAt => _expiresAt;

  @override
  Duration get serverClockOffset => _clockOffset;

  @override
  Future<SessionRevalidation> revalidateSession() => _guard(() async {
    final r = sessionRevalidationFromJson(
      (await _api.post('/api/auth/session/revalidate'))!,
    );
    _expiresAt = r.expiresAt;
    _clockOffset = r.serverTime.difference(DateTime.now().toUtc());
    _revalidations.add(r);
    return r;
  });

  @override
  Future<MyProfile> getProfile() =>
      _guard(() async => profileFromJson((await _api.get('/api/auth/me'))!));

  AuthException _map(ApiFailure f) {
    if (f.isNetwork) return const AuthException(AuthError.network);
    switch (f.code) {
      case 'AUTH_INVALID_CREDENTIALS':
        return const AuthException(AuthError.invalidCredentials);
      case 'AUTH_ACCOUNT_BLOCKED':
        return const AuthException(AuthError.accountBlocked);
    }
    if (f.status == 400 || f.status == 422) {
      return const AuthException(AuthError.validation);
    }
    if (f.status == 401) return const AuthException(AuthError.sessionExpired);
    return const AuthException(AuthError.server);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiFailure catch (f) {
      throw _map(f);
    }
  }

  @override
  Future<LoginOutcome> login(String email, String password) => _guard(() async {
    final json = await _api.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
        'client': AppConfig.clientType,
      },
    );
    final (outcome, token) = loginFromJson(json!);
    _api.accessToken = token;
    _api.lastActivityAt = DateTime.now();
    _expiresAt = outcome.expiresAt;
    return outcome;
  });

  @override
  Future<void> verifyMfa(String code) async {
    try {
      await _api.post('/api/auth/mfa/verify', data: {'code': code});
    } on ApiFailure catch (f) {
      if (f.isNetwork) throw const AuthException(AuthError.network);
      if (f.status == 401 && f.code == null) {
        throw const AuthException(AuthError.sessionExpired);
      }
      throw const AuthException(AuthError.mfaInvalid);
    }
  }

  @override
  Future<MfaEnrollment> startMfaEnrollment() => _guard(
    () async =>
        mfaEnrollmentFromJson((await _api.post('/api/auth/me/mfa/enroll'))!),
  );

  @override
  Future<List<String>> activateMfa(String code) async {
    try {
      return recoveryCodesFromJson(
        await _api.post('/api/auth/me/mfa/activate', data: {'code': code}),
      );
    } on ApiFailure catch (f) {
      throw AuthException(
        f.isNetwork ? AuthError.network : AuthError.mfaInvalid,
      );
    }
  }

  @override
  Future<List<String>> regenerateRecoveryCodes(String code) async {
    try {
      return recoveryCodesFromJson(
        await _api.post(
          '/api/auth/me/mfa/recovery-codes',
          data: {'code': code},
        ),
      );
    } on ApiFailure catch (f) {
      if (f.isNetwork) throw const AuthException(AuthError.network);
      if (f.status == 401) throw const AuthException(AuthError.sessionExpired);
      // 400: el codigo no es valido; 409: la cuenta no tiene la verificacion.
      throw const AuthException(AuthError.mfaInvalid);
    }
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
    required String confirm,
  }) => _guard(
    () => _api.post(
      '/api/auth/me/password',
      data: {
        'currentPassword': current,
        'newPassword': next,
        'confirmPassword': confirm,
      },
    ),
  );

  @override
  Future<void> selectConcession(String concessionId) => _guard(() async {
    final json = await _api.post(
      '/api/context',
      data: {'concessionId': concessionId},
    );
    final token = json?['accessToken'] as String?;
    if (token != null) _api.accessToken = token;
  });

  @override
  Future<void> requestPasswordRecovery(String email) async {
    try {
      await _api.post('/api/auth/password/recovery', data: {'email': email});
    } on ApiFailure catch (f) {
      // Sin respuesta o con error del servidor la solicitud no se proceso: se
      // avisa, para no decir "revisa tu correo" cuando no se envio nada. Una
      // respuesta del servidor es uniforme y no revela si la cuenta existe.
      if (f.isNetwork) throw const AuthException(AuthError.network);
      if (f.status != null && f.status! >= 500) {
        throw const AuthException(AuthError.server);
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } on ApiFailure {
      // Se cierra localmente aunque el servidor no responda.
    } finally {
      _api.accessToken = null;
      _expiresAt = null;
    }
  }
}
