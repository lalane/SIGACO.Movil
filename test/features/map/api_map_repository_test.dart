import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/api_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _feature(
  String id, {
  Object? geometry = const {
    'type': 'Point',
    'coordinates': [-41.98, -18.85],
  },
  String type = 'DEFENSA',
  String? conservation = 'BUENO',
  String status = 'ACTIVO',
  num? km = 150.2,
}) => {
  'id': id,
  'type': 'Feature',
  'geometry': geometry,
  'properties': {
    'code': 'COD-$id',
    'assetTypeCode': type,
    'subsystemCode': 'SGS',
    'status': status,
    'conservationState': conservation,
    'roadCode': 'BR-381',
    'kmStart': km,
  },
};

Matcher _fails(MapError e) =>
    throwsA(isA<MapException>().having((x) => x.error, 'error', e));

void main() {
  late FakeApi api;
  late String language;
  late ApiMapRepository repo;

  setUp(() {
    api = FakeApi();
    language = 'es';
    repo = ApiMapRepository(api.client(), language: () => language);
    api.on(
      'GET /api/catalogs',
      const FakeReply(200, {
        'assetTypes': [
          {
            'code': 'DEFENSA',
            'labelEs': 'Defensa metálica',
            'labelPt': 'Defensa PT',
          },
        ],
      }),
    );
  });

  test('los activos con geometria son los pines de inventario', () async {
    api.on(
      'GET /api/assets/map',
      FakeReply(200, {
        'features': [
          _feature('g-1'),
          _feature('g-2', conservation: 'REGULAR', status: 'EN_MANTENIMIENTO'),
          _feature('g-3', conservation: 'PESIMO', status: 'FUERA_SERVICIO'),
          _feature('g-4', conservation: null, type: 'OTRO', km: null),
        ],
        'truncated': false,
      }),
    );

    final pins = await repo.pins(MapLayer.inventory);

    expect(pins.map((p) => p.id), ['g-1', 'g-2', 'g-3', 'g-4']);
    final p = pins.first;
    expect(p.layer, MapLayer.inventory);
    expect(p.title, 'COD-g-1');
    expect(p.category, 'Defensa metálica');
    expect(p.kmLabel, 'KM 150+200');
    expect(p.position.latitude, -18.85);
    expect(p.position.longitude, -41.98);
    expect(p.status, PinStatus.normal);
    expect(p.operatingState, OperatingState.inOperation);
    expect(pins[1].status, PinStatus.attention);
    expect(pins[1].operatingState, OperatingState.inMaintenance);
    expect(pins[2].status, PinStatus.critical);
    expect(pins[2].operatingState, OperatingState.outOfService);
    // Un tipo que el catalogo no conoce se muestra con su codigo.
    expect(pins[3].category, 'OTRO');
    expect(pins[3].kmLabel, isNull);
    expect(
      api.to('GET /api/assets/map').single.queryParameters['bbox'],
      '-180,-90,180,90',
    );
  });

  test('un pin sin geometria valida se omite', () async {
    api.on(
      'GET /api/assets/map',
      FakeReply(200, {
        'features': [
          _feature('ok'),
          _feature('sin', geometry: null),
          _feature(
            'fuera',
            geometry: {
              'type': 'Point',
              'coordinates': [500, 99],
            },
          ),
        ],
      }),
    );
    expect((await repo.pins(MapLayer.inventory)).map((p) => p.id), ['ok']);
  });

  test('el catalogo sale en el idioma elegido y se pide una vez', () async {
    language = 'pt';
    api.on(
      'GET /api/assets/map',
      FakeReply(200, {
        'features': [_feature('g-1')],
      }),
    );
    expect((await repo.pins(MapLayer.inventory)).first.category, 'Defensa PT');
    await repo.pins(MapLayer.inventory);
    expect(api.to('GET /api/catalogs'), hasLength(1));
  });

  test('sin catalogo los pines salen igual, con el codigo del tipo', () async {
    api.on('GET /api/catalogs', const FakeReply(500, {'title': 'x'}));
    api.on(
      'GET /api/assets/map',
      FakeReply(200, {
        'features': [_feature('g-1')],
      }),
    );
    expect((await repo.pins(MapLayer.inventory)).first.category, 'DEFENSA');
  });

  group('pines de mantenimiento', () {
    Map<String, Object?> order(
      String id, {
      String status = 'PROGRAMADO',
      bool overdue = false,
      Object? geometry = const {
        'type': 'LineString',
        'coordinates': [
          [-41.98, -18.84],
          [-41.97, -18.85],
          [-41.96, -18.86],
        ],
      },
    }) => {
      'id': id,
      'folio': 'MP-$id',
      'activity': 'Bacheo',
      'status': status,
      'isOverdue': overdue,
      'subsystemCode': 'SGP',
      'kmStart': 513.615,
      'geometry': geometry,
    };

    test('las ordenes abiertas con geometria se ubican en su centro', () async {
      api.on(
        'GET /api/preventive-maintenance',
        FakeReply(200, {
          'items': [
            order('m1'),
            order('m2', overdue: true),
            order('m3', status: 'COMPLETADO'),
            order('m4', status: 'CANCELADO'),
            order('m5', geometry: null),
          ],
          'total': 5,
          'page': 1,
          'pageSize': 100,
        }),
      );
      final pins = await repo.pins(MapLayer.maintenance);
      expect(pins.map((p) => p.id), ['m1', 'm2']);
      expect(pins.first.layer, MapLayer.maintenance);
      expect(pins.first.title, 'Bacheo');
      expect(pins.first.subtitle, 'MP-m1');
      expect(pins.first.category, 'SGP');
      expect(pins.first.kmLabel, 'KM 513+615');
      expect(pins.first.position.latitude, -18.85);
      expect(pins.first.position.longitude, -41.97);
      expect(pins.first.status, PinStatus.normal);
      expect(pins.last.status, PinStatus.attention);
    });

    test('pide las paginas que faltan', () async {
      api.reply('GET /api/preventive-maintenance', (o) {
        final page = o.queryParameters['page'];
        return FakeReply(200, {
          'items': [order(page == 1 ? 'a' : 'b')],
          'total': 2,
          'page': page,
          'pageSize': 100,
        });
      });
      final pins = await repo.pins(MapLayer.maintenance);
      expect(pins.map((p) => p.id), ['a', 'b']);
    });

    test('sin permiso o sin red lo dice', () async {
      api.on('GET /api/preventive-maintenance', const FakeReply(403));
      await expectLater(
        repo.pins(MapLayer.maintenance),
        _fails(MapError.permissionDenied),
      );
      api.offline = true;
      await expectLater(
        repo.pins(MapLayer.maintenance),
        _fails(MapError.network),
      );
    });
  });

  group('pines del servidor (tickets y obras)', () {
    Map<String, Object?> pin(
      String layer,
      String id, {
      String title = 'Bache en carril derecho\n\nCerca del puente',
      String? priority = 'MEDIA',
      Object? lat = -18.84,
      Object? lon = -41.98,
    }) => {
      'layer': layer,
      'id': id,
      'code': 'COD-$id',
      'title': title,
      'status': 'NUEVO',
      'priority': priority,
      'longitude': lon,
      'latitude': lat,
      'roadId': 'r1',
      'kmStart': 513.615,
    };

    Map<String, Object?> answer(
      String layer,
      List<Map<String, Object?>> pins,
    ) => {
      'layers': [
        {
          'layer': layer,
          'count': pins.length,
          'withoutGeometry': 0,
          'truncated': false,
        },
      ],
      'pins': pins,
    };

    test('los tickets abiertos salen de /api/map/pins', () async {
      api.on(
        'GET /api/map/pins',
        FakeReply(
          200,
          answer('TICKETS', [
            pin('TICKETS', 't1', priority: 'CRITICA'),
            pin('TICKETS', 't2', priority: 'ALTA'),
            pin('TICKETS', 't3'),
          ]),
        ),
      );
      final pins = await repo.pins(MapLayer.tickets);

      final sent = api.to('GET /api/map/pins').single.queryParameters;
      expect(sent['layers'], 'TICKETS');
      expect(sent['bbox'], '-180,-90,180,90');
      expect(sent['limit'], 2000);
      expect(pins.map((p) => p.id), ['t1', 't2', 't3']);
      expect(pins.map((p) => p.status), [
        PinStatus.critical,
        PinStatus.attention,
        PinStatus.normal,
      ]);
      expect(pins.first.layer, MapLayer.tickets);
      expect(pins.first.title, 'Bache en carril derecho');
      expect(pins.first.subtitle, 'COD-t1');
      expect(pins.first.kmLabel, 'KM 513+615');
      expect(pins.first.position.latitude, -18.84);
      expect(pins.first.position.longitude, -41.98);
    });

    test('las obras piden la capa OBRAS', () async {
      api.on(
        'GET /api/map/pins',
        FakeReply(
          200,
          answer('OBRAS', [
            pin('OBRAS', 'w1', title: 'Repavimentacion km 500'),
          ]),
        ),
      );
      final pins = await repo.pins(MapLayer.works);
      expect(
        api.to('GET /api/map/pins').single.queryParameters['layers'],
        'OBRAS',
      );
      expect(pins.single.layer, MapLayer.works);
      expect(pins.single.title, 'Repavimentacion km 500');
    });

    test('un pin sin coordenadas validas se omite', () async {
      api.on(
        'GET /api/map/pins',
        FakeReply(
          200,
          answer('TICKETS', [
            pin('TICKETS', 'ok'),
            pin('TICKETS', 'mal', lat: 'x'),
            pin('TICKETS', 'fuera', lat: 120),
          ]),
        ),
      );
      expect((await repo.pins(MapLayer.tickets)).map((p) => p.id), ['ok']);
    });

    test('una capa que el servidor no entrega es falta de permiso', () async {
      api.on(
        'GET /api/map/pins',
        const FakeReply(200, {'layers': [], 'pins': []}),
      );
      await expectLater(
        repo.pins(MapLayer.tickets),
        _fails(MapError.permissionDenied),
      );
    });

    test('una capa sin pines es un mapa vacio, no un error', () async {
      api.on('GET /api/map/pins', FakeReply(200, answer('TICKETS', [])));
      expect(await repo.pins(MapLayer.tickets), isEmpty);
    });

    test('traduce los errores del servidor', () async {
      api.on('GET /api/map/pins', const FakeReply(500));
      await expectLater(repo.pins(MapLayer.tickets), _fails(MapError.server));
      api.on('GET /api/map/pins', const FakeReply(200, {'pins': 'mal'}));
      await expectLater(repo.pins(MapLayer.works), _fails(MapError.server));
      api.offline = true;
      await expectLater(repo.pins(MapLayer.tickets), _fails(MapError.network));
    });
  });

  test('traduce los errores del servidor', () async {
    api.on('GET /api/assets/map', const FakeReply(403, {'code': 'X'}));
    await expectLater(
      repo.pins(MapLayer.inventory),
      _fails(MapError.permissionDenied),
    );
    api.on('GET /api/assets/map', const FakeReply(500, {'title': 'x'}));
    await expectLater(repo.pins(MapLayer.inventory), _fails(MapError.server));
    api.on('GET /api/assets/map', const FakeReply(200, {'features': 'mal'}));
    await expectLater(repo.pins(MapLayer.inventory), _fails(MapError.server));
    api.offline = true;
    await expectLater(repo.pins(MapLayer.inventory), _fails(MapError.network));
  });
}
