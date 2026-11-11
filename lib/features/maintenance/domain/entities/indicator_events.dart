import 'maintenance.dart';

/// Un evento de indisponibilidad (SGITS) o una interrupción (SGSEI, SGOST) tal
/// como lo muestra la app.
class IndicatorEvent {
  const IndicatorEvent({
    required this.id,
    required this.folio,
    required this.assetCode,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.computableHours,
    required this.slaHours,
    required this.slaState,
    required this.cause,
  });

  final String id;
  final String folio;
  final String assetCode;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// PENDIENTE_APROBACION, VIGENTE, RECHAZADO o ANULADO.
  final String status;
  final double computableHours;
  final int? slaHours;

  /// EN_PLAZO, EN_RIESGO, EXCEDIDO o SIN_SLA.
  final String slaState;
  final String? cause;

  bool get open => endedAt == null;

  factory IndicatorEvent.fromJson(Map<String, dynamic> json) => IndicatorEvent(
    id: json['id'] as String,
    folio: json['folio'] as String? ?? '',
    assetCode: json['assetCode'] as String? ?? '?',
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
    status: json['status'] as String? ?? '',
    computableHours: (json['computableHours'] as num?)?.toDouble() ?? 0,
    slaHours: (json['slaHours'] as num?)?.toInt(),
    slaState: json['slaState'] as String? ?? 'SIN_SLA',
    cause: json['cause'] as String?,
  );
}

/// Resultado de un parámetro PER en el desempeño del indicador.
class IndicatorParameterStatus {
  const IndicatorParameterStatus({
    required this.code,
    required this.name,
    required this.status,
    required this.reason,
  });

  final String code;
  final String name;

  /// CUMPLE, NO_CUMPLE, NO_EVALUADO, NO_APLICA, PENDIENTE_VALIDACION o
  /// AUN_NO_EXIGIBLE.
  final String status;
  final String reason;

  factory IndicatorParameterStatus.fromJson(Map<String, dynamic> json) =>
      IndicatorParameterStatus(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? 'NO_EVALUADO',
        reason: json['reason'] as String? ?? '',
      );
}

/// Un activo del indicador para elegirlo al registrar un evento.
class IndicatorAssetOption {
  const IndicatorAssetOption({required this.id, required this.code});

  final String id;
  final String code;
}

/// Los indicadores de MC2 con ficha propia y cuáles registran eventos en campo
/// (DTF SGITS HU-ITS-04, SGSEI HU-SEI-07, SGOST HU-OST-06).
const mc2Indicators = {
  MaintenanceIndicator.sgits,
  MaintenanceIndicator.sge,
  MaintenanceIndicator.sgf,
  MaintenanceIndicator.sgost,
  MaintenanceIndicator.sgsei,
};

const mc2EventIndicators = {
  MaintenanceIndicator.sgits,
  MaintenanceIndicator.sgsei,
  MaintenanceIndicator.sgost,
};
