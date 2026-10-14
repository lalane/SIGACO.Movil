import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/entities/document_query.dart';
import '../../domain/repositories/documents_repository.dart';

/// Gestor documental contra el backend (`/api/documents`). El servidor aplica
/// vistas, busqueda, filtros y permisos; la app solo traduce lo que ya existe
/// en su modelo (codigos y rutas legibles) a los identificadores del servidor.
class DocumentsRepositoryImpl implements DocumentsRepository, ScopeCleaner {
  DocumentsRepositoryImpl(this._api, {required this._language});

  final ApiClient _api;
  final String Function() _language;

  /// Tamano de pagina maximo que acepta el servidor (25, 50 o 100) y tope de
  /// paginas que se piden: la lista movil no tiene paginacion propia.
  static const _pageSize = 100;
  static const _maxPages = 5;

  _Lookups? _lookups;

  /// Catalogos, carpetas y usuarios son de la concesion activa: al cambiarla o
  /// cerrar sesion no deben sobrevivir en memoria (RN-CTX-02).
  @override
  Future<void> clear() async => _lookups = null;

  @override
  Future<DocumentListing> list(DocumentQuery query) => _guard(() async {
    final lookups = await _loadLookups();
    final filters = query.filters;
    // «Todos» sin criterios navega por carpetas en el servidor; en el telefono
    // se muestra plano, asi que se pide desde la raiz (recursivo).
    final inFolder = filters.folder != null
        ? lookups.folderIds[filters.folder]
        : (query.view == DocumentView.all && !query.hasCriteria
              ? lookups.rootId
              : null);
    final params = <String, Object?>{
      'view': _viewName(query.view),
      'q': query.search.trim(),
      'typeId': filters.typeCode == null
          ? null
          : lookups.typeIds[filters.typeCode],
      'categoryId': filters.categoryCode == null
          ? null
          : lookups.categoryIds[filters.categoryCode],
      'inFolderId': inFolder,
      'modifiedBy': filters.modifiedBy == null
          ? null
          : lookups.userIds[filters.modifiedBy],
      'from': filters.from == null ? null : _day(filters.from!),
      'to': filters.to == null ? null : _day(filters.to!),
      'pageSize': _pageSize,
      'lang': _language(),
    };
    final result = <DocumentSummary>[];
    var page = 1;
    var totalPages = 1;
    do {
      final json = await _api.getJson(
        '/api/documents',
        query: {...params, 'page': page},
      );
      final map = _asMap(json);
      totalPages = (map['totalPages'] as num?)?.toInt() ?? 1;
      for (final item in _asList(map['documents'])) {
        result.add(_summary(_asMap(item)));
      }
      page++;
    } while (page <= totalPages && page <= _maxPages);
    return DocumentListing(result);
  });

  @override
  Future<DocumentDetail> detail(String id) => _guard(() async {
    final json = await _api.getJson(
      '/api/documents/$id',
      query: {'lang': _language()},
    );
    final map = _asMap(json);
    final type = _asMap(map['type']);
    final category = map['category'] is Map ? _asMap(map['category']) : null;
    final version = _asMap(map['currentVersion']);
    final folderPath = (_asMap(map['folder'])['path'] as String? ?? '').trim();
    final summary = DocumentSummary(
      id: map['id'] as String,
      name: map['name'] as String,
      typeCode: type['code'] as String,
      typeLabel: type['label'] as String,
      categoryCode: category?['code'] as String?,
      categoryLabel: category?['label'] as String?,
      ownerUsername: _username(_asMap(map['owner'])),
      modifiedAt: DateTime.parse(map['lastModifiedAt'] as String).toUtc(),
      signature: _signature(version['signatureStatus'] as String?),
      isFavorite: map['isFavorite'] as bool? ?? false,
      format: _format(map['extension'] as String?),
    );
    return DocumentDetail(
      summary: summary,
      version: (version['number'] as num?)?.toInt() ?? 1,
      sizeBytes: (version['sizeBytes'] as num?)?.toInt() ?? 0,
      modifiedBy: _username(_asMap(map['modifiedBy'])),
      description: map['description'] as String? ?? '',
      folder: _isRoot(folderPath) ? null : folderPath,
      previewAvailable: version['previewStatus'] != 'SIN_VISOR',
      versionId: version['id'] as String? ?? '',
      checksum: version['checksum'] as String? ?? '',
    );
  });

