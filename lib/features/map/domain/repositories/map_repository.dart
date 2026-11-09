import '../entities/geo_bounds.dart';
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

/// La consulta se cancelo porque ya no hacia falta (el mapa se movio otra vez):
/// no es un error y no se muestra.
class MapQueryCancelled implements Exception {
  const MapQueryCancelled();

  @override
  String toString() => 'MapQueryCancelled';
}

/// Para dejar de esperar una consulta del mapa. Quien la hace se suscribe con
/// [onCancel] (por ejemplo, para cortar la peticion HTTP).
class MapQueryCancel {
  final _listeners = <void Function()>[];
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  /// Llama a [listener] al cancelar; si ya se cancelo, enseguida.
  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// Los pines de una zona del mapa.
class AreaPins {
  const AreaPins(this.pins, {this.truncated = false, this.cachedAt});

  final List<MapPin> pins;

  /// En la zona habia mas de los que caben en una consulta: acercar el mapa.
  final bool truncated;

  /// Si no es null, no vienen del servidor sino de lo guardado en el telefono
  /// en ese momento (UTC).
  final DateTime? cachedAt;
}

/// Los activos cercanos segun el servidor (`/api/assets/nearby`): mide hasta la
/// geometria de cada activo (una linea o un poligono, no solo su punto). Lanza
/// [MapException]; sin conexion el mapa los calcula con lo que ya tiene.
abstract interface class NearbyAssetsSource {
  Future<List<NearbyPin>> nearbyAssets(GeoPoint from, double radiusMeters);
}

/// Pestanas que se piden por zona (el rectangulo visible) en vez de completas:
/// son demasiados elementos para bajar todos de una vez (el inventario).
abstract interface class AreaPinsSource {
  /// Si [layer] se pide por zona con esta fuente.
  bool loadsByArea(MapLayer layer);

  /// Los pines de [layer] dentro de [area]. Lanza [MapException], o
  /// [MapQueryCancelled] si [cancel] se cancelo antes de tener respuesta.
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  });
}

/// Lo que el mapa muestra de la concesion activa. Lanza [MapException].
abstract interface class MapRepository {
  /// Los pines de una pestana, ya acotados a la concesion y a lo que el
  /// usuario puede ver. En tickets, solo los abiertos: el historial completo
  /// es del modulo de tickets. Sin conexion entrega lo ultimo guardado como un
  /// [PinListing] con `cachedAt`.
  Future<List<MapPin>> pins(MapLayer layer);
}
