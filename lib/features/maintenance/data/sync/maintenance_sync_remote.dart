import '../../../../core/offline/api_sync_remote.dart';
import '../../../../core/offline/operation.dart';
import '../repositories/api_maintenance_repository.dart';
import '../repositories/offline_maintenance_repository.dart';

/// Envia al servidor los seguimientos de mantenimiento capturados sin conexion
/// (ver [ApiSyncRemote]). Las fotos no viajan en el lote: suben despues,
/// ligadas al seguimiento que creo el servidor.
class MaintenanceSyncRemote extends ApiSyncRemote {
  MaintenanceSyncRemote(
    super.api,
    super.deviceIdentifier, {
    ApiMaintenanceRepository? maintenance,
  }) : _maintenance = maintenance ?? ApiMaintenanceRepository(api);

  final ApiMaintenanceRepository _maintenance;

  @override
  Set<String> get entities => const {
    OfflineMaintenanceRepository.progressEntity,
  };

  @override
  Future<void> afterApplied(
    PendingOperation operation,
    String? recordId,
  ) async {
    final maintenanceId = operation.recordId;
    final photos = [
      for (final p
          in (operation.payload[OfflineMaintenanceRepository.photosKey]
                  as List?) ??
              const [])
        if (p is String) p,
    ];
    if (maintenanceId == null || photos.isEmpty) return;
    await _maintenance.attachPhotos(
      maintenanceId,
      photos,
      progressId: recordId,
      capturedAt:
          DateTime.tryParse(
            '${operation.payload[OfflineMaintenanceRepository.atKey] ?? ''}',
          ) ??
          operation.capturedAt,
    );
  }
}
