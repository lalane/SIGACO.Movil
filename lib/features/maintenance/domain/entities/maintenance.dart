import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Los indicadores de desempeno de la carretera (mockup "Seleccione un
/// indicador"): cada uno agrupa sus propios mantenimientos.
enum MaintenanceIndicator {
  /// Pavimentos.
  sgp,

  /// Senalizacion.
  sgs,

  /// Obras de arte especiales.
  sgoae,

  /// Obras de arte corrientes.
  sgoac,

  /// Equipos ITS.
  sgits,

  /// Conservacion (BBP §7.8: el selector de indicadores la lista entre SGITS y
  /// SGE).
  conservacion,

  /// Edificaciones e instalaciones.
  sge,

  /// Terraplenos y estructuras.
  sgtec,

  /// Sistemas electricos e iluminacion.
  sgsei,

  /// Tuneles.
  sgost,

  /// Faixa de dominio.
  sgf,
}

enum MaintenanceStatus { open, inProgress, closed }

/// Un mantenimiento de un indicador: que se hace, donde, cuanto lleva y cuanto
/// cuesta. La app lo consulta; las acciones operativas llegan despues (el
/// mockup cubre consulta e historial).
class MaintenanceOrder extends Equatable {
  const MaintenanceOrder({
    required this.id,
    required this.indicator,
    required this.title,
    required this.activity,
    required this.status,
    required this.totalVolume,
    required this.executedVolume,
    required this.unit,
    this.unitCost,
    this.programmedAmount,
    this.executedAmount,
    this.startDate,
    this.endDate,
    this.kmStart,
    this.kmEnd,
    this.direction,
    this.sense,
  });

  final String id;
  final MaintenanceIndicator indicator;

  /// Donde: `Tunel Norte - Portal Norte`.
  final String title;

  /// Que se hace: `Revision de luminarias LED`.
  final String activity;
  final MaintenanceStatus status;
  final double totalVolume;
  final double executedVolume;

  /// Unidad del volumen (`PZA`, `M2`).
  final String unit;
  final double? unitCost;
  final double? programmedAmount;
  final double? executedAmount;

  /// Fechas programadas, en UTC.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Cadenamiento tal como lo muestra el negocio (`016 + 100`).
  final String? kmStart;
  final String? kmEnd;
  final String? direction;
  final String? sense;

  /// Avance de 0 a 1 segun el volumen ejecutado.
  double get progress =>
      totalVolume <= 0 ? 0 : (executedVolume / totalVolume).clamp(0.0, 1.0);

  /// Lo que falta por ejecutar del importe programado.
  double? get pendingAmount {
    final programmed = programmedAmount;
    if (programmed == null) return null;
    return math.max(0, programmed - (executedAmount ?? 0));
  }

  /// Texto para buscar: ubicacion y actividad.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        activity.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [
    id,
    indicator,
    title,
    activity,
    status,
    totalVolume,
    executedVolume,
    unit,
    unitCost,
    programmedAmount,
    executedAmount,
    startDate,
    endDate,
    kmStart,
    kmEnd,
    direction,
    sense,
  ];
}
