import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/time/concession_zone.dart';
import '../../../core/ui/module_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/asset_history.dart';
import '../domain/entities/asset_template.dart';
import '../domain/entities/inventory_asset.dart';

String conditionLabel(AppLocalizations l10n, AssetCondition c) => switch (c) {
  AssetCondition.unknown => l10n.invConditionUnknown,
  AssetCondition.good => l10n.invConditionGood,
  AssetCondition.regular => l10n.invConditionRegular,
  AssetCondition.poor => l10n.invConditionPoor,
};

String conditionStatLabel(AppLocalizations l10n, AssetCondition c) =>
    switch (c) {
      AssetCondition.unknown => l10n.invConditionUnknown,
      AssetCondition.good => l10n.invStatGood,
      AssetCondition.regular => l10n.invStatRegular,
      AssetCondition.poor => l10n.invStatPoor,
    };

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color conditionColor(AssetCondition c) => switch (c) {
  AssetCondition.unknown => const Color(0xFF94A3B8),
  AssetCondition.good => StatusColors.closed,
  AssetCondition.regular => StatusColors.attended,
  AssetCondition.poor => StatusColors.open,
};

String lifecycleLabel(AppLocalizations l10n, AssetLifecycle s) => switch (s) {
  AssetLifecycle.pendingValidation => l10n.invLifecyclePending,
  AssetLifecycle.active => l10n.invLifecycleActive,
  AssetLifecycle.outOfService => l10n.invLifecycleOutOfService,
  AssetLifecycle.inactive => l10n.invLifecycleInactive,
  AssetLifecycle.decommissioned => l10n.invLifecycleDecommissioned,
  AssetLifecycle.discarded => l10n.invLifecycleDiscarded,
};

/// Pendiente pide atencion (amarillo); fuera de servicio, rojo; lo inactivo,
/// gris; lo activo, verde.
Color lifecycleColor(AssetLifecycle s) => switch (s) {
  AssetLifecycle.pendingValidation => StatusColors.attended,
  AssetLifecycle.active => StatusColors.closed,
  AssetLifecycle.outOfService => StatusColors.open,
  AssetLifecycle.inactive ||
  AssetLifecycle.decommissioned ||
  AssetLifecycle.discarded => const Color(0xFF94A3B8),
};

/// "En mantenimiento": tiene un ticket abierto (no es un estado).
const maintenanceColor = Color(0xFF60A5FA);

/// El nombre de un tipo de la historia operativa.
String historyKindLabel(AppLocalizations l10n, AssetHistoryKind k) =>
    switch (k) {
      AssetHistoryKind.tickets => l10n.invHistoryTickets,
      AssetHistoryKind.inspections => l10n.invHistoryInspections,
      AssetHistoryKind.maintenances => l10n.invHistoryMaintenances,
    };

/// "Este activo no tiene ..." de un tipo de la historia.
String historyEmptyLabel(AppLocalizations l10n, AssetHistoryKind k) =>
    switch (k) {
      AssetHistoryKind.tickets => l10n.invHistoryEmptyTickets,
      AssetHistoryKind.inspections => l10n.invHistoryEmptyInspections,
      AssetHistoryKind.maintenances => l10n.invHistoryEmptyMaintenances,
    };

IconData historyKindIcon(AssetHistoryKind k) => switch (k) {
  AssetHistoryKind.tickets => Icons.confirmation_number_outlined,
  AssetHistoryKind.inspections => Icons.fact_check_outlined,
  AssetHistoryKind.maintenances => Icons.build_outlined,
};

/// El estado de un registro de la historia, con los codigos del servidor de su
/// modulo; uno que no se conoce se muestra legible (`EN_PROCESO` -> "En
/// proceso").
String historyStatusLabel(
  AppLocalizations l10n,
  AssetHistoryKind kind,
  String code,
) {
  final label = switch ((kind, code)) {
    (AssetHistoryKind.tickets, 'NUEVO') => l10n.invHistTkNew,
    (AssetHistoryKind.tickets, 'ASIGNADO') => l10n.invHistTkAssigned,
    (AssetHistoryKind.tickets, 'EN_PROCESO') => l10n.invHistTkInProgress,
    (AssetHistoryKind.tickets, 'EN_ESPERA') => l10n.invHistTkOnHold,
    (AssetHistoryKind.tickets, 'REABIERTO') => l10n.invHistTkReopened,
    (AssetHistoryKind.tickets, 'RESUELTO') => l10n.invHistTkResolved,
    (AssetHistoryKind.tickets, 'CERRADO') => l10n.invHistTkClosed,
    (AssetHistoryKind.tickets, 'CANCELADO') => l10n.invHistTkCancelled,
    (AssetHistoryKind.inspections, 'PENDIENTE') => l10n.invHistInPending,
    (AssetHistoryKind.inspections, 'ASIGNADA') => l10n.invHistInAssigned,
    (AssetHistoryKind.inspections, 'EN_PROCESO') => l10n.invHistInInProgress,
    (AssetHistoryKind.inspections, 'ATENDIDA') => l10n.invHistInAttended,
    (AssetHistoryKind.inspections, 'EN_REVISION') => l10n.invHistInReview,
    (AssetHistoryKind.inspections, 'CERRADA') => l10n.invHistInClosed,
    (AssetHistoryKind.inspections, 'CANCELADA') => l10n.invHistInCancelled,
    (AssetHistoryKind.maintenances, 'PROGRAMADO') => l10n.invHistMpScheduled,
    (AssetHistoryKind.maintenances, 'EN_EJECUCION') =>
      l10n.invHistMpInExecution,
    (AssetHistoryKind.maintenances, 'COMPLETADO') => l10n.invHistMpCompleted,
    (AssetHistoryKind.maintenances, 'CANCELADO') => l10n.invHistMpCancelled,
    _ => null,
  };
  if (label != null) return label;
  final text = code.replaceAll('_', ' ').toLowerCase();
  return text.isEmpty ? '—' : text[0].toUpperCase() + text.substring(1);
}

