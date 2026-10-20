import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../inventory_labels.dart';

/// La tarjeta de la lista: estado y nombre, tipo, ubicacion y ultima inspeccion.
class InventoryCard extends StatelessWidget {
  const InventoryCard({
    super.key,
    required this.asset,
    required this.zone,
    required this.onTap,
  });

  final InventoryAsset asset;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final where = [
      ?asset.kmLabel,
      if (asset.segmentCode != null)
        '${asset.segmentCode}'
            '${asset.direction == null ? '' : ' · ${asset.direction}'}',
    ].join(' · ');
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('inventory-${asset.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModuleStatusPill(
                      key: Key('inventory-condition-${asset.id}'),
                      label: conditionLabel(l10n, asset.condition),
                      color: conditionColor(asset.condition),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Text(
                        asset.name,
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
                  asset.category,
                  style: TextStyle(color: moduleMuted, fontSize: r.s(16)),
                ),
                if (where.isNotEmpty) ...[
                  SizedBox(height: r.s(6)),
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
                            fontWeight: FontWeight.w700,
                            fontSize: r.s(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (asset.lastInspectionAt != null) ...[
                  SizedBox(height: r.s(6)),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: r.s(18),
                        color: moduleMuted,
                      ),
                      SizedBox(width: r.s(6)),
                      Text(
                        l10n.invCardInspected(
                          moduleDay(asset.lastInspectionAt!, zone),
                        ),
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

/// Los estados de la lista sin tarjetas.
class InventoryStateView extends StatelessWidget {
  const InventoryStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const InventoryStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final InventoryError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('inventory-state-empty'),
        child: ModuleStateView(icon: Icons.inventory_2_outlined, body: message),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      InventoryError.notAvailable => (
        Icons.inventory_2_outlined,
        l10n.invUnavailableTitle,
        l10n.invUnavailableBody,
        false,
      ),
      InventoryError.permissionDenied => (
        Icons.lock_outline,
        l10n.invNoPermissionTitle,
        l10n.invNoPermissionBody,
        false,
      ),
      InventoryError.notFound => (
        Icons.search_off,
        l10n.invNotFound,
        '',
        false,
      ),
      InventoryError.network || InventoryError.server => (
        Icons.cloud_off_outlined,
        l10n.invErrorTitle,
        l10n.invErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('inventory-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.invRetry : null,
        onRetry: onRetry,
        retryKey: const Key('inventory-retry'),
      ),
    );
  }
}
