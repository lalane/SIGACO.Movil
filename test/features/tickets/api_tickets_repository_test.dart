import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/geo/km_label.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _dto(
  String id, {
  String status = 'NUEVO',
  String description = 'Bache en carril derecho\n\nCerca del puente',
  int rowVersion = 3,
}) => {
  'id': id,
  'folio': 'TK-2026-000$id',
  'ticketTypeLabel': 'Bache',
  'status': status,
  'description': description,
  'detectedAt': '2026-10-23T15:00:00Z',
  'dueAt': '2026-10-25T15:00:00Z',
  'kmStart': 513.615,
  'kmEnd': null,
  'lane': 'A',
  'company': 'Mantenimiento SA',
  'geometry': {
    'type': 'Point',
    'coordinates': [-41.98, -18.84],
  },
  'rowVersion': rowVersion,
};

Map<String, Object?> _page(List<Map<String, Object?>> items, {int? total}) => {
  'items': items,
  'total': total ?? items.length,
  'page': 1,
  'pageSize': 100,
};

const _config = {
  'operationalCatalogs': {
    'ticketTypes': [
      {
        'code': 'BACHE',
        'labelEs': 'Bache',
        'labelPt': 'Buraco',
        'sortOrder': 2,
        'active': true,
      },
      {
        'code': 'FUGA',
        'labelEs': 'Fuga de agua',
        'labelPt': null,
        'sortOrder': 1,
        'active': true,
      },
      {
        'code': 'SGP_ABCD1234',
        'labelEs': 'Buraco',
        'labelPt': 'Buraco',
        'subsystemCode': 'SGP',
        'classification': 'Buracos, desagregações e perda de material',
        'attentionHours': 720,
        'attentionLabel': '30 dias',
        'sortOrder': 101,
        'active': true,
      },
      {'code': 'VIEJO', 'labelEs': 'Obsoleto', 'sortOrder': 3, 'active': false},
    ],
  },
};

/// Carpeta temporal que se borra al terminar. En Windows el servidor falso no lee
/// el archivo y puede seguir abierto: borrarlo no debe romper la prueba.
Directory _tempDir() {
  final dir = Directory.systemTemp.createTempSync('tk_');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Lo recoge el sistema.
    }
  });
  return dir;
}

Matcher _fails(TicketsError error) =>
    throwsA(isA<TicketsException>().having((e) => e.error, 'error', error));

