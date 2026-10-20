import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';

enum InspectionsListStatus { loading, ready, failure }

class InspectionsState extends Equatable {
  const InspectionsState({
    this.status = InspectionsListStatus.loading,
    this.items = const [],
    this.error,
    this.statusFilter,
    this.query = '',
  });

  final InspectionsListStatus status;
  final List<Inspection> items;
  final InspectionsError? error;

  /// Estado elegido; null = todos.
  final InspectionStatus? statusFilter;
  final String query;

  int get total => items.length;

  int count(InspectionStatus s) => items.where((i) => i.status == s).length;

  /// Lo que se ve: estado y busqueda; lo que hay que hacer primero (en
  /// proceso, pendientes) por fecha, y al final lo que ya no se puede llenar.
  List<Inspection> get visible {
    final list = [
      for (final i in items)
        if ((statusFilter == null || i.status == statusFilter) &&
            i.matches(query))
          i,
    ];
    int rank(Inspection i) => switch (i.status) {
      InspectionStatus.inProgress => 0,
      InspectionStatus.pending => 1,
      InspectionStatus.attended => 2,
      InspectionStatus.closed => 3,
      InspectionStatus.cancelled => 4,
    };
    list.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final x = a.scheduledAt;
      final y = b.scheduledAt;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return list;
  }

  bool get hasActiveFilters => statusFilter != null || query.trim().isNotEmpty;

  InspectionsState copyWith({
    InspectionsListStatus? status,
    List<Inspection>? items,
    InspectionsError? error,
    bool clearError = false,
    InspectionStatus? statusFilter,
    bool clearStatus = false,
    String? query,
  }) => InspectionsState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: clearError ? null : (error ?? this.error),
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [status, items, error, statusFilter, query];
}

/// La lista de inspecciones: carga, estado y busqueda.
class InspectionsCubit extends Cubit<InspectionsState> {
  InspectionsCubit(this._repository) : super(const InspectionsState());

  final InspectionsRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: InspectionsListStatus.loading, clearError: true),
    );
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final items = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InspectionsListStatus.ready,
          items: items,
          clearError: true,
        ),
      );
    } on InspectionsException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: InspectionsListStatus.failure, error: e.error),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InspectionsListStatus.failure,
          error: InspectionsError.server,
        ),
      );
    }
  }

  void setStatus(InspectionStatus? status) => emit(
    status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(statusFilter: status),
  );

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearFilters() => emit(state.copyWith(clearStatus: true, query: ''));
}
