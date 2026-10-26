import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/composition/map_base_source.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/presentation/maplibre/map_data.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/configured_tile_source.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/map_tile_source.dart';

MapPin _pin(
  String id, {
  double lat = -18.85,
  double lon = -41.98,
  PinStatus status = PinStatus.normal,
}) => MapPin(
  id: id,
  layer: MapLayer.inventory,
  title: 'Pin $id',
  position: GeoPoint(lat, lon),
  status: status,
);

RoadSegment _segment(
  String id,
  String code, {
  TravelDirection direction = TravelDirection.increasing,
  int points = 3,
}) => RoadSegment(
  id: id,
  code: code,
  direction: direction,
  points: [
    for (var i = 0; i < points; i++) GeoPoint(-18.85 + i * 0.01, -41.98),
  ],
);

List<Map<String, Object?>> _features(Map<String, Object?> collection) =>
    (collection['features']! as List).cast<Map<String, Object?>>();

void main() {
  group('colores y gravedad', () {
    test('un color se escribe como #RRGGBB', () {
      expect(hexColor(const Color(0xFF1D4ED8)), '#1D4ED8');
      expect(hexColor(const Color(0xFF000000)), '#000000');
      expect(hexColor(const Color(0x80FFFFFF)), '#FFFFFF');
    });

    test('la atencion que pide un pin es un numero', () {
      expect(severity(PinStatus.normal), 0);
      expect(severity(PinStatus.attention), 1);
      expect(severity(PinStatus.critical), 2);
    });

    test('el color sale de la gravedad', () {
      final e = severityColor(
        normal: const Color(0xFF2E7D32),
        attention: const Color(0xFFF9A825),
        critical: const Color(0xFFD32F2F),
      );
      expect(jsonEncode(e), contains('#D32F2F'));
      expect(e.first, 'match');
      expect(e.last, '#2E7D32');
    });
  });

  group('GeoJSON', () {
    test('los pines llevan [longitud, latitud], su id y su gravedad', () {
      final json = pinsGeoJson([
        _pin('a', lat: -18.85, lon: -41.98, status: PinStatus.critical),
      ]);
      expect(json['type'], 'FeatureCollection');
      final f = _features(json).single;
      expect((f['geometry']! as Map)['coordinates'], [-41.98, -18.85]);
      expect(f['properties'], {'id': 'a', 'sev': 2, 'ic': 'pin-inventory'});
    });

    test('el pin elegido no entra en los grupos y va aparte', () {
      final pins = [_pin('a'), _pin('b')];
      expect(
        _features(
          pinsGeoJson(pins, exceptId: 'a'),
        ).map((f) => (f['properties']! as Map)['id']),
        ['b'],
      );
      expect(_features(selectedPinGeoJson(pins.first)).single['properties'], {
        'id': 'a',
        'sev': 0,
        'ic': 'pin-inventory',
      });
      expect(_features(selectedPinGeoJson(null)), isEmpty);
    });

    test('los tramos son lineas con su sentido y si estan resaltados', () {
      final a = _segment('s1', 'BMG-1');
      final b = _segment('s2', 'BMG-1', direction: TravelDirection.decreasing);
      final json = segmentsGeoJson([a, b], highlighted: (s) => s.id == 's2');
      final f = _features(json);
      expect(f, hasLength(2));
      expect((f.first['geometry']! as Map)['type'], 'LineString');
      expect(f.first['properties'], {'id': 's1', 'dir': 'inc', 'hl': 0});
      expect(f.last['properties'], {'id': 's2', 'dir': 'dec', 'hl': 1});
    });

    test('un tramo que no se puede dibujar se omite', () {
      final json = segmentsGeoJson([
        _segment('s1', 'X', points: 1),
      ], highlighted: (_) => false);
      expect(_features(json), isEmpty);
    });

    test('una etiqueta por codigo, en el punto medio', () {
      final json = segmentLabelsGeoJson([
        _segment('s1', 'BMG-1'),
        _segment('s2', 'BMG-1', direction: TravelDirection.decreasing),
        _segment('s3', 'BMG-2'),
      ]);
      final f = _features(json);
      expect(f.map((e) => (e['properties']! as Map)['code']), [
        'BMG-1',
        'BMG-2',
      ]);
      // Tres puntos: el de en medio es el segundo.
      expect((f.first['geometry']! as Map)['coordinates'], [-41.98, -18.84]);
    });

    test('la ubicacion lleva su precision y la escala de su latitud', () {
      final here = UserLocation(
        position: const GeoPoint(-18.85, -41.98),
        accuracyMeters: 12,
        capturedAt: DateTime.utc(2026, 10, 23),
      );
      final f = _features(locationGeoJson(here)).single;
      final props = f['properties']! as Map;
      expect(props['acc'], 12);
      expect(
        props['k'],
        closeTo(78271.517 * math.cos(18.85 * math.pi / 180), 1e-6),
      );
      expect(_features(locationGeoJson(null)), isEmpty);
    });

    test('la precision que no es un numero valido se dibuja en cero', () {
      final here = UserLocation(
        position: const GeoPoint(0, 0),
        accuracyMeters: double.nan,
        capturedAt: DateTime.utc(2026, 10, 23),
      );
      expect(
        (_features(locationGeoJson(here)).single['properties']! as Map)['acc'],
        0,
      );
    });

    test('el punto elegido es uno o ninguno', () {
      expect(_features(pointGeoJson(const GeoPoint(-18, -41))), hasLength(1));
      expect(_features(pointGeoJson(null)), isEmpty);
    });

    test('el circulo de precision crece al doble por nivel de zoom', () {
      final e = accuracyRadius();
      expect(e[0], 'interpolate');
      expect(e[3], 0);
      expect(e[5], 22);
      expect(jsonEncode(e), contains('4194304'));
    });
  });

  group('encuadre', () {
    test('se encuadran los pines o, sin pines, los tramos', () {
      final segments = [_segment('s1', 'X')];
      expect(fitPoints([_pin('a')], segments), [
        const GeoPoint(-18.85, -41.98),
      ]);
      expect(fitPoints(const [], segments), hasLength(3));
      expect(fitPoints(const [], const []), isEmpty);
    });

    test('el rectangulo contiene todos los puntos', () {
      final b = boundsOf([
        const GeoPoint(-18.9, -42.0),
        const GeoPoint(-18.8, -41.9),
        const GeoPoint(-18.85, -41.95),
      ])!;
      expect(b.southWest, const GeoPoint(-18.9, -42.0));
      expect(b.northEast, const GeoPoint(-18.8, -41.9));
      expect(boundsOf(const []), isNull);
    });
  });

  group('mapa base', () {
    test('sin mapa base el estilo es un fondo liso', () {
      const none = NoTileSource();
      expect(none.hasBase, isFalse);
      final style = jsonDecode(none.styleString) as Map;
      expect(style['version'], 8);
      expect((style['layers']! as List).single['type'], 'background');
    });

    test('unas teselas de imagen se vuelven un estilo raster', () {
      const source = UrlTemplateTileSource(
        urlTemplate: 'https://t.example/{z}/{x}/{y}.png',
        zoomMax: 18,
      );
      expect(source.hasBase, isTrue);
      final style = jsonDecode(source.styleString) as Map;
      final base = (style['sources']! as Map)['base'] as Map;
      expect(base['type'], 'raster');
      expect(base['tiles'], ['https://t.example/{z}/{x}/{y}.png']);
      expect(base['maxzoom'], 18);
    });

    test('un estilo vectorial se pasa tal cual', () {
      const source = StyleUrlTileSource(
        styleUrl: 'https://tiles.example/styles/x',
      );
      expect(source.styleString, 'https://tiles.example/styles/x');
      expect(source.hasBase, isTrue);
      expect(source.buildLayer(), isNull);
    });

    test(
      'el servidor puede indicar un estilo o unas teselas; el estilo manda',
      () {
        final style = ApiMapBaseSource.parse({
          'styleUrl': 'https://tiles.example/styles/x',
          'urlTemplate': 'https://t.example/{z}/{x}/{y}.png',
          'attribution': '© Ejemplo',
          'maxZoom': 17,
        });
        expect(style, isA<StyleUrlTileSource>());
        expect(style!.attribution, '© Ejemplo');
        expect(style.maxZoom, 17);

        expect(
          ApiMapBaseSource.parse({
            'urlTemplate': 'https://t.example/{z}/{x}/{y}.png',
          }),
          isA<UrlTemplateTileSource>(),
        );
      },
    );

    test('un estilo que no es https no sirve', () {
      expect(
        ApiMapBaseSource.parse({'styleUrl': 'http://tiles.example/x'}),
        isNull,
      );
      expect(ApiMapBaseSource.parse({'styleUrl': 'file:///x'}), isNull);
    });

    test('el mapa configurado entrega el estilo del que esta en uso', () {
      final tiles = ConfiguredTileSource(fallback: const NoTileSource());
      expect(tiles.hasBase, isFalse);
      tiles.apply(
        const StyleUrlTileSource(styleUrl: 'https://tiles.example/styles/x'),
      );
      expect(tiles.hasBase, isTrue);
      expect(tiles.styleString, 'https://tiles.example/styles/x');
      tiles.apply(null);
      expect(tiles.styleString, MapTileSource.neutralStyle);
    });
  });
}
