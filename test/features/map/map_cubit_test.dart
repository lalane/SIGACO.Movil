import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';

import '../../support/map_fakes.dart';
import '../../support/map_pack_fakes.dart';

void main() {
  group('cubit con paquetes', offlineTests);
  const here = GeoPoint(-18.85, -41.98);

  MapPin near(String id, {double dLat = 0.001, String? category}) => fakePin(
    id,
    position: GeoPoint(here.latitude + dLat, here.longitude),
    category: category,
  );

  late FakeMapRepository repo;
  late FakeLocationSource location;

  MapCubit build() {
    return MapCubit(repository: repo, locationSource: location);
  }

  setUp(() {
    repo = FakeMapRepository(
      data: {
        MapLayer.tickets: [
          fakePin(
            't1',
            layer: MapLayer.tickets,
            category: 'Daño',
            status: PinStatus.critical,
          ),
          fakePin(
            't2',
            layer: MapLayer.tickets,
            category: 'Pavimento',
            status: PinStatus.attention,
          ),
          fakePin('t3', layer: MapLayer.tickets, category: 'Daño'),
        ],
        MapLayer.inventory: [
          near('a1', category: 'Defensa'),
          near('a2', dLat: 0.005, category: 'Señal'),
          near('a3', dLat: 0.05, category: 'Defensa'),
        ],
        MapLayer.maintenance: [fakePin('m1', layer: MapLayer.maintenance)],
      },
    );
    location = FakeLocationSource(location: fakeLocation(position: here));
  });

  group('carga', () {
    test('empieza cargando la primera pestana', () {
      final cubit = build();
      expect(cubit.state.layer, MapLayer.tickets);
      expect(cubit.state.status, MapStatus.loading);
    });

    test('load trae los pines de la pestana abierta', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.visiblePins.map((p) => p.id), ['t1', 't2', 't3']);
      expect(repo.requested, [MapLayer.tickets]);
    });

    test('un fallo de red deja la pestana en error y se reintenta', () async {
      repo.failure = MapError.network;
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, MapStatus.failure);
      expect(cubit.state.error, MapError.network);

      repo.failure = null;
      await cubit.refresh();
      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.error, isNull);
    });

    test('sin endpoints del servidor el error es no disponible', () async {
      repo.failure = MapError.notAvailable;
      final cubit = build();
      await cubit.load();
      expect(cubit.state.error, MapError.notAvailable);
    });

    test('el permiso denegado de una pestana no rompe las demas', () async {
      repo.failureByLayer[MapLayer.maintenance] = MapError.permissionDenied;
      final cubit = build();
      await cubit.load();
      await cubit.selectLayer(MapLayer.maintenance);
      expect(cubit.state.error, MapError.permissionDenied);
      await cubit.selectLayer(MapLayer.tickets);
      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.visiblePins, hasLength(3));
    });
  });

  group('pestanas', () {
    test('cada pestana se consulta una sola vez', () async {
      final cubit = build();
      await cubit.load();
      await cubit.selectLayer(MapLayer.inventory);
      await cubit.selectLayer(MapLayer.tickets);
      await cubit.selectLayer(MapLayer.inventory);
      expect(repo.requestsFor(MapLayer.tickets), 1);
      expect(repo.requestsFor(MapLayer.inventory), 1);
    });

    test('al cambiar de pestana se limpian filtros y seleccion', () async {
      final cubit = build();
      await cubit.load();
      cubit.toggleCategory('Daño');
      cubit.setStatusFilter(PinStatus.critical);
      cubit.selectPin('t1');
      await cubit.selectLayer(MapLayer.inventory);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.statusFilter, isNull);
      expect(cubit.state.selectedId, isNull);
      expect(cubit.state.activeFilterCount, 0);
    });

    test('elegir la pestana abierta no hace nada', () async {
      final cubit = build();
      await cubit.load();
      await cubit.selectLayer(MapLayer.tickets);
      expect(repo.requestsFor(MapLayer.tickets), 1);
    });

    test('una respuesta tardia de otra pestana no pisa la actual', () async {
      final cubit = build();
      await cubit.load();
      final pending = cubit.selectLayer(MapLayer.inventory);
      await cubit.selectLayer(MapLayer.tickets);
      await pending;
      expect(cubit.state.layer, MapLayer.tickets);
      expect(cubit.state.status, MapStatus.ready);
    });
  });

  group('filtros', () {
    test('las categorias disponibles salen de la pestana, ordenadas', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.availableCategories, ['Daño', 'Pavimento']);
    });

    test('marcar categorias muestra solo esas; vacio es todas', () async {
      final cubit = build();
      await cubit.load();
      cubit.toggleCategory('Daño');
      expect(cubit.state.visiblePins.map((p) => p.id), ['t1', 't3']);
      cubit.toggleCategory('Pavimento');
      expect(cubit.state.visiblePins, hasLength(3));
      cubit.toggleCategory('Daño');
      cubit.toggleCategory('Pavimento');
      expect(cubit.state.visiblePins, hasLength(3));
    });

    test('el estado filtra y se combina con la categoria', () async {
      final cubit = build();
      await cubit.load();
      cubit.setStatusFilter(PinStatus.critical);
      expect(cubit.state.visiblePins.map((p) => p.id), ['t1']);
      cubit.toggleCategory('Pavimento');
      expect(cubit.state.visiblePins, isEmpty);
      cubit.clearFilters();
      expect(cubit.state.visiblePins, hasLength(3));
      expect(cubit.state.activeFilterCount, 0);
    });

    test('cambiar un filtro quita la seleccion', () async {
      final cubit = build();
      await cubit.load();
      cubit.selectPin('t2');
      expect(cubit.state.selectedPin?.id, 't2');
      cubit.setStatusFilter(PinStatus.critical);
      expect(cubit.state.selectedPin, isNull);
    });

    test('seleccionar un pin y cerrarlo', () async {
      final cubit = build();
      await cubit.load();
      cubit.selectPin('t1');
      expect(cubit.state.selectedPin?.title, 'Pin t1');
      cubit.selectPin(null);
      expect(cubit.state.selectedPin, isNull);
    });
  });

  group('ubicacion y cercanos', () {
    test(
      'locate guarda la ubicacion, pide centrar y trae el inventario',
      () async {
        final cubit = build();
        await cubit.load();
        await cubit.locate();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.locate, LocateStatus.ready);
        expect(cubit.state.location?.position, here);
        expect(cubit.state.focusTick, 1);
        expect(repo.requestsFor(MapLayer.inventory), 1);
        expect(cubit.state.inventoryLoaded, isTrue);
      },
    );

    test('los cercanos usan el inventario y el radio de 1 km', () async {
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.nearby.map((n) => n.pin.id), ['a1', 'a2']);
    });

    test('cambiar el radio cambia los cercanos, sin otra consulta', () async {
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      await Future<void>.delayed(Duration.zero);
      cubit.setRadius(250);
      expect(cubit.state.nearby.map((n) => n.pin.id), ['a1']);
      cubit.setRadius(5000);
      expect(cubit.state.nearby.map((n) => n.pin.id), ['a1', 'a2']);
      cubit.setRadius(10000);
      expect(cubit.state.nearby, hasLength(3));
      expect(repo.requestsFor(MapLayer.inventory), 1);
    });

    test('sin ubicacion no hay cercanos', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.nearby, isEmpty);
    });

    test('ubicarse otra vez vuelve a centrar', () async {
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      await cubit.locate();
      expect(cubit.state.focusTick, 2);
      expect(repo.requestsFor(MapLayer.inventory), 1);
    });

    for (final (failure, expected) in [
      (LocationFailure.serviceDisabled, LocateStatus.serviceDisabled),
      (LocationFailure.permissionDenied, LocateStatus.permissionDenied),
      (
        LocationFailure.permissionDeniedForever,
        LocateStatus.permissionDeniedForever,
      ),
      (LocationFailure.unavailable, LocateStatus.unavailable),
    ]) {
      test('el fallo ${failure.name} no deja ubicacion y se informa', () async {
        location.failure = failure;
        final cubit = build();
        await cubit.load();
        await cubit.locate();
        expect(cubit.state.locate, expected);
        expect(cubit.state.location, isNull);
        expect(cubit.state.focusTick, 0);
        cubit.dismissLocateMessage();
        expect(cubit.state.locate, LocateStatus.idle);
      });
    }

    test('un fallo no borra la ultima ubicacion buena', () async {
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      location.failure = LocationFailure.unavailable;
      await cubit.locate();
      expect(cubit.state.locate, LocateStatus.unavailable);
      expect(cubit.state.location?.position, here);
    });

    test('abrir ajustes usa la razon del fallo', () async {
      location.failure = LocationFailure.permissionDeniedForever;
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      await cubit.openSettings(LocationFailure.permissionDeniedForever);
      expect(location.openedSettings, [
        LocationFailure.permissionDeniedForever,
      ]);
    });

    test(
      'si el inventario falla, los cercanos quedan vacios sin romper',
      () async {
        repo.failureByLayer[MapLayer.inventory] = MapError.network;
        final cubit = build();
        await cubit.load();
        await cubit.locate();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.locate, LocateStatus.ready);
        expect(cubit.state.inventoryLoaded, isFalse);
        expect(cubit.state.nearby, isEmpty);
        // La pestana abierta sigue bien.
        expect(cubit.state.status, MapStatus.ready);
      },
    );
  });

  test('cerrar el cubit con una consulta en vuelo no lanza', () async {
    final cubit = build();
    final loading = cubit.load();
    await cubit.close();
    await loading;
  });
}

