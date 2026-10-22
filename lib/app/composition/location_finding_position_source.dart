import '../../features/inspections/domain/entities/inspection.dart';
import '../../features/inspections/domain/repositories/finding_position_source.dart';
import '../../features/map/domain/repositories/location_source.dart';

/// La posicion de un hallazgo de inspeccion sale de la misma fuente de ubicacion
/// del mapa. Una ubicacion simulada nunca se acepta (queda sin posicion), y
/// cualquier falla del GPS tambien: el hallazgo se guarda igual.
class LocationFindingPositionSource implements FindingPositionSource {
  const LocationFindingPositionSource(this._location);

  final LocationSource _location;

  @override
  Future<FindingPosition?> current() async {
    try {
      final here = await _location.current();
      if (!here.isTrusted) return null;
      return FindingPosition(
        latitude: here.position.latitude,
        longitude: here.position.longitude,
        accuracyMeters: here.accuracyMeters,
      );
    } catch (_) {
      return null;
    }
  }
}
