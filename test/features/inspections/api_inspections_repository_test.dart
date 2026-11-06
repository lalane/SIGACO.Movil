import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/api_inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/domain/entities/inspection.dart';
import 'package:sigaco_movil/features/inspections/domain/repositories/inspections_repository.dart';

import '../../support/fake_api.dart';

const _types = [
  {
    'code': 'SENALIZACION',
    'labelEs': 'Señalización',
    'labelPt': 'Sinalização',
    'active': true,
    'checklist': [
      {'key': 'LEGIBLE', 'label': 'Legible'},
      {'key': 'ANCLAJE', 'label': 'Anclaje firme', 'critical': true},
    ],
  },
  {'code': 'VIEJO', 'labelEs': 'Obsoleto', 'active': false, 'checklist': []},
];

Map<String, Object?> _dto(
  String id, {
  String status = 'ASIGNADA',
  String? notes = 'Revision del km 150',
  int rowVersion = 2,
}) => {
  'id': id,
  'folio': 'IN-2026-000$id',
  'inspectionTypeCode': 'SENALIZACION',
  'status': status,
  'assetId': 'a1',
  'assetCode': 'SEN-000001',
  'kmStart': 150.2,
  'kmEnd': null,
  'direction': 'CRECIENTE',
  'inspectorName': 'Ana Lopez',
  'scheduledOn': '2026-10-25',
  'executedAt': '2026-10-26T15:00:00Z',
  'notes': notes,
  'rowVersion': rowVersion,
};

Matcher _fails(InspectionsError e) =>
    throwsA(isA<InspectionsException>().having((x) => x.error, 'error', e));

Directory _tempDir() {
  final dir = Directory.systemTemp.createTempSync('in_');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Lo recoge el sistema.
    }
  });
  return dir;
}

