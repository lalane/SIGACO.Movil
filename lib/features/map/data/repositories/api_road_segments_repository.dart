import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';

/// Los tramos contra el backend (`/api/road-network/segments/map`): los de las
/// carreteras autorizadas, con su trazo ya unido y simplificado por el servidor
/// (sale del eje del WebGIS, con el km calibrado). Un tramo cuyo trazo tiene
/// huecos llega en varias lineas: se entrega una por linea con el mismo id, asi
/// que al tocar cualquiera se resalta el tramo entero. Los que no tienen trazo
/// no se dibujan.
class ApiRoadSegmentsRepository implements RoadSegmentsRepository {
  const ApiRoadSegmentsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<RoadSegment>> segments() async {
    try {
      final json = await _api.getJson('/api/road-network/segments/map');
      if (json is! List) throw const FormatException('sin lista');
      return [
        for (final s in json)
          if (s is Map<String, dynamic>) ..._segments(s),
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
    } catch (_) {
      throw const MapException(MapError.server);
    }
  }

  static Iterable<RoadSegment> _segments(Map<String, dynamic> s) sync* {
    final id = s['id'];
    final code = s['code'];
    final direction = switch (s['direction']) {
      'CRECIENTE' => TravelDirection.increasing,
      'DECRECIENTE' => TravelDirection.decreasing,
      _ => null,
    };
    if (id is! String || code is! String || direction == null) return;
    final start = (s['kmStart'] as num?)?.toDouble();
    final end = (s['kmEnd'] as num?)?.toDouble();
    for (final line in _lines(s['geometry'])) {
      yield RoadSegment(
        id: id,
        code: code,
        direction: direction,
        name: s['name'] as String?,
        startKmLabel: kmLabel(start, null),
        endKmLabel: kmLabel(end, null),
        points: line,
      );
    }
  }

  /// Las lineas de un LineString o MultiLineString GeoJSON (`[lon, lat]`).
  static List<List<GeoPoint>> _lines(Object? geometry) {
    if (geometry is! Map) return const [];
    final coordinates = geometry['coordinates'];
    final parts = switch (geometry['type']) {
      'LineString' => [coordinates],
      'MultiLineString' when coordinates is List => coordinates,
      _ => const [],
    };
    return [
      for (final part in parts)
        if (part is List)
          [
            for (final c in part)
              if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
                GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          ],
    ].where((l) => l.length >= 2).toList();
  }
}
