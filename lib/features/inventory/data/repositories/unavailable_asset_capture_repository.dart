import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/repositories/asset_capture_repository.dart';

/// Mientras el servidor no publique el alta (o con datos de ejemplo), el
/// formulario dice que no esta disponible en lugar de inventar tipos.
class UnavailableAssetCaptureRepository implements AssetCaptureRepository {
  const UnavailableAssetCaptureRepository();

  static const _error = AssetCaptureException(AssetCaptureError.notAvailable);

  @override
  Future<List<AssetTypeOption>> types() => Future.error(_error);

  @override
  Future<AssetTemplate> template(String typeCode) => Future.error(_error);

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async => const {};

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) async =>
      const RoadPlacement.unknown();

  @override
  Future<CapturedAsset> create(NewAsset draft) => Future.error(_error);
}
