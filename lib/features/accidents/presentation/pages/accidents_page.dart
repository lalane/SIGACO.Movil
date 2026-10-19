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
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/accidents_repository.dart';
import '../accident_labels.dart';
import '../bloc/accidents_cubit.dart';
import '../widgets/accident_widgets.dart';

/// El historial de accidentes (mockup nuevo): resumen por tipo, pestanas con su
/// cuenta, tarjetas y el boton "Nuevo accidente". Pendiente de homologacion
/// (OI-33 del Business Blueprint).
class AccidentsPage extends StatefulWidget {
  const AccidentsPage({super.key, this.sampleData = false});

  /// Los accidentes son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  @override
  State<AccidentsPage> createState() => _AccidentsPageState();
}

class _AccidentsPageState extends State<AccidentsPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// El campo de busqueda aparece al tocar la lupa de la cabecera.
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<AccidentsCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _open(String location) async {
    final cubit = context.read<AccidentsCubit>();
    await context.push(location);
    if (mounted && !cubit.isClosed) await cubit.refresh();
  }

  void _toggleSearch() {
    final cubit = context.read<AccidentsCubit>();
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
    final cubit = context.read<AccidentsCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<AccidentsCubit, AccidentsState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.accidentsTitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('accidents-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.accidentsSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                  ModuleHeaderAction(
                    key: const Key('accidents-filter-button'),
                    icon: Icons.filter_list,
                    tooltip: l10n.accidentsFilterTooltip,
                    badge: state.severity == null ? 0 : 1,
                    onPressed: () => showAccidentFilters(context),
                  ),
                ],
              ),
              if (widget.sampleData)
                Container(
                  key: const Key('accidents-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.accidentsSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('accidents-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.accidentsSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == AccidentsStatus.ready &&
                  state.accidents.isNotEmpty)
                _Summary(state: state),
              _Chips(state: state),
              SizedBox(height: r.s(12)),
              Expanded(
                child: ModuleListSheet(
                  buttonKey: const Key('accidents-new'),
                  buttonLabel: l10n.accidentsNew,
                  onButton: () => _open('/accidents/new'),
                  body: _body(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AccidentsState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<AccidentsCubit>();
    switch (state.status) {
      case AccidentsStatus.loading:
        return const Center(
          key: Key('accidents-loading'),
          child: CircularProgressIndicator(),
        );
      case AccidentsStatus.failure:
        return AccidentsStateView(
          error: state.error ?? AccidentsError.server,
          onRetry: cubit.load,
        );
      case AccidentsStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return AccidentsStateView.empty(
            message: state.accidents.isEmpty
                ? l10n.accidentsEmptyAll
                : l10n.accidentsEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('accidents-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: AccidentCard(
                  accident: visible[i],
                  zone: zone,
                  onTap: () => _open('/accidents/${visible[i].id}'),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// El resumen de arriba: el total y cuantos hay de cada tipo, con su parte del
/// total.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final AccidentsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pct = NumberFormat('0.#', moduleNumberLocale(locale));
    return ModuleSummaryCard(
      stats: [
        ModuleStat(
          key: const Key('accidents-stat-all'),
          value: '${state.total}',
          label: l10n.accidentsStatTotal,
          caption: l10n.accidentsStatTotalShare,
        ),
        for (final f in AccidentFilter.values)
          if (f != AccidentFilter.all)
            ModuleStat(
              key: Key('accidents-stat-${f.name}'),
              value: '${state.count(f)}',
              label: filterLabel(l10n, f),
              caption: l10n.accidentsStatShare(pct.format(state.share(f))),
              color: filterColor(f),
            ),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.state});

  final AccidentsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ModuleFilterChips<AccidentFilter>(
      keyPrefix: 'accidents',
      selected: state.filter,
      onSelect: context.read<AccidentsCubit>().setFilter,
      chips: [
        for (final f in AccidentFilter.values)
          ModuleChip(
            value: f,
            id: f.name,
            label: filterLabel(l10n, f),
            count: state.count(f),
            badge: filterColor(f),
          ),
      ],
    );
  }
}
