import '../entities/indicator_events.dart';
import '../entities/maintenance.dart';

/// El servidor no acepto el evento por una regla (por ejemplo, el equipo aun
/// no esta clasificado): [reason] es lo que dijo, con su codigo, para que la
/// persona sepa que hacer. Sin red u otro fallo llegan como siempre.
class IndicatorEventRejected implements Exception {
  const IndicatorEventRejected(this.reason);

  final String reason;

  @override
  String toString() => 'IndicatorEventRejected($reason)';
}

/// Desempeño y eventos de los indicadores de MC2
/// (`/api/maintenance/indicators/{code}`).
abstract class IndicatorEventsRepository {
  Future<List<IndicatorEvent>> events(MaintenanceIndicator indicator);

  Future<List<IndicatorParameterStatus>> performance(
    MaintenanceIndicator indicator,
  );

  Future<List<IndicatorAssetOption>> searchAssets(
    MaintenanceIndicator indicator,
    String term,
  );

  /// Registra el evento; en el SGITS nace pendiente de aprobación (lo aprueba
  /// el supervisor en la web con la evidencia).
  Future<IndicatorEvent> create(
    MaintenanceIndicator indicator, {
    required String assetId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String cause,
    required String clientUuid,
  });
}
