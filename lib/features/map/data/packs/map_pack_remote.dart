import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/geo_bounds.dart';
import '../../domain/entities/map_pack.dart';
import '../../domain/repositories/map_pack_manager.dart';

/// El contenido de un paquete en descarga.
class PackContent {
  const PackContent({required this.body, required this.resumed});

  final Stream<List<int>> body;

  /// El servidor respeto el `Range` y manda desde el byte pedido. Si es false,
  /// manda el archivo completo y hay que empezar de cero.
  final bool resumed;
}

/// Lo que el servidor ofrece de paquetes de mapa (propuesta de contrato:
/// `GET /api/maps/packs` y `GET /api/maps/packs/{id}/content` con Range).
abstract interface class MapPackRemote {
  Future<List<MapPack>> list();

  Future<PackContent> content(MapPack pack, {int from = 0});
}

/// El contrato propuesto, sobre la API de SIGACO. Mientras el backend no lo
/// publique, responde 404 y la app dice que los mapas sin conexion aun no estan
/// disponibles.
class ApiMapPackRemote implements MapPackRemote {
  ApiMapPackRemote(this._api);

  final ApiClient _api;

  static const listPath = '/api/maps/packs';
  static String contentPath(String id) =>
      '/api/maps/packs/${Uri.encodeComponent(id)}/content';

  static MapPackError _map(ApiFailure f, {required bool listing}) {
    if (f.isNetwork) return MapPackError.network;
    return switch (f.status) {
      403 => MapPackError.permissionDenied,
      404 || 501 => listing ? MapPackError.notAvailable : MapPackError.notFound,
      416 => MapPackError.corrupt,
      _ => MapPackError.server,
    };
  }

  @override
  Future<List<MapPack>> list() async {
    final Object? json;
    try {
      json = await _api.getJson(listPath);
    } on ApiFailure catch (f) {
      throw MapPackException(_map(f, listing: true));
    }
    final raw = switch (json) {
      final List<Object?> l => l,
      final Map<String, Object?> m when m['items'] is List =>
        m['items']! as List,
      final Map<String, Object?> m when m['data'] is List => m['data']! as List,
      _ => const <Object?>[],
    };
    return [
      for (final e in raw)
        if (e is Map<String, Object?>)
          if (parsePack(e) case final p? when p.isUsable) p,
    ];
  }

  /// Un paquete del JSON del servidor; `null` si le faltan campos.
  static MapPack? parsePack(Map<String, Object?> j) {
    int? i(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final b = j['bounds'];
    if (b is! Map<String, Object?>) return null;
    final id = j['id']?.toString();
    final version = i(j['version']);
    final size = i(j['sizeBytes']);
    final sha = j['sha256']?.toString();
    final minZoom = i(j['minZoom']);
    final maxZoom = i(j['maxZoom']);
    final south = d(b['south']);
    final west = d(b['west']);
    final north = d(b['north']);
    final east = d(b['east']);
    if (id == null ||
        version == null ||
        size == null ||
        sha == null ||
        minZoom == null ||
        maxZoom == null ||
        south == null ||
        west == null ||
        north == null ||
        east == null) {
      return null;
    }
    return MapPack(
      id: id,
      name: (j['name'] ?? id).toString(),
      version: version,
      sizeBytes: size,
      sha256: sha.toLowerCase(),
      minZoom: minZoom,
      maxZoom: maxZoom,
      bounds: GeoBounds(south: south, west: west, north: north, east: east),
      format: (j['format'] ?? 'mbtiles').toString(),
      generatedAt: DateTime.tryParse('${j['generatedAt']}')?.toUtc(),
      attribution: j['attribution']?.toString(),
    );
  }

  @override
  Future<PackContent> content(MapPack pack, {int from = 0}) async {
    try {
      final r = await _api.getStream(contentPath(pack.id), from: from);
      return PackContent(body: r.body, resumed: r.resumed);
    } on ApiFailure catch (f) {
      throw MapPackException(_map(f, listing: false));
    }
  }
}
