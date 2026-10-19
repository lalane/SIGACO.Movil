import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../maintenance_labels.dart';

/// La tarjeta de la lista: estado y ubicacion, actividad, volumen, avance y
/// fechas.
class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.order,
    required this.zone,
    required this.onTap,
  });

  final MaintenanceOrder order;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('maintenance-${order.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModuleStatusPill(
                      key: Key('maintenance-status-${order.id}'),
                      label: statusLabel(l10n, order.status),
                      color: statusColor(order.status),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Text(
                        order.title,
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
                SizedBox(height: r.s(14)),
                Text(
                  order.activity,
                  style: TextStyle(color: moduleMuted, fontSize: r.s(17)),
                ),
                SizedBox(height: r.s(8)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.maintTotalVolume(
                              quantity(locale, order.totalVolume),
                            ),
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(14),
                            ),
                          ),
                          SizedBox(height: r.s(4)),
                          Text(
                            l10n.maintUnitDescription(order.unit),
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(14),
                            ),
                          ),
                          SizedBox(height: r.s(8)),
                          Row(
                            children: [
                              Text(
                                l10n.maintProgress,
                                style: TextStyle(
                                  color: moduleMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.s(15),
                                ),
                              ),
                              SizedBox(width: r.s(10)),
                              Text(
                                percent(order.progress),
                                key: Key('maintenance-progress-${order.id}'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.s(15),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (order.startDate != null || order.endDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (order.startDate != null)
                            _DateLine(
                              icon: Icons.calendar_today_outlined,
                              text: moduleDay(order.startDate!, zone),
                            ),
                          if (order.endDate != null) ...[
                            SizedBox(height: r.s(4)),
                            _DateLine(
                              icon: Icons.schedule,
                              text: moduleDay(order.endDate!, zone),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                SizedBox(height: r.s(8)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(3)),
                  child: LinearProgressIndicator(
                    value: order.progress,
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

class _DateLine extends StatelessWidget {
  const _DateLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: r.s(18), color: moduleMuted),
        SizedBox(width: r.s(6)),
        Text(
          text,
          style: TextStyle(
            color: moduleMuted,
            fontWeight: FontWeight.w800,
            fontSize: r.s(14),
          ),
        ),
      ],
    );
  }
}

/// Los estados de la lista sin tarjetas.
class MaintenanceStateView extends StatelessWidget {
  const MaintenanceStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const MaintenanceStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final MaintenanceError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('maintenance-state-empty'),
        child: ModuleStateView(icon: Icons.build_outlined, body: message),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      MaintenanceError.notAvailable => (
        Icons.build_outlined,
        l10n.maintUnavailableTitle,
        l10n.maintUnavailableBody,
        false,
      ),
      MaintenanceError.permissionDenied => (
        Icons.lock_outline,
        l10n.maintNoPermissionTitle,
        l10n.maintNoPermissionBody,
        false,
      ),
      MaintenanceError.notFound => (
        Icons.search_off,
        l10n.maintNotFound,
        '',
        false,
      ),
      MaintenanceError.network || MaintenanceError.server => (
        Icons.cloud_off_outlined,
        l10n.maintErrorTitle,
        l10n.maintErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('maintenance-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.maintRetry : null,
        onRetry: onRetry,
        retryKey: const Key('maintenance-retry'),
      ),
    );
  }
}
