import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

enum AccidentsStatus { loading, ready, failure }

/// Las pestanas de tipo del historial.
enum AccidentFilter {
  all(null),
  collision(AccidentType.collision),
  rollover(AccidentType.rollover),
  fire(AccidentType.fire);

  const AccidentFilter(this.type);

  /// El tipo que deja pasar; null = todos.
  final AccidentType? type;

  bool accepts(Accident a) => type == null || a.type == type;
}

class AccidentsState extends Equatable {
  const AccidentsState({
    this.status = AccidentsStatus.loading,
    this.accidents = const [],
    this.error,
    this.filter = AccidentFilter.all,
    this.severity,
    this.query = '',
  });

  final AccidentsStatus status;
  final List<Accident> accidents;
  final AccidentsError? error;
  final AccidentFilter filter;

  /// Gravedad elegida en la hoja de filtros; null = todas.
  final AccidentSeverity? severity;
  final String query;

  int get total => accidents.length;

  /// Cuantos hay de un tipo (con todos los filtros menos el de tipo no
  /// influyen: el resumen cuenta todo lo cargado).
  int count(AccidentFilter f) => accidents.where(f.accepts).length;

  /// La parte del total que es [f], de 0 a 100.
  double share(AccidentFilter f) => total == 0 ? 0 : count(f) * 100 / total;

  /// Lo que se ve: el tipo elegido, la gravedad y la busqueda; lo mas reciente
  /// primero.
  List<Accident> get visible {
    final list = [
      for (final a in accidents)
        if (filter.accepts(a) &&
            (severity == null || a.severity == severity) &&
            a.matches(query))
          a,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  bool get hasActiveFilters =>
      filter != AccidentFilter.all ||
      severity != null ||
      query.trim().isNotEmpty;

  AccidentsState copyWith({
    AccidentsStatus? status,
    List<Accident>? accidents,
    AccidentsError? error,
    bool clearError = false,
    AccidentFilter? filter,
    AccidentSeverity? severity,
    bool clearSeverity = false,
    String? query,
  }) => AccidentsState(
    status: status ?? this.status,
    accidents: accidents ?? this.accidents,
    error: clearError ? null : (error ?? this.error),
    filter: filter ?? this.filter,
    severity: clearSeverity ? null : (severity ?? this.severity),
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [
    status,
    accidents,
    error,
    filter,
    severity,
    query,
  ];
}

/// El historial de accidentes: carga, tipo, gravedad y busqueda.
class AccidentsCubit extends Cubit<AccidentsState> {
  AccidentsCubit(this._repository) : super(const AccidentsState());

  final AccidentsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AccidentsStatus.loading, clearError: true));
    await _fetch();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final accidents = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AccidentsStatus.ready,
          accidents: accidents,
          clearError: true,
        ),
      );
    } on AccidentsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: AccidentsStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AccidentsStatus.failure,
          error: AccidentsError.server,
        ),
      );
    }
  }

  void setFilter(AccidentFilter filter) => emit(state.copyWith(filter: filter));

  void setSeverity(AccidentSeverity? severity) => emit(
    severity == null
        ? state.copyWith(clearSeverity: true)
        : state.copyWith(severity: severity),
  );

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearFilters() => emit(
    state.copyWith(filter: AccidentFilter.all, clearSeverity: true, query: ''),
  );
}
