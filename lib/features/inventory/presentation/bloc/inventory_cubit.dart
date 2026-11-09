import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryListStatus { loading, ready, failure }

class InventoryState extends Equatable {
  const InventoryState({
    this.status = InventoryListStatus.loading,
    this.assets = const [],
    this.pending = const [],
    this.total = 0,
    this.counts,
    this.types = const [],
    this.next,
    this.refreshing = false,
    this.loadingMore = false,
    this.moreError,
    this.error,
    this.conditionFilter,
    this.typeCode,
    this.inspectedFrom,
    this.inspectedTo,
    this.query = '',
  });

  final InventoryListStatus status;

  /// Lo que ha traido el servidor, en su orden, pagina tras pagina.
  final List<InventoryAsset> assets;

  /// Las altas que esperan en el telefono y cumplen los filtros: van arriba.
  final List<InventoryAsset> pending;

  /// Cuantos activos cumplen la consulta en el servidor (no solo los traidos).
  final int total;

  /// Cuantos hay con los filtros salvo el estado, y de cada estado; null si no
  /// se pudo saber.
  final InventoryCounts? counts;

  /// Los tipos para filtrar.
  final List<AssetTypeOption> types;

  /// Con que pedir la pagina siguiente; null si ya no hay mas.
  final Object? next;

  /// Se consulta de nuevo con otros filtros: mientras, se ve lo anterior.
  final bool refreshing;
  final bool loadingMore;

  /// Por que no llego la pagina siguiente; la lista se queda como esta.
  final InventoryError? moreError;
  final InventoryError? error;

  /// Estado de conservacion elegido; null = todos.
  final AssetCondition? conditionFilter;

  /// Codigo del tipo de activo elegido; null = todos.
  final String? typeCode;

  /// Dia de calendario desde el que se monitoreo (incluido); null = sin
  /// limite.
  final DateTime? inspectedFrom;

  /// Dia de calendario hasta el que se monitoreo (incluido); null = sin
  /// limite.
  final DateTime? inspectedTo;
  final String query;

  bool get hasMore => next != null;

  /// La consulta que se manda con los filtros elegidos.
  InventoryQuery get request => InventoryQuery(
    search: query,
    typeCode: typeCode,
    condition: conditionFilter,
    inspectedFrom: inspectedFrom,
    inspectedTo: inspectedTo,
  );

  /// Lo que se ve: primero lo que espera en el telefono y despues lo del
  /// servidor, en su orden.
  List<InventoryAsset> get visible {
    if (pending.isEmpty) return assets;
    final known = {for (final a in assets) a.id};
    return [
      for (final p in pending)
        if (!known.contains(p.id)) p,
      ...assets,
    ];
  }

  int count(AssetCondition c) => counts?.of(c) ?? 0;

  /// La parte del total que es [c], de 0 a 100.
  double share(AssetCondition c) => counts?.share(c) ?? 0;

  /// Hay inventario o filtros que deshacer: se muestran el resumen y los
  /// filtros.
  bool get hasContent =>
      total > 0 ||
      pending.isNotEmpty ||
      (counts?.total ?? 0) > 0 ||
      hasActiveFilters;

  /// Los tipos para elegir, por nombre. Si no se pudieron traer, los de lo que
  /// ya se ve; el elegido siempre esta.
  List<AssetTypeOption> typeOptions(String language) {
    final byCode = <String, AssetTypeOption>{for (final t in types) t.code: t};
    if (byCode.isEmpty) {
      for (final a in visible) {
        final code = a.typeCode;
        if (code != null) {
          byCode.putIfAbsent(
            code,
            () => AssetTypeOption(code: code, labelEs: a.category),
          );
        }
      }
    }
    final chosen = typeCode;
    if (chosen != null) {
      byCode.putIfAbsent(
        chosen,
        () => AssetTypeOption(code: chosen, labelEs: chosen),
      );
    }
    return byCode.values.toList()
      ..sort((a, b) => a.label(language).compareTo(b.label(language)));
  }

  bool get hasActiveFilters =>
      conditionFilter != null ||
      typeCode != null ||
      inspectedFrom != null ||
      inspectedTo != null ||
      query.trim().isNotEmpty;

