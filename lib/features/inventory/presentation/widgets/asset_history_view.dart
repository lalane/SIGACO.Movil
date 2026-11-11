import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/asset_history.dart';
import '../../domain/entities/inventory_asset.dart';
import '../bloc/inventory_detail_cubit.dart';
import '../inventory_labels.dart';

/// Lo que la ficha del activo puede abrir o levantar en otros modulos. Lo arma
/// app/ con el menu de la persona: los modulos no se importan entre si.
class AssetRecordActions {
  const AssetRecordActions({this.openRoute, this.newTicketRoute});

  /// La ruta de la ficha de un registro en su modulo; null si la app no lo
  /// tiene o la persona no ve ese modulo (el renglon solo se lista).
  final String? Function(AssetHistoryEntry entry)? openRoute;

  /// La ruta del alta de ticket con el activo ya elegido; null si la persona no
  /// tiene el modulo de tickets.
  final String Function(InventoryAsset asset)? newTicketRoute;
}

/// La historia operativa del activo: por cada modulo que la persona puede ver,
/// cuantos registros tiene (sin cerrar y en total) y los ultimos.
class AssetHistoryView extends StatelessWidget {
  const AssetHistoryView({
    super.key,
    required this.history,
    required this.zone,
    this.routeOf,
  });

  final Map<AssetHistoryKind, AssetHistorySection> history;
  final ConcessionZone? zone;

  /// La ficha de un registro en su modulo; null si no se puede abrir (el
  /// renglon solo se lista).
  final String? Function(AssetHistoryEntry entry)? routeOf;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final kinds = [
      for (final k in AssetHistoryKind.values)
        if (history.containsKey(k)) k,
    ];
    return Column(
      key: const Key('inventory-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < kinds.length; i++) ...[
          if (i > 0) SizedBox(height: r.s(12)),
          _KindCard(
            kind: kinds[i],
            section: history[kinds[i]]!,
            zone: zone,
            routeOf: routeOf,
          ),
        ],
      ],
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.section,
    required this.zone,
    this.routeOf,
  });

  final AssetHistoryKind kind;
  final AssetHistorySection section;
  final ConcessionZone? zone;
  final String? Function(AssetHistoryEntry entry)? routeOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final count = section.count;
    final muted = TextStyle(color: moduleMuted, fontSize: r.s(13));
    final Widget body = switch (section.status) {
      AssetHistoryStatus.loading => Padding(
        padding: EdgeInsets.symmetric(vertical: r.s(8)),
        child: const LinearProgressIndicator(minHeight: 2),
      ),
      AssetHistoryStatus.failure => Text(
        l10n.invHistoryFailed,
        key: Key('inventory-history-${kind.name}-failed'),
        style: muted,
      ),
      AssetHistoryStatus.ready when section.items.isEmpty => Text(
        historyEmptyLabel(l10n, kind),
        key: Key('inventory-history-${kind.name}-empty'),
        style: muted,
      ),
      AssetHistoryStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < section.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: r.s(1),
                color: Colors.white.withValues(alpha: 0.08),
              ),
            _EntryRow(
              entry: section.items[i],
              zone: zone,
              route: routeOf?.call(section.items[i]),
            ),
          ],
          if (count.total > section.items.length) ...[
            SizedBox(height: r.s(8)),
            Text(
              l10n.invHistoryMore(section.items.length, count.total),
              key: Key('inventory-history-${kind.name}-more'),
              style: muted.copyWith(fontSize: r.s(12)),
            ),
          ],
        ],
      ),
    };
    return Container(
      key: Key('inventory-history-${kind.name}'),
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: moduleSurface,
        borderRadius: BorderRadius.circular(r.s(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(historyKindIcon(kind), color: Colors.white, size: r.s(22)),
              SizedBox(width: r.s(10)),
              Expanded(
                child: Text(
                  historyKindLabel(l10n, kind),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: r.s(16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(4)),
          Text(
            l10n.invHistoryCount(count.open, count.total),
            key: Key('inventory-history-${kind.name}-count'),
            style: muted,
          ),
          SizedBox(height: r.s(10)),
          body,
        ],
      ),
    );
  }
}

/// Un registro: folio y estado; la falla, tipo o actividad; la fecha clave y
/// quien lo atiende.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.zone, this.route});

  final AssetHistoryEntry entry;
  final ConcessionZone? zone;

  /// La ficha del registro en su modulo; null si no se puede abrir.
  final String? route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final date = entry.date;
    final detail = [
      if (date != null)
        entry.dateOnly ? moduleCalendarDay(date) : moduleDate(date, zone),
      ?entry.responsible,
    ].join(' · ');
    final tap = route;
    return InkWell(
      key: Key('inventory-history-entry-${entry.id}'),
      onTap: tap == null ? null : () => context.push(tap),
      borderRadius: BorderRadius.circular(r.s(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r.s(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.folio,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: r.s(14),
                    ),
                  ),
                  if (entry.title != null) ...[
                    SizedBox(height: r.s(2)),
                    Text(
                      entry.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: r.s(13)),
                    ),
                  ],
                  if (detail.isNotEmpty) ...[
                    SizedBox(height: r.s(2)),
                    Text(
                      detail,
                      style: TextStyle(color: moduleMuted, fontSize: r.s(12)),
                    ),
                  ],
                  SizedBox(height: r.s(6)),
                  Wrap(
                    spacing: r.s(6),
                    runSpacing: r.s(6),
                    children: [
                      ModuleStatusPill(
                        key: Key('inventory-history-entry-${entry.id}-status'),
                        label: historyStatusLabel(
                          l10n,
                          entry.kind,
                          entry.status,
                        ),
                        color: historyStatusColor(entry.status),
                      ),
                      if (entry.overdue)
                        ModuleStatusPill(
                          key: Key(
                            'inventory-history-entry-${entry.id}-overdue',
                          ),
                          label: l10n.invHistoryOverdue,
                          color: StatusColors.open,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (tap != null)
              Icon(Icons.chevron_right, color: moduleMuted, size: r.s(22)),
          ],
        ),
      ),
    );
  }
}
