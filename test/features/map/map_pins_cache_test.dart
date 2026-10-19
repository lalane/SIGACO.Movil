import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/map/data/cache/map_pins_cache.dart';
import 'package:sigaco_movil/features/map/data/repositories/cached_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';

import '../../support/map_fakes.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaOtraConcesion = OfflineScope(userId: 'ana', concessionId: 'c2');
const _luis = OfflineScope(userId: 'luis', concessionId: 'c1');

final _at = DateTime.utc(2026, 10, 16, 15, 30);

/// El mapa se ve con y sin conexion; lo guardado es de una persona y una
/// concesion (RN-CTX-02).
void main() {
  late Directory dir;
  late FileMapPinsCache cache;

  FileMapPinsCache build() =>
      FileMapPinsCache(root: () async => dir, clock: () => _at);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('map_pins_cache_test');
    cache = build();
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  final pins = [
    fakePin(
      't1',
      layer: MapLayer.tickets,
      category: 'Daño',
      status: PinStatus.critical,
      subtitle: 'Abierto',
      kmLabel: 'KM 147+200',
      segmentCode: '381BMG0160',
      direction: TravelDirection.decreasing,
      position: const GeoPoint(-18.846, -41.98),
    ),
    fakePin('t2', layer: MapLayer.tickets),
  ];

  group('cache en disco', () {
    test('sin alcance no guarda ni entrega nada', () async {
      await cache.save(MapLayer.tickets, pins);

      expect(await cache.read(MapLayer.tickets), isNull);
    });

    test('devuelve los pines tal como se guardaron, con su fecha', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);

      final saved = await cache.read(MapLayer.tickets);

      expect(saved, isNotNull);
      expect(saved!.cachedAt, _at);
      expect(saved, pins);
      expect(saved.first.position, const GeoPoint(-18.846, -41.98));
      expect(saved.first.status, PinStatus.critical);
      expect(saved.first.segmentCode, '381BMG0160');
      expect(saved.first.direction, TravelDirection.decreasing);
      // Un pin sin tramo sigue sin tramo.
      expect(saved.last.segmentCode, isNull);
      expect(saved.last.direction, isNull);
    });

    test('cada pestana se guarda aparte', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);

      expect(await cache.read(MapLayer.inventory), isNull);
    });

    test('sobrevive a cerrar la app con el mismo alcance', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);

      final reopened = build();
      await reopened.bind(_ana);

      expect((await reopened.read(MapLayer.tickets))!.length, 2);
    });

    test('otra concesion o persona no ve lo guardado', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);

      final other = build();
      await other.bind(_anaOtraConcesion);
      expect(await other.read(MapLayer.tickets), isNull);

      final again = build();
      await again.bind(_ana);
      // Ya se descarto al entrar la otra concesion.
      expect(await again.read(MapLayer.tickets), isNull);

      await again.save(MapLayer.tickets, pins);
      final someone = build();
      await someone.bind(_luis);
      expect(await someone.read(MapLayer.tickets), isNull);
    });

    test('cerrar sesion lo borra', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);

      await cache.bind(null);
      await cache.bind(_ana);

      expect(await cache.read(MapLayer.tickets), isNull);
    });

    test('un archivo danado no rompe: se trata como si no hubiera', () async {
      await cache.bind(_ana);
      await cache.save(MapLayer.tickets, pins);
      await File('${dir.path}/data/tickets.json').writeAsString('{no es json');

      expect(await cache.read(MapLayer.tickets), isNull);
    });
  });

  group('repositorio con cache', () {
    late FakeMapRepository server;
    late CachedMapRepository repo;

    setUp(() async {
      await cache.bind(_ana);
      server = FakeMapRepository(data: {MapLayer.tickets: pins});
      repo = CachedMapRepository(server, cache);
    });

    test(
      'con conexion entrega lo del servidor, sin marca, y lo guarda',
      () async {
        final result = await repo.pins(MapLayer.tickets);

        expect(result, pins);
        expect(result, isNot(isA<PinListing>()));
        expect((await cache.read(MapLayer.tickets))!.length, 2);
      },
    );

    test('sin conexion entrega lo ultimo guardado, con su fecha', () async {
      await repo.pins(MapLayer.tickets);
      server.failure = MapError.network;

      final result = await repo.pins(MapLayer.tickets);

      expect(result, pins);
      expect((result as PinListing).cachedAt, _at);
    });

    test('sin conexion y sin nada guardado falla como de red', () async {
      server.failure = MapError.network;

      await expectLater(
        repo.pins(MapLayer.tickets),
        throwsA(
          isA<MapException>().having((e) => e.error, 'error', MapError.network),
        ),
      );
    });

    for (final error in [
      MapError.permissionDenied,
      MapError.server,
      MapError.notAvailable,
    ]) {
      test('ante $error no entrega lo guardado', () async {
        await repo.pins(MapLayer.tickets);
        server.failure = error;

        await expectLater(
          repo.pins(MapLayer.tickets),
          throwsA(isA<MapException>().having((e) => e.error, 'error', error)),
        );
      });
    }

    test(
      'el cubit marca la pestana como guardada y lo quita al volver la red',
      () async {
        final cubit = MapCubit(
          repository: repo,
          locationSource: FakeLocationSource(),
        );
        addTearDown(cubit.close);
        await repo.pins(MapLayer.tickets);

        server.failure = MapError.network;
        await cubit.load();
        expect(cubit.state.status, MapStatus.ready);
        expect(cubit.state.layerSavedAt, _at);
        expect(cubit.state.visiblePins.length, 2);

        server.failure = null;
        await cubit.refresh();
        expect(cubit.state.layerSavedAt, isNull);
      },
    );
  });
}
