import '../../domain/entities/map_pack.dart';
import '../../domain/repositories/map_pack_manager.dart';

/// Sin paquetes de mapa (pruebas y entornos sin servidor): nada que bajar ni
/// nada guardado. Con el backend real se usa [FileMapPackManager].
class UnavailableMapPackManager implements MapPackManager {
  const UnavailableMapPackManager();

  @override
  Future<List<MapPack>> available() =>
      Future.error(const MapPackException(MapPackError.notAvailable));

  @override
  Future<List<InstalledPack>> installed() async => const [];

  @override
  Stream<PackProgress> download(MapPack pack) =>
      Stream.error(const MapPackException(MapPackError.notAvailable));

  @override
  Future<void> discardPartial(String packId) async {}

  @override
  Future<int> partialBytes(String packId) async => 0;

  @override
  Future<void> remove(String packId) async {}

  @override
  Future<TileReader?> openActive() async => null;
}
