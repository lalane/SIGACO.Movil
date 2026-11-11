import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/map/data/cache/map_pins_cache.dart';
import 'package:sigaco_movil/features/map/data/repositories/api_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/cached_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/entities/segment_pavement.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/domain/repositories/road_segments_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';
import 'package:sigaco_movil/features/map/presentation/maplibre/map_data.dart';

import '../../support/fake_api.dart';
import '../../support/map_fakes.dart';

const _route = 'GET /api/gis/segment-indicators';

/// Respuesta de /api/gis/segment-indicators: dos tramos medidos y uno sin datos.
Map<String, Object?> _indicators() => {
  'indicator': 'IRI',
  'label': 'IRI',
  'unit': 'm/km',
  'cycle': 5,
  'cycles': [
    {'id': 8, 'name': 'Ciclo - Treinamento'},
    {'id': 5, 'name': 'Campanha 3'},
  ],
  'thresholds': {'good': 2.7, 'fair': 3.5, 'higherIsWorse': true},
  'provisional': true,
  'segments': [
    {
      'id': 'a',
      'code': '381BMG0100',
      'direction': 'CRECIENTE',
      'kmStart': 100,
      'kmEnd': 102,
      'average': 3.33,
      'samples': 3,
      'coveragePercent': 100,
      'level': 'REGULAR',
    },
    {
      'id': 'b',
      'code': '381BMG0100',
      'direction': 'DECRECIENTE',
      'kmStart': 100,
      'kmEnd': 103,
      'average': 5.1,
      'samples': 1,
      'coveragePercent': 33,
      'level': 'MALO',
    },
    {
      'id': 'c',
      'code': '381BMG0102',
      'direction': 'CRECIENTE',
      'kmStart': 102,
      'kmEnd': 103,
      'average': null,
      'samples': 0,
      'coveragePercent': 0,
      'level': null,
    },
  ],
  'summary': <Object>[],
};

/// Tramos fijos, sin pavimento (como los datos de ejemplo).
class _PlainSegments implements RoadSegmentsRepository {
  @override
  Future<List<RoadSegment>> segments() async => const [];
}

/// DTF M10 HU-MOB-10-01 CA-04: al elegir pavimento se pinta el tramo medido.
void main() {
  late FakeApi api;

  setUp(() => api = FakeApi());

  test(
    'lee el IRI por tramo con su nivel, el ciclo y los tramos sin mediciones',
    () async {
      api.on(_route, FakeReply(200, _indicators()));
      final layer = await ApiRoadSegmentsRepository(api.client()).pavement();

      expect(api.to(_route).single.queryParameters['indicator'], 'IRI');
      expect(layer.cycleName, 'Campanha 3');
      expect(layer.levelOf('a'), PavementLevel.fair);
      expect(layer.levelOf('b'), PavementLevel.bad);
      expect(layer.levelOf('c'), isNull);
      expect(layer.segments['a']!.coveragePercent, 100);
      expect(layer.hasData, isTrue);
    },
  );

  test(
    'sin la capa «Indicadores y pavimento» (403) el cubit la deja como no disponible',
    () async {
      api.on(_route, const FakeReply(403, {'title': 'sin permiso'}));
      final cubit = MapCubit(
        repository: FakeMapRepository(),
        locationSource: FakeLocationSource(),
        segmentsRepository: ApiRoadSegmentsRepository(api.client()),
      );
      addTearDown(cubit.close);

      expect(cubit.pavementSupported, isTrue);
      await cubit.togglePavement();
      expect(cubit.state.pavementStatus, PavementStatus.unavailable);
      expect(cubit.state.pavementOn, isFalse);
      expect(cubit.state.shownPavement, isNull);
    },
  );

  test('prender y apagar: la primera vez la pide, despues la reusa', () async {
    api.on(_route, FakeReply(200, _indicators()));
    final cubit = MapCubit(
      repository: FakeMapRepository(),
      locationSource: FakeLocationSource(),
      segmentsRepository: ApiRoadSegmentsRepository(api.client()),
    );
    addTearDown(cubit.close);

    await cubit.togglePavement();
    expect(cubit.state.shownPavement?.levelOf('b'), PavementLevel.bad);
    await cubit.togglePavement();
    expect(cubit.state.shownPavement, isNull);
    await cubit.togglePavement();
    expect(cubit.state.shownPavement, isNotNull);
    expect(api.to(_route).length, 1);
  });

  test('con datos de ejemplo no se ofrece la capa', () {
    final cubit = MapCubit(
      repository: FakeMapRepository(),
      locationSource: FakeLocationSource(),
      segmentsRepository: _PlainSegments(),
    );
    addTearDown(cubit.close);
    expect(cubit.pavementSupported, isFalse);
  });

  test('sin conexion se pinta lo ultimo guardado con su fecha', () async {
    final dir = await Directory.systemTemp.createTemp('map_pavement_test');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final at = DateTime.utc(2026, 11, 10, 12);
    final cache = FileMapPinsCache(root: () async => dir, clock: () => at);
    await cache.bind(const OfflineScope(userId: 'ana', concessionId: 'c1'));
    final repo = CachedRoadSegmentsRepository(
      ApiRoadSegmentsRepository(api.client()),
      cache,
    );

    api.on(_route, FakeReply(200, _indicators()));
    expect((await repo.pavement()).cachedAt, isNull);

    api.offline = true;
    final saved = await repo.pavement();
    expect(saved.cachedAt, at);
    expect(saved.levelOf('a'), PavementLevel.fair);
  });

  test(
    'el GeoJSON de los tramos lleva el nivel solo con la capa prendida',
    () async {
      api.on(_route, FakeReply(200, _indicators()));
      final layer = await ApiRoadSegmentsRepository(api.client()).pavement();
      final segment = fakeSegment('b');

      Map<String, Object?> props(PavementLayer? pavement) {
        final collection = segmentsGeoJson(
          [segment],
          highlighted: (_) => false,
          pavement: pavement,
        );
        final feature =
            (collection['features'] as List).single as Map<String, Object?>;
        return feature['properties'] as Map<String, Object?>;
      }

      expect(props(null).containsKey('lv'), isFalse);
      expect(props(layer)['lv'], 'bad');
      expect(
        props(
          const PavementLayer(
            indicator: 'IRI',
            label: 'IRI',
            unit: 'm/km',
            segments: {},
          ),
        )['lv'],
        'none',
      );
    },
  );

  test('otro error que no es de red no entrega lo guardado', () async {
    api.on(_route, const FakeReply(500));
    expect(
      () => CachedRoadSegmentsRepository(
        ApiRoadSegmentsRepository(api.client()),
        const NoMapPinsCache(),
      ).pavement(),
      throwsA(
        isA<MapException>().having((e) => e.error, 'error', MapError.server),
      ),
    );
  });
}
