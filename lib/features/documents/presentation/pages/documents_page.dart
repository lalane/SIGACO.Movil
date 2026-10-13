import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/page_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_access.dart';
import '../../domain/repositories/documents_repository.dart';
import '../bloc/documents_cubit.dart';
import '../document_labels.dart';
import '../widgets/document_filters_sheet.dart';
import '../widgets/document_state_view.dart';
import '../widgets/document_tile.dart';

/// Consulta de documentos (DEV-MOB-068 y 069): Todos, Recientes, Favoritos y
/// Mis documentos, con busqueda y filtros. Sin el permiso Ver no consulta nada.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, required this.access});

  final DocumentAccess access;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.access.canView) context.read<DocumentsCubit>().load();
  }

  @override
  void didUpdateWidget(DocumentsPage old) {
    super.didUpdateWidget(old);
    // Le dieron Ver mientras estaba abierta: ahora si se consulta.
    if (!old.access.canView && widget.access.canView) {
      context.read<DocumentsCubit>().load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => context.read<DocumentsCubit>().search(text),
    );
  }

  void _submitSearch(String text) {
    _debounce?.cancel();
    context.read<DocumentsCubit>().search(text);
  }

  Future<void> _openFilters() async {
    final cubit = context.read<DocumentsCubit>();
    if (cubit.state.catalogs.types.isEmpty) await cubit.reloadCatalogs();
    if (!mounted) return;
    final picked = await showDocumentFilters(
      context,
      current: cubit.state.query.filters,
      catalogs: cubit.state.catalogs,
    );
    if (picked != null) await cubit.applyFilters(picked);
  }

  Future<void> _upload() async {
    final cubit = context.read<DocumentsCubit>();
    await context.push<bool>('/documents/upload');
    if (mounted && !cubit.isClosed) cubit.refresh();
  }

  Future<void> _open(DocumentSummary doc) async {
    final cubit = context.read<DocumentsCubit>();
    await context.push('/documents/${doc.id}');
    // El favorito o la actividad pudieron cambiar en la ficha.
    if (mounted && !cubit.isClosed) cubit.refresh();
  }

  void _clear() {
    _search.clear();
    context.read<DocumentsCubit>().clearCriteria();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      // Cargar exige Ver + Cargar; sin Cargar el boton no se ofrece (DEV-MOB-092).
      floatingActionButton: widget.access.canView && widget.access.canUpload
          ? FloatingActionButton.extended(
              key: const Key('docs-upload'),
              onPressed: _upload,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.docsUploadAction),
            )
          : null,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.docsTitle),
          Expanded(
            child: widget.access.canView
                ? _Content(
                    search: _search,
                    onSearchChanged: _onSearchChanged,
                    onSearchSubmitted: _submitSearch,
                    onFilters: _openFilters,
                    onOpen: _open,
                    onClear: _clear,
                  )
                : const DocumentStateView(
                    state: DocumentScreenState.noPermission,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.search,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onFilters,
    required this.onOpen,
    required this.onClear,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onFilters;
  final ValueChanged<DocumentSummary> onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return BlocConsumer<DocumentsCubit, DocumentsState>(
      listenWhen: (a, b) => b.favoriteFailed > a.favoriteFailed,
      listener: (context, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.docsFavoriteFailed))),
      builder: (context, state) {
        final zone = context.watch<ConcessionZoneCubit>().state;
        final pad = r
            .sidePadding(minGutter: r.s(20))
            .copyWith(top: 0, bottom: 0);
        return Column(
          children: [
            Padding(
              padding: pad.copyWith(top: r.s(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final v in DocumentView.values)
                      Padding(
                        padding: EdgeInsets.only(right: r.s(8)),
                        child: ChoiceChip(
                          key: Key('docs-view-${v.name}'),
                          label: Text(viewLabel(l10n, v)),
                          selected: state.query.view == v,
                          onSelected: (_) =>
                              context.read<DocumentsCubit>().selectView(v),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: pad.copyWith(top: r.s(10)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('docs-search'),
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onChanged: onSearchChanged,
                      onSubmitted: onSearchSubmitted,
                      decoration: InputDecoration(
                        hintText: l10n.docsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: r.s(8)),
                  Badge(
                    isLabelVisible: state.query.filters.activeCount > 0,
                    label: Text('${state.query.filters.activeCount}'),
                    child: IconButton.outlined(
                      key: const Key('docs-filters-button'),
                      tooltip: l10n.docsFilters,
                      onPressed: onFilters,
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
            ),
            if (zone != null)
              Padding(
                padding: pad.copyWith(top: r.s(6)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.docsZoneLegend(
                      zone.id,
                      zone.offsetLabelAt(DateTime.now()),
                    ),
                    key: const Key('docs-zone-legend'),
                    style: TextStyle(color: p.hint, fontSize: r.s(11.5)),
                  ),
                ),
              ),
            SizedBox(height: r.s(8)),
            Expanded(
              child: _Results(state: state, onOpen: onOpen, onClear: onClear),
            ),
          ],
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.state,
    required this.onOpen,
    required this.onClear,
  });

  final DocumentsState state;
  final ValueChanged<DocumentSummary> onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentsCubit>();
    final r = context.responsive;
    final p = context.palette;
    switch (state.status) {
      case DocumentsStatus.loading:
        return const DocumentStateView(state: DocumentScreenState.loading);
      case DocumentsStatus.failure:
        return DocumentStateView(
          state: screenStateFor(state.error ?? DocumentsError.server),
          onRetry: cubit.retry,
        );
      case DocumentsStatus.ready:
        if (state.items.isEmpty) {
          return DocumentStateView(
            state: state.query.hasCriteria
                ? DocumentScreenState.noResults
                : DocumentScreenState.empty,
            view: state.query.view,
            onClear: onClear,
          );
        }
        final zone = context.watch<ConcessionZoneCubit>().state;
        // Cada consulta nueva (otra vista, busqueda o filtros) empieza arriba;
        // actualizar la misma conserva el lugar.
        return KeyedSubtree(
          key: ValueKey(state.query),
          child: RefreshIndicator(
            color: p.accentOnBottom,
            backgroundColor: p.card,
            onRefresh: cubit.refresh,
            child: ListView(
              key: const Key('docs-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: r
                  .sidePadding(minGutter: r.s(20))
                  .copyWith(top: r.s(4), bottom: r.s(96)),
              children: [
                for (final d in state.items)
                  DocumentTile(
                    document: d,
                    zone: zone,
                    onOpen: () => onOpen(d),
                    onToggleFavorite: () => cubit.toggleFavorite(d),
                  ),
              ],
            ),
          ),
        );
    }
  }
}
