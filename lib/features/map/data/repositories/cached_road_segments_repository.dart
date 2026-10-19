import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';
import '../cache/map_pins_cache.dart';

/// Los tramos con lo ya consultado guardado en el telefono: con conexion salen
/// del servidor y se guardan; sin ella solo se dibuja lo guardado. Nunca se
/// entrega lo guardado ante un fallo que no sea de red.
class CachedRoadSegmentsRepository implements RoadSegmentsRepository {
  const CachedRoadSegmentsRepository(this._inner, this._cache);

  final RoadSegmentsRepository _inner;
  final MapPinsCache _cache;

  @override
  Future<List<RoadSegment>> segments() async {
    try {
      final segments = await _inner.segments();
      // Guardar es un extra: un fallo del disco no debe romper la consulta.
      try {
        await _cache.saveSegments(segments);
      } catch (_) {}
      return segments;
    } on MapException catch (e) {
      if (e.error != MapError.network) rethrow;
      SegmentListing? saved;
      try {
        saved = await _cache.readSegments();
      } catch (_) {}
      if (saved == null) rethrow;
      return saved;
    }
  }
}
