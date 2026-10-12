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

  DocumentDetail withFavorite(bool value) => DocumentDetail(
    summary: summary.withFavorite(value),
    version: version,
    sizeBytes: sizeBytes,
    modifiedBy: modifiedBy,
    description: description,
    folder: folder,
    previewAvailable: previewAvailable,
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
  ];
}
