import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';

import 'picked_file.dart';

/// De donde salen los archivos que se cargan: el selector de archivos del
/// telefono y la camara. La fuente no cambia las reglas documentales
/// (HU-MOB-03-02, regla 5). Cancelar devuelve vacio / null, no un error.
abstract interface class FileSource {
  Future<List<SelectedFile>> pickFiles();

  Future<SelectedFile?> takePhoto();
}

/// El selector de archivos y la camara del sistema (`file_picker` e
/// `image_picker`): no piden permisos propios, el sistema abre su pantalla.
class PlatformFileSource implements FileSource {
  PlatformFileSource({ImagePicker? imagePicker})
    : _images = imagePicker ?? ImagePicker();

  final ImagePicker _images;

  @override
  Future<List<SelectedFile>> pickFiles() async {
    final files = await fp.FilePicker.pickFiles();
    return [
      for (final f in files)
        if (f.path != null)
          SelectedFile(
            name: f.name,
            path: f.path!,
            sizeBytes: f.lengthSync() ?? await f.length() ?? 0,
          ),
    ];
  }

  @override
  Future<SelectedFile?> takePhoto() async {
    final shot = await _images.pickImage(source: ImageSource.camera);
    if (shot == null) return null;
    return SelectedFile(
      name: shot.name,
      path: shot.path,
      sizeBytes: await shot.length(),
    );
  }
}

/// Sin selector (pruebas y entornos sin plugins): no ofrece nada.
class NoFileSource implements FileSource {
  const NoFileSource();

  @override
  Future<List<SelectedFile>> pickFiles() async => const [];

  @override
  Future<SelectedFile?> takePhoto() async => null;
}
