import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/api_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/maintenance/domain/repositories/maintenance_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _dto(
  String id, {
  String status = 'EN_EJECUCION',
  String subsystem = 'SGS',
  num? unitCost = 100,
}) => {
  'id': id,
  'folio': 'MP-2026-000$id',
  'kind': 'MENOR',
  'activity': 'Limpieza de senales',
  'status': status,
  'subsystemCode': subsystem,
  'kmStart': 150.2,
  'kmEnd': 152,
  'direction': 'DECRECIENTE',
  'totalVolume': 200,
  'executedVolume': 50,
  'unit': 'm2',
  'unitCost': unitCost,
  'plannedStart': '2026-10-01T00:00:00Z',
  'plannedEnd': '2026-10-31T00:00:00Z',
  'actualStart': '2026-10-05T00:00:00Z',
};

Matcher _fails(MaintenanceError e) =>
    throwsA(isA<MaintenanceException>().having((x) => x.error, 'error', e));

void main() {
  late FakeApi api;
  late ApiMaintenanceRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiMaintenanceRepository(api.client());
  });

  test('un mantenimiento del servidor se ve como la app lo muestra', () async {
    api.on('GET /api/preventive-maintenance', FakeReply(200, {'items': [_dto('1')], 'total': 1}));
    final o = (await repo.list(MaintenanceIndicator.sgs)).single;

    expect(o.id, '1');
    expect(o.indicator, MaintenanceIndicator.sgs);
    expect(o.title, 'MP-2026-0001 · Limpieza de senales');
    expect(o.activity, 'Limpieza de senales');
    expect(o.status, MaintenanceStatus.inProgress);
    expect(o.totalVolume, 200);
    expect(o.executedVolume, 50);
    expect(o.progress, 0.25);
    expect(o.unit, 'm2');
    expect(o.unitCost, 100);
    expect(o.programmedAmount, 20000);
    expect(o.executedAmount, 5000);
    expect(o.pendingAmount, 15000);
    expect(o.kmStart, 'KM 150+200');
    expect(o.kmEnd, 'KM 152+000');
    expect(o.direction, 'Decreciente');
    // Si ya empezo, manda la fecha real.
    expect(o.startDate, DateTime.utc(2026, 10, 5));
    expect(o.endDate, DateTime.utc(2026, 10, 31));
  });

  test('el indicador es un filtro del servidor', () async {
    api.on('GET /api/preventive-maintenance', const FakeReply(200, {'items': <Object>[], 'total': 0}));
    await repo.list(MaintenanceIndicator.sgoae);
    expect(api.to('GET /api/preventive-maintenance').single.queryParameters['subsystemCode'], 'SGOAE');
    expect(ApiMaintenanceRepository.subsystemCode(MaintenanceIndicator.conservacion), 'CONSERVACION');
  });

  test('sin costo unitario no hay montos', () {
    final o = ApiMaintenanceRepository.orderFromDto(_dto('1', unitCost: null));
    expect(o.programmedAmount, isNull);
    expect(o.executedAmount, isNull);
    expect(o.pendingAmount, isNull);
  });

  test('los estados del servidor se agrupan en los tres de la app', () {
    expect(ApiMaintenanceRepository.statusFromCode('PROGRAMADO'), MaintenanceStatus.open);
    expect(ApiMaintenanceRepository.statusFromCode('EN_EJECUCION'), MaintenanceStatus.inProgress);
    expect(ApiMaintenanceRepository.statusFromCode('COMPLETADO'), MaintenanceStatus.closed);
    expect(ApiMaintenanceRepository.statusFromCode('CANCELADO'), MaintenanceStatus.closed);
  });

  test('la ficha saca el indicador del subsistema del servidor', () async {
    api.on('GET /api/preventive-maintenance/2', FakeReply(200, _dto('2', subsystem: 'SGOAC')));
    expect((await repo.get('2')).indicator, MaintenanceIndicator.sgoac);
    expect(ApiMaintenanceRepository.indicatorFromCode('desconocido'), MaintenanceIndicator.sgp);
  });

  test('trae todas las paginas', () async {
    api.reply('GET /api/preventive-maintenance', (o) => o.queryParameters['page'] == 1
        ? FakeReply(200, {'items': [_dto('1'), _dto('2')], 'total': 3})
        : FakeReply(200, {'items': [_dto('3')], 'total': 3}));
    expect((await repo.list(MaintenanceIndicator.sgs)).map((o) => o.id), ['1', '2', '3']);
  });

  test('el avance se envia con su clave y devuelve la orden', () async {
    api.on('POST /api/preventive-maintenance/1/progress', const FakeReply(201, {'id': 'p1'}));
    api.on('GET /api/preventive-maintenance/1', FakeReply(200, _dto('1')));
    final order = await repo.addProgress(
      '1',
      percent: 120,
      executedVolume: 60,
      notes: '  Se limpio el tramo  ',
      clientId: 'c0a80101-0000-4000-8000-000000000009',
    );
    expect(order.id, '1');
    final body = api.to('POST /api/preventive-maintenance/1/progress').single.data as Map;
    expect(body['progressPercent'], 100);
    expect(body['executedVolume'], 60);
    expect(body['notes'], 'Se limpio el tramo');
    expect(body['clientUuid'], 'c0a80101-0000-4000-8000-000000000009');
  });

  test('un avance sin permiso o sin red lo dice', () async {
    api.on('POST /api/preventive-maintenance/1/progress', const FakeReply(403));
    await expectLater(repo.addProgress('1', percent: 10), _fails(MaintenanceError.permissionDenied));
    api.offline = true;
    await expectLater(repo.addProgress('1', percent: 10), _fails(MaintenanceError.network));
  });

  test('traduce los errores del servidor', () async {
    api.on('GET /api/preventive-maintenance', const FakeReply(403));
    await expectLater(repo.list(MaintenanceIndicator.sgs), _fails(MaintenanceError.permissionDenied));
    api.on('GET /api/preventive-maintenance', const FakeReply(404));
    await expectLater(repo.list(MaintenanceIndicator.sgs), _fails(MaintenanceError.notAvailable));
    api.on('GET /api/preventive-maintenance', const FakeReply(200, {'total': 1}));
    await expectLater(repo.list(MaintenanceIndicator.sgs), _fails(MaintenanceError.server));
    api.on('GET /api/preventive-maintenance/x', const FakeReply(404));
    await expectLater(repo.get('x'), _fails(MaintenanceError.notFound));
    api.offline = true;
    await expectLater(repo.list(MaintenanceIndicator.sgs), _fails(MaintenanceError.network));
  });
}
