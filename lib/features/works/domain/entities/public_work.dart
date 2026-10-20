import 'dart:math' as math;

import 'package:equatable/equatable.dart';

enum WorkStatus { notStarted, inProgress, delayed, finished }

/// Una obra o programa de conservacion (M06, "Avance de obras"): lo que la app
/// consulta. El alta y el seguimiento financiero son de la plataforma web.
class PublicWork extends Equatable {
  const PublicWork({
    required this.id,
    required this.name,
    required this.status,
    required this.physicalProgress,
    required this.programmedProgress,
    this.description,
    this.contractor,
    this.budget,
    this.executedAmount,
    this.startDate,
    this.endDate,
    this.kmStart,
    this.kmEnd,
    this.segmentCode,
    this.direction,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final WorkStatus status;

  /// Avance real y avance que tocaba segun el programa, de 0 a 1.
  final double physicalProgress;
  final double programmedProgress;
  final String? description;
  final String? contractor;
  final double? budget;
  final double? executedAmount;

  /// Fechas programadas, en UTC.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Cadenamiento tal como lo muestra el negocio (`KM 149+000`).
  final String? kmStart;
  final String? kmEnd;
  final String? segmentCode;

  /// Sentido de la carretera, tal como lo entrega el servidor.
  final String? direction;

  /// Donde esta; sin ella no se puede abrir en el mapa.
  final double? latitude;
  final double? longitude;

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;

  /// Lo que lleva de menos respecto del programa, de 0 a 1 (0 si va al dia o
  /// adelantada).
  double get lag => math.max(0, programmedProgress - physicalProgress);

  /// Lo que falta por ejercer del presupuesto.
  double? get pendingAmount {
    final total = budget;
    if (total == null) return null;
    return math.max(0, total - (executedAmount ?? 0));
  }

  /// Texto para buscar: nombre, codigo, contratista y tramo.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      id,
      name,
      contractor,
      segmentCode,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    physicalProgress,
    programmedProgress,
    description,
    contractor,
    budget,
    executedAmount,
    startDate,
    endDate,
    kmStart,
    kmEnd,
    segmentCode,
    direction,
    latitude,
    longitude,
  ];
}
