import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Mientras el backend no publique los endpoints de mantenimiento, la pantalla
/// dice que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_MAINTENANCE=true` se usa [SampleMaintenanceRepository].
class UnavailableMaintenanceRepository implements MaintenanceRepository {
  const UnavailableMaintenanceRepository();

  static const _error = MaintenanceException(MaintenanceError.notAvailable);

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      Future.error(_error);

  @override
  Future<MaintenanceOrder> get(String id) => Future.error(_error);

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    required double percent,
    double? executedVolume,
    String? notes,
    String? clientId,
  }) => Future.error(_error);
}
