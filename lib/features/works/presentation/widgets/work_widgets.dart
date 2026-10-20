import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';
import '../works_labels.dart';

/// La tarjeta de la lista: estado y nombre, contratista, avance fisico contra
/// el programado y fechas.
class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.work,
    required this.zone,
    required this.onTap,
  });

  final PublicWork work;
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
          key: Key('work-${work.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModuleStatusPill(
                      key: Key('work-status-${work.id}'),
                      label: workStatusLabel(l10n, work.status),
                      color: workStatusColor(work.status),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Text(
                        work.name,
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
                if (work.contractor != null) ...[
                  SizedBox(height: r.s(10)),
                  Text(
                    work.contractor!,
                    style: TextStyle(color: moduleMuted, fontSize: r.s(15)),
                  ),
                ],
                SizedBox(height: r.s(12)),
                Row(
                  children: [
                    Text(
                      l10n.workPhysical,
                      style: TextStyle(
                        color: moduleMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(14),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      percent(work.physicalProgress),
                      key: Key('work-progress-${work.id}'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(15),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.s(6)),
                _ProgressBar(
                  physical: work.physicalProgress,
                  programmed: work.programmedProgress,
                  color: p.accent,
                ),
                if (work.startDate != null || work.endDate != null) ...[
                  SizedBox(height: r.s(10)),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: r.s(16),
                        color: moduleMuted,
                      ),
                      SizedBox(width: r.s(6)),
                      Text(
                        [
                          if (work.startDate != null)
                            moduleDay(work.startDate!, zone),
                          if (work.endDate != null)
                            moduleDay(work.endDate!, zone),
                        ].join(' → '),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El avance fisico con una marca donde tocaba ir segun el programa.
class WorkProgressBar extends StatelessWidget {
  const WorkProgressBar({
    super.key,
    required this.physical,
    required this.programmed,
  });

  final double physical;
  final double programmed;

  @override
  Widget build(BuildContext context) => _ProgressBar(
    physical: physical,
    programmed: programmed,
    color: context.palette.accent,
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.physical,
    required this.programmed,
    required this.color,
  });

  final double physical;
  final double programmed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mark = (programmed.clamp(0.0, 1.0)) * constraints.maxWidth;
        return SizedBox(
          height: r.s(12),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(r.s(4)),
                child: LinearProgressIndicator(
                  value: physical.clamp(0.0, 1.0),
                  minHeight: r.s(8),
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: (mark - 1).clamp(0.0, constraints.maxWidth),
                child: Container(
                  key: const Key('work-programmed-mark'),
                  width: 2,
                  height: r.s(12),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Los estados de la lista sin tarjetas.
class WorksStateView extends StatelessWidget {
  const WorksStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const WorksStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final WorksError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('works-state-empty'),
        child: ModuleStateView(icon: Icons.engineering_outlined, body: message),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      WorksError.notAvailable => (
        Icons.engineering_outlined,
        l10n.workUnavailableTitle,
        l10n.workUnavailableBody,
        false,
      ),
      WorksError.permissionDenied => (
        Icons.lock_outline,
        l10n.workNoPermissionTitle,
        l10n.workNoPermissionBody,
        false,
      ),
      WorksError.notFound => (Icons.search_off, l10n.workNotFound, '', false),
      WorksError.network || WorksError.server => (
        Icons.cloud_off_outlined,
        l10n.workErrorTitle,
        l10n.workErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('works-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.workRetry : null,
        onRetry: onRetry,
        retryKey: const Key('works-retry'),
      ),
    );
  }
}
