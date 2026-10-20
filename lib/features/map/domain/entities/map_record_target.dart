import 'package:equatable/equatable.dart';

/// De donde sale el lugar donde se levanta un registro desde el mapa.
enum MapTargetOrigin {
  /// Lectura reciente del GPS.
  gps,

  /// La ultima posicion conocida, no una lectura actual.
  lastKnown,

  /// Un punto elegido en el mapa.
  mapPoint,

  /// El activo seleccionado.
  asset,
}

/// El lugar donde se va a levantar un registro (por ejemplo un ticket) desde el
/// mapa: lo que se entrega al modulo que lo crea (DTF M10, HU-MOB-10-04).
class MapRecordTarget extends Equatable {
  const MapRecordTarget({
    required this.latitude,
    required this.longitude,
    required this.origin,
    this.accuracyMeters,
    this.readAt,
    this.assetId,
    this.kmLabel,
  });

  final double latitude;
  final double longitude;
  final MapTargetOrigin origin;

  /// Precision de la lectura, en metros; null si no es una lectura.
  final double? accuracyMeters;

  /// Cuando se leyo, en UTC.
  final DateTime? readAt;

  /// El activo del inventario seleccionado, si lo hay.
  final String? assetId;
  final String? kmLabel;

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    origin,
    accuracyMeters,
    readAt,
    assetId,
    kmLabel,
  ];
}
