import '../entities/map_pin.dart';

/// Por que no se pudieron traer los pines.
enum MapError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver esa pestana.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica el mapa para esta concesion.
  notAvailable,
}

class MapException implements Exception {
  const MapException(this.error);

  final MapError error;

  @override
  String toString() => 'MapException($error)';
}

/// Lo que el mapa muestra de la concesion activa. Lanza [MapException].
abstract interface class MapRepository {
  /// Los pines de una pestana, ya acotados a la concesion y a lo que el
  /// usuario puede ver. En tickets, solo los abiertos: el historial completo
  /// es del modulo de tickets. Sin conexion entrega lo ultimo guardado como un
  /// [PinListing] con `cachedAt`.
  Future<List<MapPin>> pins(MapLayer layer);
}
