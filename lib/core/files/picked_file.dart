import 'package:equatable/equatable.dart';

/// Un archivo que la persona eligio en el telefono (galeria, archivos, camara).
class SelectedFile extends Equatable {
  const SelectedFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  /// Nombre con extension, tal como lo tiene el archivo.
  final String name;

  /// Ruta local; puede ser temporal, asi que quien lo conserve debe copiarlo.
  final String path;
  final int sizeBytes;

  @override
  List<Object?> get props => [name, path, sizeBytes];
}