// ---------------------------------------------------------------------------
// Mapa sin conexion: el cubit abre el paquete instalado.
// ---------------------------------------------------------------------------
void offlineTests() {
  late FakeMapRepository repo;
  late FakeLocationSource location;
  late FakeMapPackManager packs;

  MapCubit build() =>
      MapCubit(repository: repo, locationSource: location, packs: packs);

  setUp(() {
    repo = FakeMapRepository(
      data: {
        MapLayer.tickets: [fakePin('t1', layer: MapLayer.tickets)],
      },
    );
    location = FakeLocationSource(location: fakeLocation());
    packs = FakeMapPackManager();
  });

  group('mapa sin conexion', () {
    test('sin paquetes instalados no hay lector', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.offlinePack, isNull);
      expect(cubit.state.offlineReader, isNull);
      expect(packs.openActiveCalls, 0);
    });

    test('con un paquete instalado abre su lector', () async {
      final pack = packFor(packBytes(100));
      packs.installedPacks = [installedFor(pack)];
      packs.reader = FakeTileReader();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.offlinePack?.id, 'br381');
      expect(cubit.state.offlineReader, same(packs.reader));
      expect(cubit.state.status, MapStatus.ready);
    });

    test('elige el paquete instalado mas reciente', () async {
      final a = installedFor(
        packFor(packBytes(100), id: 'a'),
        at: DateTime.utc(2026, 1, 1),
      );
      final b = installedFor(
        packFor(packBytes(100), id: 'b'),
        at: DateTime.utc(2026, 6, 1),
      );
      packs.installedPacks = [a, b];
      packs.reader = FakeTileReader();
      final cubit = build();
      await cubit.loadOffline();
      expect(cubit.state.offlinePack?.id, 'b');
    });

    test('un fallo al leer los paquetes no estorba al mapa', () async {
      packs.installedFailure = StateError('disco');
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.offlineReader, isNull);
    });

    test('un paquete que no abre deja el mapa sin lector', () async {
      packs.installedPacks = [installedFor(packFor(packBytes(100)))];
      packs.reader = null;
      final cubit = build();
      await cubit.load();
      expect(cubit.state.offlineReader, isNull);
    });

    test(
      'al volver de la pantalla de paquetes se actualiza y cierra el lector viejo',
      () async {
        final first = FakeTileReader();
        packs.installedPacks = [installedFor(packFor(packBytes(100)))];
        packs.reader = first;
        final cubit = build();
        await cubit.load();

        final second = FakeTileReader();
        packs.reader = second;
        await cubit.loadOffline();
        expect(cubit.state.offlineReader, same(second));
        expect(first.closed, isTrue);
        expect(second.closed, isFalse);
      },
    );

    test(
      'si el usuario borra el paquete, el mapa lo suelta y cierra el lector',
      () async {
        final reader = FakeTileReader();
        packs.installedPacks = [installedFor(packFor(packBytes(100)))];
        packs.reader = reader;
        final cubit = build();
        await cubit.load();

        packs.installedPacks = [];
        await cubit.loadOffline();
        expect(cubit.state.offlineReader, isNull);
        expect(cubit.state.offlinePack, isNull);
        expect(reader.closed, isTrue);
      },
    );

    test('cerrar el cubit cierra el lector', () async {
      final reader = FakeTileReader();
      packs.installedPacks = [installedFor(packFor(packBytes(100)))];
      packs.reader = reader;
      final cubit = build();
      await cubit.load();
      await cubit.close();
      expect(reader.closed, isTrue);
    });

    test('sin administrador de paquetes todo sigue igual', () async {
      final cubit = MapCubit(repository: repo, locationSource: location);
      await cubit.load();
      expect(cubit.state.offlineReader, isNull);
    });
  });
}
