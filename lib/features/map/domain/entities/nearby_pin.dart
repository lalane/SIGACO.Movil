import 'package:equatable/equatable.dart';

import 'geo_point.dart';
import 'map_pin.dart';

/// Un elemento a cierta distancia del usuario.
class NearbyPin extends Equatable {
  const NearbyPin(this.pin, this.distanceMeters);

  final MapPin pin;
  final double distanceMeters;

  @override
  List<Object?> get props => [pin, distanceMeters];
}

/// Los elementos de [pins] a no mas de [radiusMeters] de [from], del mas
/// cercano al mas lejano. Se calcula en el telefono: es lo que permite el
/// mismo resultado con y sin conexion cuando los pines ya estan guardados.
List<NearbyPin> nearbyPins(
  Iterable<MapPin> pins,
  GeoPoint from,
  double radiusMeters,
) {
  final result = <NearbyPin>[
    for (final pin in pins)
      if (pin.position.isValid)
        if (from.distanceTo(pin.position) case final d when d <= radiusMeters)
          NearbyPin(pin, d),
  ];
  result.sort((a, b) {
    final byDistance = a.distanceMeters.compareTo(b.distanceMeters);
    return byDistance != 0 ? byDistance : a.pin.id.compareTo(b.pin.id);
  });
  return result;
}
