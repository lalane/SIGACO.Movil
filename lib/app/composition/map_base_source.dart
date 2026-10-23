import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../features/map/presentation/tiles/configured_tile_source.dart';
import '../../features/map/presentation/tiles/map_tile_source.dart';

/// De donde sale el mapa base de la concesion activa.
abstract interface class MapBaseSource {
  /// El mapa base que indica el servidor; null si no indica ninguno o no se pudo
  /// saber (se queda el de la compilacion).
  Future<MapTileSource?> load(String concessionId);
}

class NoMapBaseSource implements MapBaseSource {
  const NoMapBaseSource();

  @override
  Future<MapTileSource?> load(String concessionId) async => null;
}

/// El campo `mapBase` de `GET /api/app-configuration`:
/// `{ urlTemplate, attribution, attributionUrl, maxZoom }`. La plantilla es una
/// direccion `https` con `{z}`, `{x}` y `{y}`; cualquier otra cosa se ignora y
/// la app se queda con el mapa de la compilacion.
class ApiMapBaseSource implements MapBaseSource {
  const ApiMapBaseSource(this._api);

  final ApiClient _api;

  @override
  Future<MapTileSource?> load(String concessionId) async {
    try {
      final json = await _api.get('/api/app-configuration');
      // La configuracion es de la concesion activa: si es otra, no vale.
      final id = json?['concessionId'];
      if (id is String && id.isNotEmpty && id != concessionId) return null;
      return parse(json?['mapBase']);
    } on ApiFailure {
      return null;
    }
  }

  /// El mapa base de un `mapBase` del servidor, o null si no es valido.
  static MapTileSource? parse(Object? raw) {
    if (raw is! Map) return null;
    final url = _text(raw['urlTemplate']);
    if (url == null || !_validTemplate(url)) return null;
    final link = _text(raw['attributionUrl']);
    final zoom = raw['maxZoom'];
    return UrlTemplateTileSource(
      urlTemplate: url,
      attributionText: _text(raw['attribution']),
      attributionLink: link != null && link.startsWith('https://') ? link : null,
      zoomMax: zoom is num ? zoom.toDouble().clamp(1.0, 22.0).toDouble() : 19,
    );
  }

  /// Solo `https` (nunca texto plano) y con las tres partes de una tesela.
  static bool _validTemplate(String url) =>
      url.startsWith('https://') &&
      url.contains('{z}') &&
      url.contains('{x}') &&
      url.contains('{y}');

  static String? _text(Object? v) {
    final s = v is String ? v.trim() : null;
    return s == null || s.isEmpty ? null : s;
  }
}

/// Pide el mapa base de la concesion al iniciar sesion y lo aplica; al cerrar la
/// sesion vuelve al de la compilacion. Un fallo no cambia nada.
class MapBaseLoader {
  MapBaseLoader({required this.tiles, this.source = const NoMapBaseSource()});

  /// Sin servidor (pruebas): no hace nada.
  MapBaseLoader.none()
    : tiles = ConfiguredTileSource(fallback: const NoTileSource()),
      source = const NoMapBaseSource();

  final ConfiguredTileSource tiles;
  final MapBaseSource source;

  Future<void> load(String concessionId) async {
    final remote = await source.load(concessionId);
    if (remote != null) tiles.apply(remote);
  }

  void reset() => tiles.apply(null);
}
