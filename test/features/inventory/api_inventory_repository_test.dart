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

  /// Un servidor de `/api/assets` con [rows] activos de cada estado de
  /// conservacion: pagina, filtra por estado y da el total, como el real.
  void serve(Map<String?, int> rows) {
    api.reply('GET /api/assets', (o) {
      final q = o.queryParameters;
      final state = q['conservationState'] as String?;
      final total = state == null
          ? rows.values.fold(0, (a, b) => a + b)
          : (rows[state] ?? 0);
      final page = q['page'] as int;
      final size = q['pageSize'] as int;
      final from = (page - 1) * size;
      final count = (total - from).clamp(0, size);
      return FakeReply(200, {
        'items': [
          for (var i = 0; i < count; i++)
            _listItem(
              '${state ?? 'x'}-${from + i}',
              code: 'C-${state ?? 'x'}-${from + i}',
              conservation: state,
            ),
        ],
        'total': total,
        'page': page,
        'pageSize': size,
      });
    });
  }

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

      final page = await repo.page(const InventoryQuery());
      final assets = page.items;

      expect(page.total, 3);
      expect(page.hasMore, isFalse);
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

    test('pide de a una pagina y el total es el del servidor', () async {
      serve({null: 120});

      final first = await repo.page(const InventoryQuery());
      expect(first.items, hasLength(50));
      expect(first.total, 120);
      expect(first.hasMore, isTrue);
      // Una sola consulta: nada de bajar todo.
      expect(api.requests, hasLength(1));
      expect(api.requests.single.queryParameters, {
        'page': 1,
        'pageSize': 50,
        'sort': 'road',
      });

      final second = await repo.page(const InventoryQuery(), after: first.next);
      expect(second.items.first.id, 'x-50');
      expect(second.hasMore, isTrue);
      final third = await repo.page(const InventoryQuery(), after: second.next);
      expect(third.items, hasLength(20));
      expect(third.items.last.id, 'x-119');
      expect(third.total, 120);
      expect(third.hasMore, isFalse);
      expect(api.requests.map((r) => r.queryParameters['page']), [1, 2, 3]);
    });

    test('la busqueda y los filtros van al servidor', () async {
      serve({'BUENO': 3});

      await repo.page(
        InventoryQuery(
          search: '  OAE 381 ',
          typeCode: 'OAE',
          condition: AssetCondition.good,
          inspectedFrom: DateTime.utc(2026, 3, 1),
          inspectedTo: DateTime.utc(2026, 11, 8),
        ),
      );

      expect(api.requests.single.queryParameters, {
        'page': 1,
        'pageSize': 50,
        'sort': 'road',
        'search': 'OAE 381',
        'assetTypeCode': 'OAE',
        'conservationState': 'BUENO',
        'dateField': 'INSPECCION',
        'from': '2026-03-01',
        'to': '2026-11-08',
      });
    });

    test(
      '"malo" pide los pesimos y luego los malos, con el total de ambos',
      () async {
        serve({'PESIMO': 3, 'MALO': 60, 'BUENO': 7});
        const query = InventoryQuery(condition: AssetCondition.poor);

        final first = await repo.page(query);
        expect(first.total, 63);
        // Los pesimos (3) y una pagina de malos (50).
        expect(first.items, hasLength(53));
        expect(first.items.take(3).map((a) => a.condition), [
          for (var i = 0; i < 3; i++) AssetCondition.poor,
        ]);
        expect(first.items.first.id, 'PESIMO-0');
        expect(first.items[3].id, 'MALO-0');
        expect(first.hasMore, isTrue);

        final second = await repo.page(query, after: first.next);
        expect(second.items.map((a) => a.id), [
          for (var i = 50; i < 60; i++) 'MALO-$i',
        ]);
        expect(second.total, 63);
        expect(second.hasMore, isFalse);
        expect(
          api.requests
              .map((r) => r.queryParameters['conservationState'])
              .toSet(),
          {'PESIMO', 'MALO'},
        );
      },
    );

    test(
      'los conteos son una fila por estado, sin el filtro de estado',
      () async {
        serve({'BUENO': 5, 'REGULAR': 2, 'MALO': 1, 'PESIMO': 4, null: 0});

        final counts = await repo.counts(
          const InventoryQuery(
            search: 'oae',
            typeCode: 'OAE',
            condition: AssetCondition.good,
          ),
        );

        expect(
          counts,
          const InventoryCounts(total: 12, good: 5, regular: 2, poor: 5),
        );
        expect(counts.of(AssetCondition.unknown), 0);
        expect(api.requests, hasLength(5));
        for (final r in api.requests) {
          expect(r.queryParameters['pageSize'], 1);
          expect(r.queryParameters['search'], 'oae');
          expect(r.queryParameters['assetTypeCode'], 'OAE');
        }
        expect(
          api.requests
              .map((r) => r.queryParameters['conservationState'])
              .toSet(),
          {null, 'BUENO', 'REGULAR', 'MALO', 'PESIMO'},
        );
      },
    );

    test('los tipos para filtrar, sin los que no tienen activos', () async {
      api.on(
        'GET /api/catalogs/asset-types',
        const FakeReply(200, [
          {'code': 'OAE', 'labelEs': 'OAE', 'assetCount': 94, 'sortOrder': 2},
          {'code': 'POSTE', 'labelEs': 'Poste', 'assetCount': 0},
          {'code': 'DEFENSA', 'labelEs': 'Defensa', 'sortOrder': 1},
          {'code': 'VIEJO', 'labelEs': 'Viejo', 'active': false},
        ]),
      );
      expect((await repo.types()).map((t) => t.code), ['DEFENSA', 'OAE']);

      // Sin la ruta, los del catalogo general; sin nada, vacio.
      api.routes.remove('GET /api/catalogs/asset-types');
      api.on(
        'GET /api/catalogs',
        const FakeReply(200, {
          'assetTypes': [
            {'code': 'OAE', 'labelEs': 'OAE'},
          ],
        }),
      );
      expect((await repo.types()).map((t) => t.code), ['OAE']);
      api.offline = true;
      expect(await repo.types(), isEmpty);
    });

    test('una consulta cancelada no espera ni usa lo guardado', () async {
      serve({null: 10});
      final cancellation = InventoryCancellation()..cancel();
      await expectLater(
        repo.page(const InventoryQuery(), cancellation: cancellation),
        _fails(InventoryError.network),
      );
      await expectLater(
        repo.counts(const InventoryQuery(), cancellation: cancellation),
        _fails(InventoryError.network),
      );
      // Sin cancelar, responde.
      expect(
        (await repo.page(
          const InventoryQuery(),
          cancellation: InventoryCancellation(),
        )).total,
        10,
      );
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
      final conditions = (await repo.page(
        const InventoryQuery(),
      )).items.map((a) => a.condition).toList();
      expect(conditions, [
        AssetCondition.good,
        AssetCondition.regular,
        AssetCondition.poor,
        AssetCondition.poor,
        AssetCondition.unknown,
      ]);
    });

    test('traduce los errores', () async {
      Future<InventoryResultPage> list() => repo.page(const InventoryQuery());
      api.on('GET /api/assets', const FakeReply(403, {'code': 'X'}));
      await expectLater(list(), _fails(InventoryError.permissionDenied));
      // Al listar, 404 es que aun no se publica.
      api.on('GET /api/assets', const FakeReply(404));
      await expectLater(list(), _fails(InventoryError.notAvailable));
      await expectLater(
        repo.counts(const InventoryQuery()),
        _fails(InventoryError.notAvailable),
      );
      api.on('GET /api/assets', const FakeReply(500, {'title': 'x'}));
      await expectLater(list(), _fails(InventoryError.server));
      api.offline = true;
      await expectLater(list(), _fails(InventoryError.network));
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

    test('una OAE del WebGIS (MULTIPOLYGON) tiene coordenadas', () async {
      // Dos poligonos: el grande (4 x 2) pesa el doble que el chico (2 x 2).
      api.on(
        'GET /api/assets/g-1',
        FakeReply(
          200,
          _detail(
            geometry: {
              'type': 'MultiPolygon',
              'coordinates': [
                [
                  [
                    [-42.0, -19.0],
                    [-38.0, -19.0],
                    [-38.0, -17.0],
                    [-42.0, -17.0],
                    [-42.0, -19.0],
                  ],
                ],
                [
                  [
                    [-48.0, -19.0],
                    [-46.0, -19.0],
                    [-46.0, -17.0],
                    [-48.0, -17.0],
                    [-48.0, -19.0],
                  ],
                ],
              ],
            },
          ),
        ),
      );
      final a = await repo.get('g-1');
      expect(a.hasLocation, isTrue);
      expect(a.latitude, closeTo(-18.0, 1e-9));
      // (-40 * 8 + -47 * 4) / 12
      expect(a.longitude, closeTo(-42.333333, 1e-6));
    });

    test('una linea de varias partes: el punto a la mitad del largo', () async {
      api.on(
        'GET /api/assets/g-1',
        FakeReply(
          200,
          _detail(
            geometry: {
              'type': 'MultiLineString',
              'coordinates': [
                [
                  [-41.0, -18.0],
                  [-41.0, -19.0],
                ],
                [
                  [-42.0, -18.0],
                  [-42.0, -21.0],
                ],
              ],
            },
          ),
        ),
      );
      final a = await repo.get('g-1');
      // Largo 4: la mitad cae a 1 del inicio de la segunda parte.
      expect(a.latitude, closeTo(-19.0, 1e-9));
      expect(a.longitude, closeTo(-42.0, 1e-9));
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
