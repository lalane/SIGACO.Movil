import '../entities/road_segment.dart';

/// Los tramos de la concesion activa, con su trayectoria, para dibujar la
/// carretera. Lanza `MapException` (el mismo error del mapa). Sin conexion
/// entrega lo ultimo guardado como un [SegmentListing] con `cachedAt`.
abstract interface class RoadSegmentsRepository {
  Future<List<RoadSegment>> segments();
}