  InventoryState copyWith({
    InventoryListStatus? status,
    List<InventoryAsset>? assets,
    List<InventoryAsset>? pending,
    int? total,
    InventoryCounts? counts,
    bool clearCounts = false,
    List<AssetTypeOption>? types,
    Object? next,
    bool clearNext = false,
    bool? refreshing,
    bool? loadingMore,
    InventoryError? moreError,
    bool clearMoreError = false,
    InventoryError? error,
    bool clearError = false,
    AssetCondition? conditionFilter,
    bool clearCondition = false,
    String? typeCode,
    bool clearType = false,
    DateTime? inspectedFrom,
    bool clearInspectedFrom = false,
    DateTime? inspectedTo,
    bool clearInspectedTo = false,
    String? query,
  }) => InventoryState(
    status: status ?? this.status,
    assets: assets ?? this.assets,
    pending: pending ?? this.pending,
    total: total ?? this.total,
    counts: clearCounts ? null : (counts ?? this.counts),
    types: types ?? this.types,
    next: clearNext ? null : (next ?? this.next),
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    moreError: clearMoreError ? null : (moreError ?? this.moreError),
    error: clearError ? null : (error ?? this.error),
    conditionFilter: clearCondition
        ? null
        : (conditionFilter ?? this.conditionFilter),
    typeCode: clearType ? null : (typeCode ?? this.typeCode),
    inspectedFrom: clearInspectedFrom
        ? null
        : (inspectedFrom ?? this.inspectedFrom),
    inspectedTo: clearInspectedTo ? null : (inspectedTo ?? this.inspectedTo),
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [
    status,
    assets,
    pending,
    total,
    counts,
    types,
    next,
    refreshing,
    loadingMore,
    moreError,
    error,
    conditionFilter,
    typeCode,
    inspectedFrom,
    inspectedTo,
    query,
  ];
}

/// La lista del catalogo: el servidor busca, filtra y pagina; aqui se piden las
/// paginas a medida que se baja, se espera a que la persona deje de escribir
/// antes de buscar y se descarta (y se corta) lo que se pidio con filtros que
/// ya cambiaron. Con [pending], tambien las altas capturadas en el telefono que
/// aun no salen.
class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(
    this._repository, {
    this._pending,
    this._searchDelay = const Duration(milliseconds: 400),
  }) : super(const InventoryState());

  final InventoryRepository _repository;
  final PendingAssetsSource? _pending;

  /// Cuanto se espera, despues de la ultima tecla, para buscar.
  final Duration _searchDelay;

  Timer? _searchTimer;
  Completer<void>? _searchDone;

  /// La consulta vigente: al cambiar los filtros se corta.
  InventoryCancellation? _current;

  /// Cuenta las consultas: lo que llega de una anterior no se muestra.
  int _generation = 0;

  /// Los conteos ya traidos y con que filtros (cambiar solo el estado no los
  /// cambia).
  InventoryQuery? _countedFor;

  /// Los tipos se piden una vez por carga, aunque no lleguen.
  bool _typesAsked = false;

  /// Primera carga (o reintento): la lista se vacia mientras llega.
  Future<void> load() async {
    _countedFor = null;
    _typesAsked = false;
    emit(
      state.copyWith(
        status: InventoryListStatus.loading,
        assets: const [],
        total: 0,
        clearNext: true,
        clearError: true,
        clearMoreError: true,
        refreshing: false,
        loadingMore: false,
      ),
    );
    await _reload();
  }

  /// Vuelve a consultar con los mismos filtros sin borrar lo que ya se ve.
  Future<void> refresh() {
    _countedFor = null;
    _typesAsked = false;
    return _reload();
  }

  Future<void> _reload() async {
    _searchTimer?.cancel();
    _searchTimer = null;
    final waiting = _searchDone;
    _searchDone = null;
    try {
      await _fetchFirst();
    } finally {
      if (waiting != null && !waiting.isCompleted) waiting.complete();
    }
  }

