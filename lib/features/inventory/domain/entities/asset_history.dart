import 'package:equatable/equatable.dart';

/// Los registros de la operacion que se ligan a un activo: su "historia
/// operativa". Cada uno vive en su modulo; la ficha del activo solo los resume.
enum AssetHistoryKind { tickets, inspections, maintenances }

/// Cuantos registros de un tipo tiene el activo y cuantos siguen abiertos.
///
/// "Abierto" es la regla del servidor: un ticket SIN_VALIDAR o ABIERTO (DTF
/// M11 v0.3; ATENDIDO ya no cuenta, es la misma regla de "en
/// mantenimiento"); una inspeccion que no esta CERRADA ni CANCELADA; un
/// mantenimiento PROGRAMADO o EN_EJECUCION.
class AssetHistoryCount extends Equatable {
  const AssetHistoryCount({required this.open, required this.total});

  final int open;
  final int total;

  @override
  List<Object?> get props => [open, total];
}

/// Los conteos de la ficha (`operationalHistory` de `GET /api/assets/{id}`).
/// Un tipo en null es que la persona no puede ver ese modulo: no se muestra.
class AssetHistoryCounts extends Equatable {
  const AssetHistoryCounts({this.tickets, this.inspections, this.maintenances});

  final AssetHistoryCount? tickets;
  final AssetHistoryCount? inspections;
  final AssetHistoryCount? maintenances;

  AssetHistoryCount? of(AssetHistoryKind kind) => switch (kind) {
    AssetHistoryKind.tickets => tickets,
    AssetHistoryKind.inspections => inspections,
    AssetHistoryKind.maintenances => maintenances,
  };

  /// Los tipos que la persona puede ver, en el orden de la ficha.
  List<AssetHistoryKind> get visible => [
    for (final k in AssetHistoryKind.values)
      if (of(k) != null) k,
  ];

  @override
  List<Object?> get props => [tickets, inspections, maintenances];
}

/// Un registro de la historia, resumido para la ficha del activo.
class AssetHistoryEntry extends Equatable {
  const AssetHistoryEntry({
    required this.id,
    required this.kind,
    required this.folio,
    required this.status,
    this.title,
    this.date,
    this.dateOnly = false,
    this.responsible,
    this.overdue = false,
    this.subsystemCode,
  });

  final String id;
  final AssetHistoryKind kind;

  /// El folio del registro (`TK-2026-000123`).
  final String folio;

  /// El codigo del estado tal como lo da el servidor (`EN_PROCESO`).
  final String status;

  /// La falla del ticket, el tipo de inspeccion o la actividad del
  /// mantenimiento.
  final String? title;

  /// La fecha clave, en UTC: la deteccion del ticket, la ejecucion (o la
  /// programacion) de la inspeccion y el fin (o el inicio) del mantenimiento.
  final DateTime? date;

  /// La fecha es un dia sin hora.
  final bool dateOnly;

  /// Quien lo atiende: el responsable del ticket o del mantenimiento, o el
  /// inspector.
  final String? responsible;

  /// Vencido: el SLA del ticket o el fin programado del mantenimiento ya paso.
  final bool overdue;

  /// El indicador del registro (abre el mantenimiento en su indicador).
  final String? subsystemCode;

  @override
  List<Object?> get props => [
    id,
    kind,
    folio,
    status,
    title,
    date,
    dateOnly,
    responsible,
    overdue,
    subsystemCode,
  ];
}

/// Los ultimos registros de un tipo y cuantos hay en total.
class AssetHistoryPage extends Equatable {
  const AssetHistoryPage({required this.items, required this.total});

  final List<AssetHistoryEntry> items;
  final int total;

  @override
  List<Object?> get props => [items, total];
}
