import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Los indicadores de desempeno de la carretera (los mismos ocho de
/// mantenimiento; aqui son los que se pueden reportar).
/// Los 11 indicadores del BBP (§7.8), en el orden del selector.
enum ReportIndicator {
  sgp,
  sgs,
  sgoae,
  sgoac,
  sgits,
  conservacion,
  sge,
  sgtec,
  sgsei,
  sgost,
  sgf,
}

enum ReportLineStatus { open, inProgress, closed }

/// Una linea del reporte: una actividad del indicador con su avance e importes.
class ReportLine extends Equatable {
  const ReportLine({
    required this.id,
    required this.indicator,
    required this.title,
    required this.activity,
    required this.status,
    required this.totalVolume,
    required this.executedVolume,
    required this.unit,
    this.programmedAmount,
    this.executedAmount,
    this.startDate,
    this.endDate,
  });

  final String id;
  final ReportIndicator indicator;
  final String title;
  final String activity;
  final ReportLineStatus status;
  final double totalVolume;
  final double executedVolume;
  final String unit;
  final double? programmedAmount;
  final double? executedAmount;

  /// Fechas, en UTC.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Avance de 0 a 1 segun el volumen ejecutado.
  double get progress =>
      totalVolume <= 0 ? 0 : (executedVolume / totalVolume).clamp(0.0, 1.0);

  /// Si empieza dentro del periodo. Sin periodo entran todas; con periodo, las
  /// que no tienen fecha de inicio quedan fuera. Los limites son dias de
  /// calendario, ambos incluidos.
  bool startsIn(DateTime? from, DateTime? to) {
    if (from == null && to == null) return true;
    final start = startDate;
    if (start == null) return false;
    final day = DateTime.utc(start.year, start.month, start.day);
    if (from != null &&
        day.isBefore(DateTime.utc(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime.utc(to.year, to.month, to.day))) {
      return false;
    }
    return true;
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
    programmedAmount,
    executedAmount,
    startDate,
    endDate,
  ];
}

/// El reporte de un indicador en un periodo (APP-MOB-02): las actividades del
/// indicador que empiezan dentro del periodo y lo que suman. Se consulta en la
/// app; la exportacion llega despues.
class IndicatorReport extends Equatable {
  const IndicatorReport({
    required this.indicator,
    required this.generatedAt,
    required this.lines,
    this.from,
    this.to,
  });

  final ReportIndicator indicator;

  /// Cuando se genero, en UTC.
  final DateTime generatedAt;

  /// Dias de calendario del periodo (ambos incluidos); null = sin limite.
  final DateTime? from;
  final DateTime? to;

  /// Las actividades del periodo, la mas reciente primero.
  final List<ReportLine> lines;

  int get total => lines.length;

  int count(ReportLineStatus s) => lines.where((o) => o.status == s).length;

  double get programmedAmount =>
      lines.fold(0.0, (sum, o) => sum + (o.programmedAmount ?? 0));

  double get executedAmount =>
      lines.fold(0.0, (sum, o) => sum + (o.executedAmount ?? 0));

  /// Lo que falta por ejecutar del importe programado.
  double get pendingAmount => math.max(0, programmedAmount - executedAmount);

  /// Importe ejecutado entre el programado, de 0 a 1.
  double get execution => programmedAmount <= 0
      ? 0
      : (executedAmount / programmedAmount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [indicator, generatedAt, from, to, lines];
}
