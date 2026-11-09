import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/api_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/nearby_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';

import '../../support/fake_api.dart';
import '../../support/map_fakes.dart';

Map<String, Object?> _feature(
  String id, {
  String subsystem = 'SGS',
  String status = 'ACTIVO',
  Object? inMaintenance,
  String? typeLabel,
}) => {
  'id': id,
  'type': 'Feature',
  'geometry': {
    'type': 'Point',
    'coordinates': [-41.98, -18.85],
  },
  'properties': {
    'id': id,
    'code': 'COD-$id',
    'assetTypeCode': 'POSTE',
    'assetTypeLabel': ?typeLabel,
    'subsystemCode': subsystem,
    'status': status,
    'inMaintenance': ?inMaintenance,
    'kmStart': 150.2,
  },
};

/// Pines fijos y cercanos del servidor (o su falta).
class _NearbyRepo extends FakeMapRepository implements NearbyAssetsSource {
  _NearbyRepo({super.data});

  List<NearbyPin>? server;
  int asked = 0;

  @override
  Future<List<NearbyPin>> nearbyAssets(GeoPoint from, double radius) async {
    asked++;
    final found = server;
    if (found == null) throw const MapException(MapError.network);
    return found;
  }
}

MapPin _pin(String id, {String? group, double lat = -18.85}) => MapPin(
  id: id,
  layer: MapLayer.inventory,
  title: id,
  group: group,
  position: GeoPoint(lat, -41.98),
);

void main() {
  group('pines del inventario (contrato de Activos)', () {
    late FakeApi api;
    late ApiMapRepository repo;

    setUp(() {
      api = FakeApi();
      repo = ApiMapRepository(api.client(), language: () => 'es');
    });

    test('el subsistema y el mantenimiento salen del servidor', () async {
      api.on(
        'GET /api/assets/map',
        FakeReply(200, {
          'type': 'FeatureCollection',
          'features': [
            _feature('a', inMaintenance: true, typeLabel: 'Poste de luz'),
            _feature('b', subsystem: 'SGOAE', status: 'FUERA_SERVICIO'),
            _feature('c', status: 'PENDIENTE_VALIDACION'),
          ],
        }),
      );

      final pins = await repo.pins(MapLayer.inventory);

      expect(pins[0].group, 'SGS');
      // Sin catalogo, el nombre del tipo que manda el mapa.
      expect(pins[0].category, 'Poste de luz');
      expect(pins[0].operatingState, OperatingState.inMaintenance);
      expect(pins[1].group, 'SGOAE');
      expect(pins[1].operatingState, OperatingState.outOfService);
      expect(pins[2].operatingState, isNull);
    });

    test('los cercanos del servidor, del mas cercano al mas lejano', () async {
      api.on(
        'GET /api/assets/nearby',
        const FakeReply(200, [
          {
            'asset': {
              'id': 'lejos',
              'code': 'P-2',
              'assetTypeCode': 'POSTE',
              'subsystemCode': 'SGS',
              'status': 'ACTIVO',
            },
            'distanceMeters': 420.0,
            'geometry': {
              'type': 'Point',
              'coordinates': [-41.97, -18.85],
            },
          },
          {
            'asset': {
              'id': 'cerca',
              'code': 'P-1',
              'assetTypeCode': 'POSTE',
              'status': 'ACTIVO',
            },
            'distanceMeters': 15.5,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-41.98, -18.85],
                [-41.981, -18.851],
              ],
            },
          },
        ]),
      );

      final near = await repo.nearbyAssets(const GeoPoint(-18.85, -41.98), 500);

      expect(near.map((n) => n.pin.id), ['cerca', 'lejos']);
      expect(near.first.distanceMeters, 15.5);
      expect(near.first.pin.title, 'P-1');
      final q = api.to('GET /api/assets/nearby').single.queryParameters;
      expect(q['lat'], -18.85);
      expect(q['lon'], -41.98);
      expect(q['radius'], 500);
    });

    test('sin red los cercanos fallan como red', () async {
      api.offline = true;
      await expectLater(
        repo.nearbyAssets(const GeoPoint(-18.85, -41.98), 500),
        throwsA(
          isA<MapException>().having((e) => e.error, 'error', MapError.network),
        ),
      );
    });
  });

  group('cubit', () {
    final here = UserLocation(
      position: const GeoPoint(-18.85, -41.98),
      accuracyMeters: 5,
      capturedAt: DateTime.utc(2026, 11, 8),
    );

    test('filtra por subsistema y lo suelta al cambiar de pestana', () async {
      final cubit = MapCubit(
        repository: FakeMapRepository(
          data: {
            MapLayer.inventory: [
              _pin('a', group: 'SGS'),
              _pin('b', group: 'SGOAE'),
              _pin('c'),
            ],
          },
        ),
        locationSource: FakeLocationSource(location: here),
      );
      await cubit.selectLayer(MapLayer.inventory);
      expect(cubit.state.availableGroups, ['SGOAE', 'SGS']);

      cubit.setGroupFilter('SGS');
      expect(cubit.state.visiblePins.map((p) => p.id), ['a']);
      expect(cubit.state.activeFilterCount, 1);

      cubit.clearFilters();
      expect(cubit.state.visiblePins, hasLength(3));

      cubit.setGroupFilter('SGOAE');
      await cubit.selectLayer(MapLayer.tickets);
      expect(cubit.state.groupFilter, isNull);
    });

    test(
      'con conexion los cercanos los da el servidor; sin ella, el telefono',
      () async {
        final repo = _NearbyRepo(
          data: {
            MapLayer.inventory: [_pin('local')],
          },
        )..server = [NearbyPin(_pin('servidor'), 30)];
        final cubit = MapCubit(
          repository: repo,
          locationSource: FakeLocationSource(location: here),
        );

        await cubit.locate();
        await pumpEventQueue();
        expect(repo.asked, 1);
        expect(cubit.state.nearby.map((n) => n.pin.id), ['servidor']);

        // Sin red (o si el servidor falla) quedan los calculados con los pines.
        repo.server = null;
        cubit.setRadius(1000);
        await pumpEventQueue();
        expect(repo.asked, 2);
        expect(cubit.state.serverNearby, isNull);
        expect(cubit.state.nearby.map((n) => n.pin.id), ['local']);
      },
    );
  });
}
