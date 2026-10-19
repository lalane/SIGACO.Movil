import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/offline/operation.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/geo_bounds.dart';
import '../../domain/entities/map_pack.dart';
import '../../domain/repositories/map_pack_manager.dart';
import 'map_pack_remote.dart';
import 'mbtiles_reader.dart';

/// Los paquetes de mapa en disco. Son de una persona y una concesion: al
/// cambiar de concesion o cerrar sesion se borran (RN-CTX-02), y si la app se
/// cerro a la fuerza, al iniciar sesion se descarta lo que era de otro alcance.
///
/// Disposicion (dentro de `data/`):
/// * `<id>-<version>.mbtiles`: paquete instalado.
/// * `<id>.part` y `<id>.part.json`: descarga a medias y de que version es.
/// * `index.json`: lo instalado.
class FileMapPackManager implements MapPackManager, ScopeBound {
  FileMapPackManager({
    required this.remote,
    Future<Directory> Function()? root,
    Future<TileReader> Function(String path)? openReader,
    DateTime Function()? clock,
  }) : _root = root ?? _defaultRoot,
       _openReader = openReader ?? MbTilesReader.open,
       _now = clock ?? DateTime.now;

  final MapPackRemote remote;
  final Future<Directory> Function() _root;
  final Future<TileReader> Function(String path) _openReader;
  final DateTime Function() _now;

