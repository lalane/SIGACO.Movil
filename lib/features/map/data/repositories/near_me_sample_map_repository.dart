import 'dart:math' as math;

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/map_repository.dart';
import 'near_me_road.dart';
import 'sample_map_repository.dart';

/// De donde se toma el punto alrededor del cual se reparten los pines.
typedef AnchorProvider = Future<GeoPoint?> Function();

/// Pines de ejemplo **a lo largo de una carretera de ejemplo que pasa por donde
/// esta el telefono** (de oeste a este), para probar "ubicarme", los activos
/// cercanos y la relacion pin-tramo sin ir a la BR-381. Hay pines a pocos metros
/// y otros a varios kilometros, a un lado y a otro, para que cada radio (250 m a
/// 5 km) de resultados distintos. Cada pin cae sobre la linea de su sentido
/// ([onRoad]) a la distancia exacta de la tabla. Esa carretera es recta e
/// inventada: no sigue las calles del mapa. Con un [RoadFinder] se busca la
/// calle real que pasa por el telefono y los pines caen sobre ella (a esa
/// distancia medida a lo largo de la calle); si no se encuentra, se usa la recta.
///
/// Si no hay ubicacion (permiso negado, GPS apagado, sin senal) usa los pines de
/// la BR-381 de [SampleMapRepository]. No son activos reales.
class NearMeSampleMapRepository implements MapRepository {
  /// Con [anchor] solo, la carretera es la recta inventada; para que siga una
  /// calle real se pasa [road] (el mismo que usan los tramos de ejemplo).
  NearMeSampleMapRepository({
    AnchorProvider? anchor,
    NearMeRoad? road,
    MapRepository? fallback,
  }) : assert(anchor != null || road != null, 'hace falta anchor o road'),
       road = road ?? NearMeRoad(anchor: anchor!),
       fallback = fallback ?? SampleMapRepository();

  final NearMeRoad road;
  final MapRepository fallback;

  Future<Map<MapLayer, List<MapPin>>?>? _data;

  /// Los cuatro tramos de ejemplo en que se corta la carretera que pasa por el
  /// telefono, de oeste a este, de igual largo.
  static const roadCodes = ['CERCA0001', 'CERCA0002', 'CERCA0003', 'CERCA0004'];

  /// Hasta donde llega la recta inventada a cada lado del telefono: mas que el
  /// pin mas lejano de la tabla.
  static const straightReachMeters = 4500.0;

  /// Los kilometros de ejemplo corren de 150+000 a lo largo de la carretera, uno
  /// por cada 1 000 m.
  static const _kmOrigin = 150;

  /// El tramo de ejemplo que cubre un punto a `alongMeters` del inicio de una
  /// carretera de `lengthMeters`.
  static String codeAt(double alongMeters, double lengthMeters) {
    final i = (alongMeters / lengthMeters * roadCodes.length).floor();
    return roadCodes[i.clamp(0, roadCodes.length - 1)];
  }

  /// La referencia kilometrica de ejemplo de un punto a `alongMeters` del inicio.
  static String kmLabelAt(double alongMeters) {
    final meters = alongMeters.round();
    return 'KM ${_kmOrigin + meters ~/ 1000}+${(meters % 1000).toString().padLeft(3, '0')}';
  }

  /// Cuanto se separa cada sentido del eje de la carretera. Con menos, los dos
  /// sentidos se encimarian a zoom bajo y se vería una sola linea.
  static const laneMeters = 30.0;

  /// El punto de la linea de un sentido, a `eastMeters` al este de `center`
  /// (negativo = al oeste). El sentido creciente va al norte del eje y el
  /// decreciente al sur.
  static GeoPoint onRoad(
    GeoPoint center,
    double eastMeters,
    TravelDirection direction,
  ) => offset(
    offset(
      center,
      direction == TravelDirection.increasing ? laneMeters : -laneMeters,
      0,
    ),
    eastMeters,
    90,
  );

