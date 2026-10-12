import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'capped_download.dart';

/// De donde salen los bytes de un logo (DEV-MOB-059).
abstract interface class LogoStore {
  /// Los bytes del logo de [url]; [version] es la version de la marca que lo
  /// entrego (si cambia, se descarga otra vez aunque la URL sea la misma).
  /// Null si no se pudo obtener: sin conexion y sin copia guardada.
  Future<Uint8List?> bytesFor(String url, {int version = 0});
}

/// Descarga cada vez, sin guardar nada. Es el respaldo de las pruebas.
class DownloadLogoStore implements LogoStore {
  const DownloadLogoStore();

  @override
  Future<Uint8List?> bytesFor(String url, {int version = 0}) =>
      downloadCapped(url);
}

/// Guarda cada logo en disco: la primera vez se descarga y despues se lee del
/// telefono, asi que el logo de la concesion aparece tambien sin conexion.
///
/// La copia se identifica por URL y version de la marca. Se conservan como
/// maximo [maxFiles] archivos (los mas recientes), para no acumular logos de
/// versiones o concesiones anteriores.
class DiskLogoStore implements LogoStore {
  DiskLogoStore({
    Future<Directory> Function()? directory,
    Future<Uint8List?> Function(String url)? download,
    this.maxFiles = 12,
  }) : _directory = directory ?? _supportLogos,
       _download = download ?? downloadCapped;

  final Future<Directory> Function() _directory;
  final Future<Uint8List?> Function(String url) _download;
  final int maxFiles;

  final _inFlight = <String, Future<Uint8List?>>{};

  static Future<Directory> _supportLogos() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}logos');
  }

  /// FNV-1a de 64 bits sobre la URL: nombre de archivo corto y estable.
  static String _hash(String s) {
    var h = 0xcbf29ce484222325;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  static String _name(String url, int version) =>
      '${_hash(url)}_v$version.logo';

  @override
  Future<Uint8List?> bytesFor(String url, {int version = 0}) {
    final name = _name(url, version);
    return _inFlight.putIfAbsent(
      name,
      () => _load(url, name).whenComplete(() {
        // Sin devolver el valor de remove: seria el mismo Future y se esperaria a si mismo.
        _inFlight.remove(name);
      }),
    );
  }

  Future<Uint8List?> _load(String url, String name) async {
    try {
      final dir = await _directory();
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      if (await file.exists()) {
        final saved = await file.readAsBytes();
        if (saved.isNotEmpty) return saved;
      }
      final bytes = await _download(url);
      if (bytes == null || bytes.isEmpty) return null;
      await dir.create(recursive: true);
      // Se escribe aparte y se renombra: un corte a medias no deja un logo roto.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
      await _prune(dir);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prune(Directory dir) async {
    final files = <(File, DateTime)>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.logo')) {
        files.add((e, (await e.stat()).modified));
      }
    }
    if (files.length <= maxFiles) return;
    files.sort((a, b) => b.$2.compareTo(a.$2));
    for (final (file, _) in files.skip(maxFiles)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
