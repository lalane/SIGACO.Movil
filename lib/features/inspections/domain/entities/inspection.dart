import 'package:equatable/equatable.dart';

/// Los estados minimos de una inspeccion (M08, reglas de negocio).
enum InspectionStatus { pending, inProgress, attended, closed, cancelled }

/// La respuesta a un punto del checklist.
enum CheckResult { pending, ok, finding }

/// Un punto del checklist: lo que hay que revisar y si un hallazgo en el es
/// critico (un hallazgo critico debe generar ticket o alerta, M08-CA-04).
class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.text,
    this.critical = false,
    this.result = CheckResult.pending,
  });

  final String id;
  final String text;
  final bool critical;
  final CheckResult result;

  ChecklistItem withResult(CheckResult value) =>
      ChecklistItem(id: id, text: text, critical: critical, result: value);

  @override
  List<Object?> get props => [id, text, critical, result];
}

/// Una inspeccion asignada: que se revisa, donde, quien y su checklist. La app
/// la consulta y la llena en campo; la configuracion de tipos y formularios es
/// de la plataforma web.
class Inspection extends Equatable {
  const Inspection({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.checklist,
    this.scheduledAt,
    this.completedAt,
    this.assignee,
    this.assetId,
    this.assetName,
    this.kmLabel,
    this.segmentCode,
    this.direction,
  });

  final String id;
  final String title;

  /// Tipo de inspeccion (`Señalización`); decide el formulario.
  final String type;
  final InspectionStatus status;
  final List<ChecklistItem> checklist;

  /// Fechas, en UTC.
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? assignee;

  /// El activo inspeccionado, si es de inventario.
  final String? assetId;
  final String? assetName;
  final String? kmLabel;
  final String? segmentCode;

  /// Sentido de la carretera, tal como lo entrega el servidor.
  final String? direction;

  /// Solo se llena mientras esta pendiente o en proceso.
  bool get editable =>
      status == InspectionStatus.pending ||
      status == InspectionStatus.inProgress;

  int get answered =>
      checklist.where((i) => i.result != CheckResult.pending).length;

  bool get complete => checklist.isNotEmpty && answered == checklist.length;

  /// Avance del checklist, de 0 a 1.
  double get progress => checklist.isEmpty ? 0 : answered / checklist.length;

  int get findings =>
      checklist.where((i) => i.result == CheckResult.finding).length;

  /// Hallazgos de puntos criticos: piden ticket o alerta.
  int get criticalFindings => checklist
      .where((i) => i.critical && i.result == CheckResult.finding)
      .length;

  Inspection copyWith({
    InspectionStatus? status,
    DateTime? completedAt,
    List<ChecklistItem>? checklist,
  }) => Inspection(
    id: id,
    title: title,
    type: type,
    status: status ?? this.status,
    checklist: checklist ?? this.checklist,
    scheduledAt: scheduledAt,
    completedAt: completedAt ?? this.completedAt,
    assignee: assignee,
    assetId: assetId,
    assetName: assetName,
    kmLabel: kmLabel,
    segmentCode: segmentCode,
    direction: direction,
  );

  /// La misma inspeccion con las respuestas dadas (`itemId` -> resultado); los
  /// puntos que no vienen conservan la suya.
  Inspection withAnswers(Map<String, CheckResult> answers) => copyWith(
    checklist: [
      for (final item in checklist)
        item.withResult(answers[item.id] ?? item.result),
    ],
  );

  /// Texto para buscar: nombre, activo, tipo, tramo y quien la hace.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      id,
      title,
      type,
      assetName,
      segmentCode,
      kmLabel,
      assignee,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    status,
    checklist,
    scheduledAt,
    completedAt,
    assignee,
    assetId,
    assetName,
    kmLabel,
    segmentCode,
    direction,
  ];
}
