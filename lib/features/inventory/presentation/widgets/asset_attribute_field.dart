import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../inventory_labels.dart';

/// Un campo de la ficha en el formulario de alta: el control sale del tipo de
/// dato (texto, entero, decimal, si/no, fecha, fecha y hora o catalogo), con su
/// unidad, minimo, maximo y si es obligatorio. La llave es
/// `asset-field-<clave>`.
class AssetAttributeField extends StatelessWidget {
  const AssetAttributeField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.language,
    required this.zone,
    this.options = const [],
    this.error,
  });

  final AttributeDefinition field;

  /// Lo capturado: texto (texto y numeros), bool, [DateTime] o codigo.
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String language;
  final ConcessionZone? zone;

  /// Los valores del catalogo, si es CATALOG.
  final List<CatalogOption> options;
  final String? error;

  Key get _key => Key('asset-field-${field.key}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = field.unit;
    final label = [
      field.label(language),
      if (unit != null && field.type.isNumber) '($unit)',
      if (field.required) '*',
    ].join(' ');
    final help = [
      ?field.help,
      if (field.origin == AttributeOrigin.layer) l10n.invNewFromLayer,
    ];
    return ModuleField(
      label: label,
      error: error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _control(context, l10n),
          for (final h in help)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                h,
                style: const TextStyle(color: Color(0xFF8B95A7), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _control(BuildContext context, AppLocalizations l10n) {
    final hasError = error != null;
    switch (field.type) {
      case AttributeType.integer:
      case AttributeType.decimal:
        final integer = field.type == AttributeType.integer;
        return TextFormField(
          key: _key,
          initialValue: value is String ? value as String : null,
          onChanged: onChanged,
          style: moduleInkStyle,
          keyboardType: TextInputType.numberWithOptions(
            decimal: !integer,
            signed: (field.min ?? -1) < 0,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(integer ? r'[0-9-]' : r'[0-9.,-]'),
            ),
          ],
          decoration: moduleInput(
            context,
            hint: _rangeHint(l10n),
            error: hasError,
            suffix: field.unit == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Align(
                      widthFactor: 1,
                      child: Text(field.unit!, style: moduleHintStyle),
                    ),
                  ),
          ),
        );
      case AttributeType.boolean:
        return DropdownButtonFormField<bool>(
          key: _key,
          initialValue: value is bool ? value as bool : null,
          isExpanded: true,
          style: moduleInkStyle,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: Text(l10n.followUpSelect, style: moduleHintStyle),
          decoration: moduleInput(context, error: hasError),
          items: [
            DropdownMenuItem(value: true, child: Text(l10n.invYes)),
            DropdownMenuItem(value: false, child: Text(l10n.invNo)),
          ],
          onChanged: onChanged,
        );
      case AttributeType.date:
        final day = value is DateTime ? value as DateTime : null;
        return ModulePickerField(
          key: _key,
          value: day == null ? null : DateFormat('dd/MM/yyyy').format(day),
          hint: l10n.invNewDateHint,
          icon: Icons.event_outlined,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: day ?? now,
              firstDate: DateTime(1950),
              lastDate: DateTime(now.year + 10),
            );
            if (picked != null) {
              onChanged(DateTime.utc(picked.year, picked.month, picked.day));
            }
          },
        );
      case AttributeType.dateTime:
        final at = value is DateTime ? value as DateTime : null;
        return ModulePickerField(
          key: _key,
          value: at == null ? null : moduleDate(at, zone),
          hint: l10n.invNewDateTimeHint,
          icon: Icons.schedule,
          onTap: () async {
            final now = DateTime.now();
            final shown = at == null ? now : inConcessionZone(at, zone);
            final day = await showDatePicker(
              context: context,
              initialDate: shown,
              firstDate: DateTime(1950),
              lastDate: DateTime(now.year + 10),
            );
            if (day == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(shown),
            );
            if (time == null) return;
            // Lo que se elige es la hora de la concesion; se guarda en UTC.
            onChanged(
              wallClockToUtc(
                DateTime(day.year, day.month, day.day, time.hour, time.minute),
                zone,
              ),
            );
          },
        );
      case AttributeType.catalog:
        final codes = {for (final o in options) o.code};
        final current = value is String && codes.contains(value)
            ? value as String
            : null;
        return DropdownButtonFormField<String>(
          key: _key,
          initialValue: current,
          isExpanded: true,
          style: moduleInkStyle,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: Text(l10n.followUpSelect, style: moduleHintStyle),
          decoration: moduleInput(context, error: hasError),
          items: [
            for (final o in options)
              DropdownMenuItem(
                value: o.code,
                child: Text(
                  o.label(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        );
      case AttributeType.text:
      case AttributeType.unknown:
        return TextFormField(
          key: _key,
          initialValue: value is String ? value as String : null,
          onChanged: onChanged,
          style: moduleInkStyle,
          maxLength: AttributeDefinition.textMaxLength,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          decoration: moduleInput(
            context,
            hint: l10n.followUpFillIn,
            error: hasError,
          ),
        );
    }
  }

  /// `De 0 a 100`, `Desde 0` o `Hasta 100`; null sin limites.
  String? _rangeHint(AppLocalizations l10n) {
    final min = field.min;
    final max = field.max;
    if (min != null && max != null) {
      return l10n.invNewRange(plainNumber(min), plainNumber(max));
    }
    if (min != null) return l10n.invNewMin(plainNumber(min));
    if (max != null) return l10n.invNewMax(plainNumber(max));
    return null;
  }
}
