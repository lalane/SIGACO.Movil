import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/map_repository.dart';
import 'sample_road_segments_repository.dart';

/// Pines de ejemplo sobre los cinco tramos de la BR-381 (km 146.9 a 164.9,
/// cerca de Governador Valadares), para ver el mapa mientras el backend no
/// publica los suyos. Cada pin cae **sobre la linea de su tramo y su sentido**
/// ([SampleRoadSegmentsRepository]), en el kilometro que dice su referencia:
/// asi se ve que los elementos estan dentro del tramo. Los extremos son los que
/// entrego la API de pistas de Strata; no son activos reales.
class SampleMapRepository implements MapRepository {
  SampleMapRepository({this.delay = Duration.zero});

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  // Extremos del tramo en la API de pistas: km 146.9 y km 155.9.
  static const _kmStart = 146.9;
  static const _kmEnd = 155.9;
  static const _start = GeoPoint(-18.846134, -41.980668);
  static const _end = GeoPoint(-18.91539, -42.011285);

  /// Posicion sobre el eje entre los extremos para un kilometro, con un
  /// desplazamiento lateral pequeno (en grados).
  static GeoPoint at(double km, {double dLat = 0, double dLon = 0}) {
    final t = ((km - _kmStart) / (_kmEnd - _kmStart)).clamp(0.0, 1.0);
    return GeoPoint(
      _start.latitude + (_end.latitude - _start.latitude) * t + dLat,
      _start.longitude + (_end.longitude - _start.longitude) * t + dLon,
    );
  }

  static String _km(double km) {
    final whole = km.floor();
    final meters = ((km - whole) * 1000).round();
    return 'KM $whole+${meters.toString().padLeft(3, '0')}';
  }

  /// Un pin sobre la linea de su tramo: el codigo del tramo y la posicion salen
  /// del kilometro y del sentido.
  static MapPin _pin(
    String id,
    MapLayer layer,
    String title,
    double km, {
    String? subtitle,
    String? category,
    PinStatus status = PinStatus.normal,
    TravelDirection direction = TravelDirection.increasing,
  }) => MapPin(
    id: id,
    layer: layer,
    title: title,
    subtitle: subtitle,
    category: category,
    kmLabel: _km(km),
    segmentCode: SampleRoadSegmentsRepository.codeAt(km),
    direction: direction,
    status: status,
    // Solo los equipos (inventario) tienen estado operativo.
    operatingState: layer == MapLayer.inventory
        ? (_operating[id] ?? OperatingState.inOperation)
        : null,
    position: SampleRoadSegmentsRepository.pointAt(km, direction),
  );

  /// Equipos que no estan en operacion; los demas si lo estan.
  static const _operating = {
    'A-004': OperatingState.inMaintenance,
    'A-008': OperatingState.inMaintenance,
    'A-005': OperatingState.outOfService,
  };

