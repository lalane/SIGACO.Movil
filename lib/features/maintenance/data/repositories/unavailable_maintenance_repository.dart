import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Mientras el backend no publique los endpoints de mantenimiento, la pantalla
/// dice que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_MAINTENANCE=true` se usa [SampleMaintenanceRepository].
class UnavailableMaintenanceRepository implements MaintenanceRepository {
  const UnavailableMaintenanceRepository();

  static const _error = MaintenanceException(MaintenanceError.notAvailable);

  @override
  Future<List<MaintenanceIndicator>> visibleIndicators() async =>
      MaintenanceIndicator.values;

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      Future.error(_error);

  @override
  Future<MaintenanceOrder> get(String id) => Future.error(_error);

  @override
  Future<MaintenanceIndicatorSummary?> summary(
    MaintenanceIndicator indicator, {
    DateTime? from,
    DateTime? to,
  }) async => null;

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  }) => Future.error(_error);
}
