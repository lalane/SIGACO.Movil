import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_source.dart';

/// Sin servicio de ubicacion (pruebas y entornos sin plugins): nunca da una
/// posicion.
class UnavailableLocationSource implements LocationSource {
  const UnavailableLocationSource();

  @override
  Future<UserLocation> current() =>
      Future.error(const LocationException(LocationFailure.unavailable));

  @override
  Future<void> openSettings(LocationFailure reason) async {}
}
