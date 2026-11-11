import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pending_definition.dart';
import '../../domain/repositories/definitions_repository.dart';

enum DefinitionsListStatus { loading, ready, failure }

class DefinitionsState extends Equatable {
  const DefinitionsState({
    this.status = DefinitionsListStatus.loading,
    this.items = const [],
    this.permissions = const DefinitionPermissions(),
    this.error,
    this.pendingOnly = true,
    this.mobileModule,
    this.onlyModule = false,
    this.query = '',
  });

  final DefinitionsListStatus status;
  final List<PendingDefinition> items;
  final DefinitionPermissions permissions;
  final DefinitionsError? error;

  /// Solo las que esperan la respuesta de TEKIA (por omision).
  final bool pendingOnly;

  /// El modulo de la app desde el que se llego (`?module=`), si vino de uno.
  final String? mobileModule;

  /// Solo las de [mobileModule].
  final bool onlyModule;
  final String query;

  int get pendingCount => items.where((d) => d.status.pending).length;

  /// Lo que se ve, agrupado por modulo en el orden en que llega del servidor
  /// (el del contrato) y, dentro, ALTA primero.
  List<(String, List<PendingDefinition>)> get groups {
    final visible = [
      for (final d in items)
        if ((!pendingOnly || d.status.pending) &&
            (!onlyModule || d.mobileModule == mobileModule) &&
            d.matches(query))
          d,
    ];
    final byModule = <String, List<PendingDefinition>>{};
    for (final d in visible) {
      byModule.putIfAbsent(d.moduleLabel, () => []).add(d);
    }
    return [
      for (final e in byModule.entries)
        (
          e.key,
          [...e.value]
            ..sort((a, b) => a.priority.index.compareTo(b.priority.index)),
        ),
    ];
  }

  DefinitionsState copyWith({
    DefinitionsListStatus? status,
    List<PendingDefinition>? items,
    DefinitionPermissions? permissions,
    DefinitionsError? error,
    bool clearError = false,
    bool? pendingOnly,
    bool? onlyModule,
    String? query,
  }) => DefinitionsState(
    status: status ?? this.status,
    items: items ?? this.items,
    permissions: permissions ?? this.permissions,
    error: clearError ? null : (error ?? this.error),
    pendingOnly: pendingOnly ?? this.pendingOnly,
    mobileModule: mobileModule,
    onlyModule: onlyModule ?? this.onlyModule,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    permissions,
    error,
    pendingOnly,
    mobileModule,
    onlyModule,
    query,
  ];
}

/// La lista de definiciones: carga, filtro (sin veredicto o todas, del modulo
/// de donde se llego) y busqueda.
class DefinitionsCubit extends Cubit<DefinitionsState> {
  DefinitionsCubit(this._repository, {String? mobileModule})
    : super(
        DefinitionsState(
          mobileModule: mobileModule,
          onlyModule: mobileModule != null,
        ),
      );

  final DefinitionsRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: DefinitionsListStatus.loading, clearError: true),
    );
    await refresh();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() async {
    try {
      final page = await _repository.list();
      emit(
        state.copyWith(
          status: DefinitionsListStatus.ready,
          items: page.items,
          permissions: page.permissions,
          clearError: true,
        ),
      );
    } on DefinitionsException catch (e) {
      emit(
        state.copyWith(status: DefinitionsListStatus.failure, error: e.error),
      );
    }
  }

  void setPendingOnly(bool value) => emit(state.copyWith(pendingOnly: value));

  void setOnlyModule(bool value) => emit(state.copyWith(onlyModule: value));

  void setQuery(String value) => emit(state.copyWith(query: value));

  /// Pone al dia una definicion despues de contestarla en su detalle.
  void replace(PendingDefinition definition) => emit(
    state.copyWith(
      items: [
        for (final d in state.items) d.code == definition.code ? definition : d,
      ],
    ),
  );
}
