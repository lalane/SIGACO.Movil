import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

enum MaintenanceListStatus { loading, ready, failure }

class MaintenanceState extends Equatable {
  const MaintenanceState({
    this.status = MaintenanceListStatus.loading,
    this.orders = const [],
    this.error,
    this.statusFilter,
    this.from,
    this.to,
    this.query = '',
    this.summary,
  });

  final MaintenanceListStatus status;
  final List<MaintenanceOrder> orders;
  final MaintenanceError? error;

  /// Estado elegido; null = todos.
  final MaintenanceStatus? statusFilter;

  /// Dias de calendario elegidos para acotar por fecha de inicio (ambos
  /// incluidos); null = sin limite.
  final DateTime? from;
  final DateTime? to;
  final String query;

  /// Tickets y evaluacion del indicador en el periodo de [from] a [to]; null
  /// mientras no llega o si el servidor no lo publica.
  final MaintenanceIndicatorSummary? summary;

  int get total => orders.length;

  int count(MaintenanceStatus s) => orders.where((o) => o.status == s).length;

  /// La parte del total que es [s], de 0 a 100.
  double share(MaintenanceStatus s) => total == 0 ? 0 : count(s) * 100 / total;

  /// Lo que se ve: estado, rango de fechas y busqueda; por fecha de inicio,
  /// lo mas reciente primero.
  List<MaintenanceOrder> get visible {
    final list = [
      for (final o in orders)
        if ((statusFilter == null || o.status == statusFilter) &&
            _inRange(o) &&
            o.matches(query))
          o,
    ];
    list.sort((a, b) {
      final x = a.startDate;
      final y = b.startDate;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return list;
  }

  bool _inRange(MaintenanceOrder o) {
    final start = o.startDate;
    if (from == null && to == null) return true;
    if (start == null) return false;
    final day = DateTime.utc(start.year, start.month, start.day);
    if (from != null &&
        day.isBefore(DateTime.utc(from!.year, from!.month, from!.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime.utc(to!.year, to!.month, to!.day))) {
      return false;
    }
    return true;
  }

  bool get hasActiveFilters =>
      statusFilter != null ||
      from != null ||
      to != null ||
      query.trim().isNotEmpty;

  MaintenanceState copyWith({
    MaintenanceListStatus? status,
    List<MaintenanceOrder>? orders,
    MaintenanceError? error,
    bool clearError = false,
    MaintenanceStatus? statusFilter,
    bool clearStatus = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    String? query,
    MaintenanceIndicatorSummary? summary,
    bool clearSummary = false,
  }) => MaintenanceState(
    status: status ?? this.status,
    orders: orders ?? this.orders,
    error: clearError ? null : (error ?? this.error),
    statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    from: clearFrom ? null : (from ?? this.from),
    to: clearTo ? null : (to ?? this.to),
    query: query ?? this.query,
    summary: clearSummary ? null : (summary ?? this.summary),
  );

  @override
  List<Object?> get props => [
    status,
    orders,
    error,
    statusFilter,
    from,
    to,
    query,
    summary,
  ];
}

/// La lista de mantenimientos de un indicador: carga, estado, fechas y busqueda.
class MaintenanceCubit extends Cubit<MaintenanceState> {
  MaintenanceCubit(this._repository, this.indicator)
    : super(const MaintenanceState());

  final MaintenanceRepository _repository;
  final MaintenanceIndicator indicator;

  Future<void> load() async {
    emit(
      state.copyWith(status: MaintenanceListStatus.loading, clearError: true),
    );
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    // Los conteos van aparte: si fallan, la lista se ve igual.
    unawaited(_fetchSummary());
    try {
      final orders = await _repository.list(indicator);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MaintenanceListStatus.ready,
          orders: orders,
          clearError: true,
        ),
      );
    } on MaintenanceException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: MaintenanceListStatus.failure, error: e.error),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MaintenanceListStatus.failure,
          error: MaintenanceError.server,
        ),
      );
    }
  }

  Future<void> _fetchSummary() async {
    final summary = await _repository.summary(
      indicator,
      from: state.from,
      to: state.to,
    );
    if (isClosed) return;
    emit(
      summary == null
          ? state.copyWith(clearSummary: true)
          : state.copyWith(summary: summary),
    );
  }

  void setStatus(MaintenanceStatus? status) => emit(
    status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(statusFilter: status),
  );

  /// Las fechas acotan la lista y los conteos de tickets del periodo.
  void setFrom(DateTime? day) {
    emit(
      day == null ? state.copyWith(clearFrom: true) : state.copyWith(from: day),
    );
    unawaited(_fetchSummary());
  }

  void setTo(DateTime? day) {
    emit(day == null ? state.copyWith(clearTo: true) : state.copyWith(to: day));
    unawaited(_fetchSummary());
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearFilters() {
    emit(
      state.copyWith(
        clearStatus: true,
        clearFrom: true,
        clearTo: true,
        query: '',
      ),
    );
    unawaited(_fetchSummary());
  }
}
