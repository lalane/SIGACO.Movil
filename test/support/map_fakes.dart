import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/repositories/road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';

/// Pines por pestana, con fallos programables y cuenta de consultas.
class FakeMapRepository implements MapRepository {
  FakeMapRepository({Map<MapLayer, List<MapPin>>? data, this.failure})
    : data = data ?? {};

  final Map<MapLayer, List<MapPin>> data;

  /// Si no es null, toda consulta falla con este error.
  MapError? failure;

  /// Fallo solo para una pestana.
  final Map<MapLayer, MapError> failureByLayer = {};
  final List<MapLayer> requested = [];

  int requestsFor(MapLayer layer) => requested.where((l) => l == layer).length;

  @override
  Future<List<MapPin>> pins(MapLayer layer) async {
    requested.add(layer);
    final error = failureByLayer[layer] ?? failure;
    if (error != null) throw MapException(error);
    return data[layer] ?? const [];
  }
}

/// Tramos programables, con fallo y cuenta de consultas.
class FakeRoadSegmentsRepository implements RoadSegmentsRepository {
  FakeRoadSegmentsRepository({List<RoadSegment>? data, this.failure})
    : data = data ?? [];

  List<RoadSegment> data;
  MapError? failure;
  int requests = 0;

  @override
  Future<List<RoadSegment>> segments() async {
    requests++;
    final error = failure;
    if (error != null) throw MapException(error);
    return data;
  }
}

RoadSegment fakeSegment(
  String id, {
  String code = 'TR01',
  TravelDirection direction = TravelDirection.increasing,
  List<GeoPoint>? points,
}) => RoadSegment(
  id: id,
  code: code,
  direction: direction,
  name: 'Tramo $id',
  startKmLabel: 'KM 10+000',
  endKmLabel: 'KM 12+000',
  points:
      points ??
      const [
        GeoPoint(-18.85, -41.98),
        GeoPoint(-18.86, -41.99),
        GeoPoint(-18.87, -41.99),
      ],
);

/// Ubicacion programable.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.location, this.failure});

  UserLocation? location;
  LocationFailure? failure;
  int calls = 0;
  final List<LocationFailure> openedSettings = [];

  @override
  Future<UserLocation> current() async {
    calls++;
    final error = failure;
    if (error != null) throw LocationException(error);
    return location!;
  }

  @override
  Future<void> openSettings(LocationFailure reason) async =>
      openedSettings.add(reason);
}

MapPin fakePin(
  String id, {
  MapLayer layer = MapLayer.inventory,
  GeoPoint position = const GeoPoint(-18.85, -41.98),
  String? category,
  PinStatus status = PinStatus.normal,
  String? subtitle,
  String? kmLabel,
  String? segmentCode,
  TravelDirection? direction,
}) => MapPin(
  id: id,
  layer: layer,
  title: 'Pin $id',
  subtitle: subtitle,
  category: category,
  kmLabel: kmLabel,
  segmentCode: segmentCode,
  direction: direction,
  status: status,
  position: position,
);

UserLocation fakeLocation({
  GeoPoint position = const GeoPoint(-18.85, -41.98),
  double accuracy = 10,
  LocationOrigin origin = LocationOrigin.gps,
}) => UserLocation(
  position: position,
  accuracyMeters: accuracy,
  capturedAt: DateTime.utc(2026, 10, 14, 12),
  origin: origin,
);
