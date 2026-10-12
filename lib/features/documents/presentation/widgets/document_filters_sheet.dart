import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_query.dart';

/// Filtros de la consulta (HU-MOB-03-01, regla 6): tipo, categoria, carpeta,
/// modificado por y rango Desde/Hasta. Devuelve los filtros elegidos, o null si
/// se cierra sin aplicar.
Future<DocumentFilters?> showDocumentFilters(
  BuildContext context, {
  required DocumentFilters current,
  required DocumentCatalogs catalogs,
}) => showModalBottomSheet<DocumentFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FiltersSheet(current: current, catalogs: catalogs),
);

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.current, required this.catalogs});

  final DocumentFilters current;
  final DocumentCatalogs catalogs;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _type = widget.current.typeCode;
  late String? _category = widget.current.categoryCode;
  late String? _folder = widget.current.folder;
  late String? _modifiedBy = widget.current.modifiedBy;
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;

  DocumentFilters get _filters => DocumentFilters(
    typeCode: _type,
    categoryCode: _category,
    folder: _folder,
    modifiedBy: _modifiedBy,
    from: _from,
    to: _to,
  );

  Future<DateTime?> _pick(DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    // Se guarda el dia elegido como fecha UTC sin hora: el servidor lo toma
    // como dia completo de la zona de la concesion.
    return picked == null
        ? null
        : DateTime.utc(picked.year, picked.month, picked.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final c = widget.catalogs;
    final rangeOk = _filters.rangeIsValid;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.docsFilters,
              style: TextStyle(
                fontSize: r.s(18),
                fontWeight: FontWeight.w800,
                color: p.textOnBottom,
              ),
            ),
            SizedBox(height: r.s(12)),
            _Choice(
              fieldKey: const Key('filter-type'),
              label: l10n.docsFilterType,
              any: l10n.docsFilterAny,
              value: _type,
              options: [for (final e in c.types) (e.code, e.label)],
              onChanged: (v) => setState(() => _type = v),
            ),
            _Choice(
              fieldKey: const Key('filter-category'),
              label: l10n.docsFilterCategory,
              any: l10n.docsFilterAny,
              value: _category,
              options: [for (final e in c.categories) (e.code, e.label)],
              onChanged: (v) => setState(() => _category = v),
            ),
            _Choice(
              fieldKey: const Key('filter-folder'),
              label: l10n.docsFilterFolder,
              any: l10n.docsFilterAny,
              value: _folder,
              options: [for (final f in c.folders) (f, f)],
              onChanged: (v) => setState(() => _folder = v),
            ),
            _Choice(
              fieldKey: const Key('filter-modified-by'),
              label: l10n.docsFilterModifiedBy,
              any: l10n.docsFilterAny,
              value: _modifiedBy,
              options: [for (final u in c.users) (u, u)],
              onChanged: (v) => setState(() => _modifiedBy = v),
            ),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    fieldKey: const Key('filter-from'),
                    label: l10n.docsFilterFrom,
                    value: _from,
                    onPick: () async {
                      final d = await _pick(_from);
                      if (d != null) setState(() => _from = d);
                    },
                    onClear: () => setState(() => _from = null),
                  ),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: _DateField(
                    fieldKey: const Key('filter-to'),
                    label: l10n.docsFilterTo,
                    value: _to,
                    onPick: () async {
                      final d = await _pick(_to);
                      if (d != null) setState(() => _to = d);
                    },
                    onClear: () => setState(() => _to = null),
                  ),
                ),
              ],
            ),
            if (!rangeOk)
              Padding(
                padding: EdgeInsets.only(top: r.s(6)),
                child: Text(
                  l10n.docsRangeInvalid,
                  key: const Key('filter-range-error'),
                  style: TextStyle(color: p.error, fontSize: r.s(12.5)),
                ),
              ),
            SizedBox(height: r.s(16)),
            Row(
              children: [
                TextButton(
                  key: const Key('filters-clear'),
                  onPressed: () => Navigator.pop(context, DocumentFilters.none),
                  child: Text(l10n.docsFiltersClear),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('filters-apply'),
                  onPressed: rangeOk
                      ? () => Navigator.pop(context, _filters)
                      : null,
                  child: Text(l10n.docsFiltersApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.fieldKey,
    required this.label,
    required this.any,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String any;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    // Un valor que ya no esta en el catalogo no se puede seleccionar.
    final current = options.any((o) => o.$1 == value) ? value : null;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(12)),
      child: DropdownButtonFormField<String?>(
        key: fieldKey,
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(any)),
          for (final o in options)
            DropdownMenuItem<String?>(
              value: o.$1,
              child: Text(o.$2, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final Key fieldKey;
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: fieldKey,
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          // El dia elegido se muestra tal cual, sin pasarlo por ninguna zona.
          value == null
              ? l10n.docsFilterPickDate
              : formatCalendarDay(context, value!),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
