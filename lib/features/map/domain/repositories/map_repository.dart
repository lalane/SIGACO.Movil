import '../entities/geo_point.dart';
import '../entities/map_pin.dart';
import '../entities/nearby_pin.dart';

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

/// Los activos cercanos segun el servidor (`/api/assets/nearby`): mide hasta la
/// geometria de cada activo (una linea o un poligono, no solo su punto). Lanza
/// [MapException]; sin conexion el mapa los calcula con lo que ya tiene.
abstract interface class NearbyAssetsSource {
  Future<List<NearbyPin>> nearbyAssets(GeoPoint from, double radiusMeters);
}

/// Lo que el mapa muestra de la concesion activa. Lanza [MapException].
abstract interface class MapRepository {
  /// Los pines de una pestana, ya acotados a la concesion y a lo que el
  /// usuario puede ver. En tickets, solo los abiertos: el historial completo
  /// es del modulo de tickets. Sin conexion entrega lo ultimo guardado como un
  /// [PinListing] con `cachedAt`.
  Future<List<MapPin>> pins(MapLayer layer);
}