void main() {
  late FakeApi api;
  late ApiTicketsRepository repo;
  var lang = 'es';
  String? road = 'road-1';

  setUp(() {
    api = FakeApi();
    lang = 'es';
    road = 'road-1';
    repo = ApiTicketsRepository(
      api.client(),
      roadId: () async => road,
      language: () => lang,
    );
  });

  group('traduccion', () {
    test('un ticket del servidor se ve como la app lo muestra', () {
      final t = ApiTicketsRepository.ticketFromDto(_dto('1'));
      expect(t.id, '1');
      expect(t.code, 'TK-2026-0001');
      expect(t.title, 'Bache en carril derecho');
      expect(t.description, 'Cerca del puente');
      expect(t.status, TicketStatus.open);
      expect(t.category, 'Bache');
      expect(t.kmLabel, 'KM 513+615');
      expect(t.latitude, -18.84);
      expect(t.longitude, -41.98);
      expect(t.carriageway, 'A');
      expect(t.company, 'Mantenimiento SA');
      expect(t.createdAt, DateTime.utc(2026, 10, 23, 15));
      expect(t.dueAt, DateTime.utc(2026, 10, 25, 15));
    });

    test('abierto es lo que nadie ha atendido; lo demas, atendido', () {
      for (final s in ['NUEVO', 'ASIGNADO', 'REABIERTO']) {
        expect(
          ApiTicketsRepository.statusFromCode(s),
          TicketStatus.open,
          reason: s,
        );
      }
      for (final s in ['EN_PROCESO', 'EN_ESPERA', 'RESUELTO', 'CERRADO']) {
        expect(
          ApiTicketsRepository.statusFromCode(s),
          TicketStatus.attended,
          reason: s,
        );
      }
    });

    test('sin descripcion, el titulo es el tipo de ticket', () {
      final t = ApiTicketsRepository.ticketFromDto(_dto('2', description: ' '));
      expect(t.title, 'Bache');
      expect(t.description, isNull);
    });

    test('titulo y descripcion viajan en una sola descripcion', () {
      expect(
        ApiTicketsRepository.composeDescription('Bache', 'Junto al puente'),
        'Bache\n\nJunto al puente',
      );
      expect(ApiTicketsRepository.composeDescription(' Bache ', null), 'Bache');
      final (title, body) = ApiTicketsRepository.splitDescription(
        'Bache\n\nJunto al puente',
      );
      expect(title, 'Bache');
      expect(body, 'Junto al puente');
    });

    test('un kilometro se lee de varios formatos', () {
      expect(parseKm('KM 513+615'), 513.615);
      expect(parseKm('513 + 6'), 513.006);
      expect(parseKm('513.615'), 513.615);
      expect(parseKm('513,5'), 513.5);
      expect(parseKm('sin km'), isNull);
      expect(parseKm(null), isNull);
      expect(kmLabel(513.615, null), 'KM 513+615');
      expect(kmLabel(513.6, 514), 'KM 513+600 - 514+000');
      expect(kmLabel(null, null), isNull);
    });

    test('el tipo de imagen sale de la extension', () {
      expect(ApiTicketsRepository.imageType('/a/b.PNG'), 'image/png');
      expect(ApiTicketsRepository.imageType('/a/b.jpg'), 'image/jpeg');
      expect(ApiTicketsRepository.imageType('/a/b'), 'image/jpeg');
      expect(ApiTicketsRepository.imageType('/a/b.heic'), 'image/heic');
    });
  });

  group('lista y ficha', () {
    test('trae todas las paginas', () async {
      api.reply('GET /api/tickets', (o) {
        final page = o.queryParameters['page'];
        return page == 1
            ? FakeReply(200, _page([_dto('1'), _dto('2')], total: 3))
            : FakeReply(200, _page([_dto('3')], total: 3));
      });
      final tickets = await repo.list();
      expect(tickets.map((t) => t.id), ['1', '2', '3']);
      expect(api.to('GET /api/tickets'), hasLength(2));
    });

    test('una respuesta sin items es un error del servidor', () async {
      api.on('GET /api/tickets', const FakeReply(200, {'total': 1}));
      await expectLater(repo.list(), _fails(TicketsError.server));
    });

    test('la ficha trae el seguimiento', () async {
      api.on(
        'GET /api/tickets/1',
        FakeReply(200, _dto('1', status: 'EN_PROCESO')),
      );
      api.on(
        'GET /api/tickets/1/follow-ups',
        const FakeReply(200, [
          {
            'id': 'f1',
            'kind': 'AVANCE',
            'description': 'Se tapo el bache',
            'previousStatus': 'NUEVO',
            'newStatus': 'EN_PROCESO',
            'createdAt': '2026-10-23T18:00:00Z',
          },
          {
            'id': 'f2',
            'kind': 'COMMENT',
            'description': 'Falta senalizar',
            'createdAt': '2026-10-23T19:00:00Z',
          },
        ]),
      );
      final t = await repo.get('1');
      expect(t.status, TicketStatus.attended);
      expect(t.followUps.map((f) => f.id), ['f1', 'f2']);
      expect(t.followUps.first.status, TicketStatus.attended);
      expect(t.followUps.first.description, 'Se tapo el bache');
      // Sin cambio de estado, hereda el del ticket.
      expect(t.followUps.last.status, TicketStatus.attended);
    });

    test('la ficha baja las fotos del ticket y de sus seguimientos', () async {
      final dir = _tempDir();
      final withPhotos = ApiTicketsRepository(
        api.client(),
        roadId: () async => 'road-1',
        cacheDir: () async => dir,
      );
      api.on('GET /api/tickets/1', FakeReply(200, _dto('1')));
      api.on(
        'GET /api/tickets/1/follow-ups',
        const FakeReply(200, [
          {
            'id': 'f1',
            'kind': 'AVANCE',
            'description': 'Listo',
            'createdAt': '2026-10-23T18:00:00Z',
          },
        ]),
      );
      api.on(
        'GET /api/tickets/1/attachments',
        const FakeReply(200, [
          {
            'id': 'a1',
            'kind': 'FOTO',
            'contentType': 'image/jpeg',
            'followUpId': null,
          },
          {
            'id': 'a2',
            'kind': 'FOTO',
            'contentType': 'image/png',
            'followUpId': 'f1',
          },
          {
            'id': 'a3',
            'kind': 'DOCUMENT',
            'contentType': 'application/pdf',
            'followUpId': null,
          },
        ]),
      );
      api.on(
        'GET /api/tickets/1/attachments/a1/content',
        FakeReply.bytes(200, Uint8List.fromList([1, 2, 3])),
      );
      api.on(
        'GET /api/tickets/1/attachments/a2/content',
        FakeReply.bytes(200, Uint8List.fromList([4, 5])),
      );

      final t = await withPhotos.get('1');
      expect(t.photoPaths, hasLength(1));
      expect(File(t.photoPaths.single).readAsBytesSync(), [1, 2, 3]);
      expect(t.photoPaths.single, endsWith('.jpg'));
      expect(t.followUps.single.photoPaths, hasLength(1));
      expect(File(t.followUps.single.photoPaths.single).readAsBytesSync(), [
        4,
        5,
      ]);
      // El documento no es una foto: no se baja.
      expect(api.to('GET /api/tickets/1/attachments/a3/content'), isEmpty);

      // La segunda vez usa lo ya bajado.
      await withPhotos.get('1');
      expect(api.to('GET /api/tickets/1/attachments/a1/content'), hasLength(1));
    });

    test('una foto que no baja no impide ver la ficha', () async {
      final dir = _tempDir();
      final withPhotos = ApiTicketsRepository(
        api.client(),
        roadId: () async => 'road-1',
        cacheDir: () async => dir,
      );
      api.on('GET /api/tickets/1', FakeReply(200, _dto('1')));
      api.on('GET /api/tickets/1/follow-ups', const FakeReply(200, []));
      api.on('GET /api/tickets/1/attachments', const FakeReply(500));
      final t = await withPhotos.get('1');
      expect(t.photoPaths, isEmpty);
      expect(t.code, 'TK-2026-0001');
    });

    test('errores del servidor segun el estado', () async {
      api.on('GET /api/tickets', const FakeReply(403));
      await expectLater(repo.list(), _fails(TicketsError.permissionDenied));
      api.on('GET /api/tickets', const FakeReply(404));
      await expectLater(repo.list(), _fails(TicketsError.notAvailable));
      api.on('GET /api/tickets', const FakeReply(500));
      await expectLater(repo.list(), _fails(TicketsError.server));
      api.on('GET /api/tickets/9', const FakeReply(404));
      await expectLater(repo.get('9'), _fails(TicketsError.notFound));
      api.offline = true;
      await expectLater(repo.list(), _fails(TicketsError.network));
    });
  });

  group('punto sobre la carretera', () {
    test('trae km, sentido y tramo', () async {
      api.on(
        'GET /api/road-network/locate',
        const FakeReply(200, {
          'roadId': 'r1',
          'roadCode': 'BR-381',
          'direction': 'CRECIENTE',
          'km': 146.9,
          'roadSegmentCode': '381BMG0100',
          'distanceMeters': 12.4,
          'directionAmbiguous': false,
        }),
      );
      final p = await repo.place(-42.61, -19.53);
      expect(p.status, TicketPlacementStatus.onRoad);
      expect(
        (p.km, p.direction, p.segmentCode),
        (146.9, 'CRECIENTE', '381BMG0100'),
      );
    });

    test('lejos de la carretera o sin eje', () async {
      api.on(
        'GET /api/road-network/locate',
        const FakeReply(404, {'code': 'LOCATION_OUT_OF_AXIS'}),
      );
      expect((await repo.place(0, 0)).status, TicketPlacementStatus.offRoad);
      api.on(
        'GET /api/road-network/locate',
        const FakeReply(409, {'code': 'ROAD_AXIS_NOT_LOADED'}),
      );
      expect((await repo.place(0, 0)).status, TicketPlacementStatus.unknown);
      api.offline = true;
      expect((await repo.place(0, 0)).status, TicketPlacementStatus.unknown);
    });
  });

  group('matriz de fallas', () {
    test(
      'solo los tipos con plazo, con indicador y subclasificacion',
      () async {
        api.on('GET /api/app-configuration', const FakeReply(200, _config));
        final failures = await repo.failures();
        expect(failures, hasLength(1));
        final f = failures.single;
        expect(f.code, 'SGP_ABCD1234');
        expect(f.subsystemCode, 'SGP');
        expect(f.group, 'Buracos, desagregações e perda de material');
        expect(f.days, 30);
        expect(f.immediate, isFalse);
      },
    );

    test('con una falla no se manda la prioridad', () async {
      api
        ..on('GET /api/app-configuration', const FakeReply(200, _config))
        ..on('POST /api/tickets', FakeReply(200, _dto('7')));
      // Como el formulario: primero las fallas y luego la lista plana.
      await repo.failures();
      await repo.categories();
      await repo.create(
        const NewTicket(
          title: 'Buraco',
          category: 'SGP_ABCD1234',
          fixedAttention: true,
        ),
      );
      final body = api.to('POST /api/tickets').single.data as Map;
      expect(body['ticketTypeCode'], 'SGP_ABCD1234');
      expect(body.containsKey('priority'), isFalse);
    });
  });

  group('tipos de ticket', () {
    test('salen del catalogo, activos y en orden', () async {
      api.on('GET /api/app-configuration', const FakeReply(200, _config));
      expect(await repo.categories(), ['Fuga de agua', 'Bache']);
    });

    test('en portugues, con el espanol si no hay traduccion', () async {
      lang = 'pt';
      api.on('GET /api/app-configuration', const FakeReply(200, _config));
      expect(await repo.categories(), ['Fuga de agua', 'Buraco']);
    });
  });

  group('crear', () {
    setUp(() {
      api.on('GET /api/app-configuration', const FakeReply(200, _config));
      api.on('POST /api/tickets', FakeReply(200, _dto('7')));
    });

    test('manda tipo, prioridad, descripcion, carretera, km y hora', () async {
      final ticket = await repo.create(
        NewTicket(
          title: 'Bache',
          category: 'Bache',
          description: 'Junto al puente',
          kmLabel: 'KM 513+615',
          capturedAt: DateTime.utc(2026, 10, 23, 15),
          clientId: 'aaaaaaaa-0000-4000-8000-000000000001',
        ),
      );
      expect(ticket.id, '7');
      final body = api.to('POST /api/tickets').single.data as Map;
      expect(body['ticketTypeCode'], 'BACHE');
      expect(body['priority'], 'MEDIA');
      expect(body['description'], 'Bache\n\nJunto al puente');
      expect(body['roadId'], 'road-1');
      expect(body['kmStart'], 513.615);
      expect(body['detectedAt'], '2026-10-23T15:00:00.000Z');
      expect(body['clientUuid'], 'aaaaaaaa-0000-4000-8000-000000000001');
      expect(body.containsKey('assetId'), isFalse);
      expect(body.containsKey('geometry'), isFalse);
    });

    test('manda la prioridad que se eligio en el formulario', () async {
      await repo.create(
        const NewTicket(
          title: 'Hundimiento',
          category: 'Bache',
          priority: TicketPriority.critical,
        ),
      );
      final body = api.to('POST /api/tickets').single.data as Map;
      expect(body['priority'], 'CRITICA');
    });

    test('desde un activo no manda carretera: sale del activo', () async {
      await repo.create(
        const NewTicket(
          title: 'Defensa rota',
          category: 'Bache',
          location: TicketLocation(
            latitude: -18.8,
            longitude: -41.9,
            origin: TicketLocationOrigin.asset,
            assetId: 'asset-1',
            kmLabel: 'KM 100+500',
          ),
        ),
      );
      final body = api.to('POST /api/tickets').single.data as Map;
      expect(body['assetId'], 'asset-1');
      expect(body.containsKey('roadId'), isFalse);
      expect(body['kmStart'], 100.5);
      expect(body['geometry'], {
        'type': 'Point',
        'coordinates': [-41.9, -18.8],
      });
    });

    test(
      'desde la ficha de un activo sin punto solo manda el activo',
      () async {
        await repo.create(
          const NewTicket(
            title: 'Defensa rota',
            category: 'Bache',
            assetId: 'asset-2',
            kmLabel: 'KM 100+500',
            kmEndLabel: 'KM 101+000',
          ),
        );
        final body = api.to('POST /api/tickets').single.data as Map;
        expect(body['assetId'], 'asset-2');
        // Carretera, sentido y geometria los pone el servidor con el activo.
        expect(body.containsKey('roadId'), isFalse);
        expect(body.containsKey('geometry'), isFalse);
        expect(body['kmStart'], 100.5);
        expect(body['kmEnd'], 101.0);
      },
    );

    test('un punto elegido en el mapa manda su geometria', () async {
      await repo.create(
        const NewTicket(
          title: 'Hundimiento',
          category: 'Fuga de agua',
          location: TicketLocation(
            latitude: -18.5,
            longitude: -42.1,
            origin: TicketLocationOrigin.mapPoint,
          ),
        ),
      );
      final body = api.to('POST /api/tickets').single.data as Map;
      expect(body['ticketTypeCode'], 'FUGA');
      expect(body['roadId'], 'road-1');
      expect(body['geometry'], {
        'type': 'Point',
        'coordinates': [-42.1, -18.5],
      });
    });

    test('sin carretera conocida no la inventa', () async {
      road = null;
      await repo.create(const NewTicket(title: 'x', category: 'Bache'));
      expect(
        (api.to('POST /api/tickets').single.data as Map).containsKey('roadId'),
        isFalse,
      );
    });

    test('un tipo que el catalogo no tiene es un error', () async {
      await expectLater(
        repo.create(const NewTicket(title: 'x', category: 'Inventado')),
        _fails(TicketsError.server),
      );
      expect(api.to('POST /api/tickets'), isEmpty);
    });

    test('sube las fotos como imagen, con hora y ubicacion', () async {
      api.on(
        'POST /api/tickets/7/attachments',
        const FakeReply(200, {'id': 'a1'}),
      );
      final dir = _tempDir();
      final photo = File('${dir.path}/foto.png')..writeAsBytesSync([1, 2, 3]);
      final missing = '${dir.path}/no_existe.jpg';

      await repo.create(
        NewTicket(
          title: 'Bache',
          category: 'Bache',
          capturedAt: DateTime.utc(2026, 10, 23, 15),
          photoPaths: [photo.path, missing],
          location: const TicketLocation(
            latitude: -18.5,
            longitude: -42.1,
            origin: TicketLocationOrigin.gps,
          ),
        ),
      );

      final uploads = api.to('POST /api/tickets/7/attachments').toList();
      // La foto que ya no existe se omite.
      expect(uploads, hasLength(1));
      final form = uploads.single.data as FormData;
      final fields = {for (final f in form.fields) f.key: f.value};
      expect(fields['kind'], 'FOTO');
      expect(fields['latitude'], '-18.5');
      expect(fields['longitude'], '-42.1');
      expect(fields['capturedAt'], '2026-10-23T15:00:00.000Z');
      expect(fields['clientUuid'], isNotEmpty);
      expect(fields.containsKey('followUpId'), isFalse);
      final file = form.files.single;
      expect(file.key, 'file');
      expect(file.value.filename, 'foto.png');
      expect(file.value.contentType?.mimeType, 'image/png');
    });

    test('una foto que no sube deja el registro guardado y lo dice', () async {
      api.on('POST /api/tickets/7/attachments', const FakeReply(500));
      final dir = _tempDir();
      final photo = File('${dir.path}/foto.jpg')..writeAsBytesSync([1]);
      await expectLater(
        repo.create(
          NewTicket(title: 'x', category: 'Bache', photoPaths: [photo.path]),
        ),
        throwsA(isA<TicketPartiallySavedException>()),
      );
    });
  });

  group('seguimiento', () {
    NewFollowUp followUp(TicketStatus s, {String text = 'Se reviso'}) =>
        NewFollowUp(
          at: DateTime.utc(2026, 10, 23, 18),
          status: s,
          description: text,
        );

    void server({required String status}) {
      api.on(
        'POST /api/tickets/1/follow-ups',
        const FakeReply(200, {'id': 'f9'}),
      );
      api.on(
        'GET /api/tickets/1',
        FakeReply(200, _dto('1', status: status, rowVersion: 5)),
      );
      api.on('GET /api/tickets/1/follow-ups', const FakeReply(200, <Object>[]));
      api.on(
        'POST /api/tickets/1/status',
        FakeReply(200, _dto('1', status: 'EN_PROCESO')),
      );
    }

    test('un comentario no cambia el estado', () async {
      server(status: 'NUEVO');
      await repo.addFollowUp('1', followUp(TicketStatus.open));
      final body = api.to('POST /api/tickets/1/follow-ups').single.data as Map;
      expect(body, {'kind': 'AVANCE', 'description': 'Se reviso'});
      expect(api.to('POST /api/tickets/1/status'), isEmpty);
    });

    test('atender un ticket nuevo lo pone en proceso', () async {
      server(status: 'ASIGNADO');
      await repo.addFollowUp('1', followUp(TicketStatus.attended));
      final status = api.to('POST /api/tickets/1/status').single.data as Map;
      expect(status, {'status': 'EN_PROCESO', 'rowVersion': 5});
    });

    test('si ya estaba en proceso, el seguimiento basta', () async {
      server(status: 'EN_PROCESO');
      await repo.addFollowUp('1', followUp(TicketStatus.attended));
      expect(api.to('POST /api/tickets/1/status'), isEmpty);
    });

    test('sin texto manda una nota para que el servidor lo acepte', () async {
      server(status: 'NUEVO');
      await repo.addFollowUp('1', followUp(TicketStatus.open, text: '  '));
      final body = api.to('POST /api/tickets/1/follow-ups').single.data as Map;
      expect(body['description'], isNotEmpty);
    });

    test('un cambio de estado que el servidor niega es un error', () async {
      server(status: 'NUEVO');
      api.on(
        'POST /api/tickets/1/status',
        const FakeReply(409, {'code': 'TRANSITION_NOT_ALLOWED'}),
      );
      await expectLater(
        repo.addFollowUp('1', followUp(TicketStatus.attended)),
        _fails(TicketsError.server),
      );
    });

    test('las fotos del seguimiento van ligadas a el', () async {
      server(status: 'EN_PROCESO');
      api.on(
        'POST /api/tickets/1/attachments',
        const FakeReply(200, {'id': 'a1'}),
      );
      final dir = _tempDir();
      final photo = File('${dir.path}/f.jpg')..writeAsBytesSync([1]);
      await repo.addFollowUp(
        '1',
        NewFollowUp(
          at: DateTime.utc(2026, 10, 23, 18),
          status: TicketStatus.open,
          description: 'Con foto',
          photoPaths: [photo.path],
        ),
      );
      final form =
          api.to('POST /api/tickets/1/attachments').single.data as FormData;
      expect({for (final f in form.fields) f.key: f.value}['followUpId'], 'f9');
    });
  });
}