  /// El punto a `meters` metros de `from`, hacia `bearingDegrees` (0 = norte,
  /// 90 = este). Aproximacion plana: sobra para distancias de pocos km.
  static GeoPoint offset(GeoPoint from, double meters, double bearingDegrees) {
    final rad = bearingDegrees * math.pi / 180;
    final north = meters * math.cos(rad);
    final east = meters * math.sin(rad);
    const metersPerDegree = 111320.0;
    final dLat = north / metersPerDegree;
    final dLon =
        east / (metersPerDegree * math.cos(from.latitude * math.pi / 180));
    return GeoPoint(from.latitude + dLat, from.longitude + dLon);
  }

  // id, pestana, titulo, subtitulo, categoria, estado, referencia km,
  // distancia en metros, rumbo en grados.
  static const _table =
      <
        (
          String,
          MapLayer,
          String,
          String,
          String,
          PinStatus,
          String,
          double,
          double,
        )
      >[
        (
          'A-001',
          MapLayer.inventory,
          'Defensa metálica',
          'Sentido creciente',
          'Defensa metálica',
          PinStatus.normal,
          'KM 147+200',
          60,
          20,
        ),
        (
          'A-002',
          MapLayer.inventory,
          'Señal vertical SV-114',
          'Sentido decreciente',
          'Señal vertical',
          PinStatus.normal,
          'KM 148+000',
          130,
          100,
        ),
        (
          'A-003',
          MapLayer.inventory,
          'Barrera New Jersey',
          'Sentido creciente',
          'Barrera',
          PinStatus.normal,
          'KM 149+400',
          220,
          200,
        ),
        (
          'A-004',
          MapLayer.inventory,
          'Descida d\'água DA-22',
          'Lado derecho',
          'Drenaje',
          PinStatus.normal,
          'KM 150+200',
          380,
          290,
        ),
        (
          'A-005',
          MapLayer.inventory,
          'Poste de iluminación P-310',
          'Acceso sudoeste',
          'Iluminación',
          PinStatus.normal,
          'KM 150+350',
          640,
          45,
        ),
        (
          'A-006',
          MapLayer.inventory,
          'OAE puente sobre arroyo',
          'Obra de arte especial',
          'OAE',
          PinStatus.normal,
          'KM 152+100',
          920,
          160,
        ),
        (
          'A-007',
          MapLayer.inventory,
          'Señal vertical SV-131',
          'Sentido creciente',
          'Señal vertical',
          PinStatus.normal,
          'KM 153+600',
          1600,
          250,
        ),
        (
          'A-008',
          MapLayer.inventory,
          'Defensa metálica',
          'Sentido decreciente',
          'Defensa metálica',
          PinStatus.normal,
          'KM 155+400',
          4200,
          330,
        ),
        (
          'T-1041',
          MapLayer.tickets,
          'Defensa dañada',
          'Abierto · prioridad alta',
          'Daño',
          PinStatus.critical,
          'KM 147+200',
          90,
          60,
        ),
        (
          'T-1042',
          MapLayer.tickets,
          'Señal ilegible',
          'Abierto',
          'Señalización',
          PinStatus.attention,
          'KM 153+600',
          300,
          150,
        ),
        (
          'T-1043',
          MapLayer.tickets,
          'Bache en el acostamiento',
          'Abierto',
          'Pavimento',
          PinStatus.attention,
          'KM 151+000',
          700,
          220,
        ),
        (
          'M-210',
          MapLayer.maintenance,
          'Limpieza de drenaje',
          'Programado · 12 de 40 unidades',
          'Drenaje',
          PinStatus.attention,
          'KM 150+200',
          180,
          10,
        ),
        (
          'M-211',
          MapLayer.maintenance,
          'Repintado de marcas viales',
          'En ejecución · 60 %',
          'Señalización',
          PinStatus.normal,
          'KM 148+500',
          800,
          120,
        ),
        (
          'M-212',
          MapLayer.maintenance,
          'Sellado de grietas',
          'Programado',
          'Pavimento',
          PinStatus.normal,
          'KM 154+200',
          1900,
          260,
        ),
        (
          'O-031',
          MapLayer.works,
          'Ampliación de acostamiento',
          'Avance 35 %',
          'Obra',
          PinStatus.normal,
          'KM 149+000',
          500,
          75,
        ),
        (
          'O-032',
          MapLayer.works,
          'Refuerzo del puente',
          'Avance 80 % · con atraso',
          'Obra',
          PinStatus.attention,
          'KM 152+100',
          2600,
          190,
        ),
      ];

