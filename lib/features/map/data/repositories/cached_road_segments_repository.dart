import '../../domain/entities/road_segment.dart';
import '../../domain/entities/segment_pavement.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';
import '../../domain/repositories/segment_pavement_source.dart';
import '../cache/map_pins_cache.dart';
import 'api_road_segments_repository.dart';

/// Los tramos con lo ya consultado guardado en el telefono: con conexion salen
/// del servidor y se guardan; sin ella solo se dibuja lo guardado. Nunca se
/// entrega lo guardado ante un fallo que no sea de red.
class CachedRoadSegmentsRepository
    implements RoadSegmentsRepository, SegmentPavementSource {
  const CachedRoadSegmentsRepository(this._inner, this._cache);

  final RoadSegmentsRepository _inner;
  final MapPinsCache _cache;

  /// El pavimento por tramo, guardado como los tramos: sin conexion se pinta
  /// lo ultimo consultado, con su fecha (DTF M10 RB-10-28).
  @override
  Future<PavementLayer> pavement() async {
    final inner = _inner;
    if (inner is! SegmentPavementSource) {
      throw const MapException(MapError.notAvailable);
    }
    final cache = _cache;
    try {
      if (inner is ApiRoadSegmentsRepository && cache is PavementCache) {
        final (layer, json) = await inner.pavementWithJson();
        try {
          await (cache as PavementCache).savePavement(json);
        } catch (_) {}
        return layer;
      }
      return await (inner as SegmentPavementSource).pavement();
    } on MapException catch (e) {
      if (e.error != MapError.network || cache is! PavementCache) rethrow;
      (Map<String, dynamic>, DateTime)? saved;
      try {
        saved = await (cache as PavementCache).readPavement();
      } catch (_) {}
      if (saved == null) rethrow;
      return ApiRoadSegmentsRepository.parsePavement(
        saved.$1,
      ).withCachedAt(saved.$2);
    }
  }

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
