import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

/// El catalogo filtrado, contado y paginado en el telefono, para los activos de
/// ejemplo (y los dobles de prueba): la misma consulta que el servidor aplica
/// en `/api/assets`. Lo que mas atencion pide va primero y despues por nombre.
mixin InMemoryInventory implements InventoryRepository {
  /// Todos los activos.
  Future<List<InventoryAsset>> allAssets();

  /// Cuantos por pagina.
  int get inMemoryPageSize => 50;

  @override
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  }) async {
    final all = [
      for (final a in await allAssets())
        if (query.matches(a)) a,
    ];
    all.sort((a, b) {
      final byCondition = b.condition.index.compareTo(a.condition.index);
      return byCondition != 0 ? byCondition : a.name.compareTo(b.name);
    });
    final from = after is int ? after.clamp(0, all.length) : 0;
    final to = (from + inMemoryPageSize).clamp(0, all.length);
    return InventoryResultPage(
      items: all.sublist(from, to),
      total: all.length,
      next: to < all.length ? to : null,
    );
  }

  @override
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  }) async {
    final base = query.withoutCondition();
    final all = [
      for (final a in await allAssets())
        if (base.matches(a)) a,
    ];
    int count(AssetCondition c) => all.where((a) => a.condition == c).length;
    return InventoryCounts(
      total: all.length,
      good: count(AssetCondition.good),
      regular: count(AssetCondition.regular),
      poor: count(AssetCondition.poor),
    );
  }

  /// Los tipos que hay entre los activos; sin codigo, su nombre hace de codigo.
  @override
  Future<List<AssetTypeOption>> types() async {
    final byCode = <String, String>{};
    for (final a in await allAssets()) {
      byCode.putIfAbsent(a.typeCode ?? a.category, () => a.category);
    }
    return [
      for (final e in byCode.entries)
        AssetTypeOption(code: e.key, labelEs: e.value),
    ]..sort((a, b) => a.labelEs.compareTo(b.labelEs));
  }
}
