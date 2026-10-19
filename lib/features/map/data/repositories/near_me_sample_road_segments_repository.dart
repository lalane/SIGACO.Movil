import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/road_segments_repository.dart';
import 'geo_path.dart';
import 'near_me_road.dart';
import 'near_me_sample_map_repository.dart';
import 'sample_road_segments_repository.dart';

/// La carretera de ejemplo que pasa **por donde esta el telefono**, cortada en
/// cuatro tramos de igual largo (de oeste a este), cada uno con sus dos sentidos:
/// ocho lineas. Los pines de [NearMeSampleMapRepository] caen sobre ellas.
///
/// Si se encuentra la calle real que pasa por el telefono (ver [RoadFinder]) las
/// lineas la siguen; si no, son una recta inventada de oeste a este. Sin
/// ubicacion usa los de [SampleRoadSegmentsRepository].
class NearMeSampleRoadSegmentsRepository implements RoadSegmentsRepository {
  /// Con [anchor] solo, la carretera es la recta inventada; para que siga una
  /// calle real se pasa [road] (el mismo que usan los pines de ejemplo).
  NearMeSampleRoadSegmentsRepository({
    AnchorProvider? anchor,
    NearMeRoad? road,
    RoadSegmentsRepository? fallback,
  }) : assert(anchor != null || road != null, 'hace falta anchor o road'),
       road = road ?? NearMeRoad(anchor: anchor!),
       fallback = fallback ?? SampleRoadSegmentsRepository();

  final NearMeRoad road;
  final RoadSegmentsRepository fallback;

  /// La linea de un sentido a todo lo largo de la carretera, de oeste a este.
  static GeoPath _lane(NearMeRoadData data, TravelDirection direction) {
    if (data.isReal) return data.lanes[direction]!;
    const reach = NearMeSampleMapRepository.straightReachMeters;
    const steps = 18;
    return GeoPath([
      for (var i = 0; i <= steps; i++)
        NearMeSampleMapRepository.onRoad(
          data.center,
          -reach + 2 * reach * i / steps,
          direction,
        ),
    ]);
  }

  /// Los cuatro tramos de un sentido: el creciente va de oeste a este y el
  /// decreciente al reves.
  static List<RoadSegment> _segments(
    NearMeRoadData data,
    TravelDirection direction,
  ) {
    final lane = _lane(data, direction);
    final axisLength = data.isReal
        ? data.axis!.length
        : 2 * NearMeSampleMapRepository.straightReachMeters;
    final count = NearMeSampleMapRepository.roadCodes.length;
    final increasing = direction == TravelDirection.increasing;
    return [
      for (var i = 0; i < count; i++)
        () {
          final piece = lane.slice(
            lane.length * i / count,
            lane.length * (i + 1) / count,
          );
          final from = NearMeSampleMapRepository.kmLabelAt(
            axisLength * i / count,
          );
          final to = NearMeSampleMapRepository.kmLabelAt(
            axisLength * (i + 1) / count,
          );
          return RoadSegment(
            id: '${NearMeSampleMapRepository.roadCodes[i]}-${direction.name}',
            code: NearMeSampleMapRepository.roadCodes[i],
            name: 'Tramo de ejemplo',
            direction: direction,
            startKmLabel: increasing ? from : to,
            endKmLabel: increasing ? to : from,
            points: increasing ? piece : piece.reversed.toList(),
          );
        }(),
    ];
  }

  @override
  Future<List<RoadSegment>> segments() async {
    final data = await road.resolve();
    if (data == null) return fallback.segments();
    return [
      for (final direction in TravelDirection.values)
        ..._segments(data, direction),
    ];
  }
}
