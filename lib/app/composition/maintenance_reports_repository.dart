import '../../features/maintenance/domain/entities/maintenance.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/reports/domain/entities/indicator_report.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';

/// Arma el reporte con los mantenimientos del indicador, que ya trae el modulo
/// de mantenimiento. Va en `app/` porque junta dos modulos. Mientras el backend
/// no publique un endpoint de reportes, los datos son los mismos que se ven en
/// la lista de mantenimiento (de ejemplo o reales); cuando exista, se cambia
/// esta clase por la que lo llame.
class MaintenanceReportsRepository implements ReportsRepository {
  MaintenanceReportsRepository(this._maintenance, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final MaintenanceRepository _maintenance;
  final DateTime Function() _clock;

  static ReportLineStatus _status(MaintenanceStatus s) => switch (s) {
    MaintenanceStatus.open => ReportLineStatus.open,
    MaintenanceStatus.inProgress => ReportLineStatus.inProgress,
    MaintenanceStatus.closed => ReportLineStatus.closed,
  };

  @override
  Future<IndicatorReport> generate(
    ReportIndicator indicator, {
    DateTime? from,
    DateTime? to,
  }) async {
    final List<MaintenanceOrder> all;
    try {
      all = await _maintenance.list(
        MaintenanceIndicator.values.byName(indicator.name),
      );
    } on MaintenanceException catch (e) {
      throw ReportException(switch (e.error) {
        MaintenanceError.network => ReportError.network,
        MaintenanceError.permissionDenied => ReportError.permissionDenied,
        MaintenanceError.notAvailable => ReportError.notAvailable,
        MaintenanceError.server ||
        MaintenanceError.notFound => ReportError.server,
      });
    }
    final lines = [
      for (final o in all)
        ReportLine(
          id: o.id,
          indicator: indicator,
          title: o.title,
          activity: o.activity,
          status: _status(o.status),
          totalVolume: o.totalVolume,
          executedVolume: o.executedVolume,
          unit: o.unit,
          programmedAmount: o.programmedAmount,
          executedAmount: o.executedAmount,
          startDate: o.startDate,
          endDate: o.endDate,
        ),
    ].where((l) => l.startsIn(from, to)).toList();
    // La mas reciente (por inicio) primero.
    lines.sort((a, b) {
      final x = a.startDate;
      final y = b.startDate;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return IndicatorReport(
      indicator: indicator,
      generatedAt: _clock().toUtc(),
      from: from,
      to: to,
      lines: lines,
    );
  }
}
