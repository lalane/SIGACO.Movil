import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/api_asset_capture_repository.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/inventory_json.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_template.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/asset_capture_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _type(
  String code, {
  List<String>? channels,
  bool active = true,
  String? geometry,
  int order = 1,
}) => {
  'id': 'id-$code',
  'code': code,
  'labelEs': 'Tipo $code',
  'labelPt': 'Tipo PT $code',
  'subsystemCode': 'SGS',
  'geometryType': geometry,
  'requiresKmEnd': false,
  'sortOrder': order,
  'active': active,
  'provisional': false,
  'birthChannels': ?channels,
};

Map<String, Object?> _template(String type, int number, String status) => {
  'id': 't-$number',
  'assetTypeId': 'id-$type',
  'assetTypeCode': type,
  'number': number,
  'name': 'Ficha $number',
  'status': status,
  'provisional': false,
  'rowVersion': 1,
  'attributes': [
    {
      'key': 'altura_m',
      'labelEs': 'Altura',
      'labelPt': 'Altura PT',
      'dataType': 'DECIMAL',
      'unit': 'm',
      'required': true,
      'minValue': 0,
      'maxValue': 12,
      'sortOrder': 2,
      'origin': 'LAYER',
    },
    {
      'key': 'material',
      'labelEs': 'Material',
      'dataType': 'CATALOG',
      'catalogCode': 'material_poste',
      'required': false,
      'sortOrder': 1,
    },
  ],
};

Map<String, Object?> _created(String id) => {
  'asset': {
    'id': id,
    'code': 'POSTE-000123',
    'status': 'PENDIENTE_VALIDACION',
    'mainPhotoId': null,
  },
  'children': [],
  'attachmentCount': 0,
};

Matcher _fails(AssetCaptureError e) =>
    throwsA(isA<AssetCaptureException>().having((x) => x.error, 'error', e));

