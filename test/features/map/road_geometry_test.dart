import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/geo_path.dart';
import 'package:sigaco_movil/features/map/data/repositories/near_me_road.dart';
import 'package:sigaco_movil/features/map/data/repositories/near_me_sample_map_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/near_me_sample_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/osrm_road_finder.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_br381_path.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';

/// Los datos de ejemplo siguen una carretera real y no cruzan calles: la linea
/// sale de un trazo real (BR-381) o de la calle que pasa por el telefono.
void main() {
  const me = GeoPoint(19.0414, -98.2063);

  /// Una calle curva de oeste a este que pasa por [me]: 10 km, con ondulaciones
  /// de hasta 300 m hacia el norte y el sur (como una calle real, no una recta).
  GeoPath curvyStreet() {
    final points = <GeoPoint>[];
    for (var east = -5000.0; east <= 5000.0; east += 250) {
      final wave = 300 * math.sin(east / 1200);
      points.add(
        NearMeSampleMapRepository.offset(
          NearMeSampleMapRepository.offset(me, wave.toDouble(), 0),
          east,
          90,
        ),
      );
    }
    return GeoPath(points);
  }

  double metersToLine(GeoPoint p, GeoPath line) =>
      line.at(line.nearestMeters(p)).distanceTo(p);

  group('GeoPath', () {
    final east = GeoPath([
      me,
      NearMeSampleMapRepository.offset(me, 500, 90),
      NearMeSampleMapRepository.offset(me, 1000, 90),
    ]);

    test('mide la linea y da el punto a una distancia', () {
      expect(east.length, closeTo(1000, 1));
      expect(me.distanceTo(east.at(0)), lessThan(0.01));
      expect(east.at(500).distanceTo(me), closeTo(500, 1));
      // Pasarse se queda en el extremo.
      expect(east.at(5000), east.points.last);
    });

    test('un pedazo empieza y termina donde se pidio', () {
      final piece = east.slice(200, 700);
      expect(GeoPath(piece).length, closeTo(500, 1));
      expect(piece.first.distanceTo(me), closeTo(200, 1));
      expect(piece.last.distanceTo(me), closeTo(700, 1));
    });

    test('corrida a la derecha de una linea al este queda al sur', () {
      final right = east.offset(10);
      final left = east.offset(-10);
      expect(right.points.first.latitude, lessThan(me.latitude));
      expect(left.points.first.latitude, greaterThan(me.latitude));
      expect(right.points.first.distanceTo(me), closeTo(10, 0.5));
      // El largo no cambia en una recta.
      expect(right.length, closeTo(east.length, 1));
    });

    test('el punto mas cercano esta a lo largo de la linea', () {
      final p = NearMeSampleMapRepository.offset(
        NearMeSampleMapRepository.offset(me, 300, 90),
        50,
        0,
      );
      expect(east.nearestMeters(p), closeTo(300, 2));
    });
  });

  group('trazo real de la BR-381', () {
    final axis = GeoPath(sampleBr381Path);

    test('mide unos 18 km y los primeros 9 terminan donde dice Strata', () {
      expect(axis.length, closeTo(18000, 200));
      // Extremos del tramo en la API de pistas de Strata: km 146.9 y km 155.9
      // (a 9 km del inicio).
      expect(
        sampleBr381Path.first.distanceTo(
          const GeoPoint(-18.846134, -41.980668),
        ),
        lessThan(60),
      );
      expect(
        axis.at(9000).distanceTo(const GeoPoint(-18.91539, -42.011285)),
        lessThan(60),
      );
    });

    test('no hay saltos grandes entre un punto y el siguiente', () {
      for (var i = 1; i < sampleBr381Path.length; i++) {
        expect(
          sampleBr381Path[i - 1].distanceTo(sampleBr381Path[i]),
          lessThan(800),
          reason: 'punto $i',
        );
      }
    });

    test(
      'las lineas de los dos sentidos siguen el eje a unos metros',
      () async {
        final segments = await SampleRoadSegmentsRepository().segments();
        for (final s in segments) {
          for (final p in s.points) {
            final d = metersToLine(p, axis);
            expect(d, inInclusiveRange(4, 14), reason: '${s.id} $p');
          }
        }
      },
    );

    test('un sentido a cada lado del eje', () async {
      final segments = await SampleRoadSegmentsRepository().segments();
      final up = segments.firstWhere(
        (s) => s.direction == TravelDirection.increasing,
      );
      final down = segments.firstWhere(
        (s) => s.direction == TravelDirection.decreasing,
      );
      // El decreciente se recorre al reves: su ultimo punto es el del km menor.
      expect(up.points.first.distanceTo(down.points.last), closeTo(16, 3));
    });
  });

  group('OSRM', () {
    test('lee la linea de la ruta (longitud, latitud)', () {
      final path = OsrmRoadFinder.parse({
        'code': 'Ok',
        'routes': [
          {
            'geometry': {
              'coordinates': [
                [-98.23, 19.03],
                [-98.22, 19.04],
                [-98.21, 19.05],
              ],
            },
          },
        ],
      });
      expect(path, isNotNull);
      expect(path!.points.first, const GeoPoint(19.03, -98.23));
      expect(path.points.length, 3);
    });

    test('sin ruta devuelve null', () {
      expect(OsrmRoadFinder.parse({'code': 'NoRoute', 'routes': []}), isNull);
      expect(OsrmRoadFinder.parse({'code': 'Ok', 'routes': []}), isNull);
      expect(OsrmRoadFinder.parse('basura'), isNull);
      expect(OsrmRoadFinder.parse(null), isNull);
      expect(
        OsrmRoadFinder.parse({
          'code': 'Ok',
          'routes': [
            {
              'geometry': {
                'coordinates': [
                  [-98.2, 19.0],
                ],
              },
            },
          ],
        }),
        isNull,
      );
    });
  });

  group('cerca de ti sobre una calle real', () {
    late int finderCalls;
    late NearMeRoad road;

    setUp(() {
      finderCalls = 0;
      road = NearMeRoad(
        anchor: () async => me,
        finder: (_) async {
          finderCalls++;
          return curvyStreet();
        },
      );
    });

    test('usa la calle encontrada, una sola vez para pines y tramos', () async {
      final pins = NearMeSampleMapRepository(road: road);
      final segments = NearMeSampleRoadSegmentsRepository(road: road);

      for (final layer in MapLayer.values) {
        await pins.pins(layer);
      }
      await segments.segments();

      expect(finderCalls, 1);
      final data = (await road.resolve())!;
      expect(data.isReal, isTrue);
      // El telefono esta a la mitad de la calle de 10 km.
      expect(data.phoneMeters, closeTo(5000, 400));
    });

    test('cada pin cae sobre la linea de su sentido', () async {
      final pins = NearMeSampleMapRepository(road: road);
      final data = (await road.resolve())!;
      var checked = 0;
      for (final layer in MapLayer.values) {
        for (final pin in await pins.pins(layer)) {
          final lane = data.lanes[pin.direction]!;
          expect(metersToLine(pin.position, lane), lessThan(1), reason: pin.id);
          checked++;
        }
      }
      expect(checked, greaterThan(10));
    });

    test(
      'los pines no se salen de la calle ni se apilan en un extremo',
      () async {
        final pins = NearMeSampleMapRepository(road: road);
        final all = [
          for (final layer in MapLayer.values) ...await pins.pins(layer),
        ];
        // Ninguno a mas de lo que mide la calle y varios a distancias distintas.
        for (final p in all) {
          expect(me.distanceTo(p.position), lessThan(6000), reason: p.id);
        }
        final distances = {
          for (final p in all) me.distanceTo(p.position).round(),
        };
        expect(distances.length, greaterThan(8));
      },
    );

    test(
      'el sentido creciente va de oeste a este y el decreciente al reves',
      () async {
        final segments = await NearMeSampleRoadSegmentsRepository(
          road: road,
        ).segments();
        final up = segments.firstWhere(
          (s) => s.direction == TravelDirection.increasing,
        );
        final down = segments.firstWhere(
          (s) => s.direction == TravelDirection.decreasing,
        );
        expect(up.points.first.longitude, lessThan(up.points.last.longitude));
        expect(
          down.points.first.longitude,
          greaterThan(down.points.last.longitude),
        );
        expect(up.isDrawable && down.isDrawable, isTrue);
      },
    );

    test('las lineas no son rectas: siguen las curvas de la calle', () async {
      final segments = await NearMeSampleRoadSegmentsRepository(
        road: road,
      ).segments();
      final lats = [
        for (final s in segments)
          if (s.direction == TravelDirection.increasing)
            for (final p in s.points) p.latitude,
      ];
      final spread =
          lats.reduce((a, b) => a > b ? a : b) -
          lats.reduce((a, b) => a < b ? a : b);
      // Mas de 200 m de diferencia entre el punto mas al norte y el mas al sur.
      expect(spread * 111320, greaterThan(200));
    });

    for (final (name, finder) in <(String, RoadFinder)>[
      ('no encuentra calle', (_) async => null),
      ('falla', (_) async => throw Exception('sin internet')),
      (
        'la calle es muy corta',
        (c) async => GeoPath([c, NearMeSampleMapRepository.offset(c, 300, 90)]),
      ),
    ]) {
      test('si $name usa la recta inventada', () async {
        final straight = NearMeRoad(anchor: () async => me, finder: finder);
        final pins = NearMeSampleMapRepository(road: straight);

        final data = (await straight.resolve())!;
        expect(data.isReal, isFalse);
        final got = [
          for (final layer in MapLayer.values) ...await pins.pins(layer),
        ];
        final expected = NearMeSampleMapRepository.around(me);
        expect(got.map((p) => p.position), [
          for (final layer in MapLayer.values)
            ...expected[layer]!.map((p) => p.position),
        ]);
      });
    }

    test('sin ubicacion usa la BR-381', () async {
      final none = NearMeRoad(
        anchor: () async => null,
        finder: (_) async => null,
      );

      final segments = await NearMeSampleRoadSegmentsRepository(
        road: none,
      ).segments();
      final pins = await NearMeSampleMapRepository(
        road: none,
      ).pins(MapLayer.tickets);

      expect(segments.first.code, startsWith('381'));
      expect(pins.first.segmentCode, startsWith('381'));
    });
  });
}
