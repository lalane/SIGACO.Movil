import '../entities/document.dart';
import '../entities/document_catalogs.dart';
import '../entities/document_preview.dart';
import '../entities/document_query.dart';

enum DocumentsError {
  /// Sin conexion con el servidor.
  network,

  /// El servidor nego Ver (o la sesion ya no lo permite).
  permissionDenied,

  /// El usuario tiene permiso, pero no carreteras asignadas en la concesion
  /// activa: el servidor no le muestra documentos (ROAD_ACCESS_REQUIRED).
  noRoadAccess,

  /// El documento ya no existe o no es de esta concesion.
  notFound,

  /// El contenido no esta en el telefono y se necesita conexion.
  notAvailableOffline,

  /// Cualquier otro fallo del servidor.
  server,
}

class DocumentsException implements Exception {
  const DocumentsException(this.error);

  final DocumentsError error;

  @override
  String toString() => 'DocumentsException($error)';
}

abstract interface class DocumentsRepository {
  /// Documentos activos de la concesion activa que cumplen [query]. El servidor
  /// aplica las vistas, la busqueda y los filtros (y limita Recientes a los
  /// ultimos 30 dias y 50 documentos); la app no recalcula nada.
  Future<List<DocumentSummary>> list(DocumentQuery query);

  Future<DocumentDetail> detail(String id);

  /// La representacion para ver el documento (nunca el original). Sin conexion y
  /// sin copia en el telefono lanza [DocumentsError.notAvailableOffline].
  Future<DocumentPreview> preview(String id);

  /// Marca o desmarca el favorito personal del usuario.
  Future<void> setFavorite(String id, {required bool favorite});

  Future<DocumentCatalogs> catalogs();
}
