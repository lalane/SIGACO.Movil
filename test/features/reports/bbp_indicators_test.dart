import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/composition/maintenance_reports_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/reports/domain/entities/indicator_report.dart';

/// Los indicadores del selector de la app movil segun el BBP aprobado (V230926,
/// §7.8): SGP, SGS, SGOAE, SGOAC, SGITS, Conservacion, SGE, SGTEC, SGSEI, SGOST
/// y SGF, en ese orden.
void main() {
  const bbpOrder = [
    'sgp',
    'sgs',
    'sgoae',
    'sgoac',
    'sgits',
    'conservacion',
    'sge',
    'sgtec',
    'sgsei',
    'sgost',
    'sgf',
  ];

  test('son once y en el orden del BBP', () {
    expect(MaintenanceIndicator.values.map((i) => i.name), bbpOrder);
    expect(ReportIndicator.values.map((i) => i.name), bbpOrder);
  });

  test('los reportes y el mantenimiento comparten los mismos indicadores', () {
    expect(
      ReportIndicator.values.map((i) => i.name),
      MaintenanceIndicator.values.map((i) => i.name),
    );
  });

  test('los indicadores nuevos tienen mantenimientos de ejemplo', () async {
    final repo = SampleMaintenanceRepository();
    for (final i in [
      MaintenanceIndicator.conservacion,
      MaintenanceIndicator.sgsei,
      MaintenanceIndicator.sgost,
    ]) {
      expect(await repo.list(i), isNotEmpty, reason: i.name);
    }
  });

  test('cada indicador genera un reporte solo con sus lineas', () async {
    final reports = MaintenanceReportsRepository(SampleMaintenanceRepository());
    for (final i in ReportIndicator.values) {
      final report = await reports.generate(i);

      expect(report.indicator, i);
      expect(report.lines.every((l) => l.indicator == i), isTrue);
    }
  });
}
