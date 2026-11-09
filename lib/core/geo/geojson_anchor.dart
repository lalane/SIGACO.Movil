import 'dart:math' as math;

/// Un punto (latitud, longitud) de una geometria GeoJSON en grados, para ubicar
/// algo en el mapa o mostrar sus coordenadas: el propio punto, el punto medio
/// (a lo largo) de una linea, el centroide de un poligono o, si son varias
/// partes (`MultiLineString`, `MultiPolygon`, como las OAE del WebGIS), el de
/// todas juntas. Null si la geometria no trae coordenadas validas.
(double, double)? geoJsonAnchor(Object? geometry) {
  if (geometry is! Map) return null;
  final coords = geometry['coordinates'];
  final xy = switch (geometry['type']) {
    'Point' => _point(coords),
    'MultiPoint' => _middleVertex(_points(coords)),
    'LineString' => _halfway([_points(coords)]),
    'MultiLineString' => _halfway([
      if (coords is List)
        for (final part in coords) _points(part),
    ]),
    'Polygon' => _centroid([coords]),
    'MultiPolygon' => _centroid(coords is List ? coords : const []),
    'GeometryCollection' => _firstOf(geometry['geometries']),
    _ => null,
  };
  return xy == null ? null : (xy.y, xy.x);
}

typedef _Xy = ({double x, double y});

_Xy? _point(Object? c) {
  if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
    final x = (c[0] as num).toDouble();
    final y = (c[1] as num).toDouble();
    return x.isFinite && y.isFinite ? (x: x, y: y) : null;
  }
  return null;
}

List<_Xy> _points(Object? c) => [
  if (c is List)
    for (final p in c) ?_point(p),
];

_Xy? _middleVertex(List<_Xy> points) =>
    points.isEmpty ? null : points[points.length ~/ 2];

double _distance(_Xy a, _Xy b) =>
    math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));

/// El punto que queda a la mitad del largo de todas las partes de la linea.
_Xy? _halfway(List<List<_Xy>> parts) {
  final drawn = [
    for (final p in parts)
      if (p.isNotEmpty) p,
  ];
  if (drawn.isEmpty) return null;
  var length = 0.0;
  for (final part in drawn) {
    for (var i = 1; i < part.length; i++) {
      length += _distance(part[i - 1], part[i]);
    }
  }
  if (length <= 0) return drawn.first.first;
  // Si la mitad cae en un vertice (con el redondeo de los decimales), se toma
  // el vertice tal cual.
  final eps = length * 1e-9;
  var left = length / 2;
  for (final part in drawn) {
    for (var i = 1; i < part.length; i++) {
      final a = part[i - 1];
      final b = part[i];
      if (left <= eps) return a;
      final step = _distance(a, b);
      if (left <= step + eps) {
        if ((step - left).abs() <= eps) return b;
        final t = left / step;
        return (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);
      }
      left -= step;
    }
  }
  return drawn.last.last;
}

/// El centroide de uno o varios poligonos (cada uno, su contorno exterior),
/// pesado por su area. Si no tienen area (anillos degenerados), el promedio de
/// sus vertices.
_Xy? _centroid(List<Object?> polygons) {
  var area = 0.0;
  var x = 0.0;
  var y = 0.0;
  final flat = <_Xy>[];
  for (final polygon in polygons) {
    if (polygon is! List || polygon.isEmpty) continue;
    final ring = _points(polygon.first);
    if (ring.length > 1 && ring.first == ring.last) ring.removeLast();
    if (ring.isEmpty) continue;
    flat.addAll(ring);
    final c = _ringCentroid(ring);
    if (c == null) continue;
    area += c.area;
    x += c.x * c.area;
    y += c.y * c.area;
  }
  if (flat.isEmpty) return null;
  if (area > 0) return (x: x / area, y: y / area);
  return (
    x: flat.map((p) => p.x).reduce((a, b) => a + b) / flat.length,
    y: flat.map((p) => p.y).reduce((a, b) => a + b) / flat.length,
  );
}

/// Formula del area con signo (shoelace), con el origen en el primer vertice
/// para no perder precision con coordenadas grandes.
({double x, double y, double area})? _ringCentroid(List<_Xy> ring) {
  if (ring.length < 3) return null;
  final ox = ring.first.x;
  final oy = ring.first.y;
  var twiceArea = 0.0;
  var cx = 0.0;
  var cy = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final px = ring[i].x - ox;
    final py = ring[i].y - oy;
    final q = ring[(i + 1) % ring.length];
    final qx = q.x - ox;
    final qy = q.y - oy;
    final cross = px * qy - qx * py;
    twiceArea += cross;
    cx += (px + qx) * cross;
    cy += (py + qy) * cross;
  }
  if (twiceArea == 0) return null;
  return (
    x: ox + cx / (3 * twiceArea),
    y: oy + cy / (3 * twiceArea),
    area: twiceArea.abs() / 2,
  );
}

_Xy? _firstOf(Object? geometries) {
  if (geometries is! List) return null;
  for (final g in geometries) {
    final anchor = geoJsonAnchor(g);
    if (anchor != null) return (x: anchor.$2, y: anchor.$1);
  }
  return null;
}
