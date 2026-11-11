import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pending_definition.dart';
import '../bloc/definitions_cubit.dart';
import '../definitions_labels.dart';

/// Las definiciones pendientes (tanda 4) por modulo: sin veredicto o todas, del
/// modulo de donde se llego y con busqueda. Cada tarjeta abre su detalle, donde
/// se contesta.
class DefinitionsPage extends StatefulWidget {
  const DefinitionsPage({super.key});

  @override
  State<DefinitionsPage> createState() => _DefinitionsPageState();
}

class _DefinitionsPageState extends State<DefinitionsPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<DefinitionsCubit>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final cubit = context.read<DefinitionsCubit>();
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
    final cubit = context.read<DefinitionsCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<DefinitionsCubit, DefinitionsState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.defTitle,
                subtitle: l10n.defSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('definitions-search-button'),
                    icon: _searching ? Icons.search_off : Icons.search,
                    tooltip: l10n.defSearchTooltip,
                    onPressed: _toggleSearch,
                  ),
                ],
              ),
              if (_searching)
                ModuleSearchBar(
                  fieldKey: const Key('definitions-search'),
                  controller: _search,
                  focus: _searchFocus,
                  hint: l10n.defSearchHint,
                  onChanged: cubit.setQuery,
                ),
              if (state.status == DefinitionsListStatus.ready) ...[
                ModuleFilterChips<bool>(
                  keyPrefix: 'definitions',
                  selected: state.pendingOnly,
                  onSelect: cubit.setPendingOnly,
                  chips: [
                    ModuleChip(
                      value: true,
                      id: 'pending',
                      label: l10n.defFilterPending,
                      count: state.pendingCount,
                    ),
                    ModuleChip(
                      value: false,
                      id: 'all',
                      label: l10n.defFilterAll,
                      count: state.items.length,
                    ),
                  ],
                ),
                if (state.mobileModule != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                    child: SwitchListTile(
                      key: const Key('definitions-only-module'),
                      contentPadding: EdgeInsets.zero,
                      value: state.onlyModule,
                      onChanged: cubit.setOnlyModule,
                      title: Text(
                        l10n.defFilterModule,
                        style: TextStyle(color: p.textOnTop, fontSize: r.s(14)),
                      ),
                    ),
                  ),
              ],
              SizedBox(height: r.s(8)),
              Expanded(child: ModuleListSheet(body: _body(context, state))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DefinitionsState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<DefinitionsCubit>();
    switch (state.status) {
      case DefinitionsListStatus.loading:
        return const Center(
          key: Key('definitions-loading'),
          child: CircularProgressIndicator(),
        );
      case DefinitionsListStatus.failure:
        return ModuleStateView(
          icon: Icons.cloud_off_outlined,
          body: definitionsErrorMessage(l10n, state.error!),
          retryLabel: l10n.retry,
          onRetry: cubit.load,
          retryKey: const Key('definitions-retry'),
        );
      case DefinitionsListStatus.ready:
        final groups = state.groups;
        if (groups.isEmpty) {
          return ModuleStateView(
            icon: Icons.task_alt,
            body: state.items.isEmpty ? l10n.defEmptyAll : l10n.defEmpty,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView(
            key: const Key('definitions-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(16)),
            children: [
              for (final (module, items) in groups) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: r.s(8), top: r.s(4)),
                  child: Text(
                    module.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: r.s(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                for (final d in items)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Responsive.formMaxWidth,
                      ),
                      child: _DefinitionCard(
                        definition: d,
                        onTap: () async {
                          await context.push('/definitions/${d.code}');
                          if (context.mounted) cubit.refresh();
                        },
                      ),
                    ),
                  ),
                SizedBox(height: r.s(12)),
              ],
            ],
          ),
        );
    }
  }
}

class _DefinitionCard extends StatelessWidget {
  const _DefinitionCard({required this.definition, required this.onTap});

  final PendingDefinition definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final d = definition;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(10)),
      child: Material(
        color: moduleSurface,
        borderRadius: BorderRadius.circular(r.s(16)),
        child: InkWell(
          key: Key('definition-${d.code}'),
          borderRadius: BorderRadius.circular(r.s(16)),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(r.s(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      d.code,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(13),
                      ),
                    ),
                    SizedBox(width: r.s(8)),
                    Text(
                      definitionPriorityLabel(l10n, d.priority),
                      style: TextStyle(
                        color: d.priority == DefinitionPriority.high
                            ? const Color(0xFFF87171)
                            : moduleMuted,
                        fontSize: r.s(12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ModuleStatusPill(
                      label: definitionStatusLabel(l10n, d.status),
                      color: definitionStatusColor(d.status),
                    ),
                  ],
                ),
                SizedBox(height: r.s(8)),
                Text(
                  d.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: r.s(15),
                  ),
                ),
                SizedBox(height: r.s(4)),
                Text(
                  d.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
