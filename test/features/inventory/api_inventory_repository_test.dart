import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/api_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _listItem(
  String id, {
  String code = 'DEFENSA-000001',
  String? conservation = 'BUENO',
  num? kmStart = 150.2,
  num? kmEnd,
}) => {
  'id': id,
  'code': code,
  'assetTypeCode': 'DEFENSA',
  'assetTypeLabel': 'Defensa metálica',
  'subsystemCode': 'SGS',
  'roadId': 'r1',
  'roadCode': 'BR-381',
  'roadSegmentCode': '381BMG0160',
  'kmStart': kmStart,
  'kmEnd': kmEnd,
  'direction': 'CRECIENTE',
  'status': 'ACTIVO',
  'conservationState': conservation,
  'hasGeometry': true,
  'brand': null,
  'updatedAt': '2026-10-22T12:00:00Z',
};

Map<String, Object?> _detail({
  Object? geometry = const {
    'type': 'Point',
    'coordinates': [-41.98, -18.85],
  },
  String? description = 'Defensa del puente',
  String? mainPhotoId,
}) => {
  'asset': {
    'id': 'g-1',
    'code': 'DEFENSA-000001',
    'description': description,
    'assetTypeLabel': 'Defensa metálica',
    'conservationState': 'MALO',
    'roadSegmentCode': '381BMG0160',
    'kmStart': 150.2,
    'kmEnd': 151,
    'direction': 'DECRECIENTE',
    'geometry': geometry,
    'installedOn': '2019-03-10',
    'notes': ' Golpeada ',
    'mainPhotoId': mainPhotoId,
  },
  'children': [],
  'attachmentCount': 0,
};

Matcher _fails(InventoryError e) =>
    throwsA(isA<InventoryException>().having((x) => x.error, 'error', e));

