import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'geo_point.dart';

/// Un rectangulo en el mapa, en grados.
class GeoBounds extends Equatable {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  /// Un rectangulo de [meters] por lado alrededor de [center] (aproximado: sirve
  /// para pedir lo cercano, no para medir).
  factory GeoBounds.around(GeoPoint center, double meters) {
    const metersPerDegree = 111320.0;
    final dLat = meters / metersPerDegree;
    final cos = math.cos(center.latitude * math.pi / 180).abs();
    final dLon = dLat / math.max(cos, 0.01);
    return GeoBounds(
      south: math.max(-90, center.latitude - dLat),
      west: math.max(-180, center.longitude - dLon),
      north: math.min(90, center.latitude + dLat),
      east: math.min(180, center.longitude + dLon),
    );
  }

  final double south;
  final double west;
  final double north;
  final double east;

  bool get isValid =>
      south.isFinite &&
      west.isFinite &&
      north.isFinite &&
      east.isFinite &&
      south >= -90 &&
      north <= 90 &&
      west >= -180 &&
      east <= 180 &&
      south <= north &&
      west <= east;

  GeoPoint get center => GeoPoint((south + north) / 2, (west + east) / 2);

  bool contains(GeoPoint p) =>
      p.latitude >= south &&
      p.latitude <= north &&
      p.longitude >= west &&
      p.longitude <= east;

  /// Si [other] cabe entero en este rectangulo.
  bool covers(GeoBounds other) =>
      other.south >= south &&
      other.north <= north &&
      other.west >= west &&
      other.east <= east;

  /// El rectangulo agrandado por cada lado en [fraction] de su alto y de su
  /// ancho, sin salirse del planeta.
  GeoBounds expanded(double fraction) {
    final dLat = (north - south) * fraction;
    final dLon = (east - west) * fraction;
    return GeoBounds(
      south: math.max(-90, south - dLat),
      west: math.max(-180, west - dLon),
      north: math.min(90, north + dLat),
      east: math.min(180, east + dLon),
    );
  }

  @override
  List<Object?> get props => [south, west, north, east];
}
