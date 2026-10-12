import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_query.dart';
import '../../domain/repositories/documents_repository.dart';

enum DocumentsStatus { loading, ready, failure }

class DocumentsState extends Equatable {
  const DocumentsState({
    this.query = const DocumentQuery(),
    this.status = DocumentsStatus.loading,
    this.items = const [],
    this.error,
    this.catalogs = const DocumentCatalogs(),
    this.rangeRejected = false,
    this.favoriteFailed = 0,
  });

  final DocumentQuery query;
  final DocumentsStatus status;
  final List<DocumentSummary> items;
  final DocumentsError? error;
  final DocumentCatalogs catalogs;

  /// El ultimo cambio de filtros tenia Desde posterior a Hasta y no se aplico.
  final bool rangeRejected;

  /// Cuenta de favoritos que no se pudieron guardar (para avisar una vez cada uno).
  final int favoriteFailed;

  DocumentsState copyWith({
    DocumentQuery? query,
    DocumentsStatus? status,
    List<DocumentSummary>? items,
    DocumentsError? error,
    bool clearError = false,
    DocumentCatalogs? catalogs,
    bool? rangeRejected,
    int? favoriteFailed,
  }) => DocumentsState(
    query: query ?? this.query,
    status: status ?? this.status,
    items: items ?? this.items,
    error: clearError ? null : (error ?? this.error),
    catalogs: catalogs ?? this.catalogs,
    rangeRejected: rangeRejected ?? this.rangeRejected,
    favoriteFailed: favoriteFailed ?? this.favoriteFailed,
  );

  @override
  List<Object?> get props => [
    query,
    status,
    items,
    error,
    catalogs,
    rangeRejected,
    favoriteFailed,
  ];
}

/// Consulta de documentos (DEV-MOB-068 y 069): la vista, la busqueda y los
/// filtros viven en [DocumentsState.query]; cada cambio vuelve a consultar al
/// servidor y gana siempre la ultima consulta.
class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit(this._repository) : super(const DocumentsState());

  final DocumentsRepository _repository;
  int _generation = 0;

  Future<void> load() async {
    _loadCatalogs();
    await _fetch(state.query);
  }

  Future<void> retry() => _fetch(state.query);

  /// Volver a consultar sin vaciar la lista (jalar para actualizar).
  Future<void> refresh() => _fetch(state.query, keepItems: true);

  Future<void> selectView(DocumentView view) async {
    if (view == state.query.view && state.status != DocumentsStatus.failure) {
      return;
    }
    await _apply(state.query.copyWith(view: view));
  }

  Future<void> search(String text) async {
    final clean = text.trim();
    if (clean == state.query.search) return;
    await _apply(state.query.copyWith(search: clean));
  }

  /// Aplica filtros. Un rango con Desde posterior a Hasta se rechaza sin
  /// consultar y conserva los filtros anteriores (CA-05).
  Future<void> applyFilters(DocumentFilters filters) async {
    if (!filters.rangeIsValid) {
      emit(state.copyWith(rangeRejected: true));
      return;
    }
    emit(state.copyWith(rangeRejected: false));
    if (filters == state.query.filters) return;
    await _apply(state.query.copyWith(filters: filters));
  }

  Future<void> clearCriteria() =>
      _apply(state.query.copyWith(search: '', filters: DocumentFilters.none));

  Future<void> _apply(DocumentQuery query) {
    emit(state.copyWith(query: query, rangeRejected: false));
    return _fetch(query);
  }

  Future<void> _fetch(DocumentQuery query, {bool keepItems = false}) async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        query: query,
        status: keepItems && state.status == DocumentsStatus.ready
            ? DocumentsStatus.ready
            : DocumentsStatus.loading,
        items: keepItems ? state.items : const [],
        clearError: true,
      ),
    );
    try {
      final items = await _repository.list(query);
      if (generation != _generation || isClosed) return;
      emit(state.copyWith(status: DocumentsStatus.ready, items: items));
    } on DocumentsException catch (e) {
      if (generation != _generation || isClosed) return;
      emit(state.copyWith(status: DocumentsStatus.failure, error: e.error));
    } catch (_) {
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: DocumentsStatus.failure,
          error: DocumentsError.server,
        ),
      );
    }
  }

  /// Los filtros son un extra: si el catalogo no llega, la lista sigue
  /// funcionando y se vuelve a pedir al abrir los filtros.
  Future<void> _loadCatalogs() async {
    try {
      final catalogs = await _repository.catalogs();
      if (!isClosed) emit(state.copyWith(catalogs: catalogs));
    } catch (_) {}
  }

  Future<void> reloadCatalogs() => _loadCatalogs();

  /// Marca o desmarca favorito sin entrar a la ficha. Se refleja al instante y
  /// se revierte si el servidor no lo acepta.
  Future<void> toggleFavorite(DocumentSummary doc) async {
    final target = !doc.isFavorite;
    emit(state.copyWith(items: _withFavorite(doc.id, target)));
    try {
      await _repository.setFavorite(doc.id, favorite: target);
      if (isClosed) return;
      // En Favoritos, quitarlo lo saca de la lista.
      if (state.query.view == DocumentView.favorites && !target) {
        emit(
          state.copyWith(
            items: [
              for (final d in state.items)
                if (d.id != doc.id) d,
            ],
          ),
        );
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          items: _withFavorite(doc.id, doc.isFavorite),
          favoriteFailed: state.favoriteFailed + 1,
        ),
      );
    }
  }

  List<DocumentSummary> _withFavorite(String id, bool value) => [
    for (final d in state.items) d.id == id ? d.withFavorite(value) : d,
  ];
}
