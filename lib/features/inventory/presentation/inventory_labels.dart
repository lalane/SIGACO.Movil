import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/time/concession_zone.dart';
import '../../../core/ui/module_format.dart';
import '../../../l10n/app_localizations.dart';
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
