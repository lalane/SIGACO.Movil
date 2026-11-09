import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/map/data/cache/map_pins_cache.dart';
import 'package:sigaco_movil/features/map/data/repositories/api_map_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/cached_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_bounds.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';
import 'package:sigaco_movil/features/map/presentation/map_camera.dart';
import 'package:sigaco_movil/features/map/presentation/maplibre/maplibre_engine.dart';

import '../../support/fake_api.dart';
import '../../support/map_fakes.dart';

/// Una consulta de zona que hizo el cubit: el rectangulo, su cancelacion y la
/// respuesta, que la prueba entrega cuando quiere.
class _AreaRequest {
  _AreaRequest(this.area, this.cancel);

  final GeoBounds area;
  final MapQueryCancel? cancel;
  final completer = Completer<AreaPins>();

  bool get cancelled => cancel?.isCancelled ?? false;

  void answer(List<MapPin> pins, {bool truncated = false}) =>
      completer.complete(AreaPins(pins, truncated: truncated));
}

/// El inventario por zona, como el servidor: cada consulta se anota. Con
/// [manual] la prueba responde; si no, responde [answer] enseguida.
class _AreaRepo extends FakeMapRepository implements AreaPinsSource {
  _AreaRepo({super.data});

  final areas = <_AreaRequest>[];
  bool manual = false;

  /// Una consulta cancelada se corta (como la de Dio); con false sigue y su
  /// respuesta llega tarde.
  bool honorCancel = true;
  List<MapPin> Function(GeoBounds area) answer = (_) => const [];
  bool truncated = false;
  MapError? areaFailure;

  @override
  bool loadsByArea(MapLayer layer) => layer == MapLayer.inventory;

  @override
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  }) {
    final request = _AreaRequest(area, cancel);
    areas.add(request);
    final failure = areaFailure;
    if (failure != null) return Future.error(MapException(failure));
    if (!manual) {
      return Future.value(AreaPins(answer(area), truncated: truncated));
    }
    if (honorCancel) {
      cancel?.onCancel(() {
        if (!request.completer.isCompleted) {
          request.completer.completeError(const MapQueryCancelled());
        }
      });
    }
    return request.completer.future;
  }
}

/// Unos 11 km por lado sobre la BR-381.
const _view = GeoBounds(south: -19.0, west: -42.1, north: -18.9, east: -42.0);

/// Otra zona, lejos de la primera.
const _far = GeoBounds(south: -19.5, west: -42.6, north: -19.4, east: -42.5);

MapPin _asset(
  String id,
  double lat,
  double lon, {
  String? category,
  String? group,
}) => MapPin(
  id: id,
  layer: MapLayer.inventory,
  title: id,
  category: category,
  group: group,
  position: GeoPoint(lat, lon),
);

