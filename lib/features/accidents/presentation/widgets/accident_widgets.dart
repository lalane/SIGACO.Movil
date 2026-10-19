import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';
import '../accident_labels.dart';
import '../bloc/accidents_cubit.dart';

/// La tarjeta del historial: gravedad, foto con el titulo encima y quien lo
/// registro.
class AccidentCard extends StatelessWidget {
  const AccidentCard({
    super.key,
    required this.accident,
    required this.zone,
    required this.onTap,
  });

  final Accident accident;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final color = severityColor(accident.severity);
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('accident-${accident.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(16), r.s(16), r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: r.s(10),
                  runSpacing: r.s(6),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: r.s(12),
                          height: r.s(12),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: r.s(10)),
                        Text(
                          'ID ${accident.code}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.s(18),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ModuleStatusPill(
                      key: Key('accident-severity-${accident.id}'),
                      label: severityLabel(l10n, accident.severity),
                      color: color,
                    ),
                  ],
                ),
                SizedBox(height: r.s(14)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(r.s(20)),
                  child: SizedBox(
                    height: r.s(170),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ModulePhoto(
                          path: accident.photoPaths.isEmpty
                              ? null
                              : accident.photoPaths.first,
                          fallbackIcon: Icons.warning_amber_rounded,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          left: r.s(14),
                          right: r.s(14),
                          bottom: r.s(12),
                          child: Text(
                            accident.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.s(18),
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: r.s(14)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: r.s(24),
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: Text(
                        _initial(accident.authorName),
                        style: TextStyle(
                          color: moduleSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: r.s(18),
                        ),
                      ),
                    ),
                    SizedBox(width: r.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (accident.authorName != null)
                            Text(
                              accident.authorName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: r.s(15),
                              ),
                            ),
                          if (accident.concessionName != null)
                            Text(
                              accident.concessionName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: moduleMuted,
                                fontSize: r.s(13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.s(8)),
                    Text(
                      moduleDate(accident.createdAt, zone),
                      style: TextStyle(
                        color: moduleMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: r.s(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initial(String? name) {
    final n = name?.trim() ?? '';
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }
}

/// Los estados del historial sin tarjetas.
class AccidentsStateView extends StatelessWidget {
  const AccidentsStateView({super.key, required this.error, this.onRetry})
    : message = null;

  const AccidentsStateView.empty({super.key, required this.message})
    : error = null,
      onRetry = null;

  final AccidentsError? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = error;
    if (e == null) {
      return KeyedSubtree(
        key: const Key('accidents-state-empty'),
        child: ModuleStateView(
          icon: Icons.warning_amber_rounded,
          body: message,
        ),
      );
    }
    final (icon, title, body, retry) = switch (e) {
      AccidentsError.notAvailable => (
        Icons.warning_amber_rounded,
        l10n.accidentsUnavailableTitle,
        l10n.accidentsUnavailableBody,
        false,
      ),
      AccidentsError.permissionDenied => (
        Icons.lock_outline,
        l10n.accidentsNoPermissionTitle,
        l10n.accidentsNoPermissionBody,
        false,
      ),
      AccidentsError.notFound => (
        Icons.search_off,
        l10n.accidentNotFound,
        '',
        false,
      ),
      AccidentsError.network || AccidentsError.server => (
        Icons.cloud_off_outlined,
        l10n.accidentsErrorTitle,
        l10n.accidentsErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('accidents-state-${e.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.accidentsRetry : null,
        onRetry: onRetry,
        retryKey: const Key('accidents-retry'),
      ),
    );
  }
}

/// Hoja con la gravedad, para el boton de filtros de la cabecera.
Future<void> showAccidentFilters(BuildContext context) {
  final cubit = context.read<AccidentsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _FiltersSheet()),
  );
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return BlocBuilder<AccidentsCubit, AccidentsState>(
      builder: (context, state) {
        final cubit = context.read<AccidentsCubit>();
        return SafeArea(
          child: Padding(
            key: const Key('accidents-filters-sheet'),
            padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accidentsFilterTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: r.s(16)),
                Text(
                  l10n.accidentsFilterSeverity,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(height: r.s(8)),
                Wrap(
                  spacing: r.s(8),
                  runSpacing: r.s(8),
                  children: [
                    ChoiceChip(
                      key: const Key('accidents-sheet-severity-all'),
                      label: Text(l10n.accidentsFilterAll),
                      selected: state.severity == null,
                      onSelected: (_) => cubit.setSeverity(null),
                    ),
                    for (final s in AccidentSeverity.values)
                      ChoiceChip(
                        key: Key('accidents-sheet-severity-${s.name}'),
                        label: Text(severityLabel(l10n, s)),
                        selected: state.severity == s,
                        onSelected: (_) => cubit.setSeverity(s),
                      ),
                  ],
                ),
                SizedBox(height: r.s(16)),
                Row(
                  children: [
                    TextButton(
                      key: const Key('accidents-sheet-clear'),
                      onPressed: state.hasActiveFilters
                          ? cubit.clearFilters
                          : null,
                      child: Text(l10n.ticketsFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('accidents-sheet-done'),
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.ticketsFilterDone),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
