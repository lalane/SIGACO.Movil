import 'package:dio/dio.dart';

import '../../domain/entities/geo_point.dart';
import 'geo_path.dart';
import 'near_me_sample_map_repository.dart';

/// Encuentra la calle real que pasa por el telefono pidiendole una ruta al
/// servicio publico de demostracion de OSRM (datos de OpenStreetMap): de unos
/// km al oeste, pasando por el telefono, a unos km al este. La ruta sigue las
/// calles, asi que la linea de ejemplo cae sobre una calle que existe en el mapa.
///
/// Es solo para los datos de ejemplo (`SAMPLE_MAP`), en desarrollo: el servicio
/// es de demostracion y no es para uso de produccion. Si falla, quien lo usa cae
/// a la recta inventada.
class OsrmRoadFinder {
  OsrmRoadFinder({Dio? dio, this.reachMeters = 4500})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'User-Agent': 'SigacoMovil-dev-sample/1.0'},
            ),
          );

  final Dio _dio;

  /// Hasta donde se pide la ruta a cada lado del telefono.
  final double reachMeters;

  static const _endpoint = 'https://router.project-osrm.org/route/v1/driving';

  Future<GeoPath?> find(GeoPoint center) async {
    final west = NearMeSampleMapRepository.offset(center, reachMeters, 270);
    final east = NearMeSampleMapRepository.offset(center, reachMeters, 90);
    String pair(GeoPoint p) => '${p.longitude},${p.latitude}';
    final response = await _dio.get<Object>(
      '$_endpoint/${pair(west)};${pair(center)};${pair(east)}',
      queryParameters: {'overview': 'full', 'geometries': 'geojson'},
    );
    return parse(response.data);
  }

  /// La linea de la respuesta de OSRM; null si no trae una ruta.
  static GeoPath? parse(Object? body) {
    if (body is! Map || body['code'] != 'Ok') return null;
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final geometry = (routes.first as Map)['geometry'];
    final coordinates = geometry is Map ? geometry['coordinates'] : null;
    if (coordinates is! List) return null;
    final points = <GeoPoint>[
      for (final c in coordinates)
        if (c is List && c.length >= 2)
          GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];
    return points.length < 2 ? null : GeoPath(points);
  }
}
