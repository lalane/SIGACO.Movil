import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

enum AlertsStatus { idle, loading, ready, failure }

class AlertsState extends Equatable {
  const AlertsState({
    this.status = AlertsStatus.idle,
    this.alerts = const [],
    this.error,
    this.onlyUnread = false,
  });

  final AlertsStatus status;
  final List<AppAlert> alerts;
  final AlertsError? error;
  final bool onlyUnread;

  /// Lo que lleva el contador de la campana.
  int get unread => alerts.where((a) => !a.read).length;

  /// Las que se ven: todas, o solo las no leidas; lo mas reciente primero.
  List<AppAlert> get visible {
    final list = [
      for (final a in alerts)
        if (!onlyUnread || !a.read) a,
    ];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  AppAlert? byId(String id) {
    for (final a in alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  AlertsState copyWith({
    AlertsStatus? status,
    List<AppAlert>? alerts,
    AlertsError? error,
    bool clearError = false,
    bool? onlyUnread,
  }) => AlertsState(
    status: status ?? this.status,
    alerts: alerts ?? this.alerts,
    error: clearError ? null : (error ?? this.error),
    onlyUnread: onlyUnread ?? this.onlyUnread,
  );

  @override
  List<Object?> get props => [status, alerts, error, onlyUnread];
}

/// Las alertas de la persona: lista, no leidas y marcarlas como leidas. Vive en
/// toda la sesion (el contador de la campana se ve desde el inicio) y se vacia
/// al cerrar sesion o cambiar de concesion.
class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit(this._repository) : super(const AlertsState());

  final AlertsRepository _repository;

  /// Se vuelve a consultar por actividad (volver a la app, recuperar la
  /// conexion); los muy seguidos se descartan.
  bool _fetching = false;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: AlertsStatus.loading,
        alerts: const [],
        clearError: true,
      ),
    );
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final alerts = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AlertsStatus.ready,
          alerts: alerts,
          clearError: true,
        ),
      );
    } on AlertsException catch (e) {
      _failed(e.error);
    } catch (_) {
      _failed(AlertsError.server);
    } finally {
      _fetching = false;
    }
  }

  void _failed(AlertsError error) {
    if (isClosed) return;
    // Con alertas ya a la vista, un fallo al actualizar no las quita.
    emit(
      state.alerts.isNotEmpty && error != AlertsError.notAvailable
          ? state.copyWith(status: AlertsStatus.ready)
          : state.copyWith(status: AlertsStatus.failure, error: error),
    );
  }

  /// Marca una alerta como leida al instante; si el servidor no lo acepta, vuelve
  /// a como estaba.
  Future<void> markRead(String id) async {
    final alert = state.byId(id);
    if (alert == null || alert.read) return;
    final before = state.alerts;
    emit(
      state.copyWith(
        alerts: [
          for (final a in before) a.id == id ? a.copyWith(read: true) : a,
        ],
      ),
    );
    try {
      await _repository.markRead(id);
    } catch (_) {
      if (!isClosed) emit(state.copyWith(alerts: before));
    }
  }

  Future<void> markAllRead() async {
    if (state.unread == 0) return;
    final before = state.alerts;
    emit(
      state.copyWith(alerts: [for (final a in before) a.copyWith(read: true)]),
    );
    try {
      await _repository.markAllRead();
    } catch (_) {
      if (!isClosed) emit(state.copyWith(alerts: before));
    }
  }

  void setOnlyUnread(bool value) => emit(state.copyWith(onlyUnread: value));

  /// Cerrar sesion o cambiar de concesion: nada de lo anterior debe verse.
  void clear() => emit(const AlertsState());
}
