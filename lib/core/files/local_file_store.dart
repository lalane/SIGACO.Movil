import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../offline/uuid.dart';

/// Guarda en el telefono los archivos de lo capturado sin conexion. Los que
/// da el selector o la camara pueden ser temporales; la cola necesita que el
/// archivo siga ahi cuando haya red, dias despues.
abstract interface class LocalFileStore {
  /// Copia [sourcePath] a un lugar propio de la app y devuelve su ruta.
  Future<String> keep(String sourcePath, {required String name});

  /// Borra un archivo guardado (si ya no existe, no falla).
  Future<void> remove(String path);
}

class DiskLocalFileStore implements LocalFileStore {
  /// [root] es la carpeta donde se guardan; sin ella, `offline_files` dentro de
  /// los documentos de la app.
  DiskLocalFileStore({this.root});

  final Directory? root;
  Directory? _resolved;

  Future<Directory> _dir() async => _resolved ??=
      root ??
      Directory(
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'offline_files',
        ),
      );

  @override
  Future<String> keep(String sourcePath, {required String name}) async {
    // Una carpeta por archivo: dos con el mismo nombre no se pisan.
    final folder = Directory(p.join((await _dir()).path, newUuid()));
    await folder.create(recursive: true);
    final target = p.join(folder.path, p.basename(name));
    try {
      await File(sourcePath).copy(target);
    } catch (_) {
      await folder.delete(recursive: true).catchError((_) => folder);
      rethrow;
    }
    return target;
  }

  @override
  Future<void> remove(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (await parent.exists() && (await parent.list().isEmpty)) {
        await parent.delete();
      }
    } catch (_) {}
  }
}
