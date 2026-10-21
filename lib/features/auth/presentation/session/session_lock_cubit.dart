import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

class SessionLockState extends Equatable {
  const SessionLockState({this.locked = false, this.expired = false});

  /// Pasaron los minutos de inactividad: la app pide desbloquear (no cierra).
  final bool locked;

  /// La sesion llego a su vencimiento: hay que entrar de nuevo con conexion.
  final bool expired;

  @override
  List<Object?> get props => [locked, expired];
}

/// Politica de la sesion movil (RN-M01-37, DEV-BACK-128):
///  - vale hasta `expiresAt` (10 h), con o sin conexion; el servidor no la cierra
///    por inactividad;
///  - los minutos de inactividad (`idleTimeoutMinutes`) los aplica la app como
///    bloqueo local, que se abre con la huella o el codigo del telefono;
///  - al vencer `expiresAt` se pide entrar otra vez, con conexion y contrasena.
///
/// La inactividad se mide con los toques en pantalla, no con las peticiones.
class SessionLockCubit extends Cubit<SessionLockState> {
  SessionLockCubit(
    this._repo, {
    this.tick = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const SessionLockState());

  final AuthRepository _repo;
  final Duration tick;
  final DateTime Function() _now;
  Timer? _timer;
  Duration? _idle;
  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);

  /// Empieza a vigilar una sesion con ese tiempo de inactividad.
  void start(Duration idle) {
    _idle = idle;
    _lastTouch = _now();
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => check());
    emit(const SessionLockState());
    check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _idle = null;
    emit(const SessionLockState());
  }

  /// La persona uso la pantalla: reinicia la cuenta de inactividad.
  void touch() {
    if (_idle == null || state.locked || state.expired) return;
    _lastTouch = _now();
  }

  /// La persona confirmo su identidad en el telefono.
  void unlock() {
    if (!state.locked) return;
    _lastTouch = _now();
    emit(const SessionLockState());
  }

  /// Compara con el vencimiento (con la hora del servidor, no la del telefono)
  /// y con el tiempo sin actividad.
  void check() {
    final idle = _idle;
    if (idle == null || state.expired) return;
    final now = _now();
    final expiresAt = _repo.sessionExpiresAt;
    if (expiresAt != null &&
        !now.toUtc().add(_repo.serverClockOffset).isBefore(expiresAt)) {
      emit(const SessionLockState(expired: true));
      return;
    }
    if (!state.locked && now.difference(_lastTouch) >= idle) {
      emit(const SessionLockState(locked: true));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