  static final Map<MapLayer, List<MapPin>> _data = {
    MapLayer.inventory: [
      _pin(
        'A-001',
        MapLayer.inventory,
        'Defensa metálica',
        147.2,
        subtitle: 'Sentido creciente',
        category: 'Defensa metálica',
      ),
      _pin(
        'A-002',
        MapLayer.inventory,
        'Señal vertical SV-114',
        148.0,
        subtitle: 'Sentido decreciente',
        category: 'Señal vertical',
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'A-003',
        MapLayer.inventory,
        'Barrera New Jersey',
        149.4,
        subtitle: 'Sentido creciente',
        category: 'Barrera',
      ),
      _pin(
        'A-004',
        MapLayer.inventory,
        'Descida d\'água DA-22',
        150.2,
        subtitle: 'Lado derecho',
        category: 'Drenaje',
      ),
      _pin(
        'A-005',
        MapLayer.inventory,
        'Poste de iluminación P-310',
        150.35,
        subtitle: 'Sentido decreciente',
        category: 'Iluminación',
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'A-006',
        MapLayer.inventory,
        'OAE puente sobre arroyo',
        152.1,
        subtitle: 'Obra de arte especial',
        category: 'OAE',
      ),
      _pin(
        'A-007',
        MapLayer.inventory,
        'Señal vertical SV-131',
        153.6,
        subtitle: 'Sentido creciente',
        category: 'Señal vertical',
      ),
      _pin(
        'A-008',
        MapLayer.inventory,
        'Defensa metálica',
        155.4,
        subtitle: 'Sentido decreciente',
        category: 'Defensa metálica',
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'A-009',
        MapLayer.inventory,
        'Defensa metálica',
        156.8,
        subtitle: 'Sentido creciente',
        category: 'Defensa metálica',
      ),
      _pin(
        'A-010',
        MapLayer.inventory,
        'Señal vertical SV-152',
        157.9,
        subtitle: 'Sentido decreciente',
        category: 'Señal vertical',
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'A-011',
        MapLayer.inventory,
        'Poste de iluminación P-420',
        160.1,
        subtitle: 'Sentido creciente',
        category: 'Iluminación',
      ),
      _pin(
        'A-012',
        MapLayer.inventory,
        'Alcantarilla AL-07',
        163.2,
        subtitle: 'Sentido decreciente',
        category: 'Drenaje',
        direction: TravelDirection.decreasing,
      ),
    ],
    MapLayer.tickets: [
      _pin(
        'T-1041',
        MapLayer.tickets,
        'Defensa dañada',
        147.2,
        subtitle: 'Abierto · prioridad alta',
        category: 'Daño',
        status: PinStatus.critical,
      ),
      _pin(
        'T-1042',
        MapLayer.tickets,
        'Señal ilegible',
        153.6,
        subtitle: 'Abierto',
        category: 'Señalización',
        status: PinStatus.attention,
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'T-1043',
        MapLayer.tickets,
        'Bache en el acostamiento',
        151.0,
        subtitle: 'Abierto',
        category: 'Pavimento',
        status: PinStatus.attention,
      ),
      _pin(
        'T-1045',
        MapLayer.tickets,
        'Bache profundo',
        157.2,
        subtitle: 'Abierto',
        category: 'Pavimento',
        status: PinStatus.attention,
      ),
      _pin(
        'T-1046',
        MapLayer.tickets,
        'Talud inestable',
        160.8,
        subtitle: 'Abierto · prioridad alta',
        category: 'Daño',
        status: PinStatus.critical,
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'T-1047',
        MapLayer.tickets,
        'Señal caída',
        163.9,
        subtitle: 'Abierto',
        category: 'Señalización',
        status: PinStatus.attention,
      ),
    ],
    MapLayer.maintenance: [
      _pin(
        'M-210',
        MapLayer.maintenance,
        'Limpieza de drenaje',
        150.2,
        subtitle: 'Programado · 12 de 40 unidades',
        category: 'Drenaje',
        status: PinStatus.attention,
      ),
      _pin(
        'M-211',
        MapLayer.maintenance,
        'Repintado de marcas viales',
        148.5,
        subtitle: 'En ejecución · 60 %',
        category: 'Señalización',
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'M-212',
        MapLayer.maintenance,
        'Sellado de grietas',
        154.2,
        subtitle: 'Programado',
        category: 'Pavimento',
      ),
      _pin(
        'M-213',
        MapLayer.maintenance,
        'Limpieza de cunetas',
        158.2,
        subtitle: 'Programado',
        category: 'Drenaje',
      ),
      _pin(
        'M-214',
        MapLayer.maintenance,
        'Reposición de barrera',
        162.5,
        subtitle: 'En ejecución · 30 %',
        category: 'Barrera',
        direction: TravelDirection.decreasing,
      ),
    ],
    MapLayer.works: [
      _pin(
        'O-031',
        MapLayer.works,
        'Ampliación de acostamiento',
        149.0,
        subtitle: 'Avance 35 %',
        category: 'Obra',
      ),
      _pin(
        'O-032',
        MapLayer.works,
        'Refuerzo del puente',
        152.1,
        subtitle: 'Avance 80 % · con atraso',
        category: 'Obra',
        status: PinStatus.attention,
        direction: TravelDirection.decreasing,
      ),
      _pin(
        'O-033',
        MapLayer.works,
        'Estabilización de talud',
        160.8,
        subtitle: 'Avance 50 %',
        category: 'Obra',
      ),
    ],
  };

  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return List.unmodifiable(_data[layer] ?? const <MapPin>[]);
  }
}
