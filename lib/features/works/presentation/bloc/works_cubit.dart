import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';

enum WorksListStatus { loading, ready, failure }

class WorksState extends Equatable {
  const WorksState({
    this.status = WorksListStatus.loading,
    this.works = const [],
    this.error,
    this.statusFilter,
    this.query = '',
  });

  final WorksListStatus status;
  final List<PublicWork> works;
  final WorksError? error;

  /// Estado elegido; null = todos.
  final WorkStatus? statusFilter;
  final String query;

  int get total => works.length;

  int count(WorkStatus s) => works.where((w) => w.status == s).length;

  /// Lo que se ve: estado y busqueda; lo mas atrasado primero y despues por
  /// nombre.
  List<PublicWork> get visible {
    final list = [
      for (final w in works)
        if ((statusFilter == null || w.status == statusFilter) &&
            w.matches(query))
          w,
    ];
    list.sort((a, b) {
      final byLag = b.lag.compareTo(a.lag);
      return byLag != 0 ? byLag : a.name.compareTo(b.name);
    });
    return list;
  }

  bool get hasActiveFilters => statusFilter != null || query.trim().isNotEmpty;

  WorksState copyWith({
    WorksListStatus? status,
    List<PublicWork>? works,
    WorksError? error,
    bool clearError = false,
    WorkStatus? statusFilter,
    bool clearStatus = false,
    String? query,
  }) => WorksState(
    status: status ?? this.status,
    works: works ?? this.works,
    error: clearError ? null : (error ?? this.error),
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [status, works, error, statusFilter, query];
}

/// La lista de obras: carga, estado y busqueda.
class WorksCubit extends Cubit<WorksState> {
  WorksCubit(this._repository) : super(const WorksState());

  final WorksRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: WorksListStatus.loading, clearError: true));
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final works = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WorksListStatus.ready,
          works: works,
          clearError: true,
        ),
      );
    } on WorksException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: WorksListStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WorksListStatus.failure,
          error: WorksError.server,
        ),
      );
    }
  }

  void setStatus(WorkStatus? status) => emit(
    status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(statusFilter: status),
  );

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearFilters() => emit(state.copyWith(clearStatus: true, query: ''));
}
