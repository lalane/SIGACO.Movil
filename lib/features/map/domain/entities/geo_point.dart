import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Un punto en la Tierra (grados decimales, WGS 84 / SIRGAS 2000: la
/// diferencia es de centimetros y no importa para pintar pines).
class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Radio medio de la Tierra, en metros.
  static const _earthRadius = 6371008.8;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Distancia en metros por el arco del circulo maximo (haversine).
  double distanceTo(GeoPoint other) {
    final dLat = _rad(other.latitude - latitude);
    final dLon = _rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(latitude)) *
            math.cos(_rad(other.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  List<Object?> get props => [latitude, longitude];
}