void main() {
  late FakeApi api;
  late ApiInspectionsRepository repo;
  var lang = 'es';
  String? road = 'road-1';

  setUp(() {
    api = FakeApi();
    lang = 'es';
    road = 'road-1';
    repo = ApiInspectionsRepository(
      api.client(),
      roadId: () async => road,
      userId: () async => 'user-1',
      language: () => lang,
    );
    api.on('GET /api/inspection-types', const FakeReply(200, _types));
  });

  group('traduccion', () {
    test('los estados del servidor se agrupan en los de la app', () {
      expect(
        ApiInspectionsRepository.statusFromCode('PENDIENTE'),
        InspectionStatus.pending,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('ASIGNADA'),
        InspectionStatus.pending,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('EN_PROCESO'),
        InspectionStatus.inProgress,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('ATENDIDA'),
        InspectionStatus.attended,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('EN_REVISION'),
        InspectionStatus.attended,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('CERRADA'),
        InspectionStatus.closed,
      );
      expect(
        ApiInspectionsRepository.statusFromCode('CANCELADA'),
        InspectionStatus.cancelled,
      );
    });

    test('conforme es bien, no conforme es hallazgo', () {
      expect(
        ApiInspectionsRepository.resultsFromJson([
          {'parameter': 'LEGIBLE', 'status': 'CONFORME'},
          {'parameter': 'ANCLAJE', 'status': 'NO_CONFORME'},
          {'parameter': 'OTRO', 'status': 'NO_APLICA'},
        ]),
        {
          'LEGIBLE': CheckResult.ok,
          'ANCLAJE': CheckResult.finding,
          'OTRO': CheckResult.pending,
        },
      );
    });

    test('solo se manda lo contestado', () {
      expect(
        ApiInspectionsRepository.resultsToJson({
          'LEGIBLE': CheckResult.ok,
          'ANCLAJE': CheckResult.finding,
          'X': CheckResult.pending,
        }),
        [
          {'parameter': 'LEGIBLE', 'value': 'CONFORME', 'status': 'CONFORME'},
          {
            'parameter': 'ANCLAJE',
            'value': 'NO_CONFORME',
            'status': 'NO_CONFORME',
          },
        ],
      );
    });
  });

  group('lista y ficha', () {
    void server() {
      api.on(
        'GET /api/inspections',
        FakeReply(200, {
          'items': [_dto('1'), _dto('2', notes: null, status: 'CERRADA')],
          'total': 2,
        }),
      );
      api.on(
        'GET /api/inspections/1/results',
        const FakeReply(200, [
          {'parameter': 'LEGIBLE', 'status': 'CONFORME'},
        ]),
      );
      api.on(
        'GET /api/inspections/2/results',
        const FakeReply(200, <Object>[]),
      );
    }

    test(
      'arma la inspeccion con el checklist del tipo y sus resultados',
      () async {
        server();
        final list = await repo.list();
        final i = list.first;
        expect(i.id, '1');
        expect(i.title, 'Revision del km 150');
        expect(i.type, 'Señalización');
        expect(i.status, InspectionStatus.pending);
        expect(i.assignee, 'Ana Lopez');
        expect(i.assetName, 'SEN-000001');
        expect(i.kmLabel, 'KM 150+200');
        expect(i.direction, 'Creciente');
        expect(i.scheduledAt, DateTime.utc(2026, 10, 25));
        expect(i.checklist.map((c) => c.id), ['LEGIBLE', 'ANCLAJE']);
        expect(i.checklist.first.result, CheckResult.ok);
        expect(i.checklist.last.result, CheckResult.pending);
        expect(i.checklist.last.critical, isTrue);
        expect(i.answered, 1);
      },
    );

    test('sin notas, el titulo es el tipo y el folio', () async {
      server();
      expect((await repo.list()).last.title, 'Señalización · IN-2026-0002');
    });

    test('en portugues usa el nombre del tipo en portugues', () async {
      lang = 'pt';
      server();
      expect((await repo.list()).first.type, 'Sinalização');
    });

    test('un resultado que no baja no tira la lista', () async {
      server();
      api.on('GET /api/inspections/1/results', const FakeReply(500));
      expect((await repo.list()).first.answered, 0);
    });

    test('en la ficha, un resultado que falla es un error', () async {
      api.on('GET /api/inspections/1', FakeReply(200, _dto('1')));
      api.on('GET /api/inspections/1/results', const FakeReply(500));
      await expectLater(repo.get('1'), _fails(InspectionsError.server));
    });

    test('errores del servidor segun el estado', () async {
      api.on('GET /api/inspections', const FakeReply(403));
      await expectLater(repo.list(), _fails(InspectionsError.permissionDenied));
      api.on('GET /api/inspections', const FakeReply(404));
      await expectLater(repo.list(), _fails(InspectionsError.notAvailable));
      api.on('GET /api/inspections/9', const FakeReply(404));
      await expectLater(repo.get('9'), _fails(InspectionsError.notFound));
      api.offline = true;
      await expectLater(repo.list(), _fails(InspectionsError.network));
    });
  });

  test('las plantillas salen de los tipos activos', () async {
    final t = await repo.templates();
    expect(t.map((x) => x.type), ['Señalización']);
    expect(t.single.items.map((i) => i.text), ['Legible', 'Anclaje firme']);
  });

  group('contestar y terminar', () {
    void server({required String status}) {
      api.on(
        'GET /api/inspections/1',
        FakeReply(200, _dto('1', status: status, rowVersion: 7)),
      );
      api.on(
        'GET /api/inspections/1/results',
        const FakeReply(200, <Object>[]),
      );
      api.on('PUT /api/inspections/1/results', const FakeReply(200));
      api.on(
        'POST /api/inspections/1/status',
        FakeReply(200, _dto('1', status: 'EN_PROCESO')),
      );
    }

    const answers = {'LEGIBLE': CheckResult.ok, 'ANCLAJE': CheckResult.finding};

    test(
      'guardar una asignada la pone en proceso y manda los resultados',
      () async {
        server(status: 'ASIGNADA');
        await repo.saveAnswers('1', answers);
        expect(api.to('POST /api/inspections/1/status').single.data, {
          'status': 'EN_PROCESO',
          'rowVersion': 7,
        });
        expect(
          api.to('PUT /api/inspections/1/results').single.data,
          hasLength(2),
        );
      },
    );

    test('guardar una que ya esta en proceso no cambia el estado', () async {
      server(status: 'EN_PROCESO');
      await repo.saveAnswers('1', answers);
      expect(api.to('POST /api/inspections/1/status'), isEmpty);
    });

    test('terminar la pasa a atendida', () async {
      server(status: 'EN_PROCESO');
      await repo.complete('1', answers);
      expect(api.to('POST /api/inspections/1/status').single.data, {
        'status': 'ATENDIDA',
        'rowVersion': 7,
      });
    });

    test('terminar con algo sin contestar no manda nada', () async {
      server(status: 'EN_PROCESO');
      await expectLater(
        repo.complete('1', {
          'LEGIBLE': CheckResult.ok,
          'ANCLAJE': CheckResult.pending,
        }),
        _fails(InspectionsError.incomplete),
      );
      expect(api.requests, isEmpty);
    });

    test('un conflicto del servidor es que ya no se puede editar', () async {
      server(status: 'EN_PROCESO');
      api.on(
        'PUT /api/inspections/1/results',
        const FakeReply(409, {'code': 'X'}),
      );
      await expectLater(
        repo.saveAnswers('1', answers),
        _fails(InspectionsError.notEditable),
      );
    });
  });

  group('crear', () {
    setUp(() {
      api.on('POST /api/inspections', FakeReply(200, _dto('5')));
      api.on('GET /api/inspections/5', FakeReply(200, _dto('5')));
      api.on(
        'GET /api/inspections/5/results',
        const FakeReply(200, <Object>[]),
      );
    });

    test('nace asignada a quien la levanta, con carretera y km', () async {
      final i = await repo.create(
        NewInspection(
          type: 'Señalización',
          title: 'Revision del km 150',
          kmLabel: 'KM 150+200',
          direction: 'Creciente',
          scheduledAt: DateTime.utc(2026, 10, 25, 3),
        ),
      );
      expect(i.id, '5');
      final body = api.to('POST /api/inspections').single.data as Map;
      expect(body['inspectionTypeCode'], 'SENALIZACION');
      expect(body['roadId'], 'road-1');
      expect(body['kmStart'], 150.2);
      expect(body['direction'], 'CRECIENTE');
      expect(body['inspectorUserId'], 'user-1');
      expect(body['scheduledOn'], '2026-10-25');
      expect(body['notes'], 'Revision del km 150');
      expect(body['clientUuid'], isNotEmpty);
    });

    test('un tipo que el servidor no tiene es un error', () async {
      await expectLater(
        repo.create(const NewInspection(type: 'Inventado', title: 'x')),
        _fails(InspectionsError.server),
      );
      expect(api.to('POST /api/inspections'), isEmpty);
    });
  });

  group('hallazgos', () {
    setUp(() {
      api.on(
        'GET /api/inspections/1',
        FakeReply(200, _dto('1', status: 'EN_PROCESO')),
      );
      api.on(
        'GET /api/inspections/1/results',
        const FakeReply(200, <Object>[]),
      );
      api.on(
        'POST /api/inspections/1/findings',
        const FakeReply(200, {'id': 'f1'}),
      );
    });

    test(
      'manda la nota, la gravedad, el punto del checklist y la posicion',
      () async {
        await repo.addFinding(
          '1',
          InspectionFinding(
            id: 'x',
            itemId: 'ANCLAJE',
            note: 'Tornillo suelto',
            capturedAt: DateTime.utc(2026, 10, 26),
            position: const FindingPosition(
              latitude: -18.8,
              longitude: -41.9,
              accuracyMeters: 8,
            ),
          ),
        );
        final body =
            api.to('POST /api/inspections/1/findings').single.data as Map;
        expect(body['description'], 'Tornillo suelto');
        // El punto del checklist critico pide mas atencion.
        expect(body['severity'], 'ALTA');
        expect(body['parameter'], 'ANCLAJE');
        expect(body['geometry'], {
          'type': 'Point',
          'coordinates': [-41.9, -18.8],
        });
      },
    );

    test('sin nota usa el texto del punto del checklist', () async {
      await repo.addFinding(
        '1',
        InspectionFinding(
          id: 'x',
          itemId: 'LEGIBLE',
          capturedAt: DateTime.utc(2026, 10, 26),
        ),
      );
      final body =
          api.to('POST /api/inspections/1/findings').single.data as Map;
      expect(body['description'], 'Legible');
      expect(body['severity'], 'MEDIA');
      expect(body.containsKey('geometry'), isFalse);
    });

    test('las fotos van ligadas al hallazgo', () async {
      api.on(
        'POST /api/inspections/1/findings/f1/attachments',
        const FakeReply(200, {'id': 'a1'}),
      );
      final dir = _tempDir();
      final photo = File('${dir.path}/h.jpg')..writeAsBytesSync([1, 2]);
      await repo.addFinding(
        '1',
        InspectionFinding(
          id: 'x',
          note: 'n',
          capturedAt: DateTime.utc(2026, 10, 26),
          photoPaths: [photo.path, '${dir.path}/no_existe.jpg'],
        ),
      );
      final uploads = api
          .to('POST /api/inspections/1/findings/f1/attachments')
          .toList();
      expect(uploads, hasLength(1));
      final form = uploads.single.data as FormData;
      expect({for (final f in form.fields) f.key: f.value}['kind'], 'FOTO');
      expect(form.files.single.value.contentType?.mimeType, 'image/jpeg');
    });
  });
}
