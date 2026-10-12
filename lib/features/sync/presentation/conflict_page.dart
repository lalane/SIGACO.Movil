import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/sigaco_wordmark.dart';
import '../../../core/offline/operation.dart';
import '../../../core/offline/sync_cubit.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/sigaco_palette.dart';
import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'sync_labels.dart';

/// Resolucion visual de un conflicto (DEV-MOB-066): lo capturado en el telefono
/// junto a lo que hay en el servidor, y una decision. Nada se aplica en silencio.
class ConflictPage extends StatefulWidget {
  const ConflictPage({super.key, required this.operationId});

  final String operationId;

  @override
  State<ConflictPage> createState() => _ConflictPageState();
}

class _ConflictPageState extends State<ConflictPage> {
  late final Future<SyncConflict?> _conflict = context
      .read<SyncCubit>()
      .conflictOf(widget.operationId);

  PendingOperation? _operation(SyncState state) {
    for (final o in state.items) {
      if (o.id == widget.operationId) return o;
    }
    return null;
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            key: const Key('conflict-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('conflict-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _keepServer() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SyncCubit>();
    final router = GoRouter.of(context);
    if (!await _confirm(
      l10n.syncConflictKeepServer,
      l10n.syncConflictKeepServerBody,
      l10n.syncConflictKeepServer,
    )) {
      return;
    }
    await cubit.discard(widget.operationId);
    if (router.canPop()) router.pop();
  }

  Future<void> _keepMine(SyncConflict conflict) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SyncCubit>();
    final router = GoRouter.of(context);
    if (!await _confirm(
      l10n.syncConflictKeepMine,
      l10n.syncConflictKeepMineBody,
      l10n.syncConflictKeepMine,
    )) {
      return;
    }
    // Se manda sobre la version actual del servidor; el servidor decide si la
    // acepta o si vuelve a haber conflicto.
    await cubit.retry(widget.operationId, baseVersion: conflict.serverVersion);
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final op = _operation(context.watch<SyncCubit>().state);
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: p.gradientTop,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(8), r.s(4), r.s(16), r.s(16)),
                child: Row(
                  children: [
                    BackButton(color: p.textOnTop),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SigacoWordmark(fontSize: r.s(26)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.syncConflictTitle,
                              maxLines: 1,
                              style: TextStyle(
                                color: p.textOnTop.withValues(alpha: 0.8),
                                fontSize: r.s(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<SyncConflict?>(
              future: _conflict,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final conflict = snapshot.data;
                if (conflict == null || op == null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(r.s(32)),
                      child: Text(
                        l10n.syncConflictMissing,
                        key: const Key('conflict-missing'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.hint, fontSize: r.s(14)),
                      ),
                    ),
                  );
                }
                return _Details(
                  op: op,
                  conflict: conflict,
                  onKeepServer: _keepServer,
                  onKeepMine: () => _keepMine(conflict),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.op,
    required this.conflict,
    required this.onKeepServer,
    required this.onKeepMine,
  });

  final PendingOperation op;
  final SyncConflict conflict;
  final VoidCallback onKeepServer;
  final VoidCallback onKeepMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final mine = op.payload;
    final server = conflict.serverPayload;
    final keys = <String>{...mine.keys, ...?server?.keys};
    final different = {
      for (final k in keys)
        if (server != null && '${mine[k]}' != '${server[k]}') k,
    };
    final name = operationName(op);
    return ListView(
      padding: r
          .sidePadding(minGutter: r.s(20))
          .copyWith(top: r.s(20), bottom: r.s(32)),
      children: [
        Text(
          name == null
              ? entityLabel(l10n, op.entity)
              : '${entityLabel(l10n, op.entity)} · $name',
          style: TextStyle(
            color: p.textOnBottom,
            fontSize: r.s(17),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: r.s(6)),
        Text(
          l10n.syncConflictIntro,
          style: TextStyle(color: p.hint, fontSize: r.s(13.5)),
        ),
        if (conflict.message != null) ...[
          SizedBox(height: r.s(8)),
          Text(
            l10n.syncMessageFromServer(conflict.message!),
            key: const Key('conflict-message'),
            style: TextStyle(
              color: p.textOnBottom,
              fontSize: r.s(13.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: r.s(16)),
        _Version(
          key: const Key('conflict-mine'),
          title: l10n.syncConflictMine,
          version: conflict.localVersion,
          fields: mine,
          different: different,
        ),
        SizedBox(height: r.s(12)),
        _Version(
          key: const Key('conflict-server'),
          title: l10n.syncConflictServer,
          version: conflict.serverVersion,
          fields: server,
          different: different,
        ),
        SizedBox(height: r.s(20)),
        FilledButton(
          key: const Key('conflict-keep-server'),
          onPressed: onKeepServer,
          child: Text(l10n.syncConflictKeepServer),
        ),
        SizedBox(height: r.s(10)),
        OutlinedButton(
          key: const Key('conflict-keep-mine'),
          onPressed: onKeepMine,
          child: Text(l10n.syncConflictKeepMine),
        ),
      ],
    );
  }
}

class _Version extends StatelessWidget {
  const _Version({
    super.key,
    required this.title,
    required this.version,
    required this.fields,
    required this.different,
  });

  final String title;
  final int? version;
  final Map<String, Object?>? fields;
  final Set<String> different;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(14.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (version != null)
                Text(
                  l10n.syncConflictVersion('$version'),
                  style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
                ),
            ],
          ),
          SizedBox(height: r.s(8)),
          if (fields == null || fields!.isEmpty)
            Text(
              l10n.syncConflictNoDetail,
              style: TextStyle(color: p.hint, fontSize: r.s(13)),
            )
          else
            for (final e in fields!.entries)
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.s(3)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (different.contains(e.key))
                      Container(
                        key: Key('diff-${e.key}'),
                        width: r.s(4),
                        height: r.s(16),
                        margin: EdgeInsets.only(right: r.s(8)),
                        decoration: BoxDecoration(
                          color: StatusColors.attended,
                          borderRadius: BorderRadius.circular(r.s(2)),
                        ),
                      )
                    else
                      SizedBox(width: r.s(12)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r.s(120)),
                      child: Text(
                        e.key,
                        style: TextStyle(color: p.hint, fontSize: r.s(13)),
                      ),
                    ),
                    SizedBox(width: r.s(10)),
                    Expanded(
                      child: Text(
                        displayValue(e.value),
                        style: TextStyle(
                          color: p.textOnBottom,
                          fontSize: r.s(13.5),
                          fontWeight: different.contains(e.key)
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
