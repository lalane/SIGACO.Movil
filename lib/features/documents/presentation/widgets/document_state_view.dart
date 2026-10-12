import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/access_state_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/documents_repository.dart';

/// Las pantallas de estado del gestor documental (MQ-MOB-22, DEV-MOB-078):
/// cargando, vacio, error con reintento, sin conexion y sin permiso, mas las que
/// piden las vistas de consulta (sin resultados, no disponible sin conexion).
/// Todas las vistas del gestor las usan en lugar de armar las suyas.
enum DocumentScreenState {
  loading,
  empty,
  noResults,
  error,
  offline,
  noPermission,
  notFound,
  notAvailableOffline,
}

/// El estado de pantalla que corresponde a un fallo del repositorio.
DocumentScreenState screenStateFor(DocumentsError error) => switch (error) {
  DocumentsError.network => DocumentScreenState.offline,
  DocumentsError.permissionDenied => DocumentScreenState.noPermission,
  DocumentsError.notFound => DocumentScreenState.notFound,
  DocumentsError.notAvailableOffline => DocumentScreenState.notAvailableOffline,
  DocumentsError.server => DocumentScreenState.error,
};

class DocumentStateView extends StatelessWidget {
  const DocumentStateView({
    super.key,
    required this.state,
    this.view = DocumentView.all,
    this.onRetry,
    this.onClear,
  });

  final DocumentScreenState state;

  /// Para el texto del estado vacio, que cambia segun la vista.
  final DocumentView view;

  /// Reintentar (error, sin conexion, sin permiso).
  final VoidCallback? onRetry;

  /// Quitar la busqueda y los filtros (sin resultados).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final key = Key('docs-state-${state.name}');
    switch (state) {
      case DocumentScreenState.loading:
        return Center(
          key: key,
          child: Semantics(
            label: l10n.docsLoading,
            child: const CircularProgressIndicator(),
          ),
        );
      case DocumentScreenState.noPermission:
        return AccessStateView(
          key: key,
          issue: AccessIssue.noPermission,
          title: l10n.docsNoPermissionTitle,
          message: l10n.docsNoPermissionBody,
          primaryLabel: l10n.retry,
          onPrimary: onRetry ?? () {},
        );
      case DocumentScreenState.empty:
        final (title, body, icon) = switch (view) {
          DocumentView.all => (
            l10n.docsEmptyAllTitle,
            l10n.docsEmptyAllBody,
            Icons.folder_open_outlined,
          ),
          DocumentView.recent => (
            l10n.docsEmptyRecentTitle,
            l10n.docsEmptyRecentBody,
            Icons.history,
          ),
          DocumentView.favorites => (
            l10n.docsEmptyFavoritesTitle,
            l10n.docsEmptyFavoritesBody,
            Icons.star_border,
          ),
          DocumentView.mine => (
            l10n.docsEmptyMineTitle,
            l10n.docsEmptyMineBody,
            Icons.person_outline,
          ),
        };
        return _Message(key: key, icon: icon, title: title, body: body);
      case DocumentScreenState.noResults:
        return _Message(
          key: key,
          icon: Icons.search_off,
          title: l10n.docsNoResultsTitle,
          body: l10n.docsNoResultsBody,
          actionLabel: l10n.docsFiltersClear,
          onAction: onClear,
        );
      case DocumentScreenState.error:
        return _Message(
          key: key,
          icon: Icons.error_outline,
          title: l10n.docsErrorTitle,
          body: l10n.docsErrorBody,
          actionLabel: l10n.retry,
          onAction: onRetry,
        );
      case DocumentScreenState.offline:
        return _Message(
          key: key,
          icon: Icons.cloud_off_outlined,
          title: l10n.docsOfflineTitle,
          body: l10n.docsOfflineBody,
          actionLabel: l10n.retry,
          onAction: onRetry,
        );
      case DocumentScreenState.notFound:
        return _Message(
          key: key,
          icon: Icons.find_in_page_outlined,
          title: l10n.docsNotFoundTitle,
          body: l10n.docsNotFoundBody,
        );
      case DocumentScreenState.notAvailableOffline:
        return _Message(
          key: key,
          icon: Icons.cloud_download_outlined,
          title: l10n.docsNotOfflineTitle,
          body: l10n.docsNotOfflineBody,
          actionLabel: l10n.retry,
          onAction: onRetry,
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(32), vertical: r.s(24)),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.s(420)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: r.s(48), color: p.accentOnBottom),
                SizedBox(height: r.s(14)),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: r.s(6)),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.hint, fontSize: r.s(13.5)),
                ),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: r.s(16)),
                  FilledButton(
                    key: const Key('docs-state-action'),
                    onPressed: onAction,
                    child: Text(actionLabel!),
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
