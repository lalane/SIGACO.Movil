import '../../domain/entities/map_pin.dart';
import '../../domain/repositories/map_repository.dart';
import '../cache/map_pins_cache.dart';

/// El mapa con lo ya consultado guardado en el telefono. Con conexion todo sale
/// del servidor y se guarda; sin ella solo se muestra lo guardado, marcado con su
/// fecha. Nunca se entrega lo guardado ante un fallo que no sea de red (sin
/// permiso, error del servidor, mapa no publicado...).
class CachedMapRepository implements MapRepository {
  const CachedMapRepository(this._inner, this._cache);

  final MapRepository _inner;
  final MapPinsCache _cache;

  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    try {
      final pins = await _inner.pins(layer);
      // Guardar es un extra: un fallo del disco no debe romper la consulta.
      try {
        await _cache.save(layer, pins);
      } catch (_) {}
      return pins;
    } on MapException catch (e) {
      if (e.error != MapError.network) rethrow;
      PinListing? saved;
      try {
        saved = await _cache.read(layer);
      } catch (_) {}
      if (saved == null) rethrow;
      return saved;
    }
  }
}