  Future<void> _fetchFirst() async {
    _current?.cancel();
    final cancellation = _current = InventoryCancellation();
    final generation = ++_generation;
    // Con lista, se sigue viendo mientras llega la nueva; sin ella (o tras un
    // error), se espera.
    emit(
      state.status == InventoryListStatus.ready
          ? state.copyWith(
              refreshing: true,
              loadingMore: false,
              clearMoreError: true,
            )
          : state.copyWith(
              status: InventoryListStatus.loading,
              clearError: true,
              loadingMore: false,
              clearMoreError: true,
            ),
    );
    final query = state.request;
    final countsKey = query.withoutCondition();
    final reuseCounts = state.counts != null && _countedFor == countsKey;
    final askTypes = state.types.isEmpty && !_typesAsked;
    _typesAsked = _typesAsked || askTypes;
    final types = askTypes ? _types() : null;
    final counts = reuseCounts ? null : _counts(countsKey, cancellation);
    final pending = _pendingAssets(query);
    try {
      final page = await _repository.page(query, cancellation: cancellation);
      final gotCounts = await counts;
      final gotPending = await pending;
      final gotTypes = await types;
      if (isClosed || generation != _generation) return;
      if (!reuseCounts) _countedFor = gotCounts == null ? null : countsKey;
      emit(
        state.copyWith(
          status: InventoryListStatus.ready,
          assets: page.items,
          total: page.total,
          next: page.next,
          clearNext: page.next == null,
          pending: gotPending,
          counts: gotCounts,
          clearCounts: !reuseCounts && gotCounts == null,
          types: gotTypes,
          refreshing: false,
          loadingMore: false,
          clearMoreError: true,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: InventoryListStatus.failure,
          error: e is InventoryException ? e.error : InventoryError.server,
          refreshing: false,
          loadingMore: false,
        ),
      );
    }
  }

  /// La pagina siguiente, al acercarse al final de la lista. Si falla, la
  /// lista se queda y se puede reintentar.
  Future<void> loadMore() async {
    final s = state;
    if (s.status != InventoryListStatus.ready ||
        s.refreshing ||
        s.loadingMore ||
        s.next == null) {
      return;
    }
    final generation = _generation;
    emit(s.copyWith(loadingMore: true, clearMoreError: true));
    try {
      final page = await _repository.page(
        s.request,
        after: s.next,
        cancellation: _current,
      );
      if (isClosed || generation != _generation) return;
      final known = {for (final a in state.assets) a.id};
      emit(
        state.copyWith(
          assets: [
            ...state.assets,
            for (final a in page.items)
              if (known.add(a.id)) a,
          ],
          total: page.total,
          next: page.next,
          clearNext: page.next == null,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          loadingMore: false,
          moreError: e is InventoryException ? e.error : InventoryError.server,
        ),
      );
    }
  }

  /// Los conteos no impiden ver la lista: sin ellos no hay resumen.
  Future<InventoryCounts?> _counts(
    InventoryQuery query,
    InventoryCancellation cancellation,
  ) async {
    try {
      return await _repository.counts(query, cancellation: cancellation);
    } catch (_) {
      return null;
    }
  }

  Future<List<AssetTypeOption>?> _types() async {
    try {
      return await _repository.types();
    } catch (_) {
      return null;
    }
  }

  /// Lo que espera en el telefono y cumple los filtros; si no se puede leer,
  /// no estorba a la lista.
  Future<List<InventoryAsset>> _pendingAssets(InventoryQuery query) async {
    try {
      final all = await _pending?.pendingAssets() ?? const [];
      return [
        for (final a in all)
          if (query.matches(a)) a,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> setCondition(AssetCondition? condition) {
    if (condition == state.conditionFilter) return Future.value();
    emit(
      condition == null
          ? state.copyWith(clearCondition: true)
          : state.copyWith(conditionFilter: condition),
    );
    return _reload();
  }

  Future<void> setType(String? typeCode) {
    if (typeCode == state.typeCode) return Future.value();
    emit(
      typeCode == null
          ? state.copyWith(clearType: true)
          : state.copyWith(typeCode: typeCode),
    );
    return _reload();
  }

  Future<void> setInspectedFrom(DateTime? day) {
    emit(
      day == null
          ? state.copyWith(clearInspectedFrom: true)
          : state.copyWith(inspectedFrom: day),
    );
    return _reload();
  }

  Future<void> setInspectedTo(DateTime? day) {
    emit(
      day == null
          ? state.copyWith(clearInspectedTo: true)
          : state.copyWith(inspectedTo: day),
    );
    return _reload();
  }

  /// La busqueda sale cuando la persona deja de escribir; lo que estaba en
  /// camino se corta. El futuro termina cuando llega el resultado.
  Future<void> setQuery(String query) {
    if (query == state.query) {
      return _searchDone?.future ?? Future.value();
    }
    emit(state.copyWith(query: query));
    _searchTimer?.cancel();
    final done = _searchDone ??= Completer<void>();
    _searchTimer = Timer(_searchDelay, _reload);
    return done.future;
  }

  Future<void> clearFilters() {
    if (!state.hasActiveFilters) return Future.value();
    emit(
      state.copyWith(
        clearCondition: true,
        clearType: true,
        clearInspectedFrom: true,
        clearInspectedTo: true,
        query: '',
      ),
    );
    return _reload();
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _current?.cancel();
    final waiting = _searchDone;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
    return super.close();
  }
}
