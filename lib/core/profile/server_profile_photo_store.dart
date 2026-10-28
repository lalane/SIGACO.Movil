import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_failure.dart';
import 'profile_photo.dart';

/// La foto de perfil en el servidor (`/api/auth/me/photo`, MOB-001), con una copia
/// en el telefono para verla sin conexion.
///
/// - Al entrar baja la del servidor; sin red, muestra la copia.
/// - Al cambiarla la sube; si no hay red, queda en el telefono y se sube en el
///   siguiente acceso. Si el servidor la rechaza (formato o peso), no cambia nada.
/// - Al quitarla la borra en el servidor; sin red, se borra despues.
class ServerProfilePhotoStore implements ProfilePhotoStore {
  ServerProfilePhotoStore({
    required this._api,
    required this._local,
    required this._prefs,
  });

  final ApiClient _api;
  final ProfilePhotoStore _local;
  final SharedPreferences _prefs;

  static const _path = '/api/auth/me/photo';

  /// El codigo con que el servidor dice que la cuenta no tiene foto.
  static const _noPhoto = 'PROFILE_PHOTO_NOT_FOUND';
  static const _upload = 'upload';
  static const _remove = 'remove';

  String _key(String userId) => 'profile_photo_pending_$userId';

  Future<void> _mark(String userId, String? pending) async {
    if (pending == null) {
      await _prefs.remove(_key(userId));
    } else {
      await _prefs.setString(_key(userId), pending);
    }
  }

  @override
  Future<String?> read(String userId) async {
    await _flushPending(userId);
    try {
      final photo = await _api.getBytes(_path);
      if (photo.bytes.isEmpty) return _local.read(userId);
      return await _cache(userId, photo.bytes);
    } on ApiFailure catch (e) {
      // El servidor dice que no tiene foto: la copia ya no vale.
      if (e.status == 404 && e.code == _noPhoto) {
        await _local.remove(userId);
        return null;
      }
      // Sin red, sin el endpoint o con un fallo: se ve la copia.
      return _local.read(userId);
    }
  }

  @override
  Future<String> save(String userId, String sourcePath) async {
    try {
      await _put(sourcePath);
      await _mark(userId, null);
    } on ApiFailure catch (e) {
      // Rechazada por el servidor: se avisa y se conserva la anterior.
      if (!_unavailable(e)) rethrow;
      // Sin red, o un servidor que aun no tiene la foto: queda en el telefono y
      // se sube despues.
      await _mark(userId, _upload);
    }
    return _local.save(userId, sourcePath);
  }

  @override
  Future<void> remove(String userId) async {
    try {
      await _api.delete(_path);
      await _mark(userId, null);
    } on ApiFailure catch (e) {
      if (!_unavailable(e)) rethrow;
      await _mark(userId, _remove);
    }
    await _local.remove(userId);
  }

  /// Lo que se hizo sin red y falta enviar. Si el servidor lo rechaza, se descarta:
  /// no se reintenta para siempre.
  Future<void> _flushPending(String userId) async {
    final pending = _prefs.getString(_key(userId));
    if (pending == null) return;
    try {
      if (pending == _remove) {
        await _api.delete(_path);
      } else {
        final local = await _local.read(userId);
        if (local != null) await _put(local);
      }
      await _mark(userId, null);
    } on ApiFailure catch (e) {
      if (!_unavailable(e)) await _mark(userId, null);
    }
  }

  /// No se pudo hablar con el servidor, o este aun no publica la foto (404 o 405
  /// sin el codigo de "sin foto"): lo hecho se conserva y se reintenta.
  static bool _unavailable(ApiFailure e) =>
      e.isNetwork ||
      ((e.status == 404 || e.status == 405) && e.code != _noPhoto);

  Future<void> _put(String filePath) => _api.putMultipart(
    _path,
    fileField: 'file',
    filePath: filePath,
    fileName: p.basename(filePath),
    contentType: _contentType(filePath),
  );

  /// El servidor reconoce el formato por el contenido; esto solo es el tipo declarado.
  static String _contentType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  /// Guarda la copia solo si cambio, para no mover la ruta (y parpadear) en cada
  /// acceso.
  Future<String> _cache(String userId, List<int> bytes) async {
    final current = await _local.read(userId);
    if (current != null) {
      try {
        final existing = await File(current).readAsBytes();
        if (existing.length == bytes.length && _same(existing, bytes)) {
          return current;
        }
      } on FileSystemException {
        // Se reemplaza.
      }
    }
    final dir = await Directory.systemTemp.createTemp('pp_dl_');
    try {
      final file = File(p.join(dir.path, 'photo.jpg'));
      await file.writeAsBytes(bytes, flush: true);
      return await _local.save(userId, file.path);
    } finally {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    }
  }

  static bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