void main() {
  late FakeApi api;
  late ApiInventoryRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiInventoryRepository(api.client());
  });

  group('lista', () {
    test('traduce los renglones del servidor', () async {
      api.on(
        'GET /api/assets',
        FakeReply(200, {
          'items': [
            _listItem('g-1'),
            _listItem('g-2', code: 'X-2', conservation: 'PESIMO', kmEnd: 151),
            _listItem('g-3', code: 'X-3', conservation: null, kmStart: null),
          ],
          'total': 3,
        }),
      );

      final assets = await repo.list();

      expect(assets, hasLength(3));
      final a = assets[0];
      expect(a.id, 'g-1');
      expect(a.code, 'DEFENSA-000001');
      expect(a.name, 'DEFENSA-000001');
      expect(a.category, 'Defensa metálica');
      expect(a.condition, AssetCondition.good);
      expect(a.kmLabel, 'KM 150+200');
      expect(a.segmentCode, '381BMG0160');
      expect(a.direction, 'CRECIENTE');
      // La lista no trae geometria: sin ubicacion hasta abrir la ficha.
      expect(a.hasLocation, isFalse);
      expect(assets[1].condition, AssetCondition.poor);
      expect(assets[1].kmLabel, 'KM 150+200 - 151+000');
      // Sin evaluar y sin kilometro.
      expect(assets[2].condition, AssetCondition.unknown);
      expect(assets[2].kmLabel, isNull);
    });

    test('pide todas las paginas hasta el total', () async {
      api.reply('GET /api/assets', (o) {
        final page = o.queryParameters['page'] as int;
        return FakeReply(200, {
          'items': [
            for (var i = 0; i < (page == 1 ? 200 : 5); i++)
              _listItem('p$page-$i', code: 'C$page-$i'),
          ],
          'total': 205,
        });
      });

      expect(await repo.list(), hasLength(205));
      expect(api.requests.first.queryParameters['pageSize'], 200);
    });

    test('los estados de conservacion del servidor', () async {
      api.on(
        'GET /api/assets',
        FakeReply(200, {
          'items': [
            _listItem('1', conservation: 'BUENO'),
            _listItem('2', conservation: 'REGULAR'),
            _listItem('3', conservation: 'MALO'),
            _listItem('4', conservation: 'PESIMO'),
            _listItem('5', conservation: 'otro'),
          ],
          'total': 5,
        }),
      );
      final conditions = (await repo.list()).map((a) => a.condition).toList();
      expect(conditions, [
        AssetCondition.good,
        AssetCondition.regular,
        AssetCondition.poor,
        AssetCondition.poor,
        AssetCondition.unknown,
      ]);
    });

    test('traduce los errores', () async {
      api.on('GET /api/assets', const FakeReply(403, {'code': 'X'}));
      await expectLater(repo.list(), _fails(InventoryError.permissionDenied));
      // Al listar, 404 es que aun no se publica.
      api.on('GET /api/assets', const FakeReply(404));
      await expectLater(repo.list(), _fails(InventoryError.notAvailable));
      api.on('GET /api/assets', const FakeReply(500, {'title': 'x'}));
      await expectLater(repo.list(), _fails(InventoryError.server));
      api.offline = true;
      await expectLater(repo.list(), _fails(InventoryError.network));
    });
  });

  group('ficha', () {
    test('trae descripcion, ubicacion, fecha y notas', () async {
      api.on('GET /api/assets/g-1', FakeReply(200, _detail()));

      final a = await repo.get('g-1');

      expect(a.name, 'Defensa del puente');
      expect(a.code, 'DEFENSA-000001');
      expect(a.condition, AssetCondition.poor);
      expect(a.latitude, -18.85);
      expect(a.longitude, -41.98);
      expect(a.hasLocation, isTrue);
      expect(a.installedAt, DateTime.utc(2019, 3, 10));
      expect(a.notes, 'Golpeada');
      expect(a.kmLabel, 'KM 150+200 - 151+000');
    });

    test('sin descripcion el nombre es el codigo', () async {
      api.on('GET /api/assets/g-1', FakeReply(200, _detail(description: null)));
      expect((await repo.get('g-1')).name, 'DEFENSA-000001');
    });

    test('la ubicacion de una linea y de un poligono', () async {
      api.on(
        'GET /api/assets/g-1',
        FakeReply(
          200,
          _detail(
            geometry: {
              'type': 'LineString',
              'coordinates': [
                [-41.0, -18.0],
                [-41.5, -18.5],
                [-42.0, -19.0],
              ],
            },
          ),
        ),
      );
      var a = await repo.get('g-1');
      expect([a.latitude, a.longitude], [-18.5, -41.5]);

      api.on(
        'GET /api/assets/g-1',
        FakeReply(
          200,
          _detail(
            geometry: {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-41.0, -18.0],
                  [-43.0, -18.0],
                  [-43.0, -20.0],
                  [-41.0, -20.0],
                ],
              ],
            },
          ),
        ),
      );
      a = await repo.get('g-1');
      expect([a.latitude, a.longitude], [-19.0, -42.0]);
    });

    test('sin geometria no hay ubicacion', () async {
      api.on('GET /api/assets/g-1', FakeReply(200, _detail(geometry: null)));
      expect((await repo.get('g-1')).hasLocation, isFalse);
    });

    test('un activo que ya no existe da notFound', () async {
      api.on('GET /api/assets/g-9', const FakeReply(404));
      await expectLater(repo.get('g-9'), _fails(InventoryError.notFound));
    });
  });

  group('foto principal', () {
    test('baja la foto con la sesion', () async {
      api.on(
        'GET /api/assets/g-1',
        FakeReply(200, _detail(mainPhotoId: 'f-7')),
      );
      api.on(
        'GET /api/assets/g-1/attachments/f-7/content',
        FakeReply.bytes(200, Uint8List.fromList([1, 2, 3])),
      );

      final asset = await repo.get('g-1');
      expect(asset.mainPhotoId, 'f-7');
      expect(await repo.mainPhoto(asset), Uint8List.fromList([1, 2, 3]));
    });

    test('sin foto no pide nada; si falla, devuelve null', () async {
      api.on('GET /api/assets/g-1', FakeReply(200, _detail()));
      final plain = await repo.get('g-1');
      expect(await repo.mainPhoto(plain), isNull);
      expect(api.to('GET /api/assets/g-1/attachments/f-7/content'), isEmpty);

      api.on(
        'GET /api/assets/g-1',
        FakeReply(200, _detail(mainPhotoId: 'f-7')),
      );
      api.on(
        'GET /api/assets/g-1/attachments/f-7/content',
        const FakeReply(500, {'title': 'x'}),
      );
      final withPhoto = await repo.get('g-1');
      expect(await repo.mainPhoto(withPhoto), isNull);
    });
  });
}