/// Deja correr la espera corta del cubit y las respuestas.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  group('cubit por zona', () {
    late _AreaRepo repo;
    late FakeLocationSource location;

    MapCubit build() {
      final cubit = MapCubit(
        repository: repo,
        locationSource: location,
        areaDelay: const Duration(milliseconds: 10),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() {
      repo = _AreaRepo(
        data: {
          MapLayer.tickets: [fakePin('t1', layer: MapLayer.tickets)],
        },
      );
      repo.answer = (area) => [
        for (final p in [
          _asset('a1', -18.95, -42.05, category: 'Defensa', group: 'SGS'),
          _asset('a2', -18.96, -42.06, category: 'Señal', group: 'SGS'),
          _asset('b1', -19.45, -42.55, category: 'OAE', group: 'SGOAE'),
        ])
          if (area.contains(p.position)) p,
      ];
      location = FakeLocationSource(
        location: fakeLocation(position: const GeoPoint(-18.95, -42.05)),
      );
    });

    test('el inventario pide solo la zona que se ve, con un margen', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      expect(cubit.state.byArea, isTrue);
      expect(cubit.state.status, MapStatus.ready);
      expect(repo.areas.single.area, _view.expanded(MapCubit.areaMargin));
      expect(cubit.state.visiblePins.map((p) => p.id), ['a1', 'a2']);
      // Nunca se pide el inventario entero.
      expect(repo.requestsFor(MapLayer.inventory), 0);
    });

    test('las otras pestanas siguen completas y no siguen al mapa', () async {
      final cubit = build();
      await cubit.load();
      cubit.viewportChanged(_view, 14);
      await _settle();

      expect(cubit.state.byArea, isFalse);
      expect(cubit.state.visiblePins.map((p) => p.id), ['t1']);
      expect(repo.areas, isEmpty);
    });

    test('lejos del zoom minimo no pide activos y pide acercarse', () async {
      final cubit = build();
      cubit.viewportChanged(_view, MapCubit.areaMinZoom - 0.5);
      await cubit.selectLayer(MapLayer.inventory);

      expect(repo.areas, isEmpty);
      expect(cubit.state.areaZoomedOut, isTrue);
      expect(cubit.state.visiblePins, isEmpty);

      cubit.viewportChanged(_view, MapCubit.areaMinZoom);
      await _settle();

      expect(repo.areas, hasLength(1));
      expect(cubit.state.areaZoomedOut, isFalse);
      expect(cubit.state.visiblePins.map((p) => p.id), ['a1', 'a2']);
    });

    test('al alejarse se quitan los activos: serian una parte cualquiera', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);
      expect(cubit.state.visiblePins, hasLength(2));

      cubit.viewportChanged(_view.expanded(2), 10);
      await _settle();

      expect(cubit.state.visiblePins, isEmpty);
      expect(cubit.state.areaZoomedOut, isTrue);
      expect(repo.areas, hasLength(1));
    });

    test('mover el mapa espera a que se detenga: una sola consulta', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      // Un arrastre: muchas posiciones seguidas, sin pausa.
      for (var i = 1; i <= 5; i++) {
        cubit.viewportChanged(
          GeoBounds(
            south: _far.south + i * 0.001,
            west: _far.west,
            north: _far.north + i * 0.001,
            east: _far.east,
          ),
          14,
        );
      }
      await _settle();

      expect(repo.areas, hasLength(2));
      expect(
        repo.areas.last.area,
        GeoBounds(
          south: _far.south + 5 * 0.001,
          west: _far.west,
          north: _far.north + 5 * 0.001,
          east: _far.east,
        ).expanded(MapCubit.areaMargin),
      );
      expect(cubit.state.visiblePins.map((p) => p.id), ['b1']);
    });

    test('moverse dentro de la zona ya traida no vuelve a pedir', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      // Un poco al norte: sigue dentro del margen.
      cubit.viewportChanged(
        const GeoBounds(
          south: -18.98,
          west: -42.09,
          north: -18.88,
          east: -41.99,
        ),
        14,
      );
      await _settle();

      expect(repo.areas, hasLength(1));
    });

    test('si la zona vino recortada, moverse si vuelve a pedir', () async {
      repo.truncated = true;
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);
      expect(cubit.state.areaTruncated, isTrue);

      cubit.viewportChanged(
        const GeoBounds(
          south: -18.98,
          west: -42.09,
          north: -18.88,
          east: -41.99,
        ),
        14,
      );
      await _settle();

      expect(repo.areas, hasLength(2));
    });

    test(
      'una zona nueva cancela la consulta anterior y su respuesta tardia no se pinta',
      () async {
        repo
          ..manual = true
          ..honorCancel = false;
        final cubit = build();
        cubit.viewportChanged(_view, 14);
        unawaited(cubit.selectLayer(MapLayer.inventory));
        await Future<void>.delayed(Duration.zero);
        expect(repo.areas, hasLength(1));
        expect(cubit.state.areaLoading, isTrue);

        cubit.viewportChanged(_far, 14);
        await _settle();

        expect(repo.areas, hasLength(2));
        expect(repo.areas.first.cancelled, isTrue);
        expect(repo.areas.last.cancelled, isFalse);

        repo.areas.last.answer([_asset('b1', -19.45, -42.55)]);
        await Future<void>.delayed(Duration.zero);
        // La primera responde despues: ya no vale.
        repo.areas.first.answer([_asset('a1', -18.95, -42.05)]);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.visiblePins.map((p) => p.id), ['b1']);
        expect(cubit.state.areaLoading, isFalse);
      },
    );

    test(
      'una consulta cortada por otra no se cuenta como fallo',
      () async {
        repo.manual = true;
        final cubit = build();
        cubit.viewportChanged(_view, 14);
        unawaited(cubit.selectLayer(MapLayer.inventory));
        await Future<void>.delayed(Duration.zero);

        cubit.viewportChanged(_far, 14);
        await _settle();
        repo.areas.last.answer([_asset('b1', -19.45, -42.55)]);
        await Future<void>.delayed(Duration.zero);

        expect(repo.areas.first.completer.isCompleted, isTrue);
        expect(cubit.state.areaError, isNull);
        expect(cubit.state.status, MapStatus.ready);
        expect(cubit.state.visiblePins.map((p) => p.id), ['b1']);
      },
    );

    test('mientras llega la zona siguen a la vista los pines de antes', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);
      repo.manual = true;

      // Un poco al este, fuera del margen: hay consulta, pero a1 y a2 se ven.
      const east = GeoBounds(
        south: -19.0,
        west: -42.07,
        north: -18.9,
        east: -41.97,
      );
      cubit.viewportChanged(east, 14);
      await _settle();
      expect(cubit.state.areaLoading, isTrue);
      expect(cubit.state.visiblePins.map((p) => p.id), ['a1', 'a2']);

      repo.areas.last.answer([
        _asset('a1', -18.95, -42.05),
        _asset('a3', -18.95, -41.98),
      ]);
      await Future<void>.delayed(Duration.zero);

      // a2 tambien cae en la zona pedida y el servidor ya no la trae: se quita.
      expect(cubit.state.visiblePins.map((p) => p.id), ['a1', 'a3']);
    });

    test('refresh vuelve a pedir la zona sin quitar el mapa', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);
      final states = <MapState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.refresh();
      await sub.cancel();

      expect(repo.areas, hasLength(2));
      expect(states.map((s) => s.status), everyElement(MapStatus.ready));
      expect(states.first.areaLoading, isTrue);
      expect(states.first.visiblePins, hasLength(2));
    });

    test('un corte deja lo que ya se veia y avisa; reintentar la pide', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      repo.areaFailure = MapError.network;
      await cubit.refresh();

      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.areaError, MapError.network);
      expect(cubit.state.visiblePins, hasLength(2));

      repo.areaFailure = null;
      await cubit.refresh();
      expect(cubit.state.areaError, isNull);
    });

    test('sin permiso la pestana lo dice entera', () async {
      repo.areaFailure = MapError.permissionDenied;
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      expect(cubit.state.status, MapStatus.failure);
      expect(cubit.state.error, MapError.permissionDenied);
    });

    test('los filtros se aplican en el telefono sobre la zona', () async {
      final cubit = build();
      cubit.viewportChanged(_view, 14);
      await cubit.selectLayer(MapLayer.inventory);

      cubit.toggleCategory('Señal');
      expect(cubit.state.visiblePins.map((p) => p.id), ['a2']);
      expect(repo.areas, hasLength(1));

      // En otra zona sin señales el filtro se puede seguir quitando.
      cubit.setGroupFilter('SGS');
      cubit.viewportChanged(_far, 14);
      await _settle();
      expect(cubit.state.visiblePins, isEmpty);
      expect(cubit.state.availableCategories, containsAll(['OAE', 'Señal']));
      expect(cubit.state.availableGroups, ['SGOAE', 'SGS']);
    });

    test('ubicarse no baja todo el inventario: solo lo de alrededor', () async {
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      await _settle();

      expect(repo.requestsFor(MapLayer.inventory), 0);
      final around = repo.areas.single.area;
      expect(around.contains(const GeoPoint(-18.95, -42.05)), isTrue);
      expect(cubit.state.inventoryLoaded, isTrue);
      // Sin el servidor de cercanos, se calculan con lo de alrededor.
      expect(cubit.state.nearby.map((n) => n.pin.id), contains('a1'));
    });
  });

  group('mezcla de la zona', () {
    final previous = [
      _asset('dentro', -18.95, -42.05),
      _asset('borde', -18.95, -42.11),
      _asset('lejos', -19.45, -42.55),
    ];
    const area = _view;
    const visible = GeoBounds(
      south: -19.0,
      west: -42.12,
      north: -18.9,
      east: -42.0,
    );

    test('dentro de la zona manda la respuesta; a la vista fuera, se queda', () {
      final merged = mergeAreaPins(
        previous: previous,
        fresh: [_asset('nuevo', -18.96, -42.04)],
        area: area,
        visible: visible,
        truncated: false,
      );
      expect(merged.map((p) => p.id), ['nuevo', 'borde']);
    });

    test('recortada: lo que ya se veia se conserva', () {
      final merged = mergeAreaPins(
        previous: previous,
        fresh: [_asset('nuevo', -18.96, -42.04)],
        area: area,
        visible: visible,
        truncated: true,
      );
      expect(merged.map((p) => p.id), ['nuevo', 'dentro', 'borde']);
    });

    test('un pin que llega otra vez no se repite', () {
      final merged = mergeAreaPins(
        previous: previous,
        fresh: [_asset('borde', -18.95, -42.11)],
        area: area,
        visible: visible,
        truncated: true,
      );
      expect(merged.map((p) => p.id), ['borde', 'dentro']);
    });
  });

  group('repositorio contra el servidor', () {
    late FakeApi api;
    late ApiMapRepository repo;

    Map<String, Object?> feature(String id) => {
      'id': id,
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [-42.05, -18.95],
      },
      'properties': {
        'code': 'COD-$id',
        'assetTypeCode': 'POSTE',
        'subsystemCode': 'SGS',
        'status': 'ACTIVO',
      },
    };

    setUp(() {
      api = FakeApi();
      repo = ApiMapRepository(api.client(), language: () => 'es');
      api.on('GET /api/catalogs', const FakeReply(200, {'assetTypes': []}));
    });

    test('solo el inventario va por zona', () {
      expect(repo.loadsByArea(MapLayer.inventory), isTrue);
      for (final layer in [
        MapLayer.tickets,
        MapLayer.maintenance,
        MapLayer.works,
      ]) {
        expect(repo.loadsByArea(layer), isFalse, reason: layer.name);
      }
    });

    test('manda el rectangulo como minLon,minLat,maxLon,maxLat y el tope', () async {
      api.on(
        'GET /api/assets/map',
        FakeReply(200, {
          'type': 'FeatureCollection',
          'features': [feature('a1')],
          'truncated': true,
        }),
      );

      final found = await repo.pinsIn(MapLayer.inventory, _view);

      final query = api.to('GET /api/assets/map').single.queryParameters;
      expect(query['bbox'], '-42.100000,-19.000000,-42.000000,-18.900000');
      expect('${query['limit']}', '${ApiMapRepository.areaLimit}');
      expect(found.pins.single.id, 'a1');
      expect(found.truncated, isTrue);
      expect(found.cachedAt, isNull);
    });

    test('el rectangulo no se sale del planeta ni queda sin ancho', () {
      expect(
        ApiMapRepository.bboxOf(
          const GeoBounds(south: -95, west: -190, north: 95, east: 190),
        ),
        '-180.000000,-90.000000,180.000000,90.000000',
      );
      final point = ApiMapRepository.bboxOf(
        const GeoBounds(south: -19, west: -42, north: -19, east: -42),
      );
      final parts = point.split(',').map(double.parse).toList();
      expect(parts[0], lessThan(parts[2]));
      expect(parts[1], lessThan(parts[3]));
    });

    test('cancelada antes de pedir: no llega al servidor', () async {
      final cancel = MapQueryCancel();
      api.reply('GET /api/catalogs', (_) {
        // Mientras baja el catalogo, el mapa ya se movio.
        cancel.cancel();
        return const FakeReply(200, {'assetTypes': []});
      });

      await expectLater(
        repo.pinsIn(MapLayer.inventory, _view, cancel: cancel),
        throwsA(isA<MapQueryCancelled>()),
      );
      expect(api.to('GET /api/assets/map'), isEmpty);
    });

    test('cancelada mientras responde: no se entrega', () async {
      final cancel = MapQueryCancel();
      api.reply('GET /api/assets/map', (_) {
        cancel.cancel();
        return FakeReply(200, {
          'features': [feature('a1')],
        });
      });

      await expectLater(
        repo.pinsIn(MapLayer.inventory, _view, cancel: cancel),
        throwsA(isA<MapQueryCancelled>()),
      );
    });

    test('los fallos son los del mapa', () async {
      api.on('GET /api/assets/map', const FakeReply(403, {'code': 'X'}));
      await expectLater(
        repo.pinsIn(MapLayer.inventory, _view),
        throwsA(
          isA<MapException>().having(
            (e) => e.error,
            'error',
            MapError.permissionDenied,
          ),
        ),
      );
      api.offline = true;
      await expectLater(
        repo.pinsIn(MapLayer.inventory, _view),
        throwsA(
          isA<MapException>().having((e) => e.error, 'error', MapError.network),
        ),
      );
    });
  });

  group('zonas guardadas en el telefono', () {
    late Directory dir;
    late FileMapPinsCache cache;
    late _AreaRepo server;
    late CachedMapRepository repo;
    final at = DateTime.utc(2026, 11, 8, 12);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('map_area_cache');
      cache = FileMapPinsCache(root: () async => dir, clock: () => at);
      await cache.bind(const OfflineScope(userId: 'ana', concessionId: 'c1'));
      server = _AreaRepo();
      repo = CachedMapRepository(server, cache);
    });

    tearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    test('cada zona se suma a lo guardado; lo de la zona se reemplaza', () async {
      await cache.save(MapLayer.inventory, [
        _asset('viejo-dentro', -18.95, -42.05),
        _asset('fuera', -19.45, -42.55),
      ]);
      server.answer = (_) => [_asset('nuevo', -18.96, -42.04)];

      final found = await repo.pinsIn(MapLayer.inventory, _view);
      expect(found.pins.map((p) => p.id), ['nuevo']);

      // Se escribe sin hacer esperar al mapa; sin conexion, lo guardado se lee
      // cuando termina de escribirse.
      server.areaFailure = MapError.network;
      final offline = await repo.pinsIn(
        MapLayer.inventory,
        const GeoBounds(south: -20, west: -43, north: -18, east: -41),
      );
      expect(offline.pins.map((p) => p.id), ['nuevo', 'fuera']);
      expect(offline.cachedAt, at);
      final saved = await cache.read(MapLayer.inventory);
      expect(saved!.map((p) => p.id), ['nuevo', 'fuera']);
    });

    test('sin conexion entrega lo guardado de la zona, con su fecha', () async {
      await cache.save(MapLayer.inventory, [
        _asset('dentro', -18.95, -42.05),
        _asset('fuera', -19.45, -42.55),
      ]);
      server.areaFailure = MapError.network;

      final found = await repo.pinsIn(MapLayer.inventory, _view);

      expect(found.pins.map((p) => p.id), ['dentro']);
      expect(found.cachedAt, at);
    });

    test('una consulta cancelada no busca lo guardado', () async {
      await cache.save(MapLayer.inventory, [_asset('dentro', -18.95, -42.05)]);
      server.manual = true;
      final cancel = MapQueryCancel();

      final pending = repo.pinsIn(MapLayer.inventory, _view, cancel: cancel);
      cancel.cancel();

      await expectLater(pending, throwsA(isA<MapQueryCancelled>()));
    });

    test('sin conexion ni nada guardado falla como de red', () async {
      server.areaFailure = MapError.network;
      await expectLater(
        repo.pinsIn(MapLayer.inventory, _view),
        throwsA(
          isA<MapException>().having((e) => e.error, 'error', MapError.network),
        ),
      );
    });
  });

  group('geometria y camara', () {
    test('el rectangulo agrandado no se sale del planeta', () {
      const near = GeoBounds(south: -89, west: -179, north: -80, east: -170);
      final grown = near.expanded(0.5);
      expect(grown.south, -90);
      expect(grown.west, -180);
      expect(grown.north, closeTo(-75.5, 1e-9));
      expect(grown.covers(near), isTrue);
      expect(near.covers(grown), isFalse);
    });

    test('alrededor de un punto lo contiene', () {
      const here = GeoPoint(-18.95, -42.05);
      final box = GeoBounds.around(here, 1000);
      expect(box.contains(here), isTrue);
      expect(box.north - box.south, closeTo(2000 / 111320, 1e-6));
    });

    test('el zoom de MapLibre se cuenta como el de la web', () {
      expect(MapLibreEngine.rasterZoom(MapCubit.areaMinZoom - 1), 12);
    });

    test('ir a un punto antes de que haya mapa se hace al conectarlo', () async {
      final camera = MapCameraController();
      await camera.moveTo(const GeoPoint(-18.95, -42.05), minZoom: 15);

      final moves = <(GeoPoint, double)>[];
      camera.attach((point, zoom) async => moves.add((point, zoom)));
      await Future<void>.delayed(Duration.zero);

      expect(moves, [(const GeoPoint(-18.95, -42.05), 15.0)]);
      // Ya conectado, va directo y no repite lo pendiente.
      await camera.moveTo(const GeoPoint(-19, -42));
      expect(moves, hasLength(2));
    });
  });
}
