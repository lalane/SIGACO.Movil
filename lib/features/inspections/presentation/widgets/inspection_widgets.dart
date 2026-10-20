import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../inspections_labels.dart';

/// La tarjeta de la lista: estado y titulo, activo y ubicacion, fecha y el
/// avance del checklist.
class InspectionCard extends StatelessWidget {
  const InspectionCard({
    super.key,
    required this.inspection,
    required this.zone,
    required this.onTap,
  });

  final Inspection inspection;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final where = [?inspection.assetName, ?inspection.kmLabel].join(' · ');
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('inspection-${inspection.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModuleStatusPill(
                      key: Key('inspection-status-${inspection.id}'),
                      label: inspectionStatusLabel(l10n, inspection.status),
                      color: inspectionStatusColor(inspection.status),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Text(
                        inspection.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.s(18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: moduleMuted),
                  ],
                ),
                SizedBox(height: r.s(10)),
                Text(
                  inspection.type,
                  style: TextStyle(color: moduleMuted, fontSize: r.s(15)),
                ),
                if (where.isNotEmpty) ...[
                  SizedBox(height: r.s(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: r.s(18),
                        color: moduleMuted,
                      ),
                      SizedBox(width: r.s(6)),
                      Expanded(
                        child: Text(
                          where,
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: r.s(10)),
                Row(
                  children: [
                    if (inspection.scheduledAt != null) ...[
                      Icon(
                        Icons.calendar_today_outlined,
                        size: r.s(16),
                        color: moduleMuted,
                      ),
                      SizedBox(width: r.s(6)),
                      Text(
                        moduleDay(inspection.scheduledAt!, zone),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      l10n.inspChecklistProgress(
                        inspection.answered,
                        inspection.checklist.length,
                      ),
                      key: Key('inspection-progress-${inspection.id}'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(3)),
                  child: LinearProgressIndicator(
                    value: inspection.progress,
                    minHeight: r.s(5),
                    color: p.accent,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un punto del checklist con sus dos respuestas.
class ChecklistTile extends StatelessWidget {
  const ChecklistTile({
    super.key,
    required this.item,
    required this.editable,
    required this.onAnswer,
  });

  final ChecklistItem item;
  final bool editable;
  final ValueChanged<CheckResult> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    Widget choice(CheckResult value, String label, Color color) {
      final selected = item.result == value;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: value == CheckResult.ok ? r.s(8) : 0),
          child: OutlinedButton(
            key: Key('check-${item.id}-${value.name}'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(r.s(44)),
              backgroundColor: selected ? color.withValues(alpha: 0.2) : null,
              foregroundColor: selected ? color : moduleMuted,
              side: BorderSide(
                color: selected ? color : Colors.white.withValues(alpha: 0.2),
                width: selected ? 2 : 1,
              ),
              shape: const StadiumBorder(),
            ),
            onPressed: editable ? () => onAnswer(value) : null,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.s(14)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(color: Colors.white, fontSize: r.s(16)),
                ),
              ),
              if (item.critical)
                Container(
                  key: Key('check-${item.id}-critical'),
                  margin: EdgeInsets.only(left: r.s(8)),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(8),
                    vertical: r.s(2),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(r.s(8)),
                  ),
                  child: Text(
                    l10n.inspCritical,
                    style: TextStyle(
                      color: const Color(0xFFF87171),
                      fontSize: r.s(12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: r.s(8)),
          Row(
            children: [
              choice(
                CheckResult.ok,
                l10n.inspResultOk,
                const Color(0xFF4ADE80),
              ),
              choice(
                CheckResult.finding,
                l10n.inspResultFinding,
                const Color(0xFFF87171),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Los estados de la lista sin tarjetas.
class InspectionsStateView extends StatelessWidget {
  const InspectionsStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const InspectionsStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final InspectionsError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('inspections-state-empty'),
        child: ModuleStateView(icon: Icons.fact_check_outlined, body: message),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      InspectionsError.notAvailable => (
        Icons.fact_check_outlined,
        l10n.inspUnavailableTitle,
        l10n.inspUnavailableBody,
        false,
      ),
      InspectionsError.permissionDenied => (
        Icons.lock_outline,
        l10n.inspNoPermissionTitle,
        l10n.inspNoPermissionBody,
        false,
      ),
      InspectionsError.notFound => (
        Icons.search_off,
        l10n.inspNotFound,
        '',
        false,
      ),
      InspectionsError.network ||
      InspectionsError.server ||
      InspectionsError.notEditable ||
      InspectionsError.incomplete => (
        Icons.cloud_off_outlined,
        l10n.inspErrorTitle,
        l10n.inspErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('inspections-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.inspRetry : null,
        onRetry: onRetry,
        retryKey: const Key('inspections-retry'),
      ),
    );
  }
}
