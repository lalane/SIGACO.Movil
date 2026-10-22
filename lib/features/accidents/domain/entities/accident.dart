import 'package:equatable/equatable.dart';

/// Los tipos de accidente del BBP (§7.8, formulario "Accidentes graves"): choque,
/// volcamiento, atropello, incendio y otro. El catalogo definitivo sigue
/// pendiente de homologar (OI-33).
enum AccidentType { collision, rollover, runOver, fire, other }

/// Gravedad de una victima segun el BBP: ileso, lesiones menores, heridas graves
/// y deceso. La del accidente es la de su victima mas grave; el color sale de
/// aqui (los colores de estatus son del sistema, COL-05).
enum AccidentSeverity { unharmed, minor, serious, fatal }

/// Zona donde ocurrio.
enum AccidentZone { rural, suburban, urban }

/// Clima al momento del accidente.
enum AccidentWeather { wind, rain, fog, normal }

/// Estado del pavimento o del senalamiento. El BBP lista Buena, Regular y Malo
/// para el pavimento; para el senalamiento no da opciones y se usa la misma
/// escala (supuesto por confirmar).
enum RoadCondition { good, fair, poor }

/// Trazado de la via.
enum RoadLayout { straight, verticalCurve, horizontalCurve }

/// Tipo de pavimento.
enum PavementType { rigid, flexible }

/// Causa del accidente.
enum AccidentCause { speeding, laneInvasion, other }

/// Donde ocurrio el accidente.
enum AccidentPlace { pavement, signage, tollBooth, other }

/// Tipo de vehiculo involucrado.
enum VehicleType { vehicle, motorcycle, livestock, fixedObject }

/// Sexo de la victima. El BBP no lista las opciones: se usan femenino,
/// masculino y no especificado (supuesto por confirmar).
enum VictimSex { female, male, unspecified }

/// Un vehiculo involucrado (el formulario se repite por cada uno).
class AccidentVehicle extends Equatable {
  const AccidentVehicle({required this.type});

  final VehicleType type;

  @override
  List<Object?> get props => [type];
}

/// Una victima (el formulario se repite por cada una).
class AccidentVictim extends Equatable {
  const AccidentVictim({required this.severity, this.sex});

  final AccidentSeverity severity;
  final VictimSex? sex;

  /// La gravedad del accidente: la de su victima mas grave; sin victimas, ileso.
  static AccidentSeverity worst(Iterable<AccidentVictim> victims) {
    var worst = AccidentSeverity.unharmed;
    for (final v in victims) {
      if (v.severity.index > worst.index) worst = v.severity;
    }
    return worst;
  }

  @override
  List<Object?> get props => [severity, sex];
}

enum AccidentStatus { registered, inProgress, closed }

/// Un accidente grave en la carretera. La app movil lo consulta y lo registra;
/// la atencion y el cierre siguen otro flujo (pendiente de homologacion).
class Accident extends Equatable {
  const Accident({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.description,
    this.authorName,
    this.authorProfile,
    this.company,
    this.concessionName,
    this.kmLabel,
    this.latitude,
    this.longitude,
    this.carriageway,
    this.photoPaths = const [],
    this.zone,
    this.weather,
    this.pavementCondition,
    this.layout,
    this.pavementType,
    this.signageCondition,
    this.cause,
    this.place,
    this.vehicles = const [],
    this.victims = const [],
  });

  final String id;

  /// El numero que se ve y se dicta (`0035`).
  final String code;
  final String title;
  final AccidentType type;
  final AccidentSeverity severity;
  final AccidentStatus status;

  /// Cuando se registro, en UTC.
  final DateTime createdAt;
  final String? description;
  final String? authorName;
  final String? authorProfile;
  final String? company;
  final String? concessionName;

  /// Cadenamiento tal como lo muestra el negocio (`KM 513+615`).
  final String? kmLabel;
  final double? latitude;
  final double? longitude;

  /// Cuerpo de la carretera (`A`, `B`).
  final String? carriageway;
  final List<String> photoPaths;

  /// Condiciones del lugar (BBP §7.8); nulas si no se capturaron.
  final AccidentZone? zone;
  final AccidentWeather? weather;
  final RoadCondition? pavementCondition;
  final RoadLayout? layout;
  final PavementType? pavementType;
  final RoadCondition? signageCondition;
  final AccidentCause? cause;
  final AccidentPlace? place;
  final List<AccidentVehicle> vehicles;
  final List<AccidentVictim> victims;

  /// Texto para buscar: titulo, numero, cadenamiento y descripcion.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      code,
      kmLabel,
      description,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    type,
    severity,
    status,
    createdAt,
    description,
    authorName,
    authorProfile,
    company,
    concessionName,
    kmLabel,
    latitude,
    longitude,
    carriageway,
    photoPaths,
    zone,
    weather,
    pavementCondition,
    layout,
    pavementType,
    signageCondition,
    cause,
    place,
    vehicles,
    victims,
  ];
}

/// Lo que la persona captura para registrar un accidente.
class NewAccident extends Equatable {
  const NewAccident({
    required this.title,
    required this.type,
    required this.severity,
    this.kmLabel,
    this.description,
    this.photoPaths = const [],
    this.capturedAt,
    this.deviceClockAt,
    this.clientId,
    this.zone,
    this.weather,
    this.pavementCondition,
    this.layout,
    this.pavementType,
    this.signageCondition,
    this.cause,
    this.place,
    this.vehicles = const [],
    this.victims = const [],
  });

  final String title;
  final AccidentType type;

  /// La de la victima mas grave ([AccidentVictim.worst]).
  final AccidentSeverity severity;
  final AccidentZone? zone;
  final AccidentWeather? weather;
  final RoadCondition? pavementCondition;
  final RoadLayout? layout;
  final PavementType? pavementType;
  final RoadCondition? signageCondition;
  final AccidentCause? cause;
  final AccidentPlace? place;
  final List<AccidentVehicle> vehicles;
  final List<AccidentVictim> victims;
  final String? kmLabel;
  final String? description;
  final List<String> photoPaths;

  /// Cuando se abrio el formulario, en UTC (RN-12 y RN-14): no depende de la
  /// zona del telefono. Es la hora del registro.
  final DateTime? capturedAt;

  /// La hora del reloj del telefono al enviar, en UTC (RN-15).
  final DateTime? deviceClockAt;

  /// Identificador unico que genera el telefono (`cliente_uuid`): evita
  /// duplicados si el registro se sincroniza dos veces.
  final String? clientId;

  @override
  List<Object?> get props => [
    title,
    type,
    severity,
    kmLabel,
    description,
    photoPaths,
    capturedAt,
    deviceClockAt,
    clientId,
    zone,
    weather,
    pavementCondition,
    layout,
    pavementType,
    signageCondition,
    cause,
    place,
    vehicles,
    victims,
  ];
}
