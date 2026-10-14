import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/entities/document_query.dart';
import '../../domain/repositories/documents_repository.dart';

/// Mientras el backend no publique los endpoints del gestor documental, todo
/// responde como un fallo del servidor y la pantalla ofrece reintentar. Se
/// reemplaza por la implementacion real sin tocar el resto de la app.
class UnavailableDocumentsRepository implements DocumentsRepository {
  const UnavailableDocumentsRepository();

  static const _error = DocumentsException(DocumentsError.server);

  @override
  Future<DocumentListing> list(DocumentQuery query) async => throw _error;

  @override
  Future<DocumentDetail> detail(String id) async => throw _error;

  @override
  Future<DocumentPreview> preview(String id) async => throw _error;

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async =>
      throw _error;

  @override
  Future<DocumentCatalogs> catalogs() async => throw _error;

  @override
  Future<DocumentSignature> sign(String id, String versionId) async =>
      throw _error;
}
