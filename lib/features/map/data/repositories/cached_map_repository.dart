import '../../domain/entities/geo_bounds.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/nearby_pin.dart';
import '../../domain/repositories/map_repository.dart';
import '../cache/map_pins_cache.dart';

/// El mapa con lo ya consultado guardado en el telefono. Con conexion todo sale
/// del servidor y se guarda; sin ella solo se muestra lo guardado, marcado con su
/// fecha. Nunca se entrega lo guardado ante un fallo que no sea de red (sin
/// permiso, error del servidor, mapa no publicado...).
class CachedMapRepository
    implements MapRepository, NearbyAssetsSource, AreaPinsSource {
  CachedMapRepository(this._inner, this._cache);

  final MapRepository _inner;
  final MapPinsCache _cache;

  /// Cuantos pines por zona se guardan como maximo: las zonas que se van viendo
  /// se suman (lo mas reciente primero) hasta este tope.
  static const areaCacheLimit = 10000;

  /// Las escrituras de las zonas van en fila: dos a la vez se pisarian.
  Future<void> _saving = Future.value();

  /// Los cercanos solo con conexion: sin ella el mapa los calcula con los pines
  /// guardados.
  @override
  Future<List<NearbyPin>> nearbyAssets(GeoPoint from, double radiusMeters) {
    final inner = _inner;
    if (inner is! NearbyAssetsSource) {
      return Future.error(const MapException(MapError.notAvailable));
    }
    return (inner as NearbyAssetsSource).nearbyAssets(from, radiusMeters);
  }

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

  @override
  bool loadsByArea(MapLayer layer) {
    final inner = _inner;
    return inner is AreaPinsSource &&
        (inner as AreaPinsSource).loadsByArea(layer);
  }

  /// La zona del servidor, que se suma a lo guardado de la pestana (sin esperar
  /// a que se escriba). Sin conexion, lo guardado que cae en la zona.
  @override
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  }) async {
    final inner = _inner;
    if (inner is! AreaPinsSource) {
      throw const MapException(MapError.notAvailable);
    }
    try {
      final found = await (inner as AreaPinsSource).pinsIn(
        layer,
        area,
        cancel: cancel,
      );
      _saving = _saving.then((_) => _remember(layer, area, found.pins));
      return found;
    } on MapException catch (e) {
      if (e.error != MapError.network || (cancel?.isCancelled ?? false)) {
        rethrow;
      }
      PinListing? saved;
      try {
        await _saving;
        saved = await _cache.read(layer);
      } catch (_) {}
      if (saved == null) rethrow;
      return AreaPins([
        for (final pin in saved)
          if (area.contains(pin.position)) pin,
      ], cachedAt: saved.cachedAt);
    }
  }

  /// Lo guardado de la pestana con la zona nueva: lo de la zona se reemplaza y
  /// lo de fuera se conserva detras, hasta [areaCacheLimit].
  Future<void> _remember(
    MapLayer layer,
    GeoBounds area,
    List<MapPin> fresh,
  ) async {
    try {
      final saved = await _cache.read(layer);
      final ids = {for (final pin in fresh) pin.id};
      final merged = [
        ...fresh,
        for (final pin in saved ?? const <MapPin>[])
          if (!area.contains(pin.position) && !ids.contains(pin.id)) pin,
      ];
      await _cache.save(
        layer,
        merged.length > areaCacheLimit
            ? merged.sublist(0, areaCacheLimit)
            : merged,
      );
    } catch (_) {
      // Guardar es un extra: un fallo del disco no debe romper el mapa.
    }
  }
}
