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
  });

  final bool busy;

  /// Clave nueva generada por el servidor; hasta confirmarla con un codigo no
  /// reemplaza a la anterior en la practica del usuario.
  final MfaEnrollment? enrollment;
  final AuthError? error;
  final bool done;

  @override
  List<Object?> get props => [busy, enrollment, error, done];

  /// Sin secretos: la clave no se registra en la trazabilidad.
  @override
  String toString() =>
      'MfaSetupState(busy: $busy, hasKey: ${enrollment != null}, '
      'error: ${error?.name}, done: $done)';
}

/// Volver a configurar la verificacion en dos pasos desde el perfil (por
/// ejemplo, al cambiar de telefono). Activarla o desactivarla es de un
/// administrador (M02-05); aqui solo se renueva la clave de una cuenta que ya
/// la tiene.
class MfaSetupCubit extends Cubit<MfaSetupState> {
  MfaSetupCubit(this._repo) : super(const MfaSetupState());

  final AuthRepository _repo;

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
      await _repo.activateMfa(code.trim());
      emit(const MfaSetupState(done: true));
    } on AuthException catch (e) {
      emit(MfaSetupState(enrollment: enrollment, error: e.error));
    }
  }
}
