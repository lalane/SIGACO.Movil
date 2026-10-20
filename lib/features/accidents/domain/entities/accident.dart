import 'package:equatable/equatable.dart';

/// Los tipos de accidente del mockup (el catalogo final esta pendiente de
/// homologar, OI-33 del Business Blueprint).
enum AccidentType { collision, rollover, fire }

/// Cuanta atencion pide: el color sale de aqui (los colores de estatus son del
/// sistema, COL-05).
enum AccidentSeverity { low, medium, high }

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
  });

  final String title;
  final AccidentType type;
  final AccidentSeverity severity;
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
  ];
}
