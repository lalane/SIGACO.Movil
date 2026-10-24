import '../domain/entities/geo_point.dart';

/// Con que se dibuja el mapa: MapLibre (el de la app) o `flutter_map` (el de
/// respaldo, `MAP_LEGACY=true`, y el que usan las pruebas de la pantalla).
enum MapEngine { flutterMap, maplibre }

/// Lo unico que la pantalla le pide a la camara del mapa, sea cual sea el motor
/// que lo dibuja: ir a un punto sin alejarse de un zoom minimo. Cada motor lo
/// conecta con [attach] al estar listo.
class MapCameraController {
  Future<void> Function(GeoPoint point, double minZoom)? _moveTo;

  void attach(Future<void> Function(GeoPoint point, double minZoom) moveTo) =>
      _moveTo = moveTo;

  void detach() => _moveTo = null;

  /// Centra el mapa en [point] con al menos [minZoom]. Si el mapa todavia no
  /// esta listo no hace nada: la siguiente peticion lo centrara.
  Future<void> moveTo(GeoPoint point, {double minZoom = 16}) async {
    try {
      await _moveTo?.call(point, minZoom);
    } catch (_) {
      // El mapa se esta reconstruyendo.
    }
  }
}
