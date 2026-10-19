import 'package:equatable/equatable.dart';

/// Valores del mapa que el negocio todavia no fija (DEC-005): se proponen un
/// kilometro de radio y 30 m de precision, y son configurables.
class MapSettings extends Equatable {
  const MapSettings({
    this.nearbyRadiusMeters = defaultRadiusMeters,
    this.minAccuracyMeters = defaultMinAccuracyMeters,
    this.clusterRadiusPx = defaultClusterRadiusPx,
  });

  static const defaultRadiusMeters = 1000.0;
  static const defaultMinAccuracyMeters = 30.0;

  /// Pines a menos de esta distancia en pantalla se agrupan; 0 = no agrupar.
  static const defaultClusterRadiusPx = 56.0;

  /// Radios que ofrece el selector de cercanos.
  static const radiusOptionsMeters = [250.0, 500.0, 1000.0, 2000.0, 5000.0];

  final double nearbyRadiusMeters;

  /// Precision minima para aceptar una ubicacion al guardar un registro.
  final double minAccuracyMeters;

  /// Cuanto se juntan los pines en pantalla antes de agruparse (pixeles).
  final double clusterRadiusPx;

  MapSettings copyWith({
    double? nearbyRadiusMeters,
    double? minAccuracyMeters,
    double? clusterRadiusPx,
  }) => MapSettings(
    nearbyRadiusMeters: nearbyRadiusMeters ?? this.nearbyRadiusMeters,
    minAccuracyMeters: minAccuracyMeters ?? this.minAccuracyMeters,
    clusterRadiusPx: clusterRadiusPx ?? this.clusterRadiusPx,
  );

  @override
  List<Object?> get props => [
    nearbyRadiusMeters,
    minAccuracyMeters,
    clusterRadiusPx,
  ];
}
