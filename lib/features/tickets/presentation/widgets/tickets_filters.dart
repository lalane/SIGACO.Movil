import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/tickets_cubit.dart';
import '../ticket_labels.dart';

/// Las pestanas de estado del historial con la cuenta de cada una.
class TicketsFilterChips extends StatelessWidget {
  const TicketsFilterChips({super.key, required this.state});

  final TicketsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ModuleFilterChips<TicketFilter>(
      keyPrefix: 'tickets',
      selected: state.filter,
      onSelect: context.read<TicketsCubit>().setFilter,
      chips: [
        for (final f in TicketFilter.values)
          ModuleChip(
            value: f,
            id: f.name,
            label: filterLabel(l10n, f),
            count: state.count(f),
            badge: switch (f) {
              TicketFilter.all => Colors.white,
              TicketFilter.open => StatusColors.open,
              TicketFilter.attended => StatusColors.attended,
            },
          ),
      ],
    );
  }
}

/// Hoja con el estado y el orden, para quien prefiere el boton de filtros.
Future<void> showTicketFilters(BuildContext context) {
  final cubit = context.read<TicketsCubit>();
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
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        final cubit = context.read<TicketsCubit>();
        return SafeArea(
          child: Padding(
            key: const Key('tickets-filters-sheet'),
            padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ticketsFilterTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: r.s(16)),
                Text(
                  l10n.ticketsFilterStatus,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(height: r.s(8)),
                Wrap(
                  spacing: r.s(8),
                  runSpacing: r.s(8),
                  children: [
                    for (final f in TicketFilter.values)
                      ChoiceChip(
                        key: Key('tickets-sheet-filter-${f.name}'),
                        label: Text(
                          '${filterLabel(l10n, f)} (${state.count(f)})',
                        ),
                        selected: state.filter == f,
                        onSelected: (_) => cubit.setFilter(f),
                      ),
                  ],
                ),
                SizedBox(height: r.s(8)),
                SwitchListTile(
                  key: const Key('tickets-sheet-sort'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.ticketsDueSort),
                  value: state.sortByDue,
                  onChanged: (_) => cubit.toggleSortByDue(),
                ),
                SizedBox(height: r.s(8)),
                Row(
                  children: [
                    TextButton(
                      key: const Key('tickets-sheet-clear'),
                      onPressed: state.hasActiveFilters
                          ? cubit.clearFilters
                          : null,
                      child: Text(l10n.ticketsFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('tickets-sheet-done'),
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