/// Los colores de estatus son del sistema: lo que nadie ha empezado es rojo,
/// lo que se esta trabajando o espera revision es ambar, lo terminado verde y
/// lo cancelado gris.
Color historyStatusColor(String code) => switch (code) {
  'NUEVO' || 'ASIGNADO' || 'REABIERTO' || 'PROGRAMADO' => StatusColors.open,
  'PENDIENTE' || 'ASIGNADA' => StatusColors.open,
  'EN_PROCESO' ||
  'EN_ESPERA' ||
  'RESUELTO' ||
  'ATENDIDA' ||
  'EN_REVISION' ||
  'EN_EJECUCION' => StatusColors.attended,
  'CERRADO' || 'CERRADA' || 'COMPLETADO' => StatusColors.closed,
  _ => const Color(0xFF94A3B8),
};

String? statusReasonLabel(AppLocalizations l10n, String? reason) =>
    switch (reason?.toUpperCase()) {
      'CAPA_RETIRADA' => l10n.invStatusReasonLayerRemoved,
      'DESAPARECIO_DEL_ORIGEN' => l10n.invStatusReasonGone,
      null => null,
      _ => reason,
    };

/// De donde nacio el activo.
String sourceLabel(AppLocalizations l10n, String source) =>
    switch (source.toUpperCase()) {
      'MOVIL' || 'MOBILE' || 'APP' => l10n.invSourceMobile,
      'INDIVIDUAL' || 'WEB' => l10n.invSourceWeb,
      'MASIVA' || 'BULK' || 'CARGA_MASIVA' => l10n.invSourceBulk,
      'WEBGIS' => l10n.invSourceWebGis,
      _ => source,
    };

/// Un numero sin ceros de sobra (`12`, `12.5`).
String plainNumber(num value) {
  final d = value.toDouble();
  if (d == d.truncateToDouble()) return d.toInt().toString();
  return d.toString();
}

/// El valor de un campo de la ficha como se lee: numeros con su unidad, si/no,
/// fechas en la zona de la concesion y el nombre del valor de catalogo.
String attributeValueText(
  AppLocalizations l10n,
  AttributeDefinition? field,
  Object? value, {
  required ConcessionZone? zone,
  String? Function(String catalogCode, String valueCode)? catalogLabel,
}) {
  const none = '—';
  if (value == null || (value is String && value.trim().isEmpty)) return none;
  final unit = field?.unit;
  String withUnit(String v) => unit == null ? v : '$v $unit';
  switch (field?.type) {
    case AttributeType.boolean:
      final b = value is bool
          ? value
          : '$value'.toLowerCase() == 'true' || '$value' == '1';
      return b ? l10n.invYes : l10n.invNo;
    case AttributeType.integer:
    case AttributeType.decimal:
      final n = AttributeDefinition.parseNumber(value);
      return withUnit(n == null ? '$value' : plainNumber(n));
    case AttributeType.date:
      final d = DateTime.tryParse('$value');
      return d == null ? '$value' : DateFormat('dd/MM/yyyy').format(d);
    case AttributeType.dateTime:
      final d = DateTime.tryParse('$value');
      return d == null ? '$value' : moduleDate(d.toUtc(), zone);
    case AttributeType.catalog:
      final code = '$value';
      final catalog = field?.catalogCode;
      return catalog == null
          ? code
          : (catalogLabel?.call(catalog, code) ?? code);
    case AttributeType.text:
    case AttributeType.unknown:
    case null:
      if (value is num) return withUnit(plainNumber(value));
      if (value is bool) return value ? l10n.invYes : l10n.invNo;
      return withUnit('$value');
  }
}

/// Lo que no sirve de un campo, para mostrarlo bajo el.
String attributeIssueText(
  AppLocalizations l10n,
  AttributeDefinition field,
  AttributeIssue issue,
) => switch (issue) {
  AttributeIssue.required => l10n.invNewRequired,
  AttributeIssue.notNumber => l10n.invNewNotNumber,
  AttributeIssue.notInteger => l10n.invNewNotInteger,
  AttributeIssue.belowMin => l10n.invNewBelowMin(plainNumber(field.min ?? 0)),
  AttributeIssue.aboveMax => l10n.invNewAboveMax(plainNumber(field.max ?? 0)),
  AttributeIssue.tooLong => l10n.invNewTooLong,
  AttributeIssue.invalid => l10n.invNewInvalid,
};

/// El idioma de la app (`es` o `pt`) para elegir las etiquetas del servidor.
String appLanguage(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'pt' ? 'pt' : 'es';
