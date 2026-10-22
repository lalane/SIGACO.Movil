/// Un punto (latitud, longitud) de una geometria GeoJSON en grados, para ubicar
/// algo en el mapa: el propio punto, el de en medio de una linea o el centro de
/// un poligono. Null si la geometria no trae coordenadas validas.
(double, double)? geoJsonAnchor(Object? geometry) {
  if (geometry is! Map) return null;
  final coords = geometry['coordinates'];

  (double, double)? point(Object? c) {
    if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      return lat.isFinite && lon.isFinite ? (lat, lon) : null;
    }
    return null;
  }

  switch (geometry['type']) {
    case 'Point':
      return point(coords);
    case 'LineString' || 'MultiPoint':
      if (coords is List && coords.isNotEmpty) {
        return point(coords[coords.length ~/ 2]);
      }
    case 'Polygon':
      if (coords is List && coords.isNotEmpty && coords.first is List) {
        final ring = (coords.first as List)
            .map(point)
            .whereType<(double, double)>()
            .toList();
        if (ring.isEmpty) return null;
        return (
          ring.map((p) => p.$1).reduce((a, b) => a + b) / ring.length,
          ring.map((p) => p.$2).reduce((a, b) => a + b) / ring.length,
        );
      }
  }
  return null;
}
