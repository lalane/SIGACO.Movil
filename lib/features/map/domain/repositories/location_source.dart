import '../entities/user_location.dart';

/// Por que no se pudo obtener la ubicacion.
enum LocationFailure {
  /// El GPS del telefono esta apagado.
  serviceDisabled,

  /// El usuario no dio el permiso (se puede volver a pedir).
  permissionDenied,

  /// El usuario marco "no volver a preguntar": solo se arregla en Ajustes.
  permissionDeniedForever,

  /// No hubo posicion a tiempo o fallo el servicio.
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException($failure)';
}

/// La posicion del telefono. Lanza [LocationException].
abstract interface class LocationSource {
  /// Pide el permiso si hace falta y devuelve la posicion de ahora.
  Future<UserLocation> current();

  /// Abre los ajustes del telefono para dar el permiso o encender el GPS.
  Future<void> openSettings(LocationFailure reason);
}
