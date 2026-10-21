import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';

class MfaSetupState extends Equatable {
  const MfaSetupState({
    this.busy = false,
    this.enrollment,
    this.error,
    this.done = false,
    this.recoveryCodes = const [],
    this.recoveryRemaining,
    this.regenerating = false,
  });

  final bool busy;

  /// Clave nueva generada por el servidor; hasta confirmarla con un codigo no
  /// reemplaza a la anterior en la practica del usuario.
  final MfaEnrollment? enrollment;
  final AuthError? error;
  final bool done;

  /// Codigos de recuperacion recien entregados (se ven una sola vez).
  final List<String> recoveryCodes;

  /// Cuantos codigos sin usar le quedan; nulo si aun no se sabe.
  final int? recoveryRemaining;

  /// Se esta pidiendo el codigo de la app para generar codigos nuevos.
  final bool regenerating;

  MfaSetupState copyWith({
    bool? busy,
    MfaEnrollment? enrollment,
    AuthError? error,
    bool clearError = false,
    bool? done,
    List<String>? recoveryCodes,
    int? recoveryRemaining,
    bool? regenerating,
  }) => MfaSetupState(
    busy: busy ?? this.busy,
    enrollment: enrollment ?? this.enrollment,
    error: clearError ? null : (error ?? this.error),
    done: done ?? this.done,
    recoveryCodes: recoveryCodes ?? this.recoveryCodes,
    recoveryRemaining: recoveryRemaining ?? this.recoveryRemaining,
    regenerating: regenerating ?? this.regenerating,
  );

  @override
  List<Object?> get props => [
    busy,
    enrollment,
    error,
    done,
    recoveryCodes,
    recoveryRemaining,
    regenerating,
  ];

  /// Sin secretos: la clave no se registra en la trazabilidad.
  @override
  String toString() =>
      'MfaSetupState(busy: $busy, hasKey: ${enrollment != null}, '
      'error: ${error?.name}, done: $done, '
      'codes: ${recoveryCodes.length})';
}

/// Volver a configurar la verificacion en dos pasos desde el perfil (por
/// ejemplo, al cambiar de telefono). Activarla o desactivarla es de un
/// administrador (M02-05); aqui solo se renueva la clave de una cuenta que ya
/// la tiene.
class MfaSetupCubit extends Cubit<MfaSetupState> {
  MfaSetupCubit(this._repo) : super(const MfaSetupState());

  final AuthRepository _repo;

  /// Cuantos codigos de recuperacion le quedan, segun el perfil del servidor.
  Future<void> loadStatus() async {
    try {
      final profile = await _repo.getProfile();
      if (isClosed) return;
      emit(
        state.copyWith(recoveryRemaining: profile.mfa?.recoveryCodesRemaining),
      );
    } on AuthException {
      // Es solo informativo: sin respuesta simplemente no se muestra el numero.
    }
  }

  Future<void> generate() async {
    emit(const MfaSetupState(busy: true));
    try {
      emit(MfaSetupState(enrollment: await _repo.startMfaEnrollment()));
    } on AuthException catch (e) {
      emit(MfaSetupState(error: e.error));
    }
  }

  Future<void> confirm(String code) async {
    final enrollment = state.enrollment;
    if (enrollment == null) return;
    emit(MfaSetupState(busy: true, enrollment: enrollment));
    try {
      final codes = await _repo.activateMfa(code.trim());
      emit(MfaSetupState(done: true, recoveryCodes: codes));
    } on AuthException catch (e) {
      emit(MfaSetupState(enrollment: enrollment, error: e.error));
    }
  }

  /// Pasa a pedir el codigo de la app para generar codigos de recuperacion nuevos.
  void startRegeneration() =>
      emit(state.copyWith(regenerating: true, clearError: true));

  void cancelRegeneration() =>
      emit(state.copyWith(regenerating: false, clearError: true));

  /// Los codigos anteriores dejan de servir en cuanto el servidor entrega estos.
  Future<void> regenerate(String code) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final codes = await _repo.regenerateRecoveryCodes(code.trim());
      emit(
        MfaSetupState(recoveryCodes: codes, recoveryRemaining: codes.length),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(busy: false, error: e.error));
    }
  }

  /// La persona confirmo que guardo los codigos.
  void acknowledgeCodes() =>
      emit(MfaSetupState(recoveryRemaining: state.recoveryRemaining));
}
