import 'dart:typed_data';

import '../entities/asset_capture.dart';
import '../entities/asset_history.dart';
import '../entities/asset_template.dart';
import '../entities/inventory_asset.dart';
import '../entities/inventory_query.dart';

export '../entities/asset_history.dart';
export '../entities/inventory_query.dart';

/// Por que no se pudo traer el inventario.
enum InventoryError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver el inventario.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica el inventario de esta concesion.
  notAvailable,

  /// El activo ya no existe.
  notFound,
}

class InventoryException implements Exception {
  const InventoryException(this.error);

  final InventoryError error;

  @override
  String toString() => 'InventoryException($error)';
}

/// El inventario de la concesion activa. Lanza [InventoryException].
abstract interface class InventoryRepository {
  /// Una pagina del catalogo que cumple [query]: la busqueda, los filtros y el
  /// orden los pone el servidor (con miles de activos, nada se baja entero).
  /// [after] es el `next` de la pagina anterior; null, la primera.
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  });

  /// Cuantos activos cumplen [query] sin mirar su estado de conservacion, y
  /// cuantos hay de cada estado.
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  });

  /// Los tipos de activo por los que se puede filtrar; vacio si no se pudieron
  /// traer (no impide ver la lista).
  Future<List<AssetTypeOption>> types();

  Future<InventoryAsset> get(String id);

  /// La foto principal del activo ("vista en sitio"), o null si no tiene o no se
  /// pudo bajar: no impide ver la ficha.
  Future<Uint8List?> mainPhoto(InventoryAsset asset);
}

/// Las fotos del activo bajadas al telefono (rutas locales), sin la principal.
/// Las que no bajan se omiten: no impiden ver la ficha. Lo implementan los
/// repositorios que hablan con el servidor.
abstract interface class AssetPhotosSource {
  Future<List<String>> photos(InventoryAsset asset);
}

/// La ficha vigente de un tipo de activo, para pintar los campos cuando el
/// activo no la trae. Null si no se pudo saber.
abstract interface class AssetTemplateSource {
  Future<AssetTemplate?> template(String typeCode);
}

/// Los valores de los catalogos genericos por codigo de catalogo, para nombrar
/// los campos CATALOG de la ficha. Vacio si no se pudieron traer.
abstract interface class AssetCatalogSource {
  Future<Map<String, List<CatalogOption>>> catalogs();
}

/// El activo de un QR (el QR lleva su token). Lanza [InventoryException]
/// (`notFound` si no es de la concesion activa o no existe).
abstract interface class AssetQrSource {
  Future<InventoryAsset> byQr(String token);
}

/// La historia operativa de un activo: los ultimos [limit] registros de un tipo
/// (los tickets, inspecciones y mantenimientos que lo tienen como activo), del
/// mas reciente al mas viejo, y cuantos hay en total. Lanza
/// [InventoryException].
abstract interface class AssetHistorySource {
  Future<AssetHistoryPage> history(
    String assetId,
    AssetHistoryKind kind, {
    int limit = 5,
  });
}

/// Los activos capturados en el telefono que aun no salen al servidor, para
/// mostrarlos en la lista como "Pendiente de validacion".
abstract interface class PendingAssetsSource {
  Future<List<InventoryAsset>> pendingAssets();
}
