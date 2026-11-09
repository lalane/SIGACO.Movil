import '../domain/entities/geo_point.dart';

/// Con que se dibuja el mapa: MapLibre (el de la app) o `flutter_map` (el de
/// respaldo, `MAP_LEGACY=true`, y el que usan las pruebas de la pantalla).
enum MapEngine { flutterMap, maplibre }

/// Lo unico que la pantalla le pide a la camara del mapa, sea cual sea el motor
/// que lo dibuja: ir a un punto sin alejarse de un zoom minimo. Cada motor lo
/// conecta con [attach] al estar listo.
class MapCameraController {
  Future<void> Function(GeoPoint point, double minZoom)? _moveTo;

  /// Lo pedido antes de que hubiera un mapa conectado.
  (GeoPoint, double)? _pending;

  /// Conecta el motor y, si se pidio ir a algun lado antes, va ahi.
  void attach(Future<void> Function(GeoPoint point, double minZoom) moveTo) {
    _moveTo = moveTo;
    final pending = _pending;
    _pending = null;
    if (pending != null) moveTo(pending.$1, pending.$2).catchError((_) {});
  }

  void detach() => _moveTo = null;

  /// Centra el mapa en [point] con al menos [minZoom]. Si todavia no hay un
  /// mapa conectado (MapLibre se crea despues de la pantalla), se hace al
  /// conectarse: abrir el mapa sobre un activo no debe perder su punto.
  Future<void> moveTo(GeoPoint point, {double minZoom = 16}) async {
    final moveTo = _moveTo;
    if (moveTo == null) {
      _pending = (point, minZoom);
      return;
    }
    try {
      await moveTo(point, minZoom);
    } catch (_) {
      // El mapa se esta reconstruyendo.
    }
  }
}
