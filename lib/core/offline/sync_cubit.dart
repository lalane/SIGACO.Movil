import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'operation.dart';
import 'operation_queue.dart';
import 'sync_engine.dart';

class SyncState extends Equatable {
  const SyncState({
    this.scope,
    this.items = const [],
    this.lastSyncAt,
    this.nextRetryAt,
    this.running = false,
    this.lastReport,
    this.enabled = true,
  });

  /// Persona y concesion de la sesion; null sin sesion.
  final OfflineScope? scope;

  /// Lo que no esta aceptado: pendientes, enviandose, rechazadas y en conflicto,
  /// de la mas antigua a la mas reciente.
  final List<PendingOperation> items;
  final DateTime? lastSyncAt;
  final DateTime? nextRetryAt;
  final bool running;
  final SyncReport? lastReport;

  /// Falso cuando la app no tiene base local (pruebas): no hay nada que mostrar.
  final bool enabled;

  int _count(Set<OperationStatus> s) =>
      items.where((o) => s.contains(o.status)).length;

  /// Esperando enviarse (en cola o enviandose).
  int get pending => _count({OperationStatus.pending, OperationStatus.sending});

  /// Que el servidor rechazo: esperan una decision.
  int get rejected => _count({OperationStatus.rejected});

  /// En conflicto: esperan una decision.
  int get conflicts => _count({OperationStatus.conflict});

  /// Piden que la persona decida algo.
  int get attention => rejected + conflicts;

  bool get isEmpty => items.isEmpty;

  SyncState copyWith({
    OfflineScope? scope,
    bool clearScope = false,
    List<PendingOperation>? items,
    DateTime? lastSyncAt,
    bool clearLastSync = false,
    DateTime? nextRetryAt,
    bool clearNextRetry = false,
    bool? running,
    SyncReport? lastReport,
    bool clearReport = false,
  }) => SyncState(
    scope: clearScope ? null : scope ?? this.scope,
    items: items ?? this.items,
    lastSyncAt: clearLastSync ? null : lastSyncAt ?? this.lastSyncAt,
    nextRetryAt: clearNextRetry ? null : nextRetryAt ?? this.nextRetryAt,
    running: running ?? this.running,
    lastReport: clearReport ? null : lastReport ?? this.lastReport,
    enabled: enabled,
  );

  @override
  List<Object?> get props => [
    scope,
    items,
    lastSyncAt,
    nextRetryAt,
    running,
    lastReport,
    enabled,
  ];
}

