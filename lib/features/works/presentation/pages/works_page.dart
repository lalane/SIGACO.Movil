import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_pills.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';
import '../bloc/works_cubit.dart';
import '../widgets/work_widgets.dart';
import '../works_labels.dart';

/// Las obras de la concesion: resumen por estado, filtro, busqueda y tarjetas.
class WorksPage extends StatefulWidget {
  const WorksPage({super.key, this.sampleData = false});

  /// Las obras son de ejemplo: se avisa para que nadie las tome por reales.
  final bool sampleData;

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// El campo de busqueda aparece al tocar la lupa de la cabecera.
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<WorksCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final cubit = context.read<WorksCubit>();
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
    final cubit = context.read<WorksCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<WorksCubit, WorksState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.workTitle,
                subtitle: l10n.workSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('works-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.workSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                  ModuleHeaderAction(
                    key: const Key('works-filter-button'),
                    icon: Icons.filter_list_off,
                    tooltip: l10n.workFilterClear,
                    badge: state.statusFilter == null ? 0 : 1,
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
                  key: const Key('works-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.workSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('works-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.workSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == WorksListStatus.ready &&
                  state.works.isNotEmpty) ...[
                _Summary(state: state),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                  child: ModuleDropdownPill<WorkStatus>(
                    key: const Key('works-status-filter'),
                    value: state.statusFilter,
                    hint: l10n.workFilterState,
                    allLabel: l10n.workFilterAllStates,
                    options: [
                      for (final s in WorkStatus.values)
                        (s, workStatusLabel(l10n, s)),
                    ],
                    onChanged: cubit.setStatus,
                  ),
                ),
              ],
              SizedBox(height: r.s(12)),
              Expanded(child: ModuleListSheet(body: _body(context, state))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WorksState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<WorksCubit>();
    switch (state.status) {
      case WorksListStatus.loading:
        return const Center(
          key: Key('works-loading'),
          child: CircularProgressIndicator(),
        );
      case WorksListStatus.failure:
        return WorksStateView(
          error: state.error ?? WorksError.server,
          onRetry: cubit.load,
        );
      case WorksListStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return WorksStateView.empty(
            message: state.works.isEmpty ? l10n.workEmptyAll : l10n.workEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('works-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: WorkCard(
                  work: visible[i],
                  zone: zone,
                  onTap: () => context.push('/works/${visible[i].id}'),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// El resumen de arriba: cuantas obras hay en cada estado.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final WorksState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ModuleSummaryCard(
      stats: [
        for (final s in WorkStatus.values)
          ModuleStat(
            key: Key('works-stat-${s.name}'),
            value: '${state.count(s)}',
            label: workStatLabel(l10n, s),
            caption: l10n.workStatTotalCaption,
            color: workStatusColor(s),
          ),
      ],
    );
  }
}
