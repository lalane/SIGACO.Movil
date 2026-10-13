import 'package:equatable/equatable.dart';

/// Un valor de catalogo: codigo estable y etiqueta en el idioma de la interfaz
/// (D-03-77).
class CatalogEntry extends Equatable {
  const CatalogEntry(this.code, this.label, {this.active = true});

  final String code;
  final String label;

  /// Un valor inactivo sigue en los documentos que ya lo tienen y en los
  /// filtros, pero no se ofrece en cargas nuevas (D-03-78).
  final bool active;

  @override
  List<Object?> get props => [code, label, active];
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
