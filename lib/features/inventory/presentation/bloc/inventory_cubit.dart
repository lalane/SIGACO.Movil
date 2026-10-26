import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryListStatus { loading, ready, failure }

class InventoryState extends Equatable {
  const InventoryState({
    this.status = InventoryListStatus.loading,
    this.assets = const [],
    this.error,
    this.conditionFilter,
    this.category,
    this.inspectedFrom,
    this.inspectedTo,
    this.query = '',
  });

  final InventoryListStatus status;
  final List<InventoryAsset> assets;
  final InventoryError? error;

  /// Estado elegido; null = todos.
  final AssetCondition? conditionFilter;

  /// Tipo de activo elegido; null = todos.
  final String? category;

  /// Dia de calendario desde el que se inspecciono (incluido); null = sin
  /// limite.
  final DateTime? inspectedFrom;

  /// Dia de calendario hasta el que se inspecciono (incluido); null = sin
  /// limite.
  final DateTime? inspectedTo;
  final String query;

  int get total => assets.length;

  /// Algun activo trae la fecha de su ultima inspeccion (o ya se eligio una).
  bool get hasInspectionDates =>
      inspectedFrom != null ||
      inspectedTo != null ||
      assets.any((a) => a.lastInspectionAt != null);

  int count(AssetCondition c) => assets.where((a) => a.condition == c).length;

  /// La parte del total que es [c], de 0 a 100.
  double share(AssetCondition c) => total == 0 ? 0 : count(c) * 100 / total;

  /// Los tipos que hay en el inventario, en orden alfabetico.
  List<String> get categories =>
      ({for (final a in assets) a.category}.toList()..sort());

  /// Lo que se ve: estado, tipo, fecha de inspeccion y busqueda; lo que mas
  /// necesita atencion primero y despues por nombre.
  List<InventoryAsset> get visible {
    final list = [
      for (final a in assets)
        if ((conditionFilter == null || a.condition == conditionFilter) &&
            (category == null || a.category == category) &&
            _inspectedInRange(a) &&
            a.matches(query))
          a,
    ];
    list.sort((a, b) {
      final byCondition = b.condition.index.compareTo(a.condition.index);
      return byCondition != 0 ? byCondition : a.name.compareTo(b.name);
    });
    return list;
  }

  /// La ultima inspeccion cae entre los dos dias elegidos, ambos incluidos.
  bool _inspectedInRange(InventoryAsset a) {
    final from = inspectedFrom;
    final to = inspectedTo;
    if (from == null && to == null) return true;
    final last = a.lastInspectionAt;
    if (last == null) return false;
    final day = DateTime.utc(last.year, last.month, last.day);
    if (from != null &&
        day.isBefore(DateTime.utc(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime.utc(to.year, to.month, to.day))) {
      return false;
    }
    return true;
  }

  bool get hasActiveFilters =>
      conditionFilter != null ||
      category != null ||
      inspectedFrom != null ||
      inspectedTo != null ||
      query.trim().isNotEmpty;

  InventoryState copyWith({
    InventoryListStatus? status,
    List<InventoryAsset>? assets,
    InventoryError? error,
    bool clearError = false,
    AssetCondition? conditionFilter,
    bool clearCondition = false,
    String? category,
    bool clearCategory = false,
    DateTime? inspectedFrom,
    bool clearInspectedFrom = false,
    DateTime? inspectedTo,
    bool clearInspectedTo = false,
    String? query,
  }) => InventoryState(
    status: status ?? this.status,
    assets: assets ?? this.assets,
    error: clearError ? null : (error ?? this.error),
    conditionFilter: clearCondition
        ? null
        : (conditionFilter ?? this.conditionFilter),
    category: clearCategory ? null : (category ?? this.category),
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
    error,
    conditionFilter,
    category,
    inspectedFrom,
    inspectedTo,
    query,
  ];
}

/// La lista del inventario: carga, estado, tipo, fecha y busqueda.
class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(this._repository) : super(const InventoryState());

  final InventoryRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: InventoryListStatus.loading, clearError: true));
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final assets = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InventoryListStatus.ready,
          assets: assets,
          clearError: true,
        ),
      );
    } on InventoryException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: InventoryListStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InventoryListStatus.failure,
          error: InventoryError.server,
        ),
      );
    }
  }

  void setCondition(AssetCondition? condition) => emit(
    condition == null
        ? state.copyWith(clearCondition: true)
        : state.copyWith(conditionFilter: condition),
  );

  void setCategory(String? category) => emit(
    category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category),
  );

  void setInspectedFrom(DateTime? day) => emit(
    day == null
        ? state.copyWith(clearInspectedFrom: true)
        : state.copyWith(inspectedFrom: day),
  );

  void setInspectedTo(DateTime? day) => emit(
    day == null
        ? state.copyWith(clearInspectedTo: true)
        : state.copyWith(inspectedTo: day),
  );

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearFilters() => emit(
    state.copyWith(
      clearCondition: true,
      clearCategory: true,
      clearInspectedFrom: true,
      clearInspectedTo: true,
      query: '',
    ),
  );
}