  @override
  Future<DocumentPreview> preview(String id) async {
    try {
      final file = await _api.getBytes('/api/documents/$id/preview');
      final kind = switch (file.contentType) {
        'image/png' || 'image/jpeg' => PreviewKind.image,
        'application/pdf' => PreviewKind.pdf,
        _ => PreviewKind.unsupported,
      };
      return DocumentPreview(kind: kind, bytes: file.bytes);
    } on ApiFailure catch (e) {
      // Sin representacion (en preparacion, no disponible o sin visor): no es
      // un fallo, la pantalla lo explica como «sin vista previa».
      if (e.status == 409 && (e.code ?? '').startsWith('PREVIEW_')) {
        return DocumentPreview(
          kind: PreviewKind.unsupported,
          bytes: Uint8List(0),
        );
      }
      throw _translate(e);
    }
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) =>
      _guard(() async {
        if (favorite) {
          await _api.put('/api/documents/$id/favorite');
        } else {
          await _api.delete('/api/documents/$id/favorite');
        }
      });

  @override
  Future<DocumentSignature> sign(String id, String versionId) =>
      _guard(() async {
        final json = await _api.post(
          '/api/documents/$id/versions/$versionId/signature',
        );
        return _signature(json?['signatureStatus'] as String?);
      });

  @override
  Future<DocumentCatalogs> catalogs() => _guard(() async {
    final lookups = await _loadLookups(force: true);
    return lookups.catalogs;
  });

  /// Identificadores que el servidor pide para abrir una carga, a partir de lo
  /// que capturo la persona (codigos y ruta). Un valor desconocido (por ejemplo
  /// un tipo que ya no existe) se devuelve nulo.
  Future<({String? typeId, String? categoryId, String? folderId})>
  resolveUploadTarget({
    String? typeCode,
    String? categoryCode,
    String? folder,
  }) async {
    var lookups = await _loadLookups();
    bool complete(_Lookups l) =>
        (typeCode == null || l.typeIds.containsKey(typeCode)) &&
        (categoryCode == null || l.categoryIds.containsKey(categoryCode)) &&
        (folder == null || l.folderIds.containsKey(folder));
    // Lo guardado pudo cambiar en el servidor (una carpeta nueva, por ejemplo).
    if (!complete(lookups)) lookups = await _loadLookups(force: true);
    return (
      typeId: typeCode == null ? null : lookups.typeIds[typeCode],
      categoryId: categoryCode == null
          ? null
          : lookups.categoryIds[categoryCode],
      folderId: folder == null ? null : lookups.folderIds[folder],
    );
  }

