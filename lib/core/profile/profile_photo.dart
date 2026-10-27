import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// De donde sale la foto de perfil: la camara o la galeria del telefono. Cancelar
/// devuelve null, no un error. La foto se reduce al elegirla: un perfil no
/// necesita mas de unos cientos de pixeles.
abstract interface class ProfilePhotoPicker {
  Future<String?> fromCamera();

  Future<String?> fromGallery();
}

/// El selector del sistema (`image_picker`): no pide permisos propios.
class PlatformProfilePhotoPicker implements ProfilePhotoPicker {
  PlatformProfilePhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _side = 640.0;
  static const _quality = 85;

  Future<String?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _side,
      maxHeight: _side,
      imageQuality: _quality,
      preferredCameraDevice: CameraDevice.front,
    );
    return file?.path;
  }

  @override
  Future<String?> fromCamera() => _pick(ImageSource.camera);

  @override
  Future<String?> fromGallery() => _pick(ImageSource.gallery);
}

/// Sin selector (pruebas): no ofrece nada.
class NoProfilePhotoPicker implements ProfilePhotoPicker {
  const NoProfilePhotoPicker();

  @override
  Future<String?> fromCamera() async => null;

  @override
  Future<String?> fromGallery() async => null;
}

/// Donde queda la foto de perfil de cada persona.
///
/// Hoy vive solo en el telefono: el servidor todavia no publica el endpoint de
/// la foto de perfil (MOB-001). Cuando exista, se sustituye esta clase por una
/// que la suba y la baje sin tocar el resto.
abstract interface class ProfilePhotoStore {
  /// La ruta de la foto de [userId], o null si no tiene.
  Future<String?> read(String userId);

  /// Guarda [sourcePath] como la foto de [userId] y devuelve su ruta.
  Future<String> save(String userId, String sourcePath);

  Future<void> remove(String userId);
}

class NoProfilePhotoStore implements ProfilePhotoStore {
  const NoProfilePhotoStore();

  @override
  Future<String?> read(String userId) async => null;

  @override
  Future<String> save(String userId, String sourcePath) async => sourcePath;

  @override
  Future<void> remove(String userId) async {}
}

/// Una copia en la carpeta de la app por persona. El nombre lleva la hora para
/// que la pantalla no siga mostrando la foto anterior desde su memoria.
class LocalProfilePhotoStore implements ProfilePhotoStore {
  LocalProfilePhotoStore({
    Future<Directory> Function()? root,
    DateTime Function()? clock,
  }) : _root = root ?? _defaultRoot,
       _now = clock ?? DateTime.now;

  final Future<Directory> Function() _root;
  final DateTime Function() _now;

  static Future<Directory> _defaultRoot() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'profile_photo'),
  );

  /// El identificador viene del servidor, pero no se confia en el para armar una
  /// ruta: solo letras, numeros y guiones.
  static String _safe(String userId) =>
      userId.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_');

  Future<List<File>> _filesOf(String userId) async {
    final dir = await _root();
    if (!await dir.exists()) return const [];
    final prefix = '${_safe(userId)}_';
    final files = [
      await for (final e in dir.list())
        if (e is File && p.basename(e.path).startsWith(prefix)) e,
    ]..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  @override
  Future<String?> read(String userId) async {
    final files = await _filesOf(userId);
    return files.isEmpty ? null : files.last.path;
  }

  @override
  Future<String> save(String userId, String sourcePath) async {
    final dir = await _root();
    await dir.create(recursive: true);
    final stamp = _now().toUtc().microsecondsSinceEpoch;
    final target = File(p.join(dir.path, '${_safe(userId)}_$stamp.jpg'));
    await File(sourcePath).copy(target.path);
    // La anterior ya no se necesita.
    for (final old in await _filesOf(userId)) {
      if (old.path != target.path) {
        try {
          await old.delete();
        } on FileSystemException {
          // Se limpia en la siguiente.
        }
      }
    }
    return target.path;
  }

  @override
  Future<void> remove(String userId) async {
    for (final file in await _filesOf(userId)) {
      try {
        await file.delete();
      } on FileSystemException {
        // Se limpia en la siguiente.
      }
    }
  }
}
