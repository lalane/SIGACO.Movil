import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/navigation_entities.dart';
import '../../domain/repositories/navigation_repository.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga (o recarga) el menu de la concesion activa.
class NavigationRequested extends NavigationEvent {
  const NavigationRequested();
}

/// Vuelve a consultar los accesos sin vaciar la pantalla (M01-05, M02-02-04):
/// al volver a la app, al jalar para actualizar o cuando el servidor niega una
/// accion. Se omite si el ultimo menu es mas reciente que [gap]; sin [gap] se
/// usa el valor de la app. Un [gap] de cero siempre consulta.
class NavigationRefreshed extends NavigationEvent {
  const NavigationRefreshed({this.gap});

  final Duration? gap;

  @override
  List<Object?> get props => [gap];
}

/// Descarta el menu: al cerrar sesion o cambiar de concesion no debe quedar
/// nada del ambiente anterior (RN-CTX-02).
class NavigationCleared extends NavigationEvent {
  const NavigationCleared();
}

enum NavigationStatus { idle, loading, ready, failure }

class NavigationState extends Equatable {
  const NavigationState({
    this.status = NavigationStatus.idle,
    this.menu = const NavigationMenu(),
    this.error,
    this.refreshing = false,
    this.accessChanges = 0,
  });

  final NavigationStatus status;
  final NavigationMenu menu;
  final NavigationError? error;

  /// Hay una consulta de accesos en curso con el menu anterior a la vista.
  final bool refreshing;

  /// Cuantas veces cambiaron los accesos durante la sesion (para avisar).
  final int accessChanges;

  NavigationState copyWith({
    NavigationStatus? status,
    NavigationMenu? menu,
    NavigationError? error,
    bool clearError = false,
    bool? refreshing,
    int? accessChanges,
  }) => NavigationState(
    status: status ?? this.status,
    menu: menu ?? this.menu,
    error: clearError ? null : (error ?? this.error),
    refreshing: refreshing ?? this.refreshing,
    accessChanges: accessChanges ?? this.accessChanges,
  );

  @override
  List<Object?> get props => [status, menu, error, refreshing, accessChanges];
}

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc(
    this._repo, {
    this.minRefreshGap = const Duration(seconds: 30),
    this.deniedRefreshGap = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const NavigationState()) {
    on<NavigationRequested>(_onRequested);
    on<NavigationRefreshed>(_onRefreshed);
    on<NavigationCleared>((_, emit) {
      _generation++;
      _lastLoadAt = null;
      emit(const NavigationState());
    });
    _deniedSub = _repo.accessDenied.listen(
      (_) => add(NavigationRefreshed(gap: deniedRefreshGap)),
    );
  }

  final NavigationRepository _repo;

  /// Tiempo minimo entre consultas por volver a la app.
  final Duration minRefreshGap;

  /// Tiempo minimo entre consultas disparadas por una accion negada.
  final Duration deniedRefreshGap;
  final DateTime Function() _now;
  late final StreamSubscription<void> _deniedSub;

  /// Se incrementa al vaciar o recargar: una respuesta tardia del ambiente
  /// anterior no debe pisar el menu actual.
  int _generation = 0;
  DateTime? _lastLoadAt;
  bool _refreshInFlight = false;

  Future<void> _onRequested(
    NavigationRequested event,
    Emitter<NavigationState> emit,
  ) async {
    final generation = ++_generation;
    emit(
      NavigationState(
        status: NavigationStatus.loading,
        accessChanges: state.accessChanges,
      ),
    );
    try {
      final menu = await _repo.load();
      if (generation != _generation || emit.isDone) return;
      _lastLoadAt = _now();
      emit(
        NavigationState(
          status: NavigationStatus.ready,
          menu: menu,
          accessChanges: state.accessChanges,
        ),
      );
    } on NavigationException catch (e) {
      if (generation != _generation || emit.isDone) return;
      emit(
        NavigationState(
          status: NavigationStatus.failure,
          error: e.error,
          accessChanges: state.accessChanges,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    NavigationRefreshed event,
    Emitter<NavigationState> emit,
  ) async {
    // Sin sesion o ya cargando: no hay nada que refrescar.
    if (state.status == NavigationStatus.idle ||
        state.status == NavigationStatus.loading ||
        _refreshInFlight) {
      return;
    }
    // Un menu que fallo se pide completo, con su indicador de carga.
    if (state.status == NavigationStatus.failure) {
      add(const NavigationRequested());
      return;
    }
    final gap = event.gap ?? minRefreshGap;
    final last = _lastLoadAt;
    if (last != null && _now().difference(last) < gap) return;

    final generation = _generation;
    _refreshInFlight = true;
    emit(state.copyWith(refreshing: true));
    try {
      final menu = await _repo.load();
      if (generation != _generation || emit.isDone) return;
      _lastLoadAt = _now();
      final changed = menu != state.menu;
      emit(
        state.copyWith(
          menu: menu,
          refreshing: false,
          accessChanges: state.accessChanges + (changed ? 1 : 0),
        ),
      );
    } on NavigationException catch (e) {
      if (generation != _generation || emit.isDone) return;
      if (e.error == NavigationError.permissionDenied) {
        // El servidor ya no deja ver nada: se muestra el estado sin permiso.
        emit(
          NavigationState(
            status: NavigationStatus.failure,
            error: e.error,
            accessChanges: state.accessChanges + 1,
          ),
        );
      } else {
        // Sin red o con error del servidor se conserva el menu a la vista.
        emit(state.copyWith(refreshing: false));
      }
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  Future<void> close() async {
    await _deniedSub.cancel();
    return super.close();
  }
}
