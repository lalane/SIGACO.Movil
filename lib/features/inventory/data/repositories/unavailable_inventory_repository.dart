import 'dart:typed_data';

import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Mientras el backend no publique los endpoints de inventario, la pantalla
/// dice que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_INVENTORY=true` se usa `SampleInventoryRepository`.
class UnavailableInventoryRepository implements InventoryRepository {
  const UnavailableInventoryRepository();

  static const _error = InventoryException(InventoryError.notAvailable);

  @override
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  }) => Future.error(_error);

  @override
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  }) => Future.error(_error);

  @override
  Future<List<AssetTypeOption>> types() async => const [];

  @override
  Future<InventoryAsset> get(String id) => Future.error(_error);

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;
}
