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
  const InventoryPage({
    super.key,
    this.sampleData = false,
    this.canCreate = false,
  });

  /// Los activos son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  /// El perfil puede dar de alta activos: se ofrece el boton de alta.
  final bool canCreate;

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

  /// El alta: al volver con un activo nuevo, la lista se pone al dia (lo que
  /// quedo en el telefono tambien se ve).
  Future<void> _create() async {
    final cubit = context.read<InventoryCubit>();
    final created = await context.push<bool>('/inventory/new');
    if (created == true && mounted && !cubit.isClosed) await cubit.refresh();
  }

  /// Un alta que sigue en el telefono no tiene ficha en el servidor: se ve en
  /// la cola de sincronizacion.
  void _open(InventoryAsset asset) => context.push(
    asset.pendingSync ? '/sync' : '/inventory/${Uri.encodeComponent(asset.id)}',
  );

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
                    key: const Key('inventory-scan-button'),
                    icon: Icons.qr_code_scanner,
                    tooltip: l10n.invScanTooltip,
                    onPressed: () => context.push('/inventory/scan'),
                  ),
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
                        (state.typeCode == null ? 0 : 1) +
                        (state.inspectedFrom == null ? 0 : 1) +
                        (state.inspectedTo == null ? 0 : 1),
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
              // Los filtros se quedan aunque no haya resultados o falle la
              // consulta: siempre se pueden deshacer.
              if (state.hasContent) ...[
                if (state.counts != null) _Summary(state: state),
                _FilterRow(state: state),
              ],
              SizedBox(height: r.s(12)),
              Expanded(
                child: ModuleListSheet(
                  buttonKey: const Key('inventory-new'),
                  buttonLabel: widget.canCreate ? l10n.invNew : null,
                  buttonIcon: Icons.add_location_alt_outlined,
                  onButton: _create,
                  body: Column(
                    children: [
                      if (state.refreshing)
                        const LinearProgressIndicator(
                          key: Key('inventory-refreshing'),
                          minHeight: 3,
                        ),
                      Expanded(child: _body(context, state)),
                    ],
                  ),
                ),
              ),
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
            message: state.hasActiveFilters ? l10n.invEmpty : l10n.invEmptyAll,
          );
        }
        // Abajo, mientras haya mas: la rueda (y se piden) o el reintento.
        final footer =
            state.hasMore || state.loadingMore || state.moreError != null;
        return NotificationListener<ScrollNotification>(
          // La pagina siguiente se pide antes de llegar al final.
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical &&
                n.metrics.extentAfter < r.s(600)) {
              _more();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView.builder(
              key: const Key('inventory-list'),
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
              itemCount: visible.length + (footer ? 1 : 0),
              itemBuilder: (context, i) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Responsive.formMaxWidth,
                  ),
                  child: i < visible.length
                      ? InventoryCard(
                          asset: visible[i],
                          zone: zone,
                          onTap: () => _open(visible[i]),
                        )
                      : _MoreFooter(state: state, onShown: _more),
                ),
              ),
            ),
          ),
        );
    }
  }

  /// Pide la pagina siguiente si hay y no se esta pidiendo ya (ni fallo: ahi
  /// se espera al reintento).
  void _more() {
    if (!mounted) return;
    final cubit = context.read<InventoryCubit>();
    final s = cubit.state;
    if (!s.hasMore || s.loadingMore || s.moreError != null) return;
    cubit.loadMore();
  }
}

/// El final de la lista mientras hay mas: la rueda mientras llega la pagina
/// siguiente o, si no llego, el aviso y el reintento. Al verse, pide la pagina
/// (tambien cuando la lista es corta y no hay como desplazarse).
class _MoreFooter extends StatefulWidget {
  const _MoreFooter({required this.state, required this.onShown});

  final InventoryState state;
  final VoidCallback onShown;

  @override
  State<_MoreFooter> createState() => _MoreFooterState();
}

class _MoreFooterState extends State<_MoreFooter> {
  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(_MoreFooter old) {
    super.didUpdateWidget(old);
    _ask();
  }

  void _ask() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.onShown();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final error = widget.state.moreError;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: error == null
          ? Center(
              key: const Key('inventory-more'),
              child: SizedBox.square(
                dimension: r.s(28),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          : Column(
              key: const Key('inventory-more-error'),
              children: [
                Text(
                  error == InventoryError.network
                      ? '${l10n.invMoreError} ${l10n.invOfflineTitle}.'
                      : l10n.invMoreError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: r.s(14),
                  ),
                ),
                TextButton(
                  key: const Key('inventory-more-retry'),
                  onPressed: context.read<InventoryCubit>().loadMore,
                  child: Text(l10n.invRetry),
                ),
              ],
            ),
    );
  }
}

/// El resumen de arriba, con los conteos del servidor: cuantos cumplen la
/// busqueda, el tipo y las fechas, y cuantos de ellos hay en cada estado.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pct = NumberFormat('0.#', moduleNumberLocale(locale));
    final number = NumberFormat.decimalPattern(moduleNumberLocale(locale));
    return ModuleSummaryCard(
      stats: [
        ModuleStat(
          key: const Key('inventory-stat-all'),
          value: number.format(state.counts?.total ?? state.total),
          label: l10n.invStatTotal,
          caption: l10n.invStatTotalCaption,
        ),
        for (final c in AssetCondition.assessed)
          ModuleStat(
            key: Key('inventory-stat-${c.name}'),
            value: number.format(state.count(c)),
            label: conditionStatLabel(l10n, c),
            caption: l10n.invStatShare(pct.format(state.share(c))),
            color: conditionColor(c),
          ),
      ],
    );
  }
}

/// Estado, tipo y fecha de monitoreo, en campos blancos; los aplica el
/// servidor.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<InventoryCubit>();
    final language = appLanguage(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 10,
                child: ModuleDropdownPill<AssetCondition>(
                  key: const Key('inventory-condition-filter'),
                  value: state.conditionFilter,
                  hint: l10n.invFilterCondition,
                  allLabel: l10n.invFilterAllConditions,
                  // El servidor no filtra lo que no se evaluo.
                  options: [
                    for (final c in AssetCondition.assessed)
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
                  value: state.typeCode,
                  hint: l10n.invFilterCategory,
                  allLabel: l10n.invFilterAllCategories,
                  options: [
                    for (final t in state.typeOptions(language))
                      (t.code, t.label(language)),
                  ],
                  onChanged: cubit.setType,
                ),
              ),
            ],
          ),
          // Con algun monitoreo ejecutado entre esos dias (en el servidor).
          SizedBox(height: r.s(8)),
          Row(
            children: [
              Expanded(
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
              SizedBox(width: r.s(8)),
              Expanded(
                child: ModuleDatePill(
                  key: const Key('inventory-to'),
                  tooltip: l10n.invInspectedTo,
                  hint: l10n.invDateHint,
                  day: state.inspectedTo,
                  onTap: () async {
                    final day = await ModuleDatePill.pick(
                      context,
                      state.inspectedTo,
                    );
                    if (day != null) cubit.setInspectedTo(day);
                  },
                  onClear: () => cubit.setInspectedTo(null),
                  clearKey: const Key('inventory-to-clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
