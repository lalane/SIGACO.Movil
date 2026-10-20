import '../entities/indicator_report.dart';

/// Por que no se pudo generar el reporte.
enum ReportError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver ese indicador.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica los datos de esta concesion.
  notAvailable,
}

class ReportException implements Exception {
  const ReportException(this.error);

  final ReportError error;

  @override
  String toString() => 'ReportException($error)';
}

/// Los reportes de la concesion activa. Lanza [ReportException].
abstract interface class ReportsRepository {
  /// El reporte de [indicator] en el periodo [from]-[to] (ambos dias
  /// incluidos); sin limites, todo el historial.
  Future<IndicatorReport> generate(
    ReportIndicator indicator, {
    DateTime? from,
    DateTime? to,
  });
}