/// Estado de la sincronizacion de la persona y concesion activas (DEV-MOB-063,
/// 064 y 065): cuantas operaciones esperan, cuales piden una decision, la
/// ultima sincronizacion, y envia la cola cuando toca.
///
/// Se envia: al recuperar la conexion, al volver a la app, cuando la persona lo
/// pide, tras encolar algo (`syncNow`) y a la hora del siguiente reintento.
/// Nunca por el simple cambio de la cola: una pasada termina con avisos de
/// cambio y se volveria a lanzar sola sin fin.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    OperationQueue queue,
    SyncEngine engine, {
    this.resumeGap = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _queue = queue,
       _engine = engine,
       _now = clock ?? DateTime.now,
       super(const SyncState()) {
    _sub = queue.changes.listen((_) => _refresh());
  }

  /// Sin base local: no hay nada que enviar ni que mostrar.
  SyncCubit.disabled()
    : _queue = null,
      _engine = null,
      _now = DateTime.now,
      resumeGap = Duration.zero,
      super(const SyncState(enabled: false));

  final OperationQueue? _queue;
  final SyncEngine? _engine;
  final DateTime Function() _now;

  /// Tiempo minimo entre dos pasadas al volver a la app.
  final Duration resumeGap;

  StreamSubscription<void>? _sub;
  Timer? _retryTimer;
  bool _online = true;
  DateTime? _lastRunAt;
  int _scopeGeneration = 0;

  OfflineScope? get scope => state.scope;

  /// Cambia la persona y concesion activas (null al cerrar sesion). Lo de
  /// otro alcance deja de verse; sigue guardado para cuando esa persona vuelva.
  Future<void> setScope(OfflineScope? scope) async {
    if (_queue == null || scope == state.scope) return;
    _scopeGeneration++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _lastRunAt = null;
    if (scope == null) {
      emit(const SyncState());
      return;
    }
    emit(SyncState(scope: scope));
    await _queue.resetInterrupted();
    await _refresh();
    unawaited(syncNow());
  }

  void setOnline(bool online) {
    final was = _online;
    _online = online;
    if (online && !was) unawaited(syncNow());
  }

  /// Al volver a la app.
  Future<void> onResume() => syncNow(minGap: resumeGap);

  /// Envia lo pendiente ahora (sin red no hace nada). Con [minGap] no repite
  /// una pasada reciente.
  Future<void> syncNow({Duration minGap = Duration.zero}) {
    final scope = state.scope;
    final engine = _engine;
    if (isClosed || scope == null || engine == null) return Future.value();
    if (!_online || state.running) return Future.value();
    final last = _lastRunAt;
    if (last != null && _now().difference(last) < minGap) return Future.value();

    _lastRunAt = _now();
    emit(state.copyWith(running: true));
    return _active = _pass(engine, scope, _scopeGeneration).whenComplete(() {
      _active = null;
    });
  }

  Future<void>? _active;

  /// Una pasada. Nunca lanza: se llama sin esperarla (al volver la conexion, a
  /// la hora de un reintento...) y un error no debe quedar sin atender.
  Future<void> _pass(
    SyncEngine engine,
    OfflineScope scope,
    int generation,
  ) async {
    SyncReport report;
    try {
      report = await engine.run(scope);
    } catch (_) {
      report = const SyncReport(networkFailed: true);
    }
    if (isClosed || generation != _scopeGeneration) return;
    emit(state.copyWith(running: false, lastReport: report));
    await _refresh();
    _scheduleRetry();
  }

  Future<void>? _inFlight;
  var _again = false;

  /// Vuelve a leer la cola. Una lectura a la vez: si llegan avisos mientras se
  /// lee, se lee otra vez al terminar. Asi una lectura vieja nunca termina
  /// despues de una nueva y deja a la vista un estado atrasado.
  Future<void> _refresh() {
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    return _inFlight = _drain().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _drain() async {
    do {
      _again = false;
      await _load();
    } while (_again && !isClosed);
  }

  Future<void> _load() async {
    final queue = _queue;
    final scope = state.scope;
    if (queue == null || scope == null) return;
    final generation = _scopeGeneration;
    try {
      final items = await queue.list(
        scope,
        statuses: {
          OperationStatus.pending,
          OperationStatus.sending,
          OperationStatus.rejected,
          OperationStatus.conflict,
        },
      );
      final last = await queue.lastSync(scope);
      final next = await queue.nextRetryAt(scope);
      if (isClosed || generation != _scopeGeneration) return;
      emit(
        state.copyWith(
          items: items,
          lastSyncAt: last,
          clearLastSync: last == null,
          nextRetryAt: next,
          clearNextRetry: next == null,
        ),
      );
    } catch (_) {
      // La base se cerro (la app se esta cerrando): se queda lo que se veia.
    }
  }

  /// A la hora del primer reintento pendiente se vuelve a intentar.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    final at = state.nextRetryAt;
    if (at == null || isClosed) return;
    final wait = at.difference(_now());
    _retryTimer = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 50),
      () => unawaited(syncNow()),
    );
  }

  // ---- Decisiones de la persona -------------------------------------------

  Future<SyncConflict?> conflictOf(String operationId) =>
      _queue?.conflictOf(operationId) ?? Future.value();

  /// Vuelve a mandar una rechazada o en conflicto. En un conflicto se manda
  /// sobre la version actual del servidor [baseVersion] (la persona se queda
  /// con lo capturado en el telefono).
  Future<void> retry(String operationId, {int? baseVersion}) async {
    await _queue?.requeue(operationId, baseVersion: baseVersion);
    unawaited(syncNow());
  }

  /// Descarta lo capturado en el telefono (y deja lo del servidor).
  Future<bool> discard(String operationId) async =>
      await _queue?.discard(operationId) ?? false;

  /// Cierra esperando a que termine la pasada y la lectura en curso: la base
  /// no se debe cerrar con trabajo a medias.
  @override
  Future<void> close() async {
    _retryTimer?.cancel();
    await _sub?.cancel();
    await _active;
    await _inFlight;
    return super.close();
  }
}
