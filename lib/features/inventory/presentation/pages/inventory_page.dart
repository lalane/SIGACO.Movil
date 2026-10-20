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
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../bloc/inventory_cubit.dart';
import '../inventory_labels.dart';
import '../widgets/inventory_widgets.dart';

/// El inventario de activos: resumen por estado, filtros de estado, tipo y
/// fecha de inspeccion, busqueda por ubicacion y las tarjetas.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.sampleData = false});

  /// Los activos son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// El campo de busqueda aparece al tocar la lupa de la cabecera.
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final cubit = context.read<InventoryCubit>();
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
    final cubit = context.read<InventoryCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      bottomNavigationBar: const SigacoModuleNav(current: ModuleTab.inventory),
      body: ModuleGradient(
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.invTitle,
                subtitle: l10n.invSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('inventory-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.invSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                  ModuleHeaderAction(
                    key: const Key('inventory-filter-button'),
                    icon: Icons.filter_list_off,
                    tooltip: l10n.invFilterClear,
                    badge:
                        (state.conditionFilter == null ? 0 : 1) +
                        (state.category == null ? 0 : 1) +
                        (state.inspectedFrom == null ? 0 : 1),
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
                  key: const Key('inventory-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.invSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('inventory-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.invSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == InventoryListStatus.ready &&
                  state.assets.isNotEmpty) ...[
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

  Widget _body(BuildContext context, InventoryState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<InventoryCubit>();
    switch (state.status) {
      case InventoryListStatus.loading:
        return const Center(
          key: Key('inventory-loading'),
          child: CircularProgressIndicator(),
        );
      case InventoryListStatus.failure:
        return InventoryStateView(
          error: state.error ?? InventoryError.server,
          onRetry: cubit.load,
        );
      case InventoryListStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return InventoryStateView.empty(
            message: state.assets.isEmpty ? l10n.invEmptyAll : l10n.invEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('inventory-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: InventoryCard(
                  asset: visible[i],
                  zone: zone,
                  onTap: () => context.push('/inventory/${visible[i].id}'),
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

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pct = NumberFormat('0.#', moduleNumberLocale(locale));
    return ModuleSummaryCard(
      stats: [
        ModuleStat(
          key: const Key('inventory-stat-all'),
          value: '${state.total}',
          label: l10n.invStatTotal,
          caption: l10n.invStatTotalCaption,
        ),
        for (final c in AssetCondition.values)
          ModuleStat(
            key: Key('inventory-stat-${c.name}'),
            value: '${state.count(c)}',
            label: conditionStatLabel(l10n, c),
            caption: l10n.invStatShare(pct.format(state.share(c))),
            color: conditionColor(c),
          ),
      ],
    );
  }
}

/// Estado, tipo y fecha de la ultima inspeccion, en tres campos blancos.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<InventoryCubit>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: ModuleDropdownPill<AssetCondition>(
              key: const Key('inventory-condition-filter'),
              value: state.conditionFilter,
              hint: l10n.invFilterCondition,
              allLabel: l10n.invFilterAllConditions,
              options: [
                for (final c in AssetCondition.values)
                  (c, conditionLabel(l10n, c)),
              ],
              onChanged: cubit.setCondition,
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            flex: 11,
            child: ModuleDropdownPill<String>(
              key: const Key('inventory-category-filter'),
              value: state.category,
              hint: l10n.invFilterCategory,
              allLabel: l10n.invFilterAllCategories,
              options: [for (final c in state.categories) (c, c)],
              onChanged: cubit.setCategory,
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            flex: 11,
            child: ModuleDatePill(
              key: const Key('inventory-from'),
              tooltip: l10n.invInspectedFrom,
              hint: l10n.invDateHint,
              day: state.inspectedFrom,
              onTap: () async {
                final day = await ModuleDatePill.pick(
                  context,
                  state.inspectedFrom,
                );
                if (day != null) cubit.setInspectedFrom(day);
              },
              onClear: () => cubit.setInspectedFrom(null),
              clearKey: const Key('inventory-from-clear'),
            ),
          ),
        ],
      ),
    );
  }
}
