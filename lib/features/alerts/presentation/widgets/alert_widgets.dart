import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../alerts_labels.dart';

/// Una alerta de la lista: importancia, titulo, texto y hora en la zona de la
/// concesion. Una sin leer lleva un punto y el titulo en negritas.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.zone,
    required this.onTap,
    this.opensRecord = false,
  });

  final AppAlert alert;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  /// Al tocarla lleva al registro al que apunta.
  final bool opensRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final color = alertSeverityColor(alert.severity);
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(14)),
      child: Material(
        color: moduleSurface,
        elevation: alert.read ? 1 : 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(24)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('alert-${alert.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  alertSeverityIcon(alert.severity),
                  color: color,
                  size: r.s(28),
                  semanticLabel: alertSeverityLabel(l10n, alert.severity),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textOnTop,
                          fontSize: r.s(15),
                          fontWeight: alert.read
                              ? FontWeight.w500
                              : FontWeight.w800,
                        ),
                      ),
                      if (alert.body != null && alert.body!.isNotEmpty) ...[
                        SizedBox(height: r.s(4)),
                        Text(
                          alert.body!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: r.s(13),
                            height: 1.3,
                          ),
                        ),
                      ],
                      SizedBox(height: r.s(8)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatInZone(context, alert.createdAt, zone),
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontSize: r.s(12),
                              ),
                            ),
                          ),
                          if (opensRecord)
                            Text(
                              l10n.alertsSeeDetail,
                              style: TextStyle(
                                color: p.accentIconOnLight,
                                fontSize: r.s(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!alert.read)
                  Padding(
                    padding: EdgeInsets.only(left: r.s(10), top: r.s(4)),
                    child: Container(
                      key: Key('alert-unread-${alert.id}'),
                      width: r.s(10),
                      height: r.s(10),
                      decoration: BoxDecoration(
                        color: p.accentIconOnLight,
                        shape: BoxShape.circle,
                      ),
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

/// Los estados de la lista sin tarjetas.
class AlertsStateView extends StatelessWidget {
  const AlertsStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const AlertsStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final AlertsError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('alerts-state-empty'),
        child: ModuleStateView(icon: Icons.notifications_none, body: message),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      AlertsError.notAvailable => (
        Icons.notifications_off_outlined,
        l10n.alertsUnavailableTitle,
        l10n.alertsUnavailableBody,
        false,
      ),
      AlertsError.permissionDenied => (
        Icons.lock_outline,
        l10n.alertsNoPermissionTitle,
        l10n.alertsNoPermissionBody,
        false,
      ),
      AlertsError.network || AlertsError.server => (
        Icons.cloud_off_outlined,
        l10n.alertsErrorTitle,
        l10n.alertsErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('alerts-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.alertsRetry : null,
        onRetry: onRetry,
        retryKey: const Key('alerts-retry'),
      ),
    );
  }
}
