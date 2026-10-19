import '../../domain/entities/geo_point.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/road_segments_repository.dart';
import 'geo_path.dart';
import 'sample_br381_path.dart';

/// Cinco tramos de ejemplo sobre la BR-381 (km 146.9 a 164.9, Governador
/// Valadares), con sus dos sentidos: diez lineas.
/// Las lineas siguen **el trazo real de la carretera** ([sampleBr381Path], de
/// OpenStreetMap), un sentido a cada lado del eje, para que se vean sobre la
/// carretera que muestra el mapa y no cruzando calles. Los pines de ejemplo
/// caen sobre estas lineas ([pointAt]). Los cortes entre tramos y los codigos son
/// inventados; la geometria oficial la entregara el servidor.
class SampleRoadSegmentsRepository implements RoadSegmentsRepository {
  SampleRoadSegmentsRepository({this.delay = Duration.zero});

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  /// Donde empieza cada tramo de ejemplo y donde termina el ultimo: cinco tramos
  /// de 4.5, 4.5, 3, 3 y 3 km.
  static const breaksKm = [146.9, 151.4, 155.9, 158.9, 161.9, 164.9];

  /// Los codigos de los cinco tramos, en el orden de [breaksKm].
  static const codes = [
    '381BMG0160',
    '381BMG0170',
    '381BMG0180',
    '381BMG0190',
    '381BMG0200',
  ];

  static const _kmStart = 146.9;
  static const _kmEnd = 164.9;

  /// El codigo del tramo de ejemplo que cubre un kilometro.
  static String codeAt(double km) {
    for (var i = 0; i < codes.length - 1; i++) {
      if (km < breaksKm[i + 1]) return codes[i];
    }
    return codes.last;
  }

  /// Cuanto se separa cada sentido del eje, en metros. Pocos: dos carriles de
  /// una carretera estan a unos metros. A zoom bajo las dos lineas se juntan en
  /// una y al acercarse se separan.
  static const laneMeters = 8.0;

  /// El eje y, a cada lado, la linea de cada sentido. El creciente va a la
  /// derecha de quien recorre la carretera en el sentido en que crece el
  /// kilometro; el decreciente, a la izquierda de ese recorrido, que es la
  /// derecha de quien va al reves.
  static final GeoPath _axis = GeoPath(sampleBr381Path);
  static final Map<TravelDirection, GeoPath> _lanes = {
    TravelDirection.increasing: _axis.offset(laneMeters),
    TravelDirection.decreasing: _axis.offset(-laneMeters),
  };

  /// Cuanto del recorrido (0 a 1) cae en un kilometro.
  static double _fraction(double km) =>
      ((km - _kmStart) / (_kmEnd - _kmStart)).clamp(0.0, 1.0);

  /// El punto de la linea de un sentido en un kilometro: es donde caen los
  /// pines de ejemplo, para que se vea que pertenecen al tramo.
  static GeoPoint pointAt(double km, TravelDirection direction) {
    final lane = _lanes[direction]!;
    return lane.at(_fraction(km) * lane.length);
  }

  static String _km(double km) {
    final whole = km.floor();
    final meters = ((km - whole) * 1000).round();
    return 'KM $whole+${meters.toString().padLeft(3, '0')}';
  }

  static RoadSegment _segment(
    String code,
    TravelDirection direction,
    double from,
    double to,
  ) {
    final increasing = direction == TravelDirection.increasing;
    final lane = _lanes[direction]!;
    final piece = lane.slice(
      _fraction(from) * lane.length,
      _fraction(to) * lane.length,
    );
    return RoadSegment(
      id: '$code-${direction.name}',
      code: code,
      name: 'BR-381 · $code',
      direction: direction,
      startKmLabel: _km(increasing ? from : to),
      endKmLabel: _km(increasing ? to : from),
      // El decreciente se recorre al reves: de su kilometro mayor al menor.
      points: increasing ? piece : piece.reversed.toList(),
    );
  }

  static final List<RoadSegment> _data = [
    for (final direction in TravelDirection.values)
      for (var i = 0; i < codes.length; i++)
        _segment(codes[i], direction, breaksKm[i], breaksKm[i + 1]),
  ];

  @override
  Future<List<RoadSegment>> segments() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return List.unmodifiable(_data);
  }
}
