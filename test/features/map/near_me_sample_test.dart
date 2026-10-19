import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/near_me_sample_map_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/near_me_sample_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/nearby_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';

void main() {
  // Un punto cualquiera: el teléfono de quien prueba.
  const me = GeoPoint(19.4326, -99.1332);

  List<MapPin> all(Map<MapLayer, List<MapPin>> data) => [
    for (final l in MapLayer.values) ...data[l]!,
  ];

  group('offset', () {
    test('al norte sube la latitud sin mover la longitud', () {
      final p = NearMeSampleMapRepository.offset(me, 1000, 0);
      expect(p.latitude, greaterThan(me.latitude));
      expect(p.longitude, closeTo(me.longitude, 1e-9));
    });

    test('al este sube la longitud sin mover la latitud', () {
      final p = NearMeSampleMapRepository.offset(me, 1000, 90);
      expect(p.longitude, greaterThan(me.longitude));
      expect(p.latitude, closeTo(me.latitude, 1e-6));
    });

    test('la distancia resultante es la pedida, en cualquier rumbo', () {
      for (final bearing in [
        0.0,
        45.0,
        90.0,
        135.0,
        180.0,
        225.0,
        270.0,
        315.0,
      ]) {
        for (final meters in [60.0, 500.0, 2600.0, 4200.0]) {
          final p = NearMeSampleMapRepository.offset(me, meters, bearing);
          expect(
            me.distanceTo(p),
            closeTo(meters, meters * 0.01 + 1),
            reason: '$meters m a $bearing grados',
          );
        }
      }
    });

    test('funciona lejos del ecuador y en el hemisferio sur', () {
      for (final base in [
        const GeoPoint(-18.85, -41.98),
        const GeoPoint(60, 10),
        const GeoPoint(-54.8, -68.3),
      ]) {
        final p = NearMeSampleMapRepository.offset(base, 1000, 135);
        expect(base.distanceTo(p), closeTo(1000, 15));
      }
    });
  });

  group('pines alrededor de una posicion', () {
    test('hay pines en las cuatro pestañas y los ids no se repiten', () {
      final data = NearMeSampleMapRepository.around(me);
      for (final l in MapLayer.values) {
        expect(data[l], isNotEmpty, reason: l.name);
        expect(data[l]!.every((p) => p.layer == l), isTrue);
      }
      final ids = all(data).map((p) => p.id);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('todos caen a menos de 5 km de la posicion', () {
      for (final p in all(NearMeSampleMapRepository.around(me))) {
        expect(me.distanceTo(p.position), lessThan(5000), reason: p.id);
      }
    });

    test('cada radio del selector da un resultado distinto', () {
      final inventory = NearMeSampleMapRepository.around(
        me,
      )[MapLayer.inventory]!;
      final counts = [
        for (final radius in [250.0, 500.0, 1000.0, 2000.0, 5000.0])
          nearbyPins(inventory, me, radius).length,
      ];
      expect(counts, [3, 4, 6, 7, 8]);
      // Estrictamente creciente salvo donde no hay activos nuevos.
      expect([...counts]..sort(), counts);
    });

    test('el mas cercano del inventario esta a unos 60 m', () {
      final inventory = NearMeSampleMapRepository.around(
        me,
      )[MapLayer.inventory]!;
      final nearest = nearbyPins(inventory, me, 5000).first;
      expect(nearest.pin.id, 'A-001');
      expect(nearest.distanceMeters, closeTo(60, 2));
    });

    test('hay pines a ambos lados del telefono, al este y al oeste', () {
      final pins = all(NearMeSampleMapRepository.around(me));
      expect(pins.any((p) => p.position.latitude > me.latitude), isTrue);
      expect(pins.any((p) => p.position.latitude < me.latitude), isTrue);
      expect(pins.any((p) => p.position.longitude > me.longitude), isTrue);
      expect(pins.any((p) => p.position.longitude < me.longitude), isTrue);
    });

    test('cada pin esta sobre la linea de su tramo y su sentido', () async {
      final segments = await NearMeSampleRoadSegmentsRepository(
        anchor: () async => me,
      ).segments();
      expect(segments.map((s) => s.direction).toSet(), {
        TravelDirection.increasing,
        TravelDirection.decreasing,
      });
      for (final pin in all(NearMeSampleMapRepository.around(me))) {
        expect(
          NearMeSampleMapRepository.roadCodes,
          contains(pin.segmentCode),
          reason: pin.id,
        );
        expect(pin.direction, isNotNull, reason: pin.id);
        final line = segments.singleWhere(
          (s) => s.code == pin.segmentCode && s.direction == pin.direction,
        );
        // La linea corre de oeste a este: todos sus puntos comparten la
        // latitud de su sentido, y el pin cae en ella.
        expect(
          pin.position.latitude,
          closeTo(line.points.first.latitude, 1e-7),
          reason: pin.id,
        );
        final lons = line.points.map((p) => p.longitude);
        expect(
          pin.position.longitude,
          inInclusiveRange(
            lons.reduce((a, b) => a < b ? a : b),
            lons.reduce((a, b) => a > b ? a : b),
          ),
          reason: pin.id,
        );
      }
    });

    test('la carretera se corta en cuatro tramos con dos sentidos', () async {
      final segments = await NearMeSampleRoadSegmentsRepository(
        anchor: () async => me,
      ).segments();

      expect(segments, hasLength(8));
      expect(
        segments.map((s) => s.code).toSet(),
        NearMeSampleMapRepository.roadCodes.toSet(),
      );
      // Cada sentido tiene sus cuatro tramos, empalmados de oeste a este.
      final up = segments
          .where((s) => s.direction == TravelDirection.increasing)
          .toList();
      expect(up, hasLength(4));
      for (var i = 1; i < up.length; i++) {
        expect(
          up[i - 1].points.last.distanceTo(up[i].points.first),
          lessThan(1),
        );
      }
    });

    test('los pines caen en el tramo que cubre su posicion', () {
      for (final pin in all(NearMeSampleMapRepository.around(me))) {
        // El tramo sale de la distancia a lo largo de la carretera: cada uno
        // cubre una cuarta parte de los 9 km de la recta.
        final east = (pin.position.longitude - me.longitude).sign;
        expect(east, isNot(0), reason: pin.id);
        final along = 4500 + east * me.distanceTo(pin.position);
        final expected = NearMeSampleMapRepository.codeAt(along, 9000);
        expect(pin.segmentCode, expected, reason: pin.id);
        expect(
          pin.kmLabel,
          matches(RegExp(r'^KM 1\d\d\+\d{3}$')),
          reason: pin.id,
        );
      }
    });

    test(
      'los dos sentidos se separan lo bastante para verse a zoom bajo',
      () async {
        final segments = await NearMeSampleRoadSegmentsRepository(
          anchor: () async => me,
        ).segments();
        final up = segments.firstWhere(
          (s) => s.direction == TravelDirection.increasing,
        );
        final down = segments.firstWhere(
          (s) => s.direction == TravelDirection.decreasing,
        );
        // El decreciente se recorre al reves: su ultimo punto es el oeste.
        expect(up.points.first.distanceTo(down.points.last), greaterThan(50));
      },
    );

    test('sin ubicacion la carretera es la de la BR-381', () async {
      final segments = await NearMeSampleRoadSegmentsRepository(
        anchor: () async => null,
      ).segments();
      expect(segments.first.code, startsWith('381'));
    });

    test('hay de los tres estados, para probar colores y filtros', () {
      final statuses = all(
        NearMeSampleMapRepository.around(me),
      ).map((p) => p.status).toSet();
      expect(statuses, PinStatus.values.toSet());
    });
  });

  group('repositorio', () {
    test('con ubicacion reparte los pines a su alrededor', () async {
      final repo = NearMeSampleMapRepository(anchor: () async => me);
      final pins = await repo.pins(MapLayer.inventory);
      expect(pins, hasLength(8));
      expect(me.distanceTo(pins.first.position), lessThan(5000));
    });

    test('pide la ubicacion una sola vez para todas las pestañas', () async {
      var calls = 0;
      final repo = NearMeSampleMapRepository(
        anchor: () async {
          calls++;
          return me;
        },
      );
      for (final l in MapLayer.values) {
        await repo.pins(l);
      }
      expect(calls, 1);
    });

    test('sin ubicacion usa los pines de la BR-381', () async {
      final repo = NearMeSampleMapRepository(anchor: () async => null);
      final pins = await repo.pins(MapLayer.inventory);
      final fixed = await SampleMapRepository().pins(MapLayer.inventory);
      expect(pins, fixed);
    });

    test('si pedir la ubicacion falla, tambien usa la BR-381', () async {
      final repo = NearMeSampleMapRepository(
        anchor: () async => throw StateError('sin GPS'),
      );
      expect(await repo.pins(MapLayer.tickets), isNotEmpty);
      expect(
        await repo.pins(MapLayer.tickets),
        await SampleMapRepository().pins(MapLayer.tickets),
      );
    });

    test('una ubicacion invalida se ignora', () async {
      final repo = NearMeSampleMapRepository(
        anchor: () async => const GeoPoint(999, 0),
      );
      expect(
        await repo.pins(MapLayer.works),
        await SampleMapRepository().pins(MapLayer.works),
      );
    });
  });
}
