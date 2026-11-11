import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/api_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/maintenance/presentation/bloc/maintenance_cubit.dart';

import '../../support/fake_api.dart';

/// Repositorio de ejemplo que cuenta las consultas del resumen y responde con
/// lo que la prueba le dice (HU-MC-15).
class _SummaryRepo extends SampleMaintenanceRepository {
  final calls = <(DateTime?, DateTime?)>[];
  MaintenanceIndicatorSummary? reply;

  @override
  Future<MaintenanceIndicatorSummary?> summary(
    MaintenanceIndicator indicator, {
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add((from, to));
    return reply;
  }
}

void main() {
  test('el resumen del servidor trae tickets, evaluacion y propuestas', () async {
    final api = FakeApi();
    api.on(
      'GET /api/maintenance/subsystems/SGTEC/summary',
      const FakeReply(200, {
        'subsystemCode': 'SGTEC',
        'ticketsTotal': 7,
        'ticketsOpen': 4,
        'ticketsAttended': 2,
        'ticketsClosed': 1,
        'openNonConformities': 3,
        'latestEvaluation': {'concessionYear': 2, 'compliancePercent': 50.5},
      }),
    );
    final repo = ApiMaintenanceRepository(api.client());

    final s = await repo.summary(
      MaintenanceIndicator.sgtec,
      from: DateTime(2026, 2, 6),
      to: DateTime(2026, 11, 10),
    );

    expect(s, isNotNull);
    expect((s!.ticketsTotal, s.ticketsOpen, s.ticketsAttended, s.ticketsClosed), (7, 4, 2, 1));
    expect((s.compliancePercent, s.evaluationYear, s.openProposals), (50.5, 2, 3));
    final query = api.requests.single.queryParameters;
    // El dia final se incluye completo.
    expect(DateTime.parse(query['to'] as String).toLocal().hour, 23);
    expect(DateTime.parse(query['from'] as String).toLocal().day, 6);
  });

  test('sin el endpoint o sin evaluacion la pantalla sigue sin conteos', () async {
    final api = FakeApi();
    api.on('GET /api/maintenance/subsystems/SGS/summary', const FakeReply(404));
    expect(await ApiMaintenanceRepository(api.client()).summary(MaintenanceIndicator.sgs), isNull);

    api.on(
      'GET /api/maintenance/subsystems/SGS/summary',
      const FakeReply(200, {'ticketsTotal': 1, 'ticketsOpen': 1, 'latestEvaluation': null}),
    );
    final s = await ApiMaintenanceRepository(api.client()).summary(MaintenanceIndicator.sgs);
    expect((s!.ticketsTotal, s.compliancePercent, s.evaluationYear), (1, null, null));
  });

  test('el cubit trae el resumen al cargar y lo vuelve a pedir con las fechas', () async {
    final repo = _SummaryRepo()
      ..reply = const MaintenanceIndicatorSummary(ticketsTotal: 3, ticketsOpen: 2, ticketsAttended: 1, ticketsClosed: 0);
    final cubit = MaintenanceCubit(repo, MaintenanceIndicator.sgs);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.summary?.ticketsTotal, 3);

    final from = DateTime(2026, 2, 6);
    cubit.setFrom(from);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.last, (from, null));

    repo.reply = null;
    cubit.clearFilters();
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.last, (null, null));
    expect(cubit.state.summary, isNull);
    await cubit.close();
  });
}
