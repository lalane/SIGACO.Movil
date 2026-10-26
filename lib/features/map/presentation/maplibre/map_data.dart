import 'dart:math' as math;
import 'dart:ui' show Color;

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/entities/user_location.dart';

/// Lo que el mapa de MapLibre dibuja, como GeoJSON y expresiones de estilo. Todo
/// es Dart puro (sin el mapa nativo) para poder probarlo.

/// `#RRGGBB` de un color (MapLibre no lee el canal alfa en el texto).
String hexColor(Color c) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
}

/// Cuanta atencion pide un pin, como numero: asi un grupo toma la del peor.
int severity(PinStatus s) => switch (s) {
  PinStatus.normal => 0,
  PinStatus.attention => 1,
  PinStatus.critical => 2,
};

Map<String, Object?> _collection(List<Map<String, Object?>> features) => {
  'type': 'FeatureCollection',
  'features': features,
};

Map<String, Object?> _point(GeoPoint p, Map<String, Object?> properties) => {
  'type': 'Feature',
  'geometry': {
    'type': 'Point',
    'coordinates': [p.longitude, p.latitude],
  },
  'properties': properties,
};

/// El nombre con el que el mapa conoce el icono de una capa.
String pinIconName(MapLayer layer) => 'pin-${layer.name}';

/// Los pines de la pestana: el id y la atencion que piden. El elegido va aparte
/// (se dibuja sobre los demas y no entra en ningun grupo).
Map<String, Object?> pinsGeoJson(List<MapPin> pins, {String? exceptId}) =>
    _collection([
      for (final p in pins)
        if (p.id != exceptId)
          _point(p.position, {
            'id': p.id,
            'sev': severity(p.status),
            'ic': pinIconName(p.layer),
          }),
    ]);

/// El pin elegido, o nada.
Map<String, Object?> selectedPinGeoJson(MapPin? pin) => _collection([
  if (pin != null)
    _point(pin.position, {
      'id': pin.id,
      'sev': severity(pin.status),
      'ic': pinIconName(pin.layer),
    }),
]);

/// Los tramos como lineas: el id, el sentido (`inc` o `dec`) y si estan
/// resaltados (`hl` 1 o 0).
Map<String, Object?> segmentsGeoJson(
  List<RoadSegment> segments, {
  required bool Function(RoadSegment) highlighted,
}) => _collection([
  for (final s in segments)
    if (s.isDrawable)
      {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            for (final p in s.points) [p.longitude, p.latitude],
          ],
        },
        'properties': {
          'id': s.id,
          'dir': s.direction == TravelDirection.increasing ? 'inc' : 'dec',
          'hl': highlighted(s) ? 1 : 0,
        },
      },
]);

/// Una etiqueta por codigo de tramo (los dos sentidos comparten codigo), en el
/// punto medio de la primera linea.
Map<String, Object?> segmentLabelsGeoJson(List<RoadSegment> segments) {
  final seen = <String>{};
  return _collection([
    for (final s in segments)
      if (s.isDrawable && seen.add(s.code))
        _point(s.points[s.points.length ~/ 2], {'code': s.code}),
  ]);
}

/// Metros por pixel en el zoom 0 a esa latitud: con el zoom se acota el circulo
/// de precision para que mida lo mismo en metros.
double metersPerPixelAtZoom0(double latitude) =>
    78271.517 * math.cos(latitude * math.pi / 180);

/// La ubicacion del usuario: su precision en metros y la escala de la latitud.
Map<String, Object?> locationGeoJson(UserLocation? here) => _collection([
  if (here != null)
    _point(here.position, {
      'acc': here.accuracyMeters.isFinite ? here.accuracyMeters : 0,
      'k': metersPerPixelAtZoom0(here.position.latitude),
    }),
]);

/// Un solo punto (el elegido con un toque largo), o nada.
Map<String, Object?> pointGeoJson(GeoPoint? p) =>
    _collection([if (p != null) _point(p, const {})]);

/// El radio en pixeles de un circulo de [meters] metros: crece con el zoom (al
/// doble por nivel) para medir siempre lo mismo sobre el terreno.
List<Object> accuracyRadius() => [
  'interpolate',
  ['exponential', 2],
  ['zoom'],
  0,
  [
    '/',
    ['get', 'acc'],
    ['get', 'k'],
  ],
  22,
  [
    '*',
    [
      '/',
      ['get', 'acc'],
      ['get', 'k'],
    ],
    4194304, // 2^22
  ],
];

/// El color segun la atencion que pide (`sev`: 0 normal, 1 atencion, 2 critico).
List<Object> severityColor({
  required Color normal,
  required Color attention,
  required Color critical,
}) => [
  'match',
  ['get', 'sev'],
  2,
  hexColor(critical),
  1,
  hexColor(attention),
  hexColor(normal),
];

/// Los puntos que hay que encuadrar: los pines o, sin pines, los tramos.
List<GeoPoint> fitPoints(List<MapPin> pins, List<RoadSegment> segments) =>
    pins.isNotEmpty
    ? [for (final p in pins) p.position]
    : [
        for (final s in segments)
          for (final p in s.points) p,
      ];

/// El rectangulo (sur-oeste y nor-este) que contiene los puntos; null sin puntos.
({GeoPoint southWest, GeoPoint northEast})? boundsOf(List<GeoPoint> points) {
  if (points.isEmpty) return null;
  var minLat = points.first.latitude;
  var maxLat = minLat;
  var minLon = points.first.longitude;
  var maxLon = minLon;
  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLon = math.min(minLon, p.longitude);
    maxLon = math.max(maxLon, p.longitude);
  }
  return (
    southWest: GeoPoint(minLat, minLon),
    northEast: GeoPoint(maxLat, maxLon),
  );
}
