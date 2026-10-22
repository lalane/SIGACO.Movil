import 'dart:typed_data';

import '../entities/inventory_asset.dart';

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
  Future<List<InventoryAsset>> list();

  Future<InventoryAsset> get(String id);

  /// La foto principal del activo ("vista en sitio"), o null si no tiene o no se
  /// pudo bajar: no impide ver la ficha.
  Future<Uint8List?> mainPhoto(InventoryAsset asset);
}
