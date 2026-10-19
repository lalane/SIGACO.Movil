import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_settings.dart';
import 'package:sigaco_movil/features/map/domain/entities/nearby_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';

import '../../support/map_fakes.dart';

void main() {
  group('GeoPoint', () {
    test('un grado de latitud mide unos 111 km', () {
      const a = GeoPoint(0, 0);
      const b = GeoPoint(1, 0);
      expect(a.distanceTo(b), closeTo(111195, 300));
    });

    test('la distancia a si mismo es cero y es simetrica', () {
      const a = GeoPoint(-18.846134, -41.980668);
      const b = GeoPoint(-18.91539, -42.011285);
      expect(a.distanceTo(a), 0);
      expect(a.distanceTo(b), closeTo(b.distanceTo(a), 0.001));
    });

    test(
      'los extremos del tramo 381BMG0160 quedan a unos 8,3 km en linea recta',
      () {
        // La API de pistas de Strata da 9 km por carretera (km 146.9 a 155.9).
        const start = GeoPoint(-18.846134, -41.980668);
        const end = GeoPoint(-18.91539, -42.011285);
        expect(start.distanceTo(end), inInclusiveRange(8000, 8700));
      },
    );

    test('valida rangos y numeros finitos', () {
      expect(const GeoPoint(-18.85, -41.98).isValid, isTrue);
      expect(const GeoPoint(91, 0).isValid, isFalse);
      expect(const GeoPoint(0, 181).isValid, isFalse);
      expect(const GeoPoint(double.nan, 0).isValid, isFalse);
    });

    test('una latitud y longitud invertidas dan otro lugar', () {
      // El ejemplo de ICP de la documentacion de Strata las trae invertidas.
      const right = GeoPoint(-19.631615638529, -42.807187551389);
      const swapped = GeoPoint(-42.807187551389, -19.631615638529);
      expect(right.distanceTo(swapped), greaterThan(1000000));
    });
  });

  group('nearbyPins', () {
    const here = GeoPoint(-18.85, -41.98);

    // 0.001 grados de latitud son unos 111 m.
    MapPin at(String id, double dLat) =>
        fakePin(id, position: GeoPoint(here.latitude + dLat, here.longitude));

    test('ordena del mas cercano al mas lejano y respeta el radio', () {
      final result = nearbyPins(
        [at('lejos', 0.020), at('cerca', 0.001), at('medio', 0.005)],
        here,
        1000,
      );
      expect(result.map((n) => n.pin.id), ['cerca', 'medio']);
      expect(result.first.distanceMeters, lessThan(result.last.distanceMeters));
    });

    test('el radio es un limite inclusivo y excluye lo de afuera', () {
      final pin = at('a', 0.005);
      final d = here.distanceTo(pin.position);
      expect(nearbyPins([pin], here, d), hasLength(1));
      expect(nearbyPins([pin], here, d - 1), isEmpty);
    });

    test('con la misma distancia desempata por id, siempre igual', () {
      final a = fakePin('b', position: const GeoPoint(-18.851, -41.98));
      final b = fakePin('a', position: const GeoPoint(-18.851, -41.98));
      expect(nearbyPins([a, b], here, 1000).map((n) => n.pin.id), ['a', 'b']);
    });

    test('descarta pines con coordenadas invalidas', () {
      final bad = fakePin('x', position: const GeoPoint(200, 0));
      expect(nearbyPins([bad], here, 1e9), isEmpty);
    });

    test('sin pines no hay cercanos', () {
      expect(nearbyPins(const <MapPin>[], here, 1000), isEmpty);
    });

    test('NearbyPin compara por valor', () {
      final pin = at('a', 0.001);
      expect(NearbyPin(pin, 10), NearbyPin(pin, 10));
    });
  });

  group('UserLocation', () {
    test('la precision se compara con el umbral', () {
      final l = fakeLocation(accuracy: 25);
      expect(l.meetsAccuracy(30), isTrue);
      expect(l.meetsAccuracy(20), isFalse);
      expect(fakeLocation(accuracy: double.nan).meetsAccuracy(30), isFalse);
    });

    test('una ubicacion simulada no es de fiar', () {
      expect(fakeLocation(origin: LocationOrigin.mocked).isTrusted, isFalse);
      expect(fakeLocation().isTrusted, isTrue);
    });
  });

  group('MapSettings', () {
    test('propone 1 km de radio y 30 m de precision', () {
      const s = MapSettings();
      expect(s.nearbyRadiusMeters, 1000);
      expect(s.minAccuracyMeters, 30);
      expect(MapSettings.radiusOptionsMeters, contains(1000));
    });

    test('copyWith cambia solo lo pedido', () {
      final s = const MapSettings().copyWith(nearbyRadiusMeters: 500);
      expect(s.nearbyRadiusMeters, 500);
      expect(s.minAccuracyMeters, 30);
    });
  });

  group('SampleMapRepository', () {
    test('trae pines en las cuatro pestanas', () async {
      final repo = SampleMapRepository();
      for (final layer in MapLayer.values) {
        final pins = await repo.pins(layer);
        expect(pins, isNotEmpty, reason: layer.name);
        expect(pins.every((p) => p.layer == layer), isTrue);
        expect(pins.every((p) => p.position.isValid), isTrue);
      }
    });

    test('los ids no se repiten y todos caen en el tramo de la BR-381', () async {
      final repo = SampleMapRepository();
      final all = [
        for (final layer in MapLayer.values) ...await repo.pins(layer),
      ];
      expect(all.map((p) => p.id).toSet(), hasLength(all.length));
      const start = GeoPoint(-18.846134, -41.980668);
      for (final p in all) {
        // Menos de 20 km del origen del trazo de ejemplo (que mide unos 18 km).
        expect(start.distanceTo(p.position), lessThan(20000), reason: p.id);
      }
    });

    test('at() ubica los extremos del tramo en sus kilometros', () {
      expect(SampleMapRepository.at(146.9).latitude, closeTo(-18.846134, 1e-9));
      expect(
        SampleMapRepository.at(155.9).longitude,
        closeTo(-42.011285, 1e-9),
      );
    });
  });
}
