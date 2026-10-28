import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/credential_store.dart';

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.busy = false,
    this.error,
    this.details = const [],
    this.success = false,
  });

  final bool busy;
  final AuthError? error;

  /// Los motivos que dio el servidor para rechazar la contrasena nueva.
  final List<String> details;
  final bool success;

  @override
  List<Object?> get props => [busy, error, details, success];

  /// Sin secretos: se registra en la trazabilidad.
  @override
  String toString() =>
      'ChangePasswordState(busy: $busy, error: ${error?.name}, success: $success)';
}

/// Cambio voluntario de la propia contrasena desde el perfil (HU-M01-03-02).
/// El backend cierra las demas sesiones del usuario y conserva la actual.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._repo, this._store)
    : super(const ChangePasswordState());

  final AuthRepository _repo;
  final CredentialStore _store;

  Future<void> submit({
    required String current,
    required String next,
    required String confirm,
  }) async {
    if (next != confirm) {
      emit(const ChangePasswordState(error: AuthError.passwordMismatch));
      return;
    }
    emit(const ChangePasswordState(busy: true));
    try {
      await _repo.changePassword(
        current: current,
        next: next,
        confirm: confirm,
      );
      await _store.refreshStoredPassword(next);
      emit(const ChangePasswordState(success: true));
    } on AuthException catch (e) {
      emit(ChangePasswordState(error: e.error, details: e.details));
    }
  }
}
