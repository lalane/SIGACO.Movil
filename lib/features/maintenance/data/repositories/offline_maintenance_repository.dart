import '../../../../core/offline/operation.dart';
import '../../../../core/offline/operation_queue.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// El mantenimiento del servidor, con el avance que no se pierde sin red: si el
/// avance no puede enviarse porque no hay conexion, queda en la cola local con
/// su clave de idempotencia y sale por `/api/sync/operations` cuando vuelve la
/// red. Cualquier otro fallo (permiso, validacion) se avisa como siempre.
class OfflineMaintenanceRepository
    implements MaintenanceRepository, ScopeBound {
  OfflineMaintenanceRepository(
    this._online,
    this._queue, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MaintenanceRepository _online;
  final OperationQueue _queue;
  final DateTime Function() _clock;
  OfflineScope? _scope;

  /// El tipo de operacion de la cola, con el nombre que le da el servidor
  /// (`SyncEntities.MaintenanceProgress`).
  static const progressEntity = 'MAINTENANCE_PROGRESS';

  @override
  Future<void> bind(OfflineScope? scope) async => _scope = scope;

  @override
  Future<void> clear() async {}

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      _online.list(indicator);

  @override
  Future<MaintenanceOrder> get(String id) => _online.get(id);

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    required double percent,
    double? executedVolume,
    String? notes,
    String? clientId,
  }) async {
    try {
      return await _online.addProgress(
        id,
        percent: percent,
        executedVolume: executedVolume,
        notes: notes,
        clientId: clientId,
      );
    } on MaintenanceException catch (e) {
      final scope = _scope;
      if (e.error != MaintenanceError.network || scope == null) rethrow;
      final captured = _clock().toUtc();
      final local = _clock();
      final text = notes?.trim();
      await _queue.enqueue(
        scope,
        entity: progressEntity,
        kind: OperationKind.insert,
        recordId: id,
        key: clientId,
        capturedAt: captured,
        payload: {
          'progressPercent': percent.clamp(0, 100),
          // El dia en que se capturo, no el del envio.
          'reportedOn':
              '${local.year.toString().padLeft(4, '0')}-'
              '${local.month.toString().padLeft(2, '0')}-'
              '${local.day.toString().padLeft(2, '0')}',
          'executedVolume': ?executedVolume,
          if (text != null && text.isNotEmpty) 'notes': text,
        },
      );
      // La ficha no cambia hasta que el servidor reciba el avance; la que se
      // vio antes sigue en el cache del telefono.
      try {
        return await _online.get(id);
      } catch (_) {
        return MaintenanceOrder(
          id: id,
          indicator: MaintenanceIndicator.sgp,
          title: '',
          activity: '',
          status: MaintenanceStatus.open,
          totalVolume: 0,
          executedVolume: 0,
          unit: '',
        );
      }
    }
  }
}
