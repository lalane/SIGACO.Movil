import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_nav.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../bloc/tickets_cubit.dart';
import '../widgets/ticket_widgets.dart';
import '../widgets/tickets_filters.dart';
import '../widgets/tickets_state_view.dart';

/// El historial de tickets (mockup nuevo): busqueda, orden por vencimiento,
/// pestanas por estado con su cuenta, tarjetas y el boton "Nuevo ticket".
class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key, this.sampleData = false});

  /// Los tickets son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<TicketsCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Abre otra pantalla del modulo y, al volver, refresca la lista.
  Future<void> _open(String location) async {
    final cubit = context.read<TicketsCubit>();
    await context.push(location);
    if (mounted && !cubit.isClosed) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<TicketsCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      bottomNavigationBar: const SigacoModuleNav(current: ModuleTab.tickets),
      body: ModuleGradient(
        child: BlocBuilder<TicketsCubit, TicketsState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.ticketsTitle,
                subtitle: l10n.ticketsSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('tickets-search-button'),
                    icon: Icons.search,
                    tooltip: l10n.ticketsSearchTooltip,
                    onPressed: _searchFocus.requestFocus,
                  ),
                  ModuleHeaderAction(
                    key: const Key('tickets-filter-button'),
                    icon: Icons.filter_list,
                    tooltip: l10n.ticketsFilterTooltip,
                    badge: state.hasActiveFilters ? 1 : 0,
                    onPressed: () => showTicketFilters(context),
                  ),
                ],
              ),
              if (widget.sampleData)
                Container(
                  key: const Key('tickets-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.ticketsSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              ModuleSearchBar(
                fieldKey: const Key('tickets-search'),
                controller: _search,
                focus: _searchFocus,
                hint: l10n.ticketsSearchHint,
                onChanged: cubit.setQuery,
                sortLabel: l10n.ticketsDueSort,
                sortActive: state.sortByDue,
                onSort: cubit.toggleSortByDue,
                sortKey: const Key('tickets-sort-due'),
              ),
              TicketsFilterChips(state: state),
              SizedBox(height: r.s(12)),
              Expanded(
                child: ModuleListSheet(
                  buttonKey: const Key('tickets-new'),
                  buttonLabel: l10n.ticketsNew,
                  onButton: () => _open('/tickets/new'),
                  body: _body(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TicketsState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<TicketsCubit>();
    switch (state.status) {
      case TicketsStatus.loading:
        return const Center(
          key: Key('tickets-loading'),
          child: CircularProgressIndicator(),
        );
      case TicketsStatus.failure:
        return TicketsStateView(
          error: state.error ?? TicketsError.server,
          onRetry: cubit.load,
        );
      case TicketsStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return TicketsStateView.empty(
            message: state.tickets.isEmpty
                ? l10n.ticketsEmptyAll
                : l10n.ticketsEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('tickets-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: TicketCard(
                  ticket: visible[i],
                  now: state.now,
                  zone: zone,
                  onTap: () => _open('/tickets/${visible[i].id}'),
                ),
              ),
            ),
          ),
        );
    }
  }
}
