import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/entities/document_query.dart';
import '../../domain/repositories/documents_repository.dart';
import '../cache/documents_cache.dart';

/// Gestor documental con lo ya consultado guardado en el telefono (DTF M03
/// §3.2, HU-MOB-03-01 CA-05 y CA-06). Con conexion todo sale del servidor y se
/// guarda; sin ella solo se muestra lo guardado, marcado con su fecha, y lo que
/// no esta guardado dice que requiere conexion. Nunca se entrega lo guardado
/// ante un fallo que no sea de red (sin permiso, error del servidor...).
class CachedDocumentsRepository implements DocumentsRepository {
  const CachedDocumentsRepository(this._inner, this._cache);

  final DocumentsRepository _inner;
  final DocumentsCache _cache;

  static bool _offline(Object e) =>
      e is DocumentsException && e.error == DocumentsError.network;

  /// Guardar es un extra: un fallo del disco no debe romper la consulta.
  Future<void> _quietly(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {}
  }

  @override
  Future<DocumentListing> list(DocumentQuery query) async {
    try {
      final listing = await _inner.list(query);
      await _quietly(() => _cache.saveList(query, listing));
      return listing;
    } on DocumentsException catch (e) {
      if (!_offline(e)) rethrow;
      final saved = await _cache.readList(query);
      if (saved == null) rethrow;
      return saved;
    }
  }

  @override
  Future<DocumentDetail> detail(String id) async {
    try {
      final detail = await _inner.detail(id);
      await _quietly(() => _cache.saveDetail(detail));
      return detail;
    } on DocumentsException catch (e) {
      if (!_offline(e)) rethrow;
      final saved = await _cache.readDetail(id);
      if (saved != null) return saved;
      throw const DocumentsException(DocumentsError.notAvailableOffline);
    }
  }

  @override
  Future<DocumentPreview> preview(String id) async {
    try {
      final preview = await _inner.preview(id);
      await _quietly(() => _cache.savePreview(id, preview));
      return preview;
    } on DocumentsException catch (e) {
      if (!_offline(e)) rethrow;
      final saved = await _cache.readPreview(id);
      if (saved != null) return saved;
      throw const DocumentsException(DocumentsError.notAvailableOffline);
    }
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    await _inner.setFavorite(id, favorite: favorite);
    // La ficha guardada ya no dice lo mismo (la estrella).
    await _quietly(() => _cache.forgetDetail(id));
  }

  @override
  Future<DocumentCatalogs> catalogs() async {
    try {
      final catalogs = await _inner.catalogs();
      await _quietly(() => _cache.saveCatalogs(catalogs));
      return catalogs;
    } on DocumentsException catch (e) {
      if (!_offline(e)) rethrow;
      final saved = await _cache.readCatalogs();
      if (saved == null) rethrow;
      return saved;
    }
  }

  @override
  Future<DocumentSignature> sign(String id, String versionId) async {
    final status = await _inner.sign(id, versionId);
    // La firma cambio lo que se guardo de este documento.
    await _quietly(() => _cache.forgetDetail(id));
    return status;
  }
}
