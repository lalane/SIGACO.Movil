import 'package:flutter/material.dart';

import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Los estados del historial sin tarjetas: error con reintento, sin permiso,
/// "aun no disponible" y lista vacia.
class TicketsStateView extends StatelessWidget {
  const TicketsStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const TicketsStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final TicketsError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('tickets-state-empty'),
        child: ModuleStateView(
          icon: Icons.receipt_long_outlined,
          body: message,
        ),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      TicketsError.notAvailable => (
        Icons.receipt_long_outlined,
        l10n.ticketsUnavailableTitle,
        l10n.ticketsUnavailableBody,
        false,
      ),
      TicketsError.permissionDenied => (
        Icons.lock_outline,
        l10n.ticketsNoPermissionTitle,
        l10n.ticketsNoPermissionBody,
        false,
      ),
      TicketsError.notFound => (
        Icons.search_off,
        l10n.ticketNotFound,
        '',
        false,
      ),
      TicketsError.network || TicketsError.server => (
        Icons.cloud_off_outlined,
        l10n.ticketsErrorTitle,
        l10n.ticketsErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('tickets-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.ticketsRetry : null,
        onRetry: onRetry,
        retryKey: const Key('tickets-retry'),
      ),
    );
  }
}
