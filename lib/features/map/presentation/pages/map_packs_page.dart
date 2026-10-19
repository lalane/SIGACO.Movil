import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/ui/page_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/map_pack_manager.dart';
import '../bloc/map_packs_cubit.dart';
import '../map_labels.dart';

/// Mapas sin conexion: los paquetes de teselas de la concesion, para bajarlos,
/// pausarlos, actualizarlos y borrarlos.
class MapPacksPage extends StatefulWidget {
  const MapPacksPage({super.key});

  @override
  State<MapPacksPage> createState() => _MapPacksPageState();
}

class _MapPacksPageState extends State<MapPacksPage> {
  @override
  void initState() {
    super.initState();
    context.read<MapPacksCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.mapPacksTitle),
          Expanded(
            child: BlocBuilder<MapPacksCubit, MapPacksState>(
              builder: (context, state) => switch (state.status) {
                PacksStatus.loading => const Center(
                  key: Key('packs-state-loading'),
                  child: CircularProgressIndicator(),
                ),
                PacksStatus.failure => _Failure(
                  error: state.error ?? MapPackError.server,
                  onRetry: context.read<MapPacksCubit>().load,
                ),
                PacksStatus.ready => _List(state: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final MapPackError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final (icon, title, body, retry) = switch (error) {
      MapPackError.notAvailable => (
        Icons.download_for_offline_outlined,
        l10n.mapPacksUnavailableTitle,
        l10n.mapPacksUnavailableBody,
        false,
      ),
      MapPackError.permissionDenied => (
        Icons.lock_outline,
        l10n.mapPacksNoPermissionTitle,
        l10n.mapPacksNoPermissionBody,
        false,
      ),
      _ => (
        Icons.cloud_off_outlined,
        l10n.mapPacksErrorTitle,
        l10n.mapPacksErrorBody,
        true,
      ),
    };
    return Center(
      key: Key('packs-state-${error.name}'),
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
            if (retry) ...[
              SizedBox(height: r.s(16)),
              FilledButton(
                key: const Key('packs-retry'),
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

class _List extends StatelessWidget {
  const _List({required this.state});

  final MapPacksState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return ListView(
      key: const Key('packs-list'),
      padding: EdgeInsets.all(r.s(16)),
      children: [
        Text(l10n.mapPacksIntro, style: TextStyle(color: p.hint)),
        if (state.listError != null) ...[
          SizedBox(height: r.s(12)),
          Card(
            key: const Key('packs-list-offline'),
            color: StatusColors.attended.withValues(alpha: 0.25),
            child: Padding(
              padding: EdgeInsets.all(r.s(12)),
              child: Text(l10n.mapPacksListOffline),
            ),
          ),
        ],
        SizedBox(height: r.s(12)),
        if (state.items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: r.s(24)),
            child: Text(
              l10n.mapPacksEmpty,
              key: const Key('packs-empty'),
              textAlign: TextAlign.center,
            ),
          ),
        for (final item in state.items) _PackCard(item: item),
      ],
    );
  }
}

String _errorText(AppLocalizations l10n, MapPackError e) => switch (e) {
  MapPackError.network => l10n.mapPackErrNetwork,
  MapPackError.corrupt => l10n.mapPackErrCorrupt,
  MapPackError.noSpace => l10n.mapPackErrNoSpace,
  MapPackError.notFound => l10n.mapPackErrNotFound,
  MapPackError.permissionDenied => l10n.mapPackErrPermission,
  MapPackError.notAvailable || MapPackError.server => l10n.mapPackErrServer,
};

class _PackCard extends StatelessWidget {
  const _PackCard({required this.item});

  final PackItem item;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapPacksCubit>();
    final locale = Localizations.localeOf(context).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('packs-delete-dialog'),
        title: Text(l10n.mapPackDeleteTitle),
        content: Text(
          l10n.mapPackDeleteBody(
            formatBytes(locale, item.installed?.sizeBytes ?? item.sizeBytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.mapPackCancel),
          ),
          FilledButton(
            key: const Key('packs-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mapPackDelete),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.remove(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<MapPacksCubit>();
    final locale = Localizations.localeOf(context).toString();
    final remote = item.remote;
    final installed = item.installed;
    final version = (remote?.version ?? installed?.version) ?? 0;

    String? status;
    if (item.phase == PackPhase.downloading) {
      status = l10n.mapPackDownloading(
        ((item.progress?.fraction ?? 0) * 100).floor(),
      );
    } else if (item.phase == PackPhase.verifying) {
      status = l10n.mapPackVerifying;
    } else if (item.phase == PackPhase.paused) {
      status = l10n.mapPackPaused(formatBytes(locale, item.partialBytes));
    }

    return Card(
      key: Key('pack-${item.id}'),
      color: p.card,
      margin: EdgeInsets.only(bottom: r.s(12)),
      child: Padding(
        padding: EdgeInsets.all(r.s(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isInstalled
                      ? Icons.download_done
                      : Icons.download_for_offline_outlined,
                  color: item.isInstalled ? StatusColors.closed : p.hint,
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(8)),
            Wrap(
              spacing: r.s(8),
              runSpacing: r.s(4),
              children: [
                Chip(
                  label: Text(l10n.mapPackVersion(version)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(formatBytes(locale, item.sizeBytes)),
                  visualDensity: VisualDensity.compact,
                ),
                if ((remote ?? installed) != null)
                  Chip(
                    label: Text(
                      l10n.mapPackZoom(
                        remote?.minZoom ?? installed!.minZoom,
                        remote?.maxZoom ?? installed!.maxZoom,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                if (item.isInstalled)
                  Chip(
                    key: Key('pack-installed-${item.id}'),
                    avatar: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: StatusColors.closed,
                    ),
                    label: Text(l10n.mapPackInstalled),
                    visualDensity: VisualDensity.compact,
                  ),
                if (item.updateAvailable)
                  Chip(
                    key: Key('pack-update-${item.id}'),
                    avatar: const Icon(
                      Icons.new_releases_outlined,
                      size: 16,
                      color: StatusColors.attended,
                    ),
                    label: Text(l10n.mapPackUpdateAvailable),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (item.isBusy || item.phase == PackPhase.paused) ...[
              SizedBox(height: r.s(12)),
              LinearProgressIndicator(
                key: Key('pack-progress-${item.id}'),
                value: item.phase == PackPhase.verifying
                    ? null
                    : (item.phase == PackPhase.paused
                          ? (item.sizeBytes == 0
                                ? 0
                                : item.partialBytes / item.sizeBytes)
                          : item.progress?.fraction),
              ),
            ],
            if (status != null) ...[
              SizedBox(height: r.s(4)),
              Text(
                status,
                key: Key('pack-status-${item.id}'),
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (item.error != null) ...[
              SizedBox(height: r.s(8)),
              Text(
                _errorText(l10n, item.error!),
                key: Key('pack-error-${item.id}'),
                style: TextStyle(color: p.error),
              ),
            ],
            SizedBox(height: r.s(8)),
            Wrap(
              spacing: r.s(8),
              children: [
                if (item.canDownload)
                  FilledButton.icon(
                    key: Key('pack-download-${item.id}'),
                    onPressed: () => cubit.download(item.id),
                    icon: const Icon(Icons.download),
                    label: Text(
                      item.phase == PackPhase.paused
                          ? l10n.mapPackResume
                          : item.updateAvailable
                          ? l10n.mapPackUpdate
                          : l10n.mapPackDownload,
                    ),
                  ),
                if (item.isBusy && item.phase == PackPhase.downloading)
                  OutlinedButton.icon(
                    key: Key('pack-pause-${item.id}'),
                    onPressed: () => cubit.pause(item.id),
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.mapPackPause),
                  ),
                if (item.phase == PackPhase.paused && item.partialBytes > 0)
                  TextButton(
                    key: Key('pack-discard-${item.id}'),
                    onPressed: () => cubit.discardPartial(item.id),
                    child: Text(l10n.mapPackDiscard),
                  ),
                if (item.isInstalled && !item.isBusy)
                  TextButton.icon(
                    key: Key('pack-delete-${item.id}'),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.mapPackDelete),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
