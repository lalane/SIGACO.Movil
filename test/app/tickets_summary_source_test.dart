import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/composition/composed_dashboard_repository.dart';
import 'package:sigaco_movil/app/composition/tickets_summary_source.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/unavailable_accidents_repository.dart';
import 'package:sigaco_movil/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/unavailable_inventory_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/unavailable_maintenance_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';

import '../support/fake_api.dart';

const _summary = {
  'total': 12,
  'open': 7,
  'attended': 5,
  'overdue': 3,
  'byStatus': [
    {'code': 'NUEVO', 'label': 'Nuevo', 'count': 7},
  ],
  'bySubsystem': [
    {'code': 'SGP', 'label': 'Pavimento', 'count': 4},
  ],
  'topCreators': [
    {'userId': 'u1', 'name': 'Ana Ruiz', 'count': 6},
    {'userId': 'u2', 'name': 'Luis Paz', 'count': 4},
  ],
};

/// El dashboard toma los tickets del resumen del servidor (MOB-019) y solo
/// cuenta las listas cuando no hay resumen.
void main() {
  late FakeApi api;

  setUp(() => api = FakeApi());

  ComposedDashboardRepository dashboard(TicketsSummarySource source) =>
      ComposedDashboardRepository(
        tickets: SampleTicketsRepository(),
        accidents: const UnavailableAccidentsRepository(),
        maintenance: const UnavailableMaintenanceRepository(),
        inventory: const UnavailableInventoryRepository(),
        ticketsSummary: source,
      );

  test('traduce el resumen del servidor', () async {
    api.on('GET /api/tickets/summary', const FakeReply(200, _summary));
    final summary = await ApiTicketsSummarySource(api.client()).load();
    expect(summary!.open, 7);
    expect(summary.attended, 5);
    expect(summary.overdue, 3);
    expect(summary.creators.map((c) => (c.name, c.count)), [
      ('Ana Ruiz', 6),
      ('Luis Paz', 4),
    ]);
  });

  test('sin los tres conteos no se usa', () async {
    api.on('GET /api/tickets/summary', const FakeReply(200, {'open': 1}));
    expect(await ApiTicketsSummarySource(api.client()).load(), isNull);
  });

  test('con datos de ejemplo no se pregunta al servidor', () async {
    final source = ApiTicketsSummarySource(api.client(), enabled: () => false);
    expect(await source.load(), isNull);
    expect(api.requests, isEmpty);
  });

  test('sin red o sin permiso se cae a las listas', () async {
    api.offline = true;
    expect(await ApiTicketsSummarySource(api.client()).load(), isNull);
    api.offline = false;
    api.on('GET /api/tickets/summary', const FakeReply(403));
    expect(await ApiTicketsSummarySource(api.client()).load(), isNull);
  });

  test('el dashboard usa el resumen del servidor', () async {
    api.on('GET /api/tickets/summary', const FakeReply(200, _summary));
    final result = await dashboard(
      ApiTicketsSummarySource(api.client()),
    ).load();
    expect(result.tickets!.open, 7);
    expect(result.tickets!.overdue, 3);
    expect(result.errors.containsKey(DashboardSection.tickets), isFalse);
  });

  test('sin resumen el dashboard cuenta las listas', () async {
    final result = await dashboard(const NoTicketsSummarySource()).load();
    final all = await SampleTicketsRepository().list();
    expect(result.tickets!.open + result.tickets!.attended, all.length);
  });
}