  /// Lo que dice una fila de la tabla: de que lado del telefono cae (este u
  /// oeste, por el rumbo) y en que sentido va (el que dice el subtitulo y, si
  /// no lo dice, el norte o el sur del rumbo).
  static (bool, TravelDirection) _placement(String subtitle, double bearing) {
    final rad = bearing * math.pi / 180;
    final direction = subtitle.contains('decreciente')
        ? TravelDirection.decreasing
        : subtitle.contains('creciente')
        ? TravelDirection.increasing
        : (math.cos(rad) >= 0
              ? TravelDirection.increasing
              : TravelDirection.decreasing);
    return (math.sin(rad) >= 0, direction);
  }

  /// Los pines repartidos a lo largo de la recta inventada que pasa por
  /// [center], cada uno a la distancia de la tabla.
  static Map<MapLayer, List<MapPin>> around(GeoPoint center) =>
      _build((meters, east, direction) {
        // Este u oeste a una distancia tal que el pin queda a `meters` del
        // telefono en linea recta, contando la separacion lateral del sentido.
        final along = math.sqrt(
          math.max(0, meters * meters - laneMeters * laneMeters),
        );
        final signed = east ? along : -along;
        return (
          onRoad(center, signed, direction),
          straightReachMeters + signed,
          2 * straightReachMeters,
        );
      });

  /// Los pines repartidos a lo largo de la calle real de [data], cada uno a la
  /// distancia de la tabla medida a lo largo de la calle (adelante o atras del
  /// punto de la calle mas cercano al telefono).
  static Map<MapLayer, List<MapPin>> aroundRoad(NearMeRoadData data) =>
      _build((meters, east, direction) {
        final length = data.axis!.length;
        final along = (data.phoneMeters + (east ? meters : -meters)).clamp(
          0.0,
          length,
        );
        return (data.pointAt(direction, along), along, length);
      });

  /// Arma los pines de la tabla. `place` da, para una fila, su posicion y a
  /// cuantos metros del inicio de la carretera (de largo `length`) esta: de ahi
  /// salen su tramo y su referencia kilometrica.
  static Map<MapLayer, List<MapPin>> _build(
    (GeoPoint, double, double) Function(
      double meters,
      bool east,
      TravelDirection direction,
    )
    place,
  ) {
    final result = {for (final l in MapLayer.values) l: <MapPin>[]};
    for (final (
          id,
          layer,
          title,
          subtitle,
          category,
          status,
          _,
          meters,
          bearing,
        )
        in _table) {
      final (east, direction) = _placement(subtitle, bearing);
      final (position, along, length) = place(meters, east, direction);
      result[layer]!.add(
        MapPin(
          id: id,
          layer: layer,
          title: title,
          subtitle: subtitle,
          category: category,
          kmLabel: kmLabelAt(along),
          segmentCode: codeAt(along, length),
          direction: direction,
          status: status,
          position: position,
        ),
      );
    }
    return result;
  }

  Future<Map<MapLayer, List<MapPin>>?> _resolve() async {
    final data = await road.resolve();
    if (data == null) return null;
    return data.isReal ? aroundRoad(data) : around(data.center);
  }

  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    final data = await (_data ??= _resolve());
    if (data == null) return fallback.pins(layer);
    return List.unmodifiable(data[layer] ?? const <MapPin>[]);
  }
}
