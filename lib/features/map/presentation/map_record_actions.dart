import '../domain/entities/map_pin.dart';
import '../domain/entities/map_record_target.dart';

/// Lo que el mapa puede hacer con otros modulos, y que compone la app (el mapa
/// no importa a los demas modulos): abrir la ficha de un elemento y levantar un
/// registro en un lugar. Cada accion es null si el usuario no puede hacerla.
class MapRecordActions {
  const MapRecordActions({this.openRoute, this.onCreate});

  /// La ruta de la ficha de [pin]; null si ese elemento no tiene ficha o el
  /// usuario no puede verla.
  final String? Function(MapPin pin)? openRoute;

  /// Levanta un registro en [target]; termina cuando el usuario vuelve del
  /// formulario, para que el mapa se ponga al dia con lo recien creado.
  final Future<void> Function(MapRecordTarget target)? onCreate;

  static const none = MapRecordActions();
}