void main() {
  late FakeApi api;
  late ApiAssetCaptureRepository repo;
  String? sessionRoad;

  setUp(() {
    api = FakeApi();
    sessionRoad = 'road-1';
    repo = ApiAssetCaptureRepository(
      api.client(),
      roadId: () async => sessionRoad,
    );
  });

  group('tipos', () {
    test(
      'pide los del canal MOBILE y deja fuera los que no nacen en la app',
      () async {
        api.on(
          'GET /api/catalogs/asset-types',
          FakeReply(200, [
            _type('POSTE', channels: ['WEB', 'MOBILE'], order: 2),
            _type('OAE', channels: ['WEBGIS']),
            _type('DEFENSA', order: 1),
            _type('VIEJO', active: false),
          ]),
        );

        final types = await repo.types();

        expect(types.map((t) => t.code), ['DEFENSA', 'POSTE']);
        final request = api.to('GET /api/catalogs/asset-types').single;
        expect(request.queryParameters['channel'], 'MOBILE');
        // Sin la lista de canales (servidor anterior), puede nacer por todos.
        expect(types.first.birthChannels, isNull);
      },
    );

    test('sin el filtro nuevo usa el catalogo completo', () async {
      // La ruta cae en un catalogo generico que no existe (404).
      api.on(
        'GET /api/catalogs',
        FakeReply(200, {
          'assetTypes': [_type('POSTE'), _type('BAJA', active: false)],
          'catalogs': [],
        }),
      );

      final types = await repo.types();

      expect(types.map((t) => t.code), ['POSTE']);
    });

    test('sin red y sin nada guardado avisa la falta de red', () async {
      api.offline = true;
      await expectLater(repo.types(), _fails(AssetCaptureError.network));
    });

    test('sin permiso lo dice', () async {
      api.on('GET /api/catalogs/asset-types', const FakeReply(403));
      await expectLater(
        repo.types(),
        _fails(AssetCaptureError.permissionDenied),
      );
    });
  });

  group('ficha', () {
    test(
      'de las versiones del tipo toma la vigente y ordena sus campos',
      () async {
        api.on(
          'GET /api/asset-templates/POSTE',
          FakeReply(200, [
            _template('POSTE', 3, 'BORRADOR'),
            _template('POSTE', 2, 'VIGENTE'),
            _template('POSTE', 1, 'RETIRADA'),
          ]),
        );

        final t = await repo.template('poste');

        expect(t.number, 2);
        expect(t.attributes.map((a) => a.key), ['material', 'altura_m']);
        final altura = t.field('altura_m')!;
        expect(altura.type, AttributeType.decimal);
        expect(altura.required, isTrue);
        expect(altura.min, 0);
        expect(altura.max, 12);
        expect(altura.unit, 'm');
        expect(altura.origin, AttributeOrigin.layer);
        expect(altura.label('pt'), 'Altura PT');
        expect(t.field('material')!.catalogCode, 'MATERIAL_POSTE');
      },
    );

    test('acepta una ficha sola y, si no, la de las vigentes', () async {
      api.on(
        'GET /api/asset-templates/POSTE',
        FakeReply(200, _template('POSTE', 4, 'VIGENTE')),
      );
      expect((await repo.template('POSTE')).number, 4);

      api.routes.remove('GET /api/asset-templates/POSTE');
      api.on(
        'GET /api/asset-templates',
        FakeReply(200, [
          _template('OTRO', 1, 'VIGENTE'),
          _template('POSTE', 5, 'VIGENTE'),
        ]),
      );
      expect((await repo.template('POSTE')).number, 5);
    });

    test('sin ficha vigente no se puede dar de alta', () async {
      api.on('GET /api/asset-templates/POSTE', const FakeReply(200, []));
      api.on('GET /api/asset-templates', const FakeReply(200, []));
      await expectLater(
        repo.template('POSTE'),
        _fails(AssetCaptureError.noTemplate),
      );
    });

    test('los catalogos genericos con sus valores activos', () async {
      api.on(
        'GET /api/catalogs',
        const FakeReply(200, {
          'assetTypes': [],
          'catalogs': [
            {
              'code': 'MATERIAL_POSTE',
              'values': [
                {'code': 'ACERO', 'labelEs': 'Acero', 'sortOrder': 2},
                {'code': 'MADERA', 'labelEs': 'Madera', 'sortOrder': 1},
                {'code': 'VIEJO', 'labelEs': 'Viejo', 'active': false},
              ],
            },
          ],
        }),
      );
      final catalogs = await repo.catalogs();
      expect(catalogs['MATERIAL_POSTE']!.map((o) => o.code), [
        'MADERA',
        'ACERO',
      ]);
    });
  });

  group('ubicacion', () {
    test('del punto salen carretera, km, sentido y tramo', () async {
      api.on(
        'GET /api/road-network/locate',
        const FakeReply(200, {
          'roadId': 'road-9',
          'roadCode': 'BR-381',
          'direction': 'CRECIENTE',
          'km': 150.2,
          'roadSegmentId': 'seg-1',
          'roadSegmentCode': '381BMG0160',
          'distanceMeters': 12.5,
          'directionAmbiguous': false,
        }),
      );

      final p = await repo.locate(-41.98, -18.85);

      expect(p.status, RoadPlacementStatus.onRoad);
      expect(p.roadId, 'road-9');
      expect(p.km, 150.2);
      expect(p.direction, 'CRECIENTE');
      expect(p.segmentCode, '381BMG0160');
      final q = api.to('GET /api/road-network/locate').single.queryParameters;
      expect(q['lon'], -41.98);
      expect(q['lat'], -18.85);
      // La carretera queda aprendida para lo que no se pueda ubicar.
      sessionRoad = null;
      expect(await repo.resolveRoad(), 'road-9');
    });

    test('lejos del eje o sin red no inventa el km', () async {
      api.on(
        'GET /api/road-network/locate',
        const FakeReply(404, {'code': 'LOCATION_OUT_OF_AXIS'}),
      );
      expect((await repo.locate(0, 0)).status, RoadPlacementStatus.offRoad);
      api.offline = true;
      expect((await repo.locate(0, 0)).status, RoadPlacementStatus.unknown);
    });

    test('sin sesion ni ubicacion, la carretera de los tramos', () async {
      sessionRoad = null;
      api.on(
        'GET /api/app-configuration',
        const FakeReply(200, {
          'roadSegments': [
            {'id': 's1', 'roadId': 'road-7'},
            {'id': 's2', 'roadId': 'road-7'},
          ],
        }),
      );
      expect(await repo.resolveRoad(), 'road-7');
    });
  });

  group('alta', () {
    late Directory dir;
    late File photo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('asset_');
      photo = File('${dir.path}/poste.jpg')..writeAsBytesSync([1, 2, 3]);
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // Lo recoge el sistema.
        }
      });
    });

    NewAsset draft({
      bool sendPoint = true,
      List<String> photos = const [],
      String? roadId = 'road-9',
    }) => NewAsset(
      clientId: 'c0a80101-0000-4000-8000-000000000001',
      typeCode: 'POSTE',
      capturedAt: DateTime.utc(2026, 11, 8, 15),
      roadId: roadId,
      kmStart: 150.2004,
      direction: 'CRECIENTE',
      position: const AssetPosition(latitude: -18.85, longitude: -41.98),
      sendPoint: sendPoint,
      attributes: const {'altura_m': 7.5, 'material': 'ACERO'},
      description: '  Poste junto al puente ',
      notes: '',
      photoPaths: photos,
    );

    test('manda lo que pide el servidor con su clave de captura', () async {
      api.on('POST /api/assets', FakeReply(201, _created('a-1')));

      final result = await repo.create(draft());

      expect(result.id, 'a-1');
      expect(result.code, 'POSTE-000123');
      expect(result.queued, isFalse);
      final body = api.to('POST /api/assets').single.data as Map;
      expect(body['assetTypeCode'], 'POSTE');
      expect(body['roadId'], 'road-9');
      expect(body['kmStart'], 150.2);
      expect(body['direction'], 'CRECIENTE');
      expect(body['geometry'], {
        'type': 'Point',
        'coordinates': [-41.98, -18.85],
      });
      expect(body['attributes'], {'altura_m': 7.5, 'material': 'ACERO'});
      expect(body['description'], 'Poste junto al puente');
      expect(body.containsKey('notes'), isFalse);
      expect(body['clientUuid'], 'c0a80101-0000-4000-8000-000000000001');
      // El estado lo decide el servidor (desde la app, pendiente).
      expect(body.containsKey('status'), isFalse);
    });

    test('un tipo de linea o poligono se ubica solo por km', () async {
      api.on('POST /api/assets', FakeReply(201, _created('a-1')));
      await repo.create(draft(sendPoint: false));
      final body = api.to('POST /api/assets').single.data as Map;
      expect(body.containsKey('geometry'), isFalse);
      expect(body['kmStart'], 150.2);
    });

    test('sin carretera de la ubicacion usa la de la sesion', () async {
      api.on('POST /api/assets', FakeReply(201, _created('a-1')));
      await repo.create(draft(roadId: null));
      final body = api.to('POST /api/assets').single.data as Map;
      expect(body['roadId'], 'road-1');
    });

    test(
      'sube las fotos con una clave fija y la primera es la principal',
      () async {
        api.on('POST /api/assets', FakeReply(201, _created('a-1')));
        api.on(
          'POST /api/assets/a-1/attachments',
          const FakeReply(201, {'id': 'f-1'}),
        );
        api.on(
          'POST /api/assets/a-1/attachments/f-1/main',
          const FakeReply(200, {}),
        );

        final result = await repo.create(draft(photos: [photo.path]));

        expect(result.warning, isNull);
        final upload = api.to('POST /api/assets/a-1/attachments').single;
        final form = upload.data as FormData;
        final fields = {for (final f in form.fields) f.key: f.value};
        expect(fields['kind'], 'FOTO');
        expect(
          fields['clientUuid'],
          InventoryJson.photoKey('c0a80101-0000-4000-8000-000000000001', 0),
        );
        expect(
          api.to('POST /api/assets/a-1/attachments/f-1/main'),
          hasLength(1),
        );
      },
    );

    test('si las fotos fallan el activo ya quedo y se avisa', () async {
      api.on('POST /api/assets', FakeReply(201, _created('a-1')));
      api.on(
        'POST /api/assets/a-1/attachments',
        const FakeReply(403, {'code': 'FORBIDDEN', 'title': 'Sin permiso'}),
      );

      final result = await repo.create(draft(photos: [photo.path]));

      expect(result.id, 'a-1');
      expect(result.warning, contains('FORBIDDEN'));
    });

    test('traduce los rechazos del servidor', () async {
      api.on(
        'POST /api/assets',
        const FakeReply(422, {
          'code': 'ASSET_CHANNEL_NOT_ALLOWED',
          'title': 'No nace en la app',
        }),
      );
      await expectLater(
        repo.create(draft()),
        _fails(AssetCaptureError.channelNotAllowed),
      );

      api.on(
        'POST /api/assets',
        const FakeReply(400, {
          'code': 'VALIDATION_FAILED',
          'title': 'Datos invalidos',
          'errors': {
            'attributes.altura_m': ['Es mayor que el máximo (12).'],
          },
        }),
      );
      await expectLater(
        repo.create(draft()),
        throwsA(
          isA<AssetCaptureException>()
              .having((e) => e.error, 'error', AssetCaptureError.validation)
              .having((e) => e.fieldErrors['attributes.altura_m'], 'campo', [
                'Es mayor que el máximo (12).',
              ]),
        ),
      );

      api.offline = true;
      await expectLater(
        repo.create(draft()),
        _fails(AssetCaptureError.network),
      );
    });
  });

  test('la clave de cada foto es estable y con forma de UUID', () {
    final a = InventoryJson.photoKey('k', 0);
    expect(a, InventoryJson.photoKey('k', 0));
    expect(a, isNot(InventoryJson.photoKey('k', 1)));
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(a),
      isTrue,
    );
  });
}
