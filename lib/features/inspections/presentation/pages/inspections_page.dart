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
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../bloc/inspections_cubit.dart';
import '../inspections_labels.dart';
import '../widgets/inspection_widgets.dart';

/// Las inspecciones asignadas: resumen por estado, filtro, busqueda y tarjetas.
class InspectionsPage extends StatefulWidget {
  const InspectionsPage({super.key, this.sampleData = false});

  /// Las inspecciones son de ejemplo: se avisa para que nadie las tome por
  /// reales.
  final bool sampleData;

  @override
  State<InspectionsPage> createState() => _InspectionsPageState();
}

class _InspectionsPageState extends State<InspectionsPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// El campo de busqueda aparece al tocar la lupa de la cabecera.
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<InspectionsCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final cubit = context.read<InspectionsCubit>();
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
    final cubit = context.read<InspectionsCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<InspectionsCubit, InspectionsState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.inspTitle,
                subtitle: l10n.inspSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('inspections-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.inspSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                  ModuleHeaderAction(
                    key: const Key('inspections-filter-button'),
                    icon: Icons.filter_list_off,
                    tooltip: l10n.inspFilterClear,
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
                  key: const Key('inspections-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.inspSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('inspections-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.inspSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == InspectionsListStatus.ready &&
                  state.items.isNotEmpty) ...[
                ModuleSummaryCard(
                  stats: [
                    for (final s in const [
                      InspectionStatus.pending,
                      InspectionStatus.inProgress,
                      InspectionStatus.attended,
                      InspectionStatus.closed,
                    ])
                      ModuleStat(
                        key: Key('inspections-stat-${s.name}'),
                        value: '${state.count(s)}',
                        label: inspectionStatLabel(l10n, s),
                        caption: l10n.inspStatCaption,
                        color: inspectionStatusColor(s),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                  child: ModuleDropdownPill<InspectionStatus>(
                    key: const Key('inspections-status-filter'),
                    value: state.statusFilter,
                    hint: l10n.inspFilterState,
                    allLabel: l10n.inspFilterAllStates,
                    options: [
                      for (final s in InspectionStatus.values)
                        (s, inspectionStatusLabel(l10n, s)),
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

  Widget _body(BuildContext context, InspectionsState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<InspectionsCubit>();
    switch (state.status) {
      case InspectionsListStatus.loading:
        return const Center(
          key: Key('inspections-loading'),
          child: CircularProgressIndicator(),
        );
      case InspectionsListStatus.failure:
        return InspectionsStateView(
          error: state.error ?? InspectionsError.server,
          onRetry: cubit.load,
        );
      case InspectionsListStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return InspectionsStateView.empty(
            message: state.items.isEmpty ? l10n.inspEmptyAll : l10n.inspEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('inspections-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: InspectionCard(
                  inspection: visible[i],
                  zone: zone,
                  onTap: () async {
                    await context.push('/inspections/${visible[i].id}');
                    // Al volver, lo que se lleno en la ficha ya cuenta.
                    if (context.mounted) cubit.refresh();
                  },
                ),
              ),
            ),
          ),
        );
    }
  }
}
