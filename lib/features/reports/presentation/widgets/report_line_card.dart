import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/indicator_report.dart';
import '../reports_labels.dart';

/// Una actividad del reporte: estado y lugar, que se hace, avance y fecha de
/// inicio. Un toque abre su ficha.
class ReportLineCard extends StatelessWidget {
  const ReportLineCard({
    super.key,
    required this.line,
    required this.zone,
    required this.onTap,
  });

  final ReportLine line;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('report-line-${line.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModuleStatusPill(
                      label: reportStatusLabel(l10n, line.status),
                      color: reportStatusColor(line.status),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Text(
                        line.title,
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
                SizedBox(height: r.s(12)),
                Text(
                  line.activity,
                  style: TextStyle(color: moduleMuted, fontSize: r.s(16)),
                ),
                SizedBox(height: r.s(10)),
                Row(
                  children: [
                    Text(
                      percent(line.progress),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(15),
                      ),
                    ),
                    const Spacer(),
                    if (line.startDate != null)
                      Text(
                        moduleCalendarDay(line.startDate!),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                  ],
                ),
                SizedBox(height: r.s(8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(3)),
                  child: LinearProgressIndicator(
                    value: line.progress,
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
