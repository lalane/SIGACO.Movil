import '../../features/inventory/domain/entities/asset_capture.dart';
import '../../features/inventory/domain/repositories/asset_capture_repository.dart';
import '../../features/map/domain/repositories/location_source.dart';

/// La posicion del alta de un activo sale de la misma fuente de ubicacion del
/// mapa. Una ubicacion simulada nunca se acepta, y cualquier falla del GPS deja
/// el alta sin posicion (la persona escribe el km).
class LocationAssetPositionSource implements AssetPositionSource {
  const LocationAssetPositionSource(this._location);

  final LocationSource _location;

  @override
  Future<AssetPosition?> current() async {
    try {
      final here = await _location.current();
      if (!here.isTrusted) return null;
      return AssetPosition(
        latitude: here.position.latitude,
        longitude: here.position.longitude,
        accuracyMeters: here.accuracyMeters,
        readAt: here.capturedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
