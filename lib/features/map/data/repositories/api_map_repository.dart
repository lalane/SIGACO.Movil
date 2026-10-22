import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/repositories/map_repository.dart';

/// El mapa contra el backend. Hoy solo el inventario publica algo para dibujar
/// (`/api/assets/map`, GeoJSON de los activos con geometria de las carreteras
/// autorizadas); tickets, mantenimiento y obras siguen sin publicarse y dicen
/// que no estan disponibles en lugar de inventar pines.
class ApiMapRepository implements MapRepository {
  ApiMapRepository(this._api, {required this._language});

  final ApiClient _api;
  final String Function() _language;

  /// El rectangulo que pide el servidor es obligatorio: todo el planeta, y el
  /// servidor ya recorta a lo que la persona puede ver. Tope del servidor.
  static const _everywhere = '-180,-90,180,90';
  static const _limit = 10000;

  Map<String, String>? _typeLabels;

  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    if (layer != MapLayer.inventory) {
      throw const MapException(MapError.notAvailable);
    }
    try {
      final labels = await _labels();
      final json = await _api.getJson(
        '/api/assets/map',
        query: {'bbox': _everywhere, 'limit': _limit},
      );
      final features = json is Map ? json['features'] : null;
      if (features is! List) throw const FormatException('sin features');
      return [
        for (final f in features)
          ?_pin(f is Map<String, dynamic> ? f : const {}, labels),
      ];
    } on ApiFailure catch (e) {
      throw MapException(
        e.isNetwork
            ? MapError.network
            : switch (e.status) {
                403 => MapError.permissionDenied,
                404 => MapError.notAvailable,
                _ => MapError.server,
              },
      );
    } on MapException {
      rethrow;
    } catch (_) {
      throw const MapException(MapError.server);
    }
  }

  /// Tipo de activo -> su nombre en el idioma elegido. Si el catalogo no baja,
  /// los pines se muestran con el codigo del tipo.
  Future<Map<String, String>> _labels() async {
    final cached = _typeLabels;
    if (cached != null) return cached;
    try {
      final json = await _api.getJson('/api/catalogs');
      final types = json is Map ? json['assetTypes'] : null;
      final key = _language() == 'pt' ? 'labelPt' : 'labelEs';
      final labels = <String, String>{
        if (types is List)
          for (final t in types)
            if (t is Map && t['code'] is String)
              t['code'] as String: (t[key] ?? t['labelEs'] ?? t['code'])
                  .toString(),
      };
      return _typeLabels = labels;
    } on ApiFailure {
      return const {};
    }
  }

  static MapPin? _pin(Map<String, dynamic> feature, Map<String, String> labels) {
    final id = feature['id'];
    final props = feature['properties'];
    final anchor = geoJsonAnchor(feature['geometry']);
    if (id is! String || props is! Map || anchor == null) return null;
    final point = GeoPoint(anchor.$1, anchor.$2);
    if (!point.isValid) return null;
    final code = (props['code'] as String?)?.trim() ?? id;
    final type = (props['assetTypeCode'] as String?)?.trim();
    final km = props['kmStart'];
    return MapPin(
      id: id,
      layer: MapLayer.inventory,
      title: code,
      category: type == null ? null : (labels[type] ?? type),
      kmLabel: km is num ? _kmLabel(km.toDouble()) : null,
      status: _attention(props['conservationState'] as String?),
      operatingState: _operating(props['status'] as String?),
      position: point,
    );
  }

  static String _kmLabel(double km) {
    final meters = (km * 1000).round();
    return 'KM ${meters ~/ 1000}+${(meters % 1000).toString().padLeft(3, '0')}';
  }

  /// Cuanta atencion pide segun su conservacion; sin evaluar no pide ninguna.
  static PinStatus _attention(String? conservation) =>
      switch (conservation?.trim().toUpperCase()) {
        'REGULAR' => PinStatus.attention,
        'MALO' || 'PESIMO' => PinStatus.critical,
        _ => PinStatus.normal,
      };

  static OperatingState? _operating(String? status) =>
      switch (status?.trim().toUpperCase()) {
        'ACTIVO' => OperatingState.inOperation,
        'EN_MANTENIMIENTO' => OperatingState.inMaintenance,
        'FUERA_SERVICIO' => OperatingState.outOfService,
        _ => null,
      };
}
