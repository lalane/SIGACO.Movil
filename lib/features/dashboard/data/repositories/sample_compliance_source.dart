import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/compliance_source.dart';

/// Cifras de ejemplo con la forma del BBP (§7.8: 72 %, 2 de 11 indicadores,
/// conteo por estado). No son resultados reales: los estados y las metas salen
/// de reglas que TEKIA aun no define.
class SampleComplianceSource implements ComplianceSource {
  const SampleComplianceSource();

  static const _indicators = [
    IndicatorCompliance(
      code: 'sgp',
      percent: 82,
      status: IndicatorStatus.good,
      met: true,
    ),
    IndicatorCompliance(
      code: 'sgs',
      percent: 76,
      status: IndicatorStatus.good,
      met: true,
    ),
    IndicatorCompliance(
      code: 'sgoae',
      percent: 68,
      status: IndicatorStatus.intermediate,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgoac',
      percent: 91,
      status: IndicatorStatus.good,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgits',
      percent: 45,
      status: IndicatorStatus.bad,
      met: false,
    ),
    IndicatorCompliance(
      code: 'conservacion',
      percent: 60,
      status: IndicatorStatus.intermediate,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sge',
      percent: 88,
      status: IndicatorStatus.good,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgtec',
      percent: 30,
      status: IndicatorStatus.inProcess,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgsei',
      percent: 52,
      status: IndicatorStatus.bad,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgost',
      percent: 74,
      status: IndicatorStatus.intermediate,
      met: false,
    ),
    IndicatorCompliance(
      code: 'sgf',
      percent: 20,
      status: IndicatorStatus.inProcess,
      met: false,
    ),
  ];

  static const _tickets = [
    SubsystemTickets(code: 'sgs', count: 9),
    SubsystemTickets(code: 'sgp', count: 7),
    SubsystemTickets(code: 'sgits', count: 5),
    SubsystemTickets(code: 'sge', count: 4),
    SubsystemTickets(code: 'conservacion', count: 2),
  ];

  @override
  Future<ComplianceSummary> load() async => const ComplianceSummary(
    overall: 72,
    overallStatus: IndicatorStatus.good,
    indicators: _indicators,
    ticketsBySubsystem: _tickets,
  );
}
