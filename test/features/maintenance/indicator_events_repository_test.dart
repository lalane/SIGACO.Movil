import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/api_indicator_events_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/maintenance/domain/repositories/indicator_events_repository.dart';

import '../../support/fake_api.dart';

void main() {
  late FakeApi api;
  late ApiIndicatorEventsRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiIndicatorEventsRepository(api.client());
  });

  test(
    'los eventos del SGITS traen horas computables y el semáforo del SLA',
    () async {
      api.on(
        'GET /api/maintenance/indicators/SGITS/events',
        FakeReply(200, {
          'items': [
            {
              'id': 'e1',
              'folio': 'EV-2026-000001',
              'assetCode': 'NV3810020',
              'startedAt': '2026-03-02T10:00:00Z',
              'endedAt': null,
              'status': 'PENDIENTE_APROBACION',
              'computableHours': 80.5,
              'slaHours': 72,
              'slaState': 'EXCEDIDO',
              'cause': 'Sin comunicación',
            },
          ],
          'total': 1,
        }),
      );
      final e = (await repo.events(MaintenanceIndicator.sgits)).single;
      expect(e.folio, 'EV-2026-000001');
      expect(e.open, isTrue);
      expect(e.computableHours, 80.5);
      expect(e.slaHours, 72);
      expect(e.slaState, 'EXCEDIDO');
    },
  );

  test('el desempeño trae un estado por parámetro del PER', () async {
    api.on(
      'GET /api/maintenance/indicators/SGF/performance',
      FakeReply(200, {
        'parameters': [
          {
            'code': 'SGF-08',
            'name': 'Notificación',
            'status': 'NO_CUMPLE',
            'reason': '0 de 573',
          },
          {
            'code': 'SGF-09',
            'name': 'Regularización',
            'status': 'AUN_NO_EXIGIBLE',
            'reason': 'Año 5',
          },
        ],
      }),
    );
    final result = await repo.performance(MaintenanceIndicator.sgf);
    expect(result.map((p) => (p.code, p.status)), [
      ('SGF-08', 'NO_CUMPLE'),
      ('SGF-09', 'AUN_NO_EXIGIBLE'),
    ]);
  });

  test(
    'registrar un evento manda el equipo, la hora en UTC y el identificador de captura',
    () async {
      api.on(
        'POST /api/maintenance/indicators/SGSEI/events',
        FakeReply(201, {
          'id': 'e2',
          'folio': 'EV-2026-000002',
          'assetCode': 'POSTE-1',
          'startedAt': '2026-03-02T10:00:00Z',
          'status': 'VIGENTE',
          'computableHours': 1,
          'slaState': 'SIN_SLA',
        }),
      );
      final created = await repo.create(
        MaintenanceIndicator.sgsei,
        assetId: 'a1',
        startedAt: DateTime.utc(2026, 3, 2, 10),
        cause: 'Luminarias apagadas',
        clientUuid: 'c1',
      );
      expect(created.status, 'VIGENTE');
      final sent = api.requests.single.data as Map;
      expect(sent['assetId'], 'a1');
      expect(sent['startedAt'], '2026-03-02T10:00:00.000Z');
      expect(sent['clientUuid'], 'c1');
    },
  );

  test('el buscador de túneles pide OAE y no filtra por subsistema', () async {
    api.on('GET /api/assets', FakeReply(200, {'items': <Object>[]}));
    await repo.searchAssets(MaintenanceIndicator.sgost, 'Tunel');
    final query = api.requests.single.queryParameters;
    expect(query['assetTypeCode'], 'OAE');
    expect(query.containsKey('subsystemCode'), isFalse);
  });

  test('un evento que el servidor rechaza por regla dice por que', () async {
    // Encontrado en la prueba de punta a punta: el equipo ITS sin clasificar
    // respondia 409 y la app solo decia «No se pudo registrar el evento».
    api.on(
      'POST /api/maintenance/indicators/SGITS/events',
      const FakeReply(409, {
        'code': 'ITS_EQUIPMENT_NOT_CLASSIFIED',
        'title': 'Clasifique el equipo antes de registrar su indisponibilidad.',
      }),
    );
    await expectLater(
      repo.create(
        MaintenanceIndicator.sgits,
        assetId: 'a1',
        startedAt: DateTime.utc(2026, 11, 10, 22),
        cause: 'Sin energia',
        clientUuid: 'c1',
      ),
      throwsA(
        isA<IndicatorEventRejected>().having(
          (e) => e.reason,
          'reason',
          'Clasifique el equipo antes de registrar su indisponibilidad. '
              '(ITS_EQUIPMENT_NOT_CLASSIFIED)',
        ),
      ),
    );
  });
}
