import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

class SessionTimeoutState extends Equatable {
  const SessionTimeoutState({this.secondsLeft, this.expired = false});

  /// Segundos que quedan, solo dentro de la ventana de aviso; null si no aplica.
  final int? secondsLeft;
  final bool expired;

  bool get warning => secondsLeft != null && !expired;

  @override
  List<Object?> get props => [secondsLeft, expired];
}

/// Avisa antes de que el servidor cierre la sesion por inactividad (FEAT-M01-06).
/// El servidor cuenta la inactividad desde la ultima peticion, por eso se mide
/// con `lastActivityAt` del repositorio y no con toques en pantalla.
class SessionTimeoutCubit extends Cubit<SessionTimeoutState> {
  SessionTimeoutCubit(
    this._repo, {
    this.warnBefore = const Duration(seconds: 60),
    this.tick = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const SessionTimeoutState());

  final AuthRepository _repo;
  final Duration warnBefore;
  final Duration tick;
  final DateTime Function() _now;
  Timer? _timer;
  Duration? _idle;

  /// Empieza a vigilar una sesion con ese tiempo maximo de inactividad.
  void start(Duration idle) {
    _idle = idle;
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => check());
    check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _idle = null;
    emit(const SessionTimeoutState());
  }

  void check() {
    final idle = _idle;
    final last = _repo.lastActivityAt;
    if (idle == null || last == null) return;
    final left = idle - _now().difference(last);
    if (left <= Duration.zero) {
      emit(const SessionTimeoutState(secondsLeft: 0, expired: true));
    } else if (left <= warnBefore) {
      emit(SessionTimeoutState(secondsLeft: left.inSeconds + 1));
    } else if (state.secondsLeft != null || state.expired) {
      emit(const SessionTimeoutState());
    }
  }

  /// Mantiene viva la sesion con una consulta ligera (cuenta como actividad).
  Future<void> keepAlive() async {
    try {
      await _repo.getProfile();
    } catch (_) {
      // Si falla por sesion vencida, el flujo normal de 401 lo resuelve.
    }
    check();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
