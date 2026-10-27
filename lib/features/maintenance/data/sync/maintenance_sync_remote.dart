import '../../../../core/offline/api_sync_remote.dart';
import '../repositories/offline_maintenance_repository.dart';

/// Envia al servidor los avances de mantenimiento capturados sin conexion (ver
/// [ApiSyncRemote]). El avance no trae nada que subir despues.
class MaintenanceSyncRemote extends ApiSyncRemote {
  MaintenanceSyncRemote(super.api, super.deviceIdentifier);

  @override
  Set<String> get entities => const {
    OfflineMaintenanceRepository.progressEntity,
  };
}
