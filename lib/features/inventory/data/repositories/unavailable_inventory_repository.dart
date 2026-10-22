import 'dart:typed_data';

import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Mientras el backend no publique los endpoints de inventario, la pantalla
/// dice que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_INVENTORY=true` se usa `SampleInventoryRepository`.
class UnavailableInventoryRepository implements InventoryRepository {
  const UnavailableInventoryRepository();

  static const _error = InventoryException(InventoryError.notAvailable);

  @override
  Future<List<InventoryAsset>> list() => Future.error(_error);

  @override
  Future<InventoryAsset> get(String id) => Future.error(_error);

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;
}
