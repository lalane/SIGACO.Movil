import '../../../../core/files/local_file_store.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/operation_queue.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import 'api_maintenance_repository.dart';

/// El mantenimiento del servidor, con el seguimiento que no se pierde sin red:
/// si no puede enviarse porque no hay conexion, queda en la cola local con su
/// clave de idempotencia y sale por `/api/sync/operations` cuando vuelve la
/// red; sus fotos se copian al telefono y suben despues, ligadas al seguimiento
/// que cree el servidor. Cualquier otro fallo (permiso, validacion) se avisa
/// como siempre.
class OfflineMaintenanceRepository
    implements MaintenanceRepository, ScopeBound {
  OfflineMaintenanceRepository(
    this._online,
    this._queue, {
    LocalFileStore? files,
    DateTime Function()? clock,
  }) : _fileStore = files,
       _clock = clock ?? DateTime.now;

  final MaintenanceRepository _online;
  final OperationQueue _queue;

  /// Donde se copian las fotos que esperan red; sin el, se dejan donde estan.
  final LocalFileStore? _fileStore;
  final DateTime Function() _clock;
  OfflineScope? _scope;

  /// El tipo de operacion de la cola, con el nombre que le da el servidor
  /// (`SyncEntities.MaintenanceProgress`).
  static const progressEntity = 'MAINTENANCE_PROGRESS';

  /// Claves locales del payload (empiezan con `_`: no viajan en el lote).
  static const photosKey = '_photos';
  static const atKey = '_at';

  @override
  Future<void> bind(OfflineScope? scope) async => _scope = scope;

  @override
  Future<void> clear() async {}

  @override
  Future<List<MaintenanceIndicator>> visibleIndicators() =>
      _online.visibleIndicators();

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      _online.list(indicator);

  @override
  Future<MaintenanceOrder> get(String id) => _online.get(id);

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  }) async {
    final captured = at ?? _clock();
    try {
      return await _online.addProgress(
        id,
        executedVolume: executedVolume,
        percent: percent,
        notes: notes,
        photoPaths: photoPaths,
        at: captured,
        clientId: clientId,
      );
    } on MaintenanceException catch (e) {
      final scope = _scope;
      if (e.error != MaintenanceError.network || scope == null) rethrow;
      final photos = await _keep(photoPaths);
      await _queue.enqueue(
        scope,
        entity: progressEntity,
        kind: OperationKind.insert,
        recordId: id,
        key: clientId,
        capturedAt: captured.toUtc(),
        payload: {
          ...ApiMaintenanceRepository.progressBody(
            executedVolume: executedVolume,
            percent: percent,
            notes: notes,
            at: captured,
          ),
          if (photos.isNotEmpty) photosKey: photos,
          atKey: captured.toUtc().toIso8601String(),
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

  /// Copia las fotos a un lugar que no se borra antes de que suban.
  Future<List<String>> _keep(List<String> paths) async {
    final files = _fileStore;
    if (files == null) return paths;
    final kept = <String>[];
    for (final path in paths) {
      try {
        kept.add(
          await files.keep(path, name: path.split(RegExp(r'[\\/]')).last),
        );
      } catch (_) {
        // Una foto que no se pudo copiar no detiene el avance.
      }
    }
    return kept;
  }
}
