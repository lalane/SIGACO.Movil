import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/offline/operation.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/entities/document_query.dart';

/// Lo que ya se consulto con conexion y queda en el telefono para verlo sin ella
/// (DTF M03 §3.2: «la app puede mostrar unicamente metadatos y contenidos ya
/// disponibles localmente»). Es de una persona y una concesion: al cambiar el
/// alcance o cerrar sesion se descarta (RN-CTX-02).
abstract interface class DocumentsCache implements ScopeBound {
  Future<void> saveList(DocumentQuery query, List<DocumentSummary> items);

  /// La ultima lista de esa misma consulta, marcada con cuando se guardo.
  Future<DocumentListing?> readList(DocumentQuery query);

  Future<void> saveDetail(DocumentDetail detail);
  Future<DocumentDetail?> readDetail(String id);

  Future<void> savePreview(String id, DocumentPreview preview);
  Future<DocumentPreview?> readPreview(String id);

  Future<void> saveCatalogs(DocumentCatalogs catalogs);
  Future<DocumentCatalogs?> readCatalogs();

  /// La ficha guardada de un documento dejo de ser fiel (por ejemplo, se firmo
  /// o cambio un favorito): se vuelve a pedir la proxima vez.
  Future<void> forgetDetail(String id);
}

/// Sin cache: todo se pide al servidor (pruebas y datos de ejemplo).
class NoDocumentsCache implements DocumentsCache {
  const NoDocumentsCache();

  @override
  Future<void> bind(OfflineScope? scope) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> saveList(
    DocumentQuery query,
    List<DocumentSummary> items,
  ) async {}
  @override
  Future<DocumentListing?> readList(DocumentQuery query) async => null;
  @override
  Future<void> saveDetail(DocumentDetail detail) async {}
  @override
  Future<DocumentDetail?> readDetail(String id) async => null;
  @override
  Future<void> savePreview(String id, DocumentPreview preview) async {}
  @override
  Future<DocumentPreview?> readPreview(String id) async => null;
  @override
  Future<void> saveCatalogs(DocumentCatalogs catalogs) async {}
  @override
  Future<DocumentCatalogs?> readCatalogs() async => null;
  @override
  Future<void> forgetDetail(String id) async {}
}

/// Cache en archivos dentro de la carpeta de la app. Sin alcance fijado (nadie
/// ha iniciado sesion) no guarda ni entrega nada.
class FileDocumentsCache implements DocumentsCache {
  FileDocumentsCache({
    Future<Directory> Function()? root,
    DateTime Function()? clock,
    this.maxLists = 30,
    this.maxDetails = 200,
    this.maxPreviews = 30,
    this.maxPreviewBytes = 15 * 1024 * 1024,
  }) : _root = root ?? _defaultRoot,
       _now = clock ?? DateTime.now;

  final Future<Directory> Function() _root;
  final DateTime Function() _now;
  final int maxLists;
  final int maxDetails;
  final int maxPreviews;

  /// Un archivo mas grande no se guarda: la vista previa se pide otra vez.
  final int maxPreviewBytes;

