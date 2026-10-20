import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_nav.dart';
import '../../../../core/ui/module_pills.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../bloc/maintenance_cubit.dart';
import '../maintenance_labels.dart';
import '../widgets/maintenance_widgets.dart';

/// Los mantenimientos de un indicador (mockup nuevo): resumen por estado,
/// filtros de estado y fechas, y las tarjetas.
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({
    super.key,
    required this.indicator,
    this.sampleData = false,
  });

  final MaintenanceIndicator indicator;

  /// Los mantenimientos son de ejemplo: se avisa para que nadie los tome por
  /// reales.
  final bool sampleData;

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// El campo de busqueda aparece al tocar la lupa de la cabecera.
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<MaintenanceCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final cubit = context.read<MaintenanceCubit>();
    setState(() => _searching = !_searching);
    if (_searching) {
      _searchFocus.requestFocus();
    } else {
      _search.clear();
      cubit.setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<MaintenanceCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      bottomNavigationBar: const SigacoModuleNav(
        current: ModuleTab.maintenance,
      ),
      body: ModuleGradient(
        child: BlocBuilder<MaintenanceCubit, MaintenanceState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title:
                    '${indicatorCode(widget.indicator)} · ${indicatorLabel(l10n, widget.indicator)}',
                subtitle: l10n.maintSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('maintenance-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.maintSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                  ModuleHeaderAction(
                    key: const Key('maintenance-filter-button'),
                    icon: Icons.filter_list_off,
                    tooltip: l10n.maintFilterClear,
                    badge:
                        (state.statusFilter == null ? 0 : 1) +
                        (state.from == null ? 0 : 1) +
                        (state.to == null ? 0 : 1),
                    onPressed: state.hasActiveFilters
                        ? () {
                            _search.clear();
                            cubit.clearFilters();
                          }
                        : null,
                  ),
                ],
              ),
              if (widget.sampleData)
                Container(
                  key: const Key('maintenance-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.maintSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('maintenance-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.maintSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == MaintenanceListStatus.ready &&
                  state.orders.isNotEmpty) ...[
                _Summary(state: state),
                _FilterRow(state: state),
              ],
              SizedBox(height: r.s(12)),
              Expanded(child: ModuleListSheet(body: _body(context, state))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MaintenanceState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<MaintenanceCubit>();
    switch (state.status) {
      case MaintenanceListStatus.loading:
        return const Center(
          key: Key('maintenance-loading'),
          child: CircularProgressIndicator(),
        );
      case MaintenanceListStatus.failure:
        return MaintenanceStateView(
          error: state.error ?? MaintenanceError.server,
          onRetry: cubit.load,
        );
      case MaintenanceListStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return MaintenanceStateView.empty(
            message: state.orders.isEmpty
                ? l10n.maintEmptyAll
                : l10n.maintEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('maintenance-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: MaintenanceCard(
                  order: visible[i],
                  zone: zone,
                  onTap: () => context.push(
                    '/maintenance/${widget.indicator.name}/${visible[i].id}',
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// El resumen de arriba: el total y cuantos hay en cada estado.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final MaintenanceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pct = NumberFormat('0.#', moduleNumberLocale(locale));
    return ModuleSummaryCard(
      stats: [
        ModuleStat(
          key: const Key('maintenance-stat-all'),
          value: '${state.total}',
          label: l10n.maintStatTotal,
          caption: l10n.maintStatTotalCaption,
        ),
        for (final s in MaintenanceStatus.values)
          ModuleStat(
            key: Key('maintenance-stat-${s.name}'),
            value: '${state.count(s)}',
            label: statLabel(l10n, s),
            caption: l10n.maintStatShare(pct.format(state.share(s))),
            color: statusColor(s),
          ),
      ],
    );
  }
}

/// Estado y rango de fechas, en tres campos blancos redondeados.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final MaintenanceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<MaintenanceCubit>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: ModuleDropdownPill<MaintenanceStatus>(
              key: const Key('maintenance-status-filter'),
              value: state.statusFilter,
              hint: l10n.maintFilterState,
              allLabel: l10n.maintFilterAllStates,
              options: [
                for (final s in MaintenanceStatus.values)
                  (s, statusLabel(l10n, s)),
              ],
              onChanged: cubit.setStatus,
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            flex: 11,
            child: ModuleDatePill(
              key: const Key('maintenance-from'),
              tooltip: l10n.maintDateFrom,
              hint: l10n.maintDateHint,
              day: state.from,
              onTap: () async {
                final day = await ModuleDatePill.pick(context, state.from);
                if (day != null) cubit.setFrom(day);
              },
              onClear: () => cubit.setFrom(null),
              clearKey: const Key('maintenance-from-clear'),
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            flex: 11,
            child: ModuleDatePill(
              key: const Key('maintenance-to'),
              tooltip: l10n.maintDateTo,
              hint: l10n.maintDateHint,
              day: state.to,
              onTap: () async {
                final day = await ModuleDatePill.pick(context, state.to);
                if (day != null) cubit.setTo(day);
              },
              onClear: () => cubit.setTo(null),
              clearKey: const Key('maintenance-to-clear'),
            ),
          ),
        ],
      ),
    );
  }
}
