import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../offline/operation.dart';
import '../session/session_scope.dart';

/// Lo que el servidor contesto a una consulta con conexion, guardado en el
/// telefono para volver a verlo cuando no haya red (listas y fichas de tickets,
/// inventario, mantenimiento, inspecciones y obras). Es de una persona y una
/// concesion: al cambiar el alcance o cerrar sesion se descarta (RN-CTX-02).
abstract interface class ResponseCache implements ScopeBound {
  /// Las consultas que se guardan: solo lo operativo de la concesion activa, no
  /// la sesion, los archivos ni lo que ya tiene su propio cache.
  bool accepts(String path);

  Future<void> save(String key, Object? json);

  /// Lo ultimo guardado para [key] y cuando se guardo; null si no hay.
  Future<({Object? json, DateTime savedAt})?> read(String key);
}

/// Sin cache: todo se pide al servidor (pruebas).
class NoResponseCache implements ResponseCache {
  const NoResponseCache();

  @override
  bool accepts(String path) => false;
  @override
  Future<void> bind(OfflineScope? scope) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> save(String key, Object? json) async {}
  @override
  Future<({Object? json, DateTime savedAt})?> read(String key) async => null;
}

/// Cache en archivos, uno por consulta. Sin alcance fijado (nadie ha iniciado
/// sesion) no guarda ni entrega nada.
class FileResponseCache implements ResponseCache {
  FileResponseCache({
    Future<Directory> Function()? root,
    DateTime Function()? clock,
  }) : _root = root ?? _defaultRoot,
       _now = clock ?? DateTime.now;

  final Future<Directory> Function() _root;
  final DateTime Function() _now;

  /// Las rutas que se guardan.
  static const _prefixes = [
    '/api/tickets',
    '/api/inspections',
    '/api/inspection-types',
    '/api/preventive-maintenance',
    '/api/assets',
    // La ficha de cada tipo: con ella se arma el alta de activos sin senal.
    '/api/asset-templates',
    '/api/works',
    '/api/app-configuration',
    '/api/catalogs',
    '/api/auth/me/notifications',
  ];

  static Future<Directory> _defaultRoot() async => Directory(
    p.join(
      (await getApplicationDocumentsDirectory()).path,
      'api_response_cache',
    ),
  );

  String? _scopeKey;

  static String _keyOf(OfflineScope scope) =>
      '${scope.userId}|${scope.concessionId}';

  @override
  bool accepts(String path) {
    final clean = path.split('?').first;
    // Las fotos y los archivos pesan y ya tienen su propio cache. Los cercanos
    // cambian con cada posicion: sin red se calculan en el telefono.
    if (clean.endsWith('/content') || clean == '/api/assets/nearby') {
      return false;
    }
    return _prefixes.any((x) => clean == x || clean.startsWith('$x/'));
  }

  Future<File> _scopeFile() async {
    final root = await _root();
    await root.create(recursive: true);
    return File(p.join(root.path, 'scope.txt'));
  }

  @override
  Future<void> bind(OfflineScope? scope) async {
    if (scope == null) {
      _scopeKey = null;
      await clear();
      return;
    }
    final key = _keyOf(scope);
    final file = await _scopeFile();
    final stored = await file.exists() ? await file.readAsString() : null;
    // Lo guardado era de otra persona u otra concesion (o no se sabe de quien):
    // se descarta antes de poder verse.
    if (stored != key) {
      await _wipeData();
      await file.writeAsString(key, flush: true);
    }
    _scopeKey = key;
  }

  @override
  Future<void> clear() async {
    _scopeKey = null;
    await _wipeData();
    try {
      final file = await _scopeFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _wipeData() async {
    try {
      final dir = Directory(p.join((await _root()).path, 'data'));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// El nombre del archivo sale de la consulta; los caracteres que no valen en
  /// un nombre se sustituyen y un sufijo evita choques entre consultas distintas.
  static String _name(String key) {
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final short = safe.length > 80 ? safe.substring(0, 80) : safe;
    return '$short-${_fnv1a(key).toRadixString(16)}.json';
  }

  /// Un resumen estable de la consulta (el `hashCode` de Dart puede cambiar de
  /// una version a otra y dejaria lo guardado sin poder leerse).
  static int _fnv1a(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  Future<File?> _file(String key) async {
    if (_scopeKey == null) return null;
    final dir = Directory(p.join((await _root()).path, 'data'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, _name(key)));
  }

  @override
  Future<void> save(String key, Object? json) async {
    final file = await _file(key);
    if (file == null) return;
    // Se escribe a un temporal y se renombra: una escritura a medias no deja un
    // archivo roto.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'at': _now().toUtc().toIso8601String(), 'json': json}),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  @override
  Future<({Object? json, DateTime savedAt})?> read(String key) async {
    final file = await _file(key);
    if (file == null || !await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return null;
      final at = DateTime.tryParse('${data['at']}');
      if (at == null || !data.containsKey('json')) return null;
      return (json: data['json'], savedAt: at.toUtc());
    } catch (_) {
      return null;
    }
  }
}
