import '../../domain/entities/geo_point.dart';
import '../../domain/entities/road_segment.dart';
import 'geo_path.dart';
import 'near_me_sample_map_repository.dart';

/// Busca la calle real que pasa por [center] y la devuelve como una linea en el
/// sentido oeste a este; null si no se pudo (sin internet, sin servicio).
typedef RoadFinder = Future<GeoPath?> Function(GeoPoint center);

/// La carretera de ejemplo del modo "cerca de ti": donde esta el telefono y, si
/// se pudo encontrar, la calle real que pasa por ahi.
class NearMeRoadData {
  NearMeRoadData.straight(this.center) : axis = null, phoneMeters = 0;

  NearMeRoadData.real({
    required this.center,
    required GeoPath this.axis,
    required this.phoneMeters,
  });

  final GeoPoint center;

  /// La calle real, en el sentido en que se recorre; null si se usa la recta
  /// inventada de [NearMeSampleMapRepository.onRoad].
  final GeoPath? axis;

  /// A cuantos metros del inicio de [axis] esta el punto mas cercano al telefono.
  final double phoneMeters;

  bool get isReal => axis != null;

  /// Cuanto se separa cada sentido del eje de la calle.
  static const laneMeters = NearMeSampleMapRepository.laneMeters;

  /// La linea de cada sentido: el creciente a la derecha de quien recorre el eje
  /// y el decreciente a su izquierda (la derecha de quien va al reves).
  late final Map<TravelDirection, GeoPath> lanes = {
    TravelDirection.increasing: axis!.offset(laneMeters),
    TravelDirection.decreasing: axis!.offset(-laneMeters),
  };

  /// El punto de la linea de un sentido a [axisMeters] del inicio del eje.
  GeoPoint pointAt(TravelDirection direction, double axisMeters) {
    final lane = lanes[direction]!;
    final along = axisMeters.clamp(0.0, axis!.length);
    return lane.at(along * lane.length / axis!.length);
  }
}

/// Resuelve una sola vez donde esta el telefono y su calle, para que los pines
/// y los tramos de ejemplo usen la misma. Sin ubicacion devuelve null (se usan
/// los de la BR-381); sin calle, la recta inventada.
class NearMeRoad {
  NearMeRoad({required this.anchor, this.finder});

  final AnchorProvider anchor;
  final RoadFinder? finder;

  /// Una calle mas corta que esto no sirve para repartir pines a varios km.
  static const minLengthMeters = 1500.0;

  Future<NearMeRoadData?>? _data;

  Future<NearMeRoadData?> resolve() => _data ??= _load();

  Future<NearMeRoadData?> _load() async {
    final GeoPoint? center;
    try {
      center = await anchor();
    } catch (_) {
      return null;
    }
    if (center == null || !center.isValid) return null;
    GeoPath? axis;
    try {
      axis = await finder?.call(center);
    } catch (_) {
      axis = null;
    }
    if (axis == null || axis.length < minLengthMeters) {
      return NearMeRoadData.straight(center);
    }
    return NearMeRoadData.real(
      center: center,
      axis: axis,
      phoneMeters: axis.nearestMeters(center),
    );
  }
}
