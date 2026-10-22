import '../entities/dashboard_summary.dart';

/// Lanzada por una fuente de cumplimiento; la app la traduce al bloque del
/// tablero.
class ComplianceException implements Exception {
  const ComplianceException(this.error);

  final DashboardError error;

  @override
  String toString() => 'ComplianceException($error)';
}

/// El cumplimiento por indicador de la concesion activa. Lo calcula el servidor
/// (las formulas y los umbrales son de TEKIA: BBP §7.8 y OI-30); la app no los
/// inventa. Lanza [ComplianceException].
abstract interface class ComplianceSource {
  Future<ComplianceSummary> load();
}
