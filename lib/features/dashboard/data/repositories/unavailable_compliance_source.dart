import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/compliance_source.dart';

/// Mientras el servidor no publique el cumplimiento por indicador, el bloque
/// dice que aun no esta disponible en lugar de mostrar cifras inventadas. Con
/// los datos de ejemplo se usa `SampleComplianceSource`.
class UnavailableComplianceSource implements ComplianceSource {
  const UnavailableComplianceSource();

  @override
  Future<ComplianceSummary> load() =>
      Future.error(const ComplianceException(DashboardError.notAvailable));
}
