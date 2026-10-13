import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Como se puede ver un documento en el telefono (D-03-45): JPG y PNG con el
/// visor de imagenes; PDF, y Office convertido a PDF por el servidor, con un
/// visor de PDF; el resto (DWG, DXF...) no tiene vista previa.
enum PreviewKind {
  image,
  pdf,
  unsupported;

  /// Lo que corresponde a una extension (sin punto, en minusculas). Es solo para
  /// decidir si ofrecer la vista previa: el servidor dice si hay representacion.
  static PreviewKind forFormat(String format) => switch (format) {
    'jpg' || 'jpeg' || 'png' => PreviewKind.image,
    'pdf' ||
    'doc' ||
    'docx' ||
    'xls' ||
    'xlsx' ||
    'ppt' ||
    'pptx' => PreviewKind.pdf,
    _ => PreviewKind.unsupported,
  };
}

/// La representacion que se muestra, no el original: la descarga del original no
/// forma parte del alcance movil (DTF M03 §3.1).
class DocumentPreview extends Equatable {
  const DocumentPreview({required this.kind, required this.bytes});

  final PreviewKind kind;
  final Uint8List bytes;

  @override
  List<Object?> get props => [kind, bytes.length];
}