  static Future<Directory> _defaultRoot() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'documents_cache'),
  );

  String? _scopeKey;

  static String _keyOf(OfflineScope scope) =>
      '${scope.userId}|${scope.concessionId}';

  Future<Directory> _data() async {
    final dir = Directory(p.join((await _root()).path, 'data'));
    await dir.create(recursive: true);
    return dir;
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
    await _wipeData();
    try {
      final file = await _scopeFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _wipeData() async {
    try {
      final root = await _root();
      final dir = Directory(p.join(root.path, 'data'));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  // ---- Listas ---------------------------------------------------------------

  static String _queryKey(DocumentQuery q) {
    final f = q.filters;
    return [
      q.view.name,
      q.search.trim().toLowerCase(),
      f.typeCode,
      f.categoryCode,
      f.folder,
      f.modifiedBy,
      f.from?.toIso8601String(),
      f.to?.toIso8601String(),
    ].join('\u{1f}');
  }

  /// FNV-1a de 64 bits: un nombre de archivo corto para la consulta. La clave
  /// completa va dentro del archivo y se compara al leer.
  static String _hash(String text) {
    var h = 0xcbf29ce484222325;
    for (final unit in utf8.encode(text)) {
      h = (h ^ unit) * 0x100000001b3;
    }
    return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  Future<File?> _file(String name) async {
    if (_scopeKey == null) return null;
    return File(p.join((await _data()).path, name));
  }

  Future<void> _write(String name, String content, {String? prune}) async {
    final file = await _file(name);
    if (file == null) return;
    await file.writeAsString(content, flush: true);
    if (prune != null) await _touchAndPrune(prune, name);
  }

  /// Cuanto cabe de cada clase de archivo.
  int _maxOf(String prefix) => switch (prefix) {
    'list_' => maxLists,
    'detail_' => maxDetails,
    _ => maxPreviews,
  };

  /// El orden de los mas recientes se lleva en un indice propio (no en la fecha
  /// del archivo, que no distingue dos escrituras seguidas). Cada entrada es el
  /// archivo principal; en las vistas previas, ademas, su `.bin`.
  Future<Map<String, List<String>>> _readIndex() async {
    final file = await _file('index.json');
    if (file == null || !await file.exists()) return {};
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return {};
      return {
        for (final e in json.entries)
          e.key: [for (final n in e.value as List) n as String],
      };
    } catch (_) {
      return {};
    }
  }

  /// Marca [name] como lo mas reciente de su clase y borra lo que sobre.
  Future<void> _touchAndPrune(String prefix, String name) async {
    final index = await _readIndex();
    final dir = await _data();
    final onDisk = {
      for (final e in dir.listSync())
        if (e is File &&
            p.basename(e.path).startsWith(prefix) &&
            p.basename(e.path).endsWith('.json'))
          p.basename(e.path),
    };
    // Lo que esta en disco pero no en el indice (indice perdido) se trata como
    // lo mas viejo.
    final order = [
      for (final n in index[prefix] ?? const <String>[])
        if (n != name && onDisk.contains(n)) n,
    ];
    final unknown = [
      for (final n in onDisk)
        if (n != name && !order.contains(n)) n,
    ]..sort();
    final ordered = [...unknown, ...order, name];
    final extra = ordered.length - _maxOf(prefix);
    if (extra > 0) {
      for (final old in ordered.take(extra)) {
        await _deleteEntry(old);
      }
    }
    index[prefix] = ordered.skip(extra > 0 ? extra : 0).toList();
    final file = await _file('index.json');
    await file?.writeAsString(jsonEncode(index), flush: true);
  }

  Future<void> _deleteEntry(String name) async {
    for (final n in [
      name,
      if (name.startsWith('preview_'))
        name.replaceFirst(RegExp(r'.json$'), '.bin'),
    ]) {
      final file = await _file(n);
      if (file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  Future<Map<String, dynamic>?> _readJson(String name) async {
    final file = await _file(name);
    if (file == null || !await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveList(DocumentQuery query, List<DocumentSummary> items) =>
      _write(
        'list_${_hash(_queryKey(query))}.json',
        jsonEncode({
          'key': _queryKey(query),
          'at': _now().toUtc().toIso8601String(),
          'items': [for (final d in items) _summaryToJson(d)],
        }),
        prune: 'list_',
      );

  @override
  Future<DocumentListing?> readList(DocumentQuery query) async {
    final json = await _readJson('list_${_hash(_queryKey(query))}.json');
    if (json == null || json['key'] != _queryKey(query)) return null;
    try {
      return DocumentListing([
        for (final e in json['items'] as List)
          _summaryFromJson(e as Map<String, dynamic>),
      ], cachedAt: DateTime.parse(json['at'] as String).toUtc());
    } catch (_) {
      return null;
    }
  }

  // ---- Fichas ---------------------------------------------------------------

  @override
  Future<void> saveDetail(DocumentDetail d) => _write(
    'detail_${_safe(d.summary.id)}.json',
    jsonEncode({
      'at': _now().toUtc().toIso8601String(),
      'summary': _summaryToJson(d.summary),
      'version': d.version,
      'sizeBytes': d.sizeBytes,
      'modifiedBy': d.modifiedBy,
      'description': d.description,
      'folder': d.folder,
      'previewAvailable': d.previewAvailable,
      'versionId': d.versionId,
      'checksum': d.checksum,
    }),
    prune: 'detail_',
  );

  @override
  Future<DocumentDetail?> readDetail(String id) async {
    final json = await _readJson('detail_${_safe(id)}.json');
    if (json == null) return null;
    try {
      return DocumentDetail(
        summary: _summaryFromJson(json['summary'] as Map<String, dynamic>),
        version: json['version'] as int,
        sizeBytes: json['sizeBytes'] as int,
        modifiedBy: json['modifiedBy'] as String,
        description: json['description'] as String? ?? '',
        folder: json['folder'] as String?,
        previewAvailable: json['previewAvailable'] as bool? ?? true,
        versionId: json['versionId'] as String? ?? '',
        checksum: json['checksum'] as String? ?? '',
        cachedAt: DateTime.parse(json['at'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  // ---- Vistas previas ---------------------------------------------------------

  @override
  Future<void> savePreview(String id, DocumentPreview preview) async {
    if (preview.kind == PreviewKind.unsupported ||
        preview.bytes.isEmpty ||
        preview.bytes.length > maxPreviewBytes) {
      return;
    }
    final bin = await _file('preview_${_safe(id)}.bin');
    if (bin == null) return;
    await bin.writeAsBytes(preview.bytes, flush: true);
    await _write(
      'preview_${_safe(id)}.json',
      jsonEncode({
        'kind': preview.kind.name,
        'at': _now().toUtc().toIso8601String(),
      }),
      prune: 'preview_',
    );
  }

  @override
  Future<DocumentPreview?> readPreview(String id) async {
    final meta = await _readJson('preview_${_safe(id)}.json');
    final bin = await _file('preview_${_safe(id)}.bin');
    if (meta == null || bin == null || !await bin.exists()) return null;
    try {
      final kind = PreviewKind.values.byName(meta['kind'] as String);
      final Uint8List bytes = await bin.readAsBytes();
      return DocumentPreview(
        kind: kind,
        bytes: bytes,
        cachedAt: DateTime.parse(meta['at'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  // ---- Catalogos ----------------------------------------------------------------

  @override
  Future<void> saveCatalogs(DocumentCatalogs c) => _write(
    'catalogs.json',
    jsonEncode({
      'types': [for (final e in c.types) _entryToJson(e)],
      'categories': [for (final e in c.categories) _entryToJson(e)],
      'folders': c.folders,
      'users': c.users,
    }),
  );

  @override
  Future<DocumentCatalogs?> readCatalogs() async {
    final json = await _readJson('catalogs.json');
    if (json == null) return null;
    try {
      List<CatalogEntry> entries(Object? raw) => [
        for (final e in raw as List)
          CatalogEntry(
            (e as Map<String, dynamic>)['code'] as String,
            e['label'] as String,
            active: e['active'] as bool? ?? true,
          ),
      ];
      return DocumentCatalogs(
        types: entries(json['types']),
        categories: entries(json['categories']),
        folders: [for (final f in json['folders'] as List) f as String],
        users: [for (final u in json['users'] as List) u as String],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> forgetDetail(String id) async {
    final file = await _file('detail_${_safe(id)}.json');
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  // ---- Codificacion --------------------------------------------------------------

  /// Un id como parte de un nombre de archivo.
  static String _safe(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static Map<String, Object?> _entryToJson(CatalogEntry e) => {
    'code': e.code,
    'label': e.label,
    'active': e.active,
  };

  static Map<String, Object?> _summaryToJson(DocumentSummary d) => {
    'id': d.id,
    'name': d.name,
    'typeCode': d.typeCode,
    'typeLabel': d.typeLabel,
    'categoryCode': d.categoryCode,
    'categoryLabel': d.categoryLabel,
    'ownerUsername': d.ownerUsername,
    'modifiedAt': d.modifiedAt.toUtc().toIso8601String(),
    'signature': d.signature.name,
    'isFavorite': d.isFavorite,
    'format': d.format,
  };

  static DocumentSummary _summaryFromJson(Map<String, dynamic> j) =>
      DocumentSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        typeCode: j['typeCode'] as String,
        typeLabel: j['typeLabel'] as String,
        categoryCode: j['categoryCode'] as String?,
        categoryLabel: j['categoryLabel'] as String?,
        ownerUsername: j['ownerUsername'] as String,
        modifiedAt: DateTime.parse(j['modifiedAt'] as String).toUtc(),
        signature: DocumentSignature.values.byName(j['signature'] as String),
        isFavorite: j['isFavorite'] as bool? ?? false,
        format: j['format'] as String? ?? '',
      );
}
