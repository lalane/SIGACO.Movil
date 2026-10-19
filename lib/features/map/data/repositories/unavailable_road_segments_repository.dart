import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';

/// Mientras el backend no publique los tramos, el mapa se dibuja sin la
/// carretera en lugar de inventarla. Con `SAMPLE_MAP=true` se usa
/// [SampleRoadSegmentsRepository].
class UnavailableRoadSegmentsRepository implements RoadSegmentsRepository {
  const UnavailableRoadSegmentsRepository();

  @override
  Future<List<RoadSegment>> segments() =>
      Future.error(const MapException(MapError.notAvailable));
}
