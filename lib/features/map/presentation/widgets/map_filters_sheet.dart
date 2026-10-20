import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../bloc/map_cubit.dart';
import '../map_labels.dart';

/// Filtros de la pestana abierta: categoria (varias) y estado (uno). Se aplican
/// al tocar, sin boton de confirmar; "Listo" solo cierra la hoja.
Future<void> showMapFilters(BuildContext context) {
  final cubit = context.read<MapCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
    final p = context.palette;
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        final cubit = context.read<MapCubit>();
        return SafeArea(
          child: SingleChildScrollView(
            key: const Key('map-filters-sheet'),
            padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mapFiltersTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: r.s(16)),
                if (state.availableCategories.isNotEmpty) ...[
                  Text(
                    l10n.mapFilterCategory,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SizedBox(height: r.s(8)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.s(8),
                    children: [
                      for (final c in state.availableCategories)
                        FilterChip(
                          key: Key('map-filter-category-$c'),
                          label: Text(c),
                          selected: state.categories.contains(c),
                          onSelected: (_) => cubit.toggleCategory(c),
                        ),
                    ],
                  ),
                  SizedBox(height: r.s(16)),
                ],
                Text(
                  l10n.mapFilterStatus,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(height: r.s(8)),
                Wrap(
                  spacing: r.s(8),
                  runSpacing: r.s(8),
                  children: [
                    ChoiceChip(
                      key: const Key('map-filter-status-all'),
                      label: Text(l10n.mapFilterAll),
                      selected: state.statusFilter == null,
                      onSelected: (_) => cubit.setStatusFilter(null),
                    ),
                    for (final s in PinStatus.values)
                      ChoiceChip(
                        key: Key('map-filter-status-${s.name}'),
                        avatar: CircleAvatar(
                          radius: 6,
                          backgroundColor: pinColor(p, s),
                        ),
                        label: Text(statusLabel(l10n, s)),
                        selected: state.statusFilter == s,
                        onSelected: (_) => cubit.setStatusFilter(s),
                      ),
                  ],
                ),
                if (state.hasOperatingStates) ...[
                  SizedBox(height: r.s(16)),
                  Text(
                    l10n.mapFilterOperating,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SizedBox(height: r.s(8)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.s(8),
                    children: [
                      ChoiceChip(
                        key: const Key('map-filter-operating-all'),
                        label: Text(l10n.mapFilterAll),
                        selected: state.operatingFilter == null,
                        onSelected: (_) => cubit.setOperatingFilter(null),
                      ),
                      for (final s in OperatingState.values)
                        ChoiceChip(
                          key: Key('map-filter-operating-${s.name}'),
                          label: Text(operatingStateLabel(l10n, s)),
                          selected: state.operatingFilter == s,
                          onSelected: (_) => cubit.setOperatingFilter(s),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: r.s(20)),
                Row(
                  children: [
                    TextButton(
                      key: const Key('map-filter-clear'),
                      onPressed: state.activeFilterCount == 0
                          ? null
                          : cubit.clearFilters,
                      child: Text(l10n.mapFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('map-filter-done'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.mapFilterDone),
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
