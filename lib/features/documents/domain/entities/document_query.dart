import 'package:equatable/equatable.dart';

import 'document.dart';

/// Filtros de la consulta (HU-MOB-03-01, regla 6). Todos son opcionales y se
/// combinan entre si y con la busqueda.
class DocumentFilters extends Equatable {
  const DocumentFilters({
    this.typeCode,
    this.categoryCode,
    this.folder,
    this.modifiedBy,
    this.from,
    this.to,
  });

  static const none = DocumentFilters();

  final String? typeCode;
  final String? categoryCode;
  final String? folder;
  final String? modifiedBy;

  /// Rango de fechas de modificacion, dias completos de la zona de la concesion.
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      typeCode == null &&
      categoryCode == null &&
      folder == null &&
      modifiedBy == null &&
      from == null &&
      to == null;

  /// Cuantos filtros hay activos (el rango cuenta como uno).
  int get activeCount =>
      [typeCode, categoryCode, folder, modifiedBy].nonNulls.length +
      ((from != null || to != null) ? 1 : 0);

  /// Un rango con Desde posterior a Hasta se rechaza sin consultar (CA-05).
  bool get rangeIsValid => from == null || to == null || !from!.isAfter(to!);

  @override
  List<Object?> get props => [
    typeCode,
    categoryCode,
    folder,
    modifiedBy,
    from,
    to,
  ];
}

class DocumentQuery extends Equatable {
  const DocumentQuery({
    this.view = DocumentView.all,
    this.search = '',
    this.filters = DocumentFilters.none,
  });

  final DocumentView view;

  /// Busca por nombre, propietario y categoria.
  final String search;
  final DocumentFilters filters;

  DocumentQuery copyWith({
    DocumentView? view,
    String? search,
    DocumentFilters? filters,
  }) => DocumentQuery(
    view: view ?? this.view,
    search: search ?? this.search,
    filters: filters ?? this.filters,
  );

  bool get hasCriteria => search.trim().isNotEmpty || !filters.isEmpty;

  @override
  List<Object?> get props => [view, search, filters];
}
