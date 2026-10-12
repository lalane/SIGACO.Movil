import 'package:equatable/equatable.dart';

/// Un valor de catalogo: codigo estable y etiqueta en el idioma de la interfaz
/// (D-03-77).
class CatalogEntry extends Equatable {
  const CatalogEntry(this.code, this.label);

  final String code;
  final String label;

  @override
  List<Object?> get props => [code, label];
}

/// Lo que ofrecen los filtros; sale del servidor (catalogos globales cerrados,
/// D-03-76).
class DocumentCatalogs extends Equatable {
  const DocumentCatalogs({
    this.types = const [],
    this.categories = const [],
    this.folders = const [],
    this.users = const [],
  });

  final List<CatalogEntry> types;
  final List<CatalogEntry> categories;
  final List<String> folders;
  final List<String> users;

  @override
  List<Object?> get props => [types, categories, folders, users];
}
