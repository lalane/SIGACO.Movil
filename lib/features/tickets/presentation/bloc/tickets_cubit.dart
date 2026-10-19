import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

enum TicketsStatus { loading, ready, failure }

/// Las pestanas de estado del historial.
enum TicketFilter {
  all,
  open,
  attended;

  bool accepts(Ticket t) => switch (this) {
    TicketFilter.all => true,
    TicketFilter.open => t.status == TicketStatus.open,
    TicketFilter.attended => t.status == TicketStatus.attended,
  };
}

class TicketsState extends Equatable {
  const TicketsState({
    this.status = TicketsStatus.loading,
    this.tickets = const [],
    this.error,
    this.filter = TicketFilter.all,
    this.query = '',
    this.sortByDue = false,
    required this.now,
  });

  final TicketsStatus status;
  final List<Ticket> tickets;
  final TicketsError? error;
  final TicketFilter filter;
  final String query;

  /// Primero los que vencen antes (los vencidos arriba).
  final bool sortByDue;

  /// El momento con el que se calculan los vencimientos.
  final DateTime now;

  int count(TicketFilter f) => tickets.where(f.accepts).length;

  /// Lo que se ve: el estado elegido y la busqueda; con el orden por
  /// vencimiento o, si no, lo mas reciente primero.
  List<Ticket> get visible {
    final list = [
      for (final t in tickets)
        if (filter.accepts(t) && t.matches(query)) t,
    ];
    if (sortByDue) {
      list.sort((a, b) {
        final x = a.timeToDue(now);
        final y = b.timeToDue(now);
        if (x == null && y == null) return b.createdAt.compareTo(a.createdAt);
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  bool get hasActiveFilters =>
      filter != TicketFilter.all || query.trim().isNotEmpty || sortByDue;

  TicketsState copyWith({
    TicketsStatus? status,
    List<Ticket>? tickets,
    TicketsError? error,
    bool clearError = false,
    TicketFilter? filter,
    String? query,
    bool? sortByDue,
    DateTime? now,
  }) => TicketsState(
    status: status ?? this.status,
    tickets: tickets ?? this.tickets,
    error: clearError ? null : (error ?? this.error),
    filter: filter ?? this.filter,
    query: query ?? this.query,
    sortByDue: sortByDue ?? this.sortByDue,
    now: now ?? this.now,
  );

  @override
  List<Object?> get props => [
    status,
    tickets,
    error,
    filter,
    query,
    sortByDue,
    now,
  ];
}

/// El historial de tickets: carga, estado, busqueda y orden por vencimiento.
class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(TicketsState(now: (clock ?? DateTime.now)().toUtc()));

  final TicketsRepository _repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(state.copyWith(status: TicketsStatus.loading, clearError: true));
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve (jalar o volver de otra
  /// pantalla).
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final tickets = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TicketsStatus.ready,
          tickets: tickets,
          now: _clock().toUtc(),
          clearError: true,
        ),
      );
    } on TicketsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: TicketsStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TicketsStatus.failure,
          error: TicketsError.server,
        ),
      );
    }
  }

  void setFilter(TicketFilter filter) => emit(state.copyWith(filter: filter));

  void setQuery(String query) => emit(state.copyWith(query: query));

  void toggleSortByDue() => emit(state.copyWith(sortByDue: !state.sortByDue));

  void clearFilters() => emit(
    state.copyWith(filter: TicketFilter.all, query: '', sortByDue: false),
  );
}
