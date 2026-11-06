import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/works/data/repositories/api_works_repository.dart';
import 'package:sigaco_movil/features/works/domain/entities/public_work.dart';
import 'package:sigaco_movil/features/works/domain/repositories/works_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _dto(
  String id, {
  String status = 'EN_EJECUCION',
  String name = 'Repavimentacion km 500',
}) => {
  'id': id,
  'code': 'OB-$id',
  'name': name,
  'status': status,
  'direction': 'CRECIENTE',
  'kmStart': 500.2,
  'kmEnd': 505,
  'plannedStart': '2026-03-01T00:00:00Z',
  'plannedEnd': '2026-12-31T00:00:00Z',
  'actualStart': '2026-03-10T00:00:00Z',
  'budget': 1500000,
  'description': 'Carril derecho',
  'geometry': {
    'type': 'LineString',
    'coordinates': [
      [-41.9, -18.8],
      [-41.8, -18.7],
      [-41.7, -18.6],
    ],
  },
};

const _summary = {
  'workId': 'w1',
  'physicalPercent': 35.5,
  'plannedPercent': 40,
  'executedAmount': 400000,
};

Matcher _fails(WorksError e) =>
    throwsA(isA<WorksException>().having((x) => x.error, 'error', e));

void main() {
  late FakeApi api;
  late ApiWorksRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiWorksRepository(api.client());
  });

  test('una obra del servidor se ve como la app la muestra', () async {
    api.on(
      'GET /api/works',
      FakeReply(200, {
        'items': [_dto('w1')],
        'total': 1,
      }),
    );
    api.on('GET /api/works/w1/summary', const FakeReply(200, _summary));

    final works = await repo.list();
    final w = works.single;
    expect(w.id, 'w1');
    expect(w.name, 'Repavimentacion km 500');
    expect(w.status, WorkStatus.inProgress);
    expect(w.physicalProgress, closeTo(0.355, 1e-9));
    expect(w.programmedProgress, 0.4);
    expect(w.budget, 1500000);
    expect(w.executedAmount, 400000);
    expect(w.pendingAmount, 1100000);
    expect(w.kmStart, 'KM 500+200');
    expect(w.kmEnd, 'KM 505+000');
    expect(w.direction, 'Creciente');
    expect(w.description, 'Carril derecho');
    expect(w.startDate, DateTime.utc(2026, 3, 10));
    expect(w.endDate, DateTime.utc(2026, 12, 31));
    // El punto es el de en medio de la linea.
    expect(w.latitude, -18.7);
    expect(w.longitude, -41.8);
    expect(w.hasLocation, isTrue);
  });

  test('los estados del servidor se agrupan en los cuatro de la app', () {
    expect(
      ApiWorksRepository.statusFromCode('PLANIFICADA'),
      WorkStatus.notStarted,
    );
    expect(
      ApiWorksRepository.statusFromCode('APROBADA'),
      WorkStatus.notStarted,
    );
    expect(
      ApiWorksRepository.statusFromCode('EN_EJECUCION'),
      WorkStatus.inProgress,
    );
    expect(ApiWorksRepository.statusFromCode('SUSPENDIDA'), WorkStatus.delayed);
    expect(
      ApiWorksRepository.statusFromCode('CON_DESVIACION'),
      WorkStatus.delayed,
    );
    expect(ApiWorksRepository.statusFromCode('TERMINADA'), WorkStatus.finished);
    expect(ApiWorksRepository.statusFromCode('CERRADA'), WorkStatus.finished);
  });

  test('una obra cancelada no se muestra', () async {
    api.on(
      'GET /api/works',
      FakeReply(200, {
        'items': [_dto('w1'), _dto('w2', status: 'CANCELADA')],
        'total': 2,
      }),
    );
    api.on('GET /api/works/w1/summary', const FakeReply(200, _summary));
    expect((await repo.list()).map((w) => w.id), ['w1']);
    expect(api.to('GET /api/works/w2/summary'), isEmpty);
  });

  test(
    'un resumen que no baja deja la obra sin avance, no sin lista',
    () async {
      api.on(
        'GET /api/works',
        FakeReply(200, {
          'items': [_dto('w1')],
          'total': 1,
        }),
      );
      api.on('GET /api/works/w1/summary', const FakeReply(500));
      final w = (await repo.list()).single;
      expect(w.physicalProgress, 0);
      expect(w.programmedProgress, 0);
      expect(w.executedAmount, isNull);
    },
  );

  test('el avance se acota entre 0 y 100 por ciento', () {
    final w = ApiWorksRepository.workFromDto(_dto('w1'), const {
      'physicalPercent': 130,
      'plannedPercent': -5,
    });
    expect(w.physicalProgress, 1);
    expect(w.programmedProgress, 0);
  });

  test('trae todas las paginas', () async {
    api.reply('GET /api/works', (o) {
      final page = o.queryParameters['page'];
      return page == 1
          ? FakeReply(200, {
              'items': [_dto('w1'), _dto('w2')],
              'total': 3,
            })
          : FakeReply(200, {
              'items': [_dto('w3')],
              'total': 3,
            });
    });
    for (final id in ['w1', 'w2', 'w3']) {
      api.on('GET /api/works/$id/summary', const FakeReply(200, _summary));
    }
    expect((await repo.list()).map((w) => w.id), ['w1', 'w2', 'w3']);
  });

  test('la ficha trae la obra con su resumen', () async {
    api.on('GET /api/works/w1', FakeReply(200, _dto('w1')));
    api.on('GET /api/works/w1/summary', const FakeReply(200, _summary));
    final w = await repo.get('w1');
    expect(w.physicalProgress, closeTo(0.355, 1e-9));
  });

  test('en la ficha, un resumen que falla es un error', () async {
    api.on('GET /api/works/w1', FakeReply(200, _dto('w1')));
    api.on('GET /api/works/w1/summary', const FakeReply(500));
    await expectLater(repo.get('w1'), _fails(WorksError.server));
  });

  test('traduce los errores del servidor', () async {
    api.on('GET /api/works', const FakeReply(403));
    await expectLater(repo.list(), _fails(WorksError.permissionDenied));
    api.on('GET /api/works', const FakeReply(404));
    await expectLater(repo.list(), _fails(WorksError.notAvailable));
    api.on('GET /api/works', const FakeReply(200, {'total': 1}));
    await expectLater(repo.list(), _fails(WorksError.server));
    api.on('GET /api/works/x', const FakeReply(404));
    await expectLater(repo.get('x'), _fails(WorksError.notFound));
    api.offline = true;
    await expectLater(repo.list(), _fails(WorksError.network));
  });
}
