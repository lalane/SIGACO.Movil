import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../../../core/geo/km_label.dart';
import '../../domain/entities/geo_bounds.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/nearby_pin.dart';
import '../../domain/repositories/map_repository.dart';

/// El mapa contra el backend. El inventario sale de `/api/assets/map` (GeoJSON
/// de los activos con geometria de las carreteras autorizadas) por zona: son
/// demasiados para bajarlos todos de una vez (ver [pinsIn]). Los tickets
/// abiertos y las obras en curso, de `/api/map/pins`; el mantenimiento, de las
/// ordenes de mantenimiento preventivo que siguen abiertas y tienen geometria
/// (`/api/preventive-maintenance`). Los activos cercanos, de
/// `/api/assets/nearby`.
class ApiMapRepository
    implements MapRepository, NearbyAssetsSource, AreaPinsSource {
  ApiMapRepository(this._api, {required this._language});

  final ApiClient _api;
  final String Function() _language;

  /// El rectangulo que pide el servidor es obligatorio: todo el planeta, y el
  /// servidor ya recorta a lo que la persona puede ver. Tope del servidor.
  static const _everywhere = '-180,-90,180,90';
  static const _limit = 10000;

  /// Activos por consulta de zona. El servidor acepta hasta 10 000, pero las
  /// lineas y los poligonos llegan completos y la respuesta pesa; con el zoom
  /// minimo del mapa una zona trae bastante menos. Si hay mas, el servidor lo
  /// avisa (`truncated`) y el mapa pide acercarse.
  static const areaLimit = 3000;

  /// Pines por capa que acepta `/api/map/pins` (1 a 2000).
  static const _pinsLimit = 2000;

  Map<String, String>? _typeLabels;

  @override
  bool loadsByArea(MapLayer layer) => layer == MapLayer.inventory;

  /// Los activos con geometria que tocan [area]. Los filtros del mapa se
  /// aplican en el telefono sobre lo que baja, como con las demas pestanas.
  @override
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  }) async {
    if (layer != MapLayer.inventory) {
      throw const MapException(MapError.notAvailable);
    }
    if (cancel?.isCancelled ?? false) throw const MapQueryCancelled();
    final token = CancelToken();
    cancel?.onCancel(token.cancel);
    try {
      final labels = await _labels();
      if (cancel?.isCancelled ?? false) throw const MapQueryCancelled();
      final json = await _api.getJson(
        '/api/assets/map',
        query: {'bbox': bboxOf(area), 'limit': areaLimit},
        cancelToken: token,
      );
      // Llego justo cuando ya no hacia falta.
      if (cancel?.isCancelled ?? false) throw const MapQueryCancelled();
      return AreaPins(
        _inventoryPins(json, labels),
        truncated: json is Map && json['truncated'] == true,
      );
    } on MapQueryCancelled {
      rethrow;
    } catch (e) {
      // Cortada a medias: no es un fallo de red.
      if (cancel?.isCancelled ?? false) throw const MapQueryCancelled();
      throw _mapFailure(e);
    }
  }

  /// El rectangulo como lo pide el servidor: `minLon,minLat,maxLon,maxLat`, en
  /// grados con punto decimal y seis decimales (unos 10 cm), dentro del planeta
  /// y con los minimos menores que los maximos.
  static String bboxOf(GeoBounds area) {
    double clamp(double v, double max) => v.clamp(-max, max).toDouble();
    var west = clamp(area.west, 180);
    var east = clamp(area.east, 180);
    var south = clamp(area.south, 90);
    var north = clamp(area.north, 90);
    // Un rectangulo sin ancho o sin alto (un punto) el servidor no lo acepta.
    const epsilon = 0.00001;
    if (east - west < epsilon) {
      west = clamp(west - epsilon, 180);
      east = clamp(east + epsilon, 180);
    }
    if (north - south < epsilon) {
      south = clamp(south - epsilon, 90);
      north = clamp(north + epsilon, 90);
    }
    String f(double v) => v.toStringAsFixed(6);
    return '${f(west)},${f(south)},${f(east)},${f(north)}';
  }

  /// La pestana completa. El inventario se pide por zona ([pinsIn]); entero
  /// solo si quien llama no sabe pedir por zona (tope del servidor).
  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    try {
      if (layer == MapLayer.maintenance) return await _maintenancePins();
      if (layer != MapLayer.inventory) return await _serverPins(layer);
      final labels = await _labels();
      final json = await _api.getJson(
        '/api/assets/map',
        query: {'bbox': _everywhere, 'limit': _limit},
      );
      return _inventoryPins(json, labels);
    } catch (e) {
      throw _mapFailure(e);
    }
  }

  /// Los pines de inventario de una respuesta de `/api/assets/map`.
  static List<MapPin> _inventoryPins(
    Object? json,
    Map<String, String> labels,
  ) {
    final features = json is Map ? json['features'] : null;
    if (features is! List) throw const FormatException('sin features');
    return [
      for (final f in features)
        ?_pin(f is Map<String, dynamic> ? f : const {}, labels),
    ];
  }

  /// Un fallo de la consulta como lo entiende el mapa.
  static MapException _mapFailure(Object e) => switch (e) {
    MapException() => e,
    ApiFailure(isNetwork: true) => const MapException(MapError.network),
    ApiFailure(:final status) => MapException(switch (status) {
      403 => MapError.permissionDenied,
      404 => MapError.notAvailable,
      _ => MapError.server,
    }),
    _ => const MapException(MapError.server),
  };

  static const _maintenancePageSize = 100;
  static const _maintenanceMaxPages = 10;

  /// Las ordenes de mantenimiento programadas o en ejecucion que se pueden
  /// ubicar: el pin cae en el centro de su geometria y pide atencion si ya
  /// vencio.
  Future<List<MapPin>> _maintenancePins() async {
    final pins = <MapPin>[];
    var page = 1;
    var received = 0;
    var total = 0;
    do {
      final json = await _api.getJson(
        '/api/preventive-maintenance',
        query: {'page': page, 'pageSize': _maintenancePageSize},
      );
      if (json is! Map) throw const FormatException('respuesta inesperada');
      total = (json['total'] as num?)?.toInt() ?? 0;
      final items = json['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      received += items.length;
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final pin = maintenancePin(item);
          if (pin != null) pins.add(pin);
        }
      }
      page++;
    } while (received < total && page <= _maintenanceMaxPages);
    return pins;
  }

  /// Un pin de una orden de mantenimiento preventivo; null si ya termino, se
  /// cancelo o no tiene geometria.
  static MapPin? maintenancePin(Map<String, dynamic> m) {
    final status = (m['status'] as String?)?.toUpperCase();
    if (status == 'COMPLETADO' || status == 'CANCELADO') return null;
    final id = m['id'];
    final anchor = geoJsonAnchor(m['geometry']);
    if (id is! String || anchor == null) return null;
    final point = GeoPoint(anchor.$1, anchor.$2);
    if (!point.isValid) return null;
    final folio = (m['folio'] as String?)?.trim();
    final activity = (m['activity'] as String?)?.trim();
    final km = m['kmStart'];
    return MapPin(
      id: id,
      layer: MapLayer.maintenance,
      title: activity == null || activity.isEmpty ? (folio ?? id) : activity,
      subtitle: folio == null || folio.isEmpty ? null : folio,
      category: (m['subsystemCode'] as String?)?.trim(),
      kmLabel: km is num ? kmLabel(km.toDouble(), null) : null,
      status: m['isOverdue'] == true ? PinStatus.attention : PinStatus.normal,
      position: point,
    );
  }

  /// Tickets abiertos y obras en curso (`/api/map/pins`): el servidor da el
  /// centroide de cada uno y deja fuera lo que no tiene geometria. Si la persona
  /// no puede ver la capa, el servidor no la devuelve: eso es falta de permiso,
  /// no un mapa vacio.
  Future<List<MapPin>> _serverPins(MapLayer layer) async {
    final code = layer == MapLayer.tickets ? 'TICKETS' : 'OBRAS';
    final json = await _api.getJson(
      '/api/map/pins',
      query: {'layers': code, 'bbox': _everywhere, 'limit': _pinsLimit},
    );
    if (json is! Map) throw const FormatException('respuesta inesperada');
    final layers = json['layers'];
    final pins = json['pins'];
    if (layers is! List || pins is! List) {
      throw const FormatException('sin pines');
    }
    final served = layers.any((l) => l is Map && l['layer'] == code);
    if (!served) throw const MapException(MapError.permissionDenied);
    return [
      for (final p in pins)
        if (p is Map<String, dynamic> && p['layer'] == code)
          ?serverPin(p, layer),
    ];
  }

  /// Un pin de `/api/map/pins`. El titulo del ticket es la primera linea de su
  /// descripcion; la prioridad pide mas o menos atencion.
  static MapPin? serverPin(Map<String, dynamic> p, MapLayer layer) {
    final id = p['id'];
    final lat = p['latitude'];
    final lon = p['longitude'];
    if (id is! String || lat is! num || lon is! num) return null;
    final point = GeoPoint(lat.toDouble(), lon.toDouble());
    if (!point.isValid) return null;
    final code = (p['code'] as String?)?.trim() ?? id;
    final title = (p['title'] as String?)?.trim().split('\n').first.trim();
    final km = p['kmStart'];
    return MapPin(
      id: id,
      layer: layer,
      title: title == null || title.isEmpty ? code : title,
      subtitle: code,
      kmLabel: km is num ? kmLabel(km.toDouble(), null) : null,
      status: switch ((p['priority'] as String?)?.toUpperCase()) {
        'CRITICA' => PinStatus.critical,
        'ALTA' => PinStatus.attention,
        _ => PinStatus.normal,
      },
      position: point,
    );
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

  static MapPin? _pin(
    Map<String, dynamic> feature,
    Map<String, String> labels,
  ) {
    final id = feature['id'];
    final props = feature['properties'];
    final anchor = geoJsonAnchor(feature['geometry']);
    if (id is! String || props is! Map || anchor == null) return null;
    final point = GeoPoint(anchor.$1, anchor.$2);
    if (!point.isValid) return null;
    final code = (props['code'] as String?)?.trim() ?? id;
    final type = (props['assetTypeCode'] as String?)?.trim();
    final typeLabel = (props['assetTypeLabel'] as String?)?.trim();
    final subsystem = (props['subsystemCode'] as String?)?.trim();
    final km = props['kmStart'];
    return MapPin(
      id: id,
      layer: MapLayer.inventory,
      title: code,
      category: type == null
          ? typeLabel
          : (labels[type] ??
                (typeLabel == null || typeLabel.isEmpty ? type : typeLabel)),
      group: subsystem == null || subsystem.isEmpty ? null : subsystem,
      kmLabel: km is num ? _kmLabel(km.toDouble()) : null,
      status: _attention(props['conservationState'] as String?),
      operatingState: _operating(
        props['status'] as String?,
        inMaintenance: props['inMaintenance'] == true,
      ),
      position: point,
    );
  }

  /// Cuantos cercanos pide al servidor.
  static const _nearbyLimit = 100;

  @override
  Future<List<NearbyPin>> nearbyAssets(
    GeoPoint from,
    double radiusMeters,
  ) async {
    try {
      final labels = await _labels();
      final json = await _api.getJson(
        '/api/assets/nearby',
        query: {
          'lon': from.longitude,
          'lat': from.latitude,
          'radius': radiusMeters.round(),
          'limit': _nearbyLimit,
        },
      );
      final items = json is List ? json : (json is Map ? json['items'] : null);
      if (items is! List) throw const FormatException('sin cercanos');
      final result = [
        for (final n in items)
          if (n is Map<String, dynamic>) ?nearbyPin(n, labels),
      ]..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return result;
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

  /// Un cercano del servidor (`NearbyAssetDto`: el renglon del activo, la
  /// distancia y su geometria). Null si no se puede ubicar.
  static NearbyPin? nearbyPin(
    Map<String, dynamic> n,
    Map<String, String> labels,
  ) {
    final asset = n['asset'];
    final distance = n['distanceMeters'];
    if (asset is! Map<String, dynamic> || distance is! num) return null;
    final pin = _pin({
      'id': asset['id'],
      'properties': asset,
      'geometry': n['geometry'] ?? asset['geometry'],
    }, labels);
    return pin == null ? null : NearbyPin(pin, distance.toDouble());
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

  /// "En mantenimiento" ya no es un estado del activo: sale de tener un ticket
  /// abierto (`inMaintenance`). Fuera de servicio pesa mas.
  static OperatingState? _operating(
    String? status, {
    bool inMaintenance = false,
  }) => switch (status?.trim().toUpperCase()) {
    'FUERA_SERVICIO' => OperatingState.outOfService,
    _ when inMaintenance => OperatingState.inMaintenance,
    'ACTIVO' => OperatingState.inOperation,
    'EN_MANTENIMIENTO' => OperatingState.inMaintenance,
    _ => null,
  };
}
