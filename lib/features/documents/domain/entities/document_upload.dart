import 'package:equatable/equatable.dart';

/// Una causa por la que lo capturado no se puede guardar todavia. El servidor
/// vuelve a validar todo al sincronizar (HU-MOB-03-02, regla 4); esto solo evita
/// capturar lo que se sabe que sera rechazado.
enum UploadIssue {
  noFile,
  emptyFile,
  blockedExtension,
  nameEmpty,
  nameInvalid,
  nameTooLong,
  typeMissing,
  descriptionRequired,
  descriptionTooLong,
}

/// Un archivo a cargar, con el nombre que tendra el documento. La extension es la
/// real del archivo y no se edita (D-03-79: «conservar la extension real»).
class UploadItem extends Equatable {
  const UploadItem({
    required this.path,
    required this.baseName,
    required this.extension,
    required this.sizeBytes,
  });

  /// De un nombre de archivo como `acta final.pdf`.
  factory UploadItem.fromFile({
    required String path,
    required String fileName,
    required int sizeBytes,
  }) {
    final dot = fileName.lastIndexOf('.');
    // `.gitignore` no tiene extension.
    final hasExtension = dot > 0 && dot < fileName.length - 1;
    return UploadItem(
      path: path,
      baseName: hasExtension ? fileName.substring(0, dot) : fileName,
      extension: hasExtension ? fileName.substring(dot) : '',
      sizeBytes: sizeBytes,
    );
  }

  final String path;

  /// Parte editable del nombre, sin la extension.
  final String baseName;

  /// Con el punto (`.pdf`), o vacia si el archivo no tiene.
  final String extension;
  final int sizeBytes;

  /// Nombre del documento: el editable recortado mas la extension real.
  String get name => '${baseName.trim()}$extension';

  /// Extension en minusculas, sin punto (`pdf`).
  String get format =>
      extension.isEmpty ? '' : extension.substring(1).toLowerCase();

  UploadItem withBaseName(String value) => UploadItem(
    path: path,
    baseName: value,
    extension: extension,
    sizeBytes: sizeBytes,
  );

  @override
  List<Object?> get props => [path, baseName, extension, sizeBytes];
}

/// Datos comunes a los archivos que se cargan juntos.
class UploadMetadata extends Equatable {
  const UploadMetadata({
    this.typeCode,
    this.categoryCode,
    this.description = '',
    this.folder,
  });

  final String? typeCode;
  final String? categoryCode;
  final String description;
  final String? folder;

  @override
  List<Object?> get props => [typeCode, categoryCode, description, folder];
}

/// Reglas de carga de documentos (DTF M03 §5.1, D-03-46, D-03-75, D-03-79).
abstract final class DocumentUploadRules {
  /// Catalogo inicial de extensiones bloqueadas (D-03-46). El catalogo real lo
  /// administra ADMINISTRADOR SISTEMA y el servidor es quien manda: esta lista
  /// es solo la inicial, para avisar antes de guardar.
  static const blockedExtensions = {
    'exe', 'msi', 'bat', 'cmd', 'com', 'scr', 'pif', 'cpl', 'dll', 'sys', //
    'ps1', 'psm1', 'vbs', 'vbe', 'js', 'jse', 'wsf', 'wsh', 'hta', 'jar',
    'sh', 'apk', 'app', 'reg', 'lnk',
  };

  /// Codigo estable del tipo «Otro» (TD12): pide descripcion.
  static const otherTypeCode = 'TD12';

  static const maxNameLength = 255;
  static const minOtherDescription = 10;
  static const maxDescription = 2000;

  static final _invalidChars = RegExp(r'[<>:"/\\|?*\u0000-\u001F\u007F]');

  /// Los problemas del nombre completo (con extension), sin repetir.
  static List<UploadIssue> nameIssues(UploadItem item) {
    final base = item.baseName.trim();
    if (base.isEmpty) return [UploadIssue.nameEmpty];
    final issues = <UploadIssue>[];
    if (RegExp(r'^\.+$').hasMatch(base) ||
        _invalidChars.hasMatch(base) ||
        item.name.endsWith('.')) {
      issues.add(UploadIssue.nameInvalid);
    }
    // Caracteres Unicode, no unidades UTF-16.
    if (item.name.runes.length > maxNameLength) {
      issues.add(UploadIssue.nameTooLong);
    }
    return issues;
  }

  static bool isBlocked(UploadItem item) =>
      blockedExtensions.contains(item.format);

  /// Problemas de un archivo.
  static List<UploadIssue> itemIssues(UploadItem item) => [
    if (item.sizeBytes <= 0) UploadIssue.emptyFile,
    if (isBlocked(item)) UploadIssue.blockedExtension,
    ...nameIssues(item),
  ];

  /// Problemas de los datos comunes. La categoria es opcional.
  static List<UploadIssue> metadataIssues(UploadMetadata m) {
    final issues = <UploadIssue>[];
    if (m.typeCode == null) issues.add(UploadIssue.typeMissing);
    final description = m.description.trim();
    final length = description.runes.length;
    if (m.typeCode == otherTypeCode && length < minOtherDescription) {
      issues.add(UploadIssue.descriptionRequired);
    }
    if (length > maxDescription) issues.add(UploadIssue.descriptionTooLong);
    return issues;
  }
}
