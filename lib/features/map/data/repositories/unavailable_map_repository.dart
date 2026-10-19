import '../../domain/entities/map_pin.dart';
import '../../domain/repositories/map_repository.dart';

/// Mientras el backend no publique los endpoints del mapa (activos, tickets,
/// mantenimiento y obras), el mapa dice que no esta disponible en lugar de
/// inventar datos. Con `SAMPLE_MAP=true` se usa [SampleMapRepository].
class UnavailableMapRepository implements MapRepository {
  const UnavailableMapRepository();

  @override
  Future<List<MapPin>> pins(MapLayer layer) =>
      Future.error(const MapException(MapError.notAvailable));
}
