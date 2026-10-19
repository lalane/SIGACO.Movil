import 'package:equatable/equatable.dart';

import 'geo_point.dart';

/// De donde salio la ubicacion; se guarda con ella para auditarla.
enum LocationOrigin { gps, network, mocked }

/// La posicion del usuario con lo que hace falta para decidir si se puede
/// confiar en ella: precision, hora y origen.
class UserLocation extends Equatable {
  const UserLocation({
    required this.position,
    required this.accuracyMeters,
    required this.capturedAt,
    this.origin = LocationOrigin.gps,
  });

  final GeoPoint position;

  /// Radio de incertidumbre en metros (cuanto menor, mejor).
  final double accuracyMeters;

  /// UTC.
  final DateTime capturedAt;
  final LocationOrigin origin;

  /// Una ubicacion simulada nunca se acepta para guardar datos.
  bool get isTrusted => origin != LocationOrigin.mocked;

  /// Sirve para guardar una ubicacion si la precision llega al umbral.
  bool meetsAccuracy(double maxMeters) =>
      accuracyMeters.isFinite && accuracyMeters <= maxMeters;

  @override
  List<Object?> get props => [position, accuracyMeters, capturedAt, origin];
}
