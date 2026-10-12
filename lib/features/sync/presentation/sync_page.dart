import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/offline/operation.dart';
import '../../../core/offline/sync_cubit.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/sigaco_palette.dart';
import '../../../core/ui/page_header.dart';
import '../../../core/time/concession_zone.dart';
import '../../../core/time/concession_zone_cubit.dart';
import '../../../core/ui/zone_format.dart';
import '../../../l10n/app_localizations.dart';
import 'sync_labels.dart';

/// Centro de sincronizacion (DEV-MOB-065): lo que espera enviarse, lo que el
/// servidor rechazo y lo que quedo en conflicto, con lo que se puede hacer.
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.syncTitle),
          const Expanded(child: _Body()),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final state = context.watch<SyncCubit>().state;
    final online = context.select((ConnectivityCubit c) => c.state.online);
    final zone = context.select((ConcessionZoneCubit c) => c.state);

    final attention = state.items.where((o) => o.needsAttention).toList();
    final pending = state.items.where((o) => o.isOpen).toList();

    return ListView(
      padding: r
          .sidePadding(minGutter: r.s(20))
          .copyWith(top: r.s(20), bottom: r.s(32)),
      children: [
        _Summary(state: state, online: online, zone: zone),
        SizedBox(height: r.s(20)),
        if (state.isEmpty)
          Padding(
            key: const Key('sync-empty'),
            padding: EdgeInsets.symmetric(vertical: r.s(32)),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: p.accentOnBottom,
                  size: r.s(44),
                ),
                SizedBox(height: r.s(12)),
                Text(
                  l10n.syncAllDone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: r.s(6)),
                Text(
                  l10n.syncAllDoneBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.hint, fontSize: r.s(13)),
                ),
              ],
            ),
          ),
        if (attention.isNotEmpty) ...[
          _SectionTitle(l10n.syncSectionAttention),
          for (final op in attention) _OperationCard(op: op, zone: zone),
        ],
        if (pending.isNotEmpty) ...[
          _SectionTitle(l10n.syncSectionPending),
          for (final op in pending) _OperationCard(op: op, zone: zone),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.state,
    required this.online,
    required this.zone,
  });

  final SyncState state;
  final bool online;
  final ConcessionZone? zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final last = state.lastSyncAt;
    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                online ? Icons.sync : Icons.cloud_off_outlined,
                color: p.accentOnBottom,
                size: r.s(22),
              ),
              SizedBox(width: r.s(10)),
              Expanded(
                child: Text(
                  last == null
                      ? l10n.syncNever
                      : l10n.syncLastSync(formatInZone(context, last, zone)),
                  key: const Key('sync-last'),
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!online) ...[
            SizedBox(height: r.s(8)),
            Text(
              l10n.syncOfflineHint,
              key: const Key('sync-offline-hint'),
              style: TextStyle(color: p.hint, fontSize: r.s(13)),
            ),
          ],
          SizedBox(height: r.s(14)),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('sync-now'),
              onPressed: online && !state.running
                  ? () => context.read<SyncCubit>().syncNow()
                  : null,
              icon: state.running
                  ? SizedBox(
                      width: r.s(16),
                      height: r.s(16),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(state.running ? l10n.syncRunning : l10n.syncNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(top: r.s(8), bottom: r.s(8)),
      child: Text(
        text,
        style: TextStyle(
          color: p.textOnBottom,
          fontSize: r.s(15),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.op, required this.zone});

  final PendingOperation op;
  final ConcessionZone? zone;

  Future<void> _discard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SyncCubit>();
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncDiscardTitle),
        content: Text(l10n.syncDiscardBody),
        actions: [
          TextButton(
            key: const Key('sync-discard-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('sync-discard-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.syncActionDiscard),
          ),
        ],
      ),
    );
    if (sure == true) await cubit.discard(op.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final name = operationName(op);
    final color = statusColor(op.status);
    return Container(
      key: Key('sync-item-${op.id}'),
      margin: EdgeInsets.only(bottom: r.s(10)),
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name == null
                      ? entityLabel(l10n, op.entity)
                      : '${entityLabel(l10n, op.entity)} · $name',
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: r.s(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.s(8),
                  vertical: r.s(3),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(r.s(10)),
                  border: Border.all(color: color),
                ),
                child: Text(
                  statusLabel(l10n, op.status),
                  style: TextStyle(
                    color: p.textOnBottom,
                    fontSize: r.s(11.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(4)),
          Text(
            '${kindLabel(l10n, op.kind)} · '
            '${l10n.syncCaptured(formatInZone(context, op.capturedAt, zone))}'
            '${op.attempts > 0 ? ' · ${l10n.syncAttempts(op.attempts)}' : ''}',
            style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
          ),
          if (op.lastError != null && op.needsAttention) ...[
            SizedBox(height: r.s(6)),
            Text(
              op.lastError!,
              key: Key('sync-error-${op.id}'),
              style: TextStyle(color: p.textOnBottom, fontSize: r.s(13)),
            ),
          ],
          if (op.status != OperationStatus.sending) ...[
            SizedBox(height: r.s(8)),
            Wrap(
              spacing: r.s(8),
              children: [
                if (op.status == OperationStatus.conflict)
                  FilledButton.tonal(
                    key: Key('sync-review-${op.id}'),
                    onPressed: () => context.push('/sync/conflict/${op.id}'),
                    child: Text(l10n.syncActionReview),
                  ),
                if (op.status == OperationStatus.rejected)
                  FilledButton.tonal(
                    key: Key('sync-retry-${op.id}'),
                    onPressed: () => context.read<SyncCubit>().retry(op.id),
                    child: Text(l10n.syncActionRetry),
                  ),
                TextButton(
                  key: Key('sync-discard-${op.id}'),
                  onPressed: () => _discard(context),
                  child: Text(l10n.syncActionDiscard),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
