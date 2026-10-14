import 'dart:collection';

import 'package:equatable/equatable.dart';

/// Estado de firma de la version vigente (D-03-50): M03 no tiene flujo de
/// aprobacion, solo este estado.
enum DocumentSignature { unsigned, pending, validated }

/// Las cuatro vistas de la consulta movil (HU-MOB-03-01, regla 1).
enum DocumentView { all, recent, favorites, mine }

/// Lo que muestra cada fila del listado.
class DocumentSummary extends Equatable {
  const DocumentSummary({
    required this.id,
    required this.name,
    required this.typeCode,
    required this.typeLabel,
    required this.ownerUsername,
    required this.modifiedAt,
    this.categoryCode,
    this.categoryLabel,
    this.signature = DocumentSignature.unsigned,
    this.isFavorite = false,
    this.format = '',
  });

  final String id;
  final String name;
  final String typeCode;
  final String typeLabel;
  final String? categoryCode;
  final String? categoryLabel;

  /// Parte del correo antes de «@» (D-03-52).
  final String ownerUsername;

  /// Ultima modificacion, en UTC.
  final DateTime modifiedAt;
  final DocumentSignature signature;
  final bool isFavorite;

  /// Extension del archivo en minusculas, sin punto (`pdf`, `jpg`...).
  final String format;

  DocumentSummary withSignature(DocumentSignature value) => DocumentSummary(
    id: id,
    name: name,
    typeCode: typeCode,
    typeLabel: typeLabel,
    categoryCode: categoryCode,
    categoryLabel: categoryLabel,
    ownerUsername: ownerUsername,
    modifiedAt: modifiedAt,
    signature: value,
    isFavorite: isFavorite,
    format: format,
  );

  DocumentSummary withFavorite(bool value) => DocumentSummary(
    id: id,
    name: name,
    typeCode: typeCode,
    typeLabel: typeLabel,
    categoryCode: categoryCode,
    categoryLabel: categoryLabel,
    ownerUsername: ownerUsername,
    modifiedAt: modifiedAt,
    signature: signature,
    isFavorite: value,
    format: format,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    typeCode,
    typeLabel,
    categoryCode,
    categoryLabel,
    ownerUsername,
    modifiedAt,
    signature,
    isFavorite,
    format,
  ];
}

/// El resultado de una consulta. Se comporta como la lista de documentos; ademas
/// dice si salio del telefono (sin conexion) y de cuando son esos datos, para no
/// presentar informacion atrasada como si fuera nueva (CA-HU-MOB-03-01-06).
class DocumentListing extends ListBase<DocumentSummary> {
  DocumentListing(List<DocumentSummary> items, {this.cachedAt})
    : _items = List.unmodifiable(items);

  final List<DocumentSummary> _items;

  /// UTC. Si no es null, la lista no viene del servidor: es la ultima que se
  /// pudo consultar, guardada en el telefono en ese momento.
  final DateTime? cachedAt;

  bool get fromPhone => cachedAt != null;

  @override
  int get length => _items.length;

  @override
  set length(int newLength) =>
      throw UnsupportedError('La consulta no se puede modificar');

  @override
  DocumentSummary operator [](int index) => _items[index];

  @override
  void operator []=(int index, DocumentSummary value) =>
      throw UnsupportedError('La consulta no se puede modificar');
}

/// La ficha: la version vigente y sus metadatos. El historial completo de
/// versiones queda fuera de la app movil (HU-MOB-03-01, regla 7).
class DocumentDetail extends Equatable {
  const DocumentDetail({
    required this.summary,
    required this.version,
    required this.sizeBytes,
    required this.modifiedBy,
    this.description = '',
    this.folder,
    this.previewAvailable = true,
    this.versionId = '',
    this.checksum = '',
    this.cachedAt,
  });

  final DocumentSummary summary;

  /// Numero de la version vigente (V1, V2...).
  final int version;
  final int sizeBytes;
  final String modifiedBy;
  final String description;

  /// Ruta de la carpeta; null en el nivel inicial de la concesion (D-03-53).
  final String? folder;

  /// El formato tiene visor o representacion en PDF (D-03-45).
  final bool previewAvailable;

  /// Identificador de la version vigente y su hash: lo que se firma (HU-MOB-03-03).
  final String versionId;
  final String checksum;

  /// UTC. Si no es null, la ficha viene del telefono, no del servidor.
  final DateTime? cachedAt;

  DocumentDetail withFavorite(bool value) =>
      _copy(summary: summary.withFavorite(value));

  DocumentDetail withSignature(DocumentSignature value) =>
      _copy(summary: summary.withSignature(value));

  /// La misma ficha marcada como guardada en el telefono en [at].
  DocumentDetail fromPhone(DateTime at) => _copy(cachedAt: at);

  DocumentDetail _copy({DocumentSummary? summary, DateTime? cachedAt}) =>
      DocumentDetail(
        summary: summary ?? this.summary,
        version: version,
        sizeBytes: sizeBytes,
        modifiedBy: modifiedBy,
        description: description,
        folder: folder,
        previewAvailable: previewAvailable,
        versionId: versionId,
        checksum: checksum,
        cachedAt: cachedAt ?? this.cachedAt,
      );

  @override
  List<Object?> get props => [
    summary,
    version,
    sizeBytes,
    modifiedBy,
    description,
    folder,
    previewAvailable,
    versionId,
    checksum,
    cachedAt,
  ];
}
