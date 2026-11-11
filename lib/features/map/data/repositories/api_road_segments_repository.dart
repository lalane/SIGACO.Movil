import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/entities/segment_pavement.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';
import '../../domain/repositories/segment_pavement_source.dart';

/// Los tramos contra el backend (`/api/road-network/segments/map`): los de las
/// carreteras autorizadas, con su trazo ya unido y simplificado por el servidor
/// (sale del eje del WebGIS, con el km calibrado). Un tramo cuyo trazo tiene
/// huecos llega en varias lineas: se entrega una por linea con el mismo id, asi
/// que al tocar cualquiera se resalta el tramo entero. Los que no tienen trazo
/// no se dibujan.
class ApiRoadSegmentsRepository
    implements RoadSegmentsRepository, SegmentPavementSource {
  const ApiRoadSegmentsRepository(this._api);

  final ApiClient _api;

  /// El indicador del pavimento que se pinta en campo (DTF M10 HU-MOB-10-01).
  /// Supuesto S-GIS-03: el IRI del ciclo por omision del servidor (el mas
  /// reciente que no es de entrenamiento).
  static const pavementPath = '/api/gis/segment-indicators';

  /// El IRI por tramo con su nivel. Devuelve tambien el JSON tal cual llego,
  /// para guardarlo en el telefono.
  Future<(PavementLayer, Map<String, dynamic>)> pavementWithJson() async {
    try {
      final json = await _api.getJson(
        pavementPath,
        query: const {'indicator': 'IRI'},
      );
      if (json is! Map<String, dynamic>) {
        throw const FormatException('sin objeto');
      }
      return (parsePavement(json), json);
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

  @override
  Future<PavementLayer> pavement() async => (await pavementWithJson()).$1;

  /// Lee la respuesta de `/api/gis/segment-indicators` (o lo guardado de ella).
  static PavementLayer parsePavement(Map<String, dynamic> json) {
    final cycle = json['cycle'];
    String? cycleName;
    for (final c in (json['cycles'] as List?) ?? const []) {
      if (c is Map && c['id'] == cycle) cycleName = c['name'] as String?;
    }
    return PavementLayer(
      indicator: json['indicator'] as String? ?? 'IRI',
      label: json['label'] as String? ?? 'IRI',
      unit: json['unit'] as String? ?? '',
      cycleName: cycleName,
      provisional: json['provisional'] as bool? ?? true,
      segments: {
        for (final s in (json['segments'] as List?) ?? const [])
          if (s is Map<String, dynamic> && s['id'] is String)
            s['id'] as String: SegmentPavement(
              segmentId: s['id'] as String,
              level: switch (s['level']) {
                'BUENO' => PavementLevel.good,
                'REGULAR' => PavementLevel.fair,
                'MALO' => PavementLevel.bad,
                _ => null,
              },
              average: (s['average'] as num?)?.toDouble(),
              samples: (s['samples'] as num?)?.toInt() ?? 0,
              coveragePercent: (s['coveragePercent'] as num?)?.toInt() ?? 0,
            ),
      },
    );
  }

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
