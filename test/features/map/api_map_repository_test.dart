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

  test('tickets, mantenimiento y obras aun no se publican', () async {
    for (final layer in [
      MapLayer.tickets,
      MapLayer.maintenance,
      MapLayer.works,
    ]) {
      await expectLater(repo.pins(layer), _fails(MapError.notAvailable));
    }
    expect(api.requests, isEmpty);
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
