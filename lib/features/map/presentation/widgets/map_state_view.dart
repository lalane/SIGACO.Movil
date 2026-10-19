import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/map_repository.dart';

/// Las pantallas de estado de la pestana del mapa: cargando, error con
/// reintento, sin permiso y "aun no disponible". Una sola pieza para todas, como
/// en el gestor documental.
class MapStateView extends StatelessWidget {
  const MapStateView.loading({super.key})
    : error = null,
      loading = true,
      onRetry = null;

  const MapStateView.error(this.error, {super.key, this.onRetry})
    : loading = false;

  final bool loading;
  final MapError? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    if (loading) {
      return Center(
        key: const Key('map-state-loading'),
        child: Semantics(
          label: l10n.mapLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final (icon, title, body, retry) = switch (error!) {
      MapError.notAvailable => (
        Icons.map_outlined,
        l10n.mapUnavailableTitle,
        l10n.mapUnavailableBody,
        false,
      ),
      MapError.permissionDenied => (
        Icons.lock_outline,
        l10n.mapNoPermissionTitle,
        l10n.mapNoPermissionBody,
        false,
      ),
      MapError.network || MapError.server => (
        Icons.cloud_off_outlined,
        l10n.mapErrorTitle,
        l10n.mapErrorBody,
        true,
      ),
    };
    return Center(
      key: Key('map-state-${error!.name}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.s(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.s(48), color: p.hint),
            SizedBox(height: r.s(16)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: r.s(8)),
            Text(body, textAlign: TextAlign.center),
            if (retry && onRetry != null) ...[
              SizedBox(height: r.s(16)),
              FilledButton(
                key: const Key('map-retry'),
                onPressed: onRetry,
                child: Text(l10n.mapRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