  static Future<Directory> _defaultRoot() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'map_packs'),
  );

  String? _scopeKey;
  final Set<String> _downloading = {};

  // ---------------------------------------------------------------- alcance

  static String _keyOf(OfflineScope scope) => crypto.sha256
      .convert(utf8.encode('${scope.userId}|${scope.concessionId}'))
      .toString();

  @override
  Future<void> bind(OfflineScope? scope) async {
    if (scope == null) {
      _scopeKey = null;
      await clear();
      return;
    }
    final key = _keyOf(scope);
    final root = await _root();
    final file = File(p.join(root.path, 'scope.txt'));
    String? saved;
    try {
      if (await file.exists()) saved = (await file.readAsString()).trim();
    } catch (_) {}
    if (saved != key) {
      await _deleteData(root);
      await root.create(recursive: true);
      await file.writeAsString(key, flush: true);
    }
    _scopeKey = key;
  }

  @override
  Future<void> clear() async {
    _scopeKey = null;
    await _deleteData(await _root());
  }

  static Future<void> _deleteData(Directory root) async {
    final data = Directory(p.join(root.path, 'data'));
    if (await data.exists()) await data.delete(recursive: true);
    final scope = File(p.join(root.path, 'scope.txt'));
    if (await scope.exists()) await scope.delete();
  }

  Future<Directory> _data() async {
    if (_scopeKey == null) {
      throw const MapPackException(MapPackError.notAvailable);
    }
    final dir = Directory(p.join((await _root()).path, 'data'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ----------------------------------------------------------------- indice

  File _indexFile(Directory dir) => File(p.join(dir.path, 'index.json'));

  Future<List<InstalledPack>> _readIndex(Directory dir) async {
    final file = _indexFile(dir);
    if (!await file.exists()) return [];
    try {
      final json = jsonDecode(await file.readAsString());
      final list = json is Map<String, Object?> ? json['packs'] : null;
      if (list is! List) return [];
      return [
        for (final e in list)
          if (e is Map<String, Object?>) ?_fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(Directory dir, List<InstalledPack> packs) async {
    final tmp = File(p.join(dir.path, 'index.json.tmp'));
    await tmp.writeAsString(
      jsonEncode({
        'packs': [for (final x in packs) _toJson(x)],
      }),
      flush: true,
    );
    await tmp.rename(_indexFile(dir).path);
  }

  static Map<String, Object?> _toJson(InstalledPack x) => {
    'id': x.id,
    'name': x.name,
    'version': x.version,
    'sizeBytes': x.sizeBytes,
    'sha256': x.sha256,
    'minZoom': x.minZoom,
    'maxZoom': x.maxZoom,
    'bounds': {
      'south': x.bounds.south,
      'west': x.bounds.west,
      'north': x.bounds.north,
      'east': x.bounds.east,
    },
    'installedAt': x.installedAt.toIso8601String(),
    'attribution': x.attribution,
  };

  static InstalledPack? _fromJson(Map<String, Object?> j) {
    try {
      final b = j['bounds']! as Map<String, Object?>;
      return InstalledPack(
        id: j['id']! as String,
        name: j['name']! as String,
        version: (j['version']! as num).toInt(),
        sizeBytes: (j['sizeBytes']! as num).toInt(),
        sha256: j['sha256']! as String,
        minZoom: (j['minZoom']! as num).toInt(),
        maxZoom: (j['maxZoom']! as num).toInt(),
        bounds: GeoBounds(
          south: (b['south']! as num).toDouble(),
          west: (b['west']! as num).toDouble(),
          north: (b['north']! as num).toDouble(),
          east: (b['east']! as num).toDouble(),
        ),
        installedAt: DateTime.parse(j['installedAt']! as String).toUtc(),
        attribution: j['attribution'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String _fileName(String id, int version) => '${_safe(id)}-$version.mbtiles';

  /// El id viene del servidor: solo letras, numeros y guiones en el disco.
  static String _safe(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  File _partFile(Directory dir, String id) =>
      File(p.join(dir.path, '${_safe(id)}.part'));

  File _partMeta(Directory dir, String id) =>
      File(p.join(dir.path, '${_safe(id)}.part.json'));

  // ------------------------------------------------------------------ lectura

  @override
  Future<List<MapPack>> available() => remote.list();

  @override
  Future<List<InstalledPack>> installed() async {
    if (_scopeKey == null) return [];
    final dir = await _data();
    final index = await _readIndex(dir);
    final valid = <InstalledPack>[];
    for (final x in index) {
      final file = File(p.join(dir.path, _fileName(x.id, x.version)));
      if (await file.exists() && await file.length() == x.sizeBytes) {
        valid.add(x);
      }
    }
    if (valid.length != index.length) await _writeIndex(dir, valid);
    return valid;
  }

  @override
  Future<TileReader?> openActive() async {
    final packs = await installed();
    if (packs.isEmpty) return null;
    final newest = ([
      ...packs,
    ]..sort((a, b) => b.installedAt.compareTo(a.installedAt))).first;
    final dir = await _data();
    final path = p.join(dir.path, _fileName(newest.id, newest.version));
    try {
      return await _openReader(path);
    } catch (_) {
      // Un archivo que no abre no sirve: se borra para no volver a intentarlo.
      await remove(newest.id);
      return null;
    }
  }

  // ----------------------------------------------------------------- descarga

  @override
  Future<int> partialBytes(String packId) async {
    if (_scopeKey == null) return 0;
    final part = _partFile(await _data(), packId);
    return await part.exists() ? part.length() : 0;
  }

  @override
  Future<void> discardPartial(String packId) async {
    if (_scopeKey == null) return;
    final dir = await _data();
    for (final f in [_partFile(dir, packId), _partMeta(dir, packId)]) {
      if (await f.exists()) await f.delete();
    }
  }

  @override
  Stream<PackProgress> download(MapPack pack) async* {
    if (!pack.isUsable) throw const MapPackException(MapPackError.corrupt);
    if (!_downloading.add(pack.id)) {
      throw StateError('El paquete ${pack.id} ya se esta bajando.');
    }
    try {
      final dir = await _data();
      final part = _partFile(dir, pack.id);
      final meta = _partMeta(dir, pack.id);

      // ¿Hay una descarga anterior de esta misma version y huella?
      var have = 0;
      if (await part.exists() && await meta.exists()) {
        try {
          final m =
              jsonDecode(await meta.readAsString()) as Map<String, Object?>;
          if (m['version'] == pack.version && m['sha256'] == pack.sha256) {
            have = await part.length();
          }
        } catch (_) {}
      }
      if (have > pack.sizeBytes || have == 0) {
        have = 0;
        if (await part.exists()) await part.delete();
      }
      await meta.writeAsString(
        jsonEncode({'version': pack.version, 'sha256': pack.sha256}),
        flush: true,
      );

      if (have < pack.sizeBytes) {
        final content = await remote.content(pack, from: have);
        var mode = FileMode.append;
        if (!content.resumed && have > 0) {
          // El servidor ignoro el Range y manda todo: se empieza de cero.
          have = 0;
          mode = FileMode.write;
        }
        final sink = part.openWrite(mode: mode);
        try {
          await for (final chunk in content.body) {
            sink.add(chunk);
            have += chunk.length;
            if (have > pack.sizeBytes) {
              await sink.close();
              await discardPartial(pack.id);
              throw const MapPackException(MapPackError.corrupt);
            }
            yield PackProgress(receivedBytes: have, totalBytes: pack.sizeBytes);
          }
          await sink.flush();
        } on MapPackException {
          rethrow;
        } on FileSystemException catch (e) {
          final code = e.osError?.errorCode;
          throw MapPackException(
            code == 28 || code == 112
                ? MapPackError.noSpace
                : MapPackError.network,
          );
        } catch (_) {
          // Se corto la conexion: lo bajado se conserva para reanudar.
          throw const MapPackException(MapPackError.network);
        } finally {
          try {
            await sink.close();
          } catch (_) {}
        }
      }

      if (await part.length() != pack.sizeBytes) {
        // Termino antes de tiempo: se puede reanudar.
        throw const MapPackException(MapPackError.network);
      }

      yield PackProgress(
        receivedBytes: pack.sizeBytes,
        totalBytes: pack.sizeBytes,
        verifying: true,
      );
      final digest = (await crypto.sha256.bind(part.openRead()).first)
          .toString();
      if (digest != pack.sha256.toLowerCase()) {
        await discardPartial(pack.id);
        throw const MapPackException(MapPackError.corrupt);
      }

      await _install(dir, pack, part);
      if (await meta.exists()) await meta.delete();
      yield PackProgress(
        receivedBytes: pack.sizeBytes,
        totalBytes: pack.sizeBytes,
      );
    } finally {
      _downloading.remove(pack.id);
    }
  }

  Future<void> _install(Directory dir, MapPack pack, File part) async {
    final target = File(p.join(dir.path, _fileName(pack.id, pack.version)));
    if (await target.exists()) await target.delete();
    await part.rename(target.path);
    final all = await _readIndex(dir);
    final older = all.where((x) => x.id == pack.id).toList();
    final next = [
      for (final x in all)
        if (x.id != pack.id) x,
      InstalledPack(
        id: pack.id,
        name: pack.name,
        version: pack.version,
        sizeBytes: pack.sizeBytes,
        sha256: pack.sha256,
        minZoom: pack.minZoom,
        maxZoom: pack.maxZoom,
        bounds: pack.bounds,
        installedAt: _now().toUtc(),
        attribution: pack.attribution,
      ),
    ];
    await _writeIndex(dir, next);
    // La version anterior ya no sirve; si esta abierta en otra parte, no pasa
    // nada grave: el siguiente arranque la ignora.
    for (final old in older) {
      if (old.version == pack.version) continue;
      try {
        final f = File(p.join(dir.path, _fileName(old.id, old.version)));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> remove(String packId) async {
    if (_scopeKey == null) return;
    final dir = await _data();
    final all = await _readIndex(dir);
    for (final x in all.where((x) => x.id == packId)) {
      try {
        final f = File(p.join(dir.path, _fileName(x.id, x.version)));
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await discardPartial(packId);
    await _writeIndex(dir, [
      for (final x in all)
        if (x.id != packId) x,
    ]);
  }
}
