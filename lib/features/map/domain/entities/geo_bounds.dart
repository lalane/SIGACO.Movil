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

  bool contains(GeoPoint p) =>
      p.latitude >= south &&
      p.latitude <= north &&
      p.longitude >= west &&
      p.longitude <= east;

  @override
  List<Object?> get props => [south, west, north, east];
}
