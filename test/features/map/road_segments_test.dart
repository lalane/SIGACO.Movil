import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/map/data/cache/map_pins_cache.dart';
import 'package:sigaco_movil/features/map/data/repositories/cached_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/unavailable_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';

import '../../support/map_fakes.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _otra = OfflineScope(userId: 'ana', concessionId: 'c2');
final _at = DateTime.utc(2026, 10, 16, 18);

/// Distancia en metros de un punto a una linea (plano local: sobra para unos
/// kilometros).
double _metersToLine(GeoPoint p, List<GeoPoint> line) {
  const metersPerDegree = 111320.0;
  final cosLat = math.cos(p.latitude * math.pi / 180);
  double x(GeoPoint g) =>
      (g.longitude - p.longitude) * metersPerDegree * cosLat;
  double y(GeoPoint g) => (g.latitude - p.latitude) * metersPerDegree;
  var best = double.infinity;
  for (var i = 0; i + 1 < line.length; i++) {
    final ax = x(line[i]), ay = y(line[i]);
    final bx = x(line[i + 1]), by = y(line[i + 1]);
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0
        ? 0.0
        : (((-ax) * dx + (-ay) * dy) / len2).clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    best = math.min(best, math.sqrt(px * px + py * py));
  }
  return best;
}

/// La carretera se dibuja con y sin conexion, y lo guardado es de una persona y
/// una concesion (RN-CTX-02).
void main() {
  group('tramo', () {
    test('se puede dibujar con al menos dos puntos validos', () {
      expect(fakeSegment('a').isDrawable, isTrue);
      expect(
        fakeSegment('b', points: const [GeoPoint(-18, -41)]).isDrawable,
        isFalse,
      );
      expect(
        fakeSegment(
          'c',
          points: const [GeoPoint(-18, -41), GeoPoint(999, -41)],
        ).isDrawable,
        isFalse,
      );
    });

    test(
      'hay cinco tramos en la BR-381, cada uno con sus dos sentidos',
      () async {
        final all = await SampleRoadSegmentsRepository().segments();

        expect(all, hasLength(10));
        expect(all.map((s) => s.code).toSet(), hasLength(5));
        expect(
          all.map((s) => s.code).toSet(),
          SampleRoadSegmentsRepository.codes.toSet(),
        );
      },
    );

    test('los tramos de un sentido se empalman uno con el siguiente', () async {
      final all = await SampleRoadSegmentsRepository().segments();
      final up = all
          .where((s) => s.direction == TravelDirection.increasing)
          .toList();

      expect(up, hasLength(5));
      for (var i = 1; i < up.length; i++) {
        // El final de un tramo es el inicio del siguiente (a unos metros).
        expect(
          up[i - 1].points.last.distanceTo(up[i].points.first),
          lessThan(1),
        );
      }
    });

    test('cada tramo nuevo tiene pines de ejemplo dentro', () async {
      final repo = SampleMapRepository();
      final codes = {
        for (final layer in MapLayer.values)
          for (final pin in await repo.pins(layer)) pin.segmentCode,
      };

      expect(codes, SampleRoadSegmentsRepository.codes.toSet());
    });

    test('el mismo codigo en dos sentidos son tramos distintos', () async {
      final all = await SampleRoadSegmentsRepository().segments();

      expect(all, isNotEmpty);
      expect(all.every((s) => s.isDrawable), isTrue);
      expect(all.map((s) => s.id).toSet().length, all.length);
      final byCode = <String, Set<TravelDirection>>{};
      for (final s in all) {
        (byCode[s.code] ??= {}).add(s.direction);
      }
      expect(byCode.values.every((d) => d.length == 2), isTrue);
    });

    test('sin publicar falla como no disponible', () async {
      await expectLater(
        const UnavailableRoadSegmentsRepository().segments(),
        throwsA(
          isA<MapException>().having(
            (e) => e.error,
            'error',
            MapError.notAvailable,
          ),
        ),
      );
    });
  });

  group('pines dentro del tramo', () {
    test(
      'cada pin de ejemplo esta sobre la linea de su tramo y su sentido',
      () async {
        final segments = await SampleRoadSegmentsRepository().segments();
        final repo = SampleMapRepository();
        var checked = 0;
        for (final layer in MapLayer.values) {
          for (final pin in await repo.pins(layer)) {
            expect(pin.segmentCode, isNotNull, reason: pin.id);
            expect(pin.direction, isNotNull, reason: pin.id);
            final segment = segments.singleWhere(
              (s) => s.code == pin.segmentCode && s.direction == pin.direction,
              orElse: () => throw StateError('${pin.id} no tiene tramo'),
            );
            expect(
              _metersToLine(pin.position, segment.points),
              lessThan(15),
              reason: '${pin.id} debe caer sobre ${segment.id}',
            );
            checked++;
          }
        }
        expect(checked, greaterThan(10));
      },
    );

    test('el kilometro del pin esta dentro del rango de su tramo', () async {
      final segments = await SampleRoadSegmentsRepository().segments();
      double km(String label) {
        final m = RegExp(r'KM (\d+)\+(\d+)').firstMatch(label)!;
        return int.parse(m[1]!) + int.parse(m[2]!) / 1000;
      }

      final repo = SampleMapRepository();
      for (final layer in MapLayer.values) {
        for (final pin in await repo.pins(layer)) {
          final segment = segments.firstWhere(
            (s) => s.code == pin.segmentCode && s.direction == pin.direction,
          );
          final a = km(segment.startKmLabel!), b = km(segment.endKmLabel!);
          expect(
            km(pin.kmLabel!),
            inInclusiveRange(math.min(a, b) - 1e-9, math.max(a, b) + 1e-9),
            reason: pin.id,
          );
        }
      }
    });
  });

  group('cache y repositorio', () {
    late Directory dir;
    late FileMapPinsCache cache;
    late FakeRoadSegmentsRepository server;
    late CachedRoadSegmentsRepository repo;

    FileMapPinsCache build() =>
        FileMapPinsCache(root: () async => dir, clock: () => _at);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('road_segments_test');
      cache = build();
      await cache.bind(_ana);
      server = FakeRoadSegmentsRepository(
        data: [
          fakeSegment('a'),
          fakeSegment('b', direction: TravelDirection.decreasing),
        ],
      );
      repo = CachedRoadSegmentsRepository(server, cache);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('guarda y devuelve los tramos con sus puntos y su fecha', () async {
      await cache.saveSegments(server.data);

      final saved = await cache.readSegments();

      expect(saved, isNotNull);
      expect(saved!.cachedAt, _at);
      expect(saved, server.data);
      expect(saved.last.direction, TravelDirection.decreasing);
      expect(saved.first.points.length, 3);
    });

    test('sin alcance no guarda ni entrega nada', () async {
      final other = build();

      await other.saveSegments(server.data);

      expect(await other.readSegments(), isNull);
    });

    test('otra concesion no ve los tramos guardados', () async {
      await cache.saveSegments(server.data);

      final other = build();
      await other.bind(_otra);

      expect(await other.readSegments(), isNull);
    });

    test('con conexion entrega lo del servidor y lo guarda', () async {
      final result = await repo.segments();

      expect(result, isNot(isA<SegmentListing>()));
      expect((await cache.readSegments())!.length, 2);
    });

    test('sin conexion entrega lo guardado, con su fecha', () async {
      await repo.segments();
      server.failure = MapError.network;

      final result = await repo.segments();

      expect(result, server.data);
      expect((result as SegmentListing).cachedAt, _at);
    });

    test('sin conexion y sin nada guardado falla como de red', () async {
      server.failure = MapError.network;

      await expectLater(
        repo.segments(),
        throwsA(
          isA<MapException>().having((e) => e.error, 'error', MapError.network),
        ),
      );
    });

    test('ante un fallo que no es de red no entrega lo guardado', () async {
      await repo.segments();
      server.failure = MapError.permissionDenied;

      await expectLater(repo.segments(), throwsA(isA<MapException>()));
    });
  });

  group('cubit', () {
    late FakeMapRepository pins;
    late FakeRoadSegmentsRepository segments;

    MapCubit build() => MapCubit(
      repository: pins,
      locationSource: FakeLocationSource(),
      segmentsRepository: segments,
    );

    setUp(() {
      pins = FakeMapRepository(
        data: {
          MapLayer.tickets: [fakePin('t1', layer: MapLayer.tickets)],
        },
      );
      segments = FakeRoadSegmentsRepository(
        data: [
          fakeSegment('a'),
          fakeSegment('b', direction: TravelDirection.decreasing),
        ],
      );
    });

    test('carga los tramos junto con los pines', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.segments.map((s) => s.id), ['a', 'b']);
      expect(cubit.state.segmentsSavedAt, isNull);
    });

    test('no dibuja un tramo que no es una linea', () async {
      segments.data = [
        fakeSegment('a'),
        fakeSegment('rota', points: const [GeoPoint(-18, -41)]),
      ];
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.segments.map((s) => s.id), ['a']);
    });

    test('si los tramos fallan el mapa sigue con sus pines', () async {
      segments.failure = MapError.notAvailable;
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, MapStatus.ready);
      expect(cubit.state.segments, isEmpty);
      expect(cubit.state.visiblePins.length, 1);
    });

    test('sin repositorio de tramos no hay tramos', () async {
      final cubit = MapCubit(
        repository: pins,
        locationSource: FakeLocationSource(),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.segments, isEmpty);
    });

    test('marca de cuando son los tramos guardados en el telefono', () async {
      segments.data = SegmentListing([fakeSegment('a')], cachedAt: _at);
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.segmentsSavedAt, _at);
    });

    test('elegir un tramo suelta el pin y al reves', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      cubit.selectPin('t1');
      cubit.selectSegment('b');
      expect(cubit.state.selectedSegment?.id, 'b');
      expect(cubit.state.selectedPin, isNull);

      cubit.selectPin('t1');
      expect(cubit.state.selectedPin?.id, 't1');
      expect(cubit.state.selectedSegment, isNull);

      cubit.selectSegment('a');
      cubit.selectSegment(null);
      expect(cubit.state.selectedSegment, isNull);
    });

    test('cambiar de pestana suelta el tramo elegido', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      cubit.selectSegment('a');

      await cubit.selectLayer(MapLayer.inventory);

      expect(cubit.state.selectedSegment, isNull);
      // Los tramos son de la carretera, no de la pestana: siguen.
      expect(cubit.state.segments.length, 2);
    });
  });
}
