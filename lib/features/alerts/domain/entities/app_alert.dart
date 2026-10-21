import 'package:equatable/equatable.dart';

/// Importancia de una alerta (se ve en el color y el icono; el estatus de los
/// registros tiene sus propios colores del sistema).
enum AlertSeverity { info, warning, critical }

/// Una alerta operativa para la persona (M05): lo que paso, cuando y, si apunta
/// a un registro, a cual. El destino se guarda como tipo e identificador y no
/// como ruta: la app decide a donde lleva segun lo que la persona puede ver.
class AppAlert extends Equatable {
  const AppAlert({
    required this.id,
    required this.title,
    required this.createdAt,
    this.body,
    this.read = false,
    this.severity = AlertSeverity.info,
    this.entityType,
    this.entityId,
  });

  final String id;
  final String title;
  final String? body;

  /// UTC; se muestra en la zona de la concesion (RN-04).
  final DateTime createdAt;
  final bool read;
  final AlertSeverity severity;

  /// A que registro apunta: `TICKET`, `ACCIDENT`, `INSPECTION`, `WORK`, `ASSET`
  /// o `MAINTENANCE`. Nulo si es solo informativa.
  final String? entityType;
  final String? entityId;

  AppAlert copyWith({bool? read}) => AppAlert(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    severity: severity,
    entityType: entityType,
    entityId: entityId,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    createdAt,
    read,
    severity,
    entityType,
    entityId,
  ];
}