  Future<_Lookups> _loadLookups({bool force = false}) async {
    final cached = _lookups;
    if (cached != null && !force) return cached;
    final lang = _language();
    final catalogs = _asMap(await _api.getJson('/api/documents/catalogs'));
    final folders = _asList(await _api.getJson('/api/documents/folders'));
    final modifiers = _asList(await _api.getJson('/api/documents/modifiers'));

    CatalogEntry entry(Map<String, dynamic> t) {
      final pt = t['labelPt'] as String?;
      final label = lang == 'pt' && pt != null && pt.isNotEmpty
          ? pt
          : t['labelEs'] as String;
      return CatalogEntry(
        t['code'] as String,
        label,
        active: t['active'] as bool? ?? true,
      );
    }

    final types = [for (final t in _asList(catalogs['types'])) _asMap(t)];
    final categories = [
      for (final t in _asList(catalogs['categories'])) _asMap(t),
    ];
    final folderMaps = [for (final f in folders) _asMap(f)];
    final root = folderMaps.where((f) => f['kind'] == 'RAIZ');
    // El acceso a SharePoint es un enlace fijo: no guarda documentos.
    final named = folderMaps.where((f) => f['kind'] == 'CARPETA');
    final users = [for (final u in modifiers) _asMap(u)];

    final lookups = _Lookups(
      catalogs: DocumentCatalogs(
        types: [for (final t in types) entry(t)],
        categories: [for (final t in categories) entry(t)],
        folders: [for (final f in named) f['path'] as String],
        users: [for (final u in users) _username(u)],
      ),
      typeIds: {for (final t in types) t['code'] as String: t['id'] as String},
      categoryIds: {
        for (final t in categories) t['code'] as String: t['id'] as String,
      },
      folderIds: {
        for (final f in named) f['path'] as String: f['id'] as String,
      },
      userIds: {for (final u in users) _username(u): u['id'] as String},
      rootId: root.isEmpty ? null : root.first['id'] as String,
    );
    return _lookups = lookups;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw _translate(e);
    } on DocumentsException {
      rethrow;
    } catch (_) {
      throw const DocumentsException(DocumentsError.server);
    }
  }

  static DocumentsException _translate(ApiFailure e) => DocumentsException(
    e.isNetwork
        ? DocumentsError.network
        : switch (e.status) {
            409 when e.code == 'VERSION_ALREADY_SIGNED' =>
              DocumentsError.alreadySigned,
            409 when e.code == 'HASH_MISMATCH' =>
              DocumentsError.contentMismatch,
            409 when e.code == 'SIGNER_PROFILE_REQUIRED' =>
              DocumentsError.signerProfileRequired,
            403 when e.code == 'ROAD_ACCESS_REQUIRED' =>
              DocumentsError.noRoadAccess,
            403 => DocumentsError.permissionDenied,
            404 => DocumentsError.notFound,
            _ => DocumentsError.server,
          },
  );

  static String _viewName(DocumentView v) => switch (v) {
    DocumentView.all => 'all',
    DocumentView.recent => 'recent',
    DocumentView.favorites => 'favorites',
    DocumentView.mine => 'mine',
  };

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DocumentSummary _summary(Map<String, dynamic> m) {
    final type = _asMap(m['type']);
    final category = m['category'] is Map ? _asMap(m['category']) : null;
    return DocumentSummary(
      id: m['id'] as String,
      name: m['name'] as String,
      typeCode: type['code'] as String,
      typeLabel: type['label'] as String,
      categoryCode: category?['code'] as String?,
      categoryLabel: category?['label'] as String?,
      // El listado trae quien modifico por ultima vez; el propietario solo
      // llega en la ficha.
      ownerUsername: _username(_asMap(m['modifiedBy'])),
      modifiedAt: DateTime.parse(m['lastModifiedAt'] as String).toUtc(),
      signature: _signature(m['signatureStatus'] as String?),
      isFavorite: m['isFavorite'] as bool? ?? false,
      format: _format(m['extension'] as String?),
    );
  }

  static DocumentSignature _signature(String? status) => switch (status) {
    'VALIDADO' => DocumentSignature.validated,
    'PENDIENTE_VALIDACION' => DocumentSignature.pending,
    _ => DocumentSignature.unsigned,
  };

  static String _format(String? extension) =>
      (extension ?? '').toLowerCase().replaceFirst('.', '');

  /// Parte del correo antes de «@» (D-03-52).
  static String _username(Map<String, dynamic> user) =>
      ((user['username'] as String?) ?? '').split('@').first;

  static bool _isRoot(String path) {
    final t = path.replaceAll('/', '').trim();
    return t.isEmpty;
  }

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('Respuesta inesperada');
  }

  static List<Object?> _asList(Object? v) {
    if (v is List) return v.cast<Object?>();
    throw const FormatException('Respuesta inesperada');
  }
}

class _Lookups {
  const _Lookups({
    required this.catalogs,
    required this.typeIds,
    required this.categoryIds,
    required this.folderIds,
    required this.userIds,
    required this.rootId,
  });

  final DocumentCatalogs catalogs;
  final Map<String, String> typeIds;
  final Map<String, String> categoryIds;
  final Map<String, String> folderIds;
  final Map<String, String> userIds;
  final String? rootId;
}
