import 'dart:typed_data';

import '../../features/accidents/domain/entities/accident.dart';
import '../../features/accidents/domain/repositories/accidents_repository.dart';
import '../../features/alerts/domain/entities/app_alert.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/repositories/compliance_source.dart';
import '../../features/inspections/domain/entities/inspection.dart';
import '../../features/inspections/domain/repositories/inspections_repository.dart';
import '../../features/inventory/data/repositories/unavailable_asset_capture_repository.dart';
import '../../features/inventory/domain/entities/asset_capture.dart';
import '../../features/inventory/domain/entities/asset_template.dart';
import '../../features/inventory/domain/entities/inventory_asset.dart';
import '../../features/inventory/domain/repositories/asset_capture_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/maintenance/domain/entities/maintenance.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/map/domain/entities/geo_bounds.dart';
import '../../features/map/domain/entities/geo_point.dart';
import '../../features/map/domain/entities/map_pin.dart';
import '../../features/map/domain/entities/nearby_pin.dart';
import '../../features/map/domain/entities/road_segment.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../features/map/domain/repositories/road_segments_repository.dart';
import '../../features/tickets/domain/entities/ticket.dart';
import '../../features/tickets/domain/repositories/tickets_repository.dart';
import '../../features/works/domain/entities/public_work.dart';
import '../../features/works/domain/repositories/works_repository.dart';

/// Cada modulo con dos fuentes: la real (el servidor) y la de ejemplo. [demo]
/// se consulta en cada llamada, asi el interruptor de la cuenta cambia de una a
/// otra al momento, sin reiniciar la app ni cerrar la sesion.

class DemoAwareTickets
    implements TicketsRepository, TicketFailureSource, TicketPlacementSource {
  const DemoAwareTickets({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final TicketsRepository real;
  final TicketsRepository sample;
  final bool Function() demo;

  TicketsRepository get _r => demo() ? sample : real;

  @override
  Future<List<Ticket>> list() => _r.list();

  @override
  Future<Ticket> get(String id) => _r.get(id);

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) =>
      _r.addFollowUp(ticketId, followUp);

  @override
  Future<Ticket> create(NewTicket draft) => _r.create(draft);

  @override
  Future<List<String>> categories() => _r.categories();

  @override
  Future<List<TicketFailure>> failures() async {
    final r = _r;
    return r is TicketFailureSource
        ? (r as TicketFailureSource).failures()
        : const <TicketFailure>[];
  }

  @override
  Future<TicketPlacement> place(double longitude, double latitude) async {
    final r = _r;
    return r is TicketPlacementSource
        ? (r as TicketPlacementSource).place(longitude, latitude)
        : const TicketPlacement.unknown();
  }
}

class DemoAwareWorks implements WorksRepository {
  const DemoAwareWorks({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final WorksRepository real;
  final WorksRepository sample;
  final bool Function() demo;

  WorksRepository get _r => demo() ? sample : real;

  @override
  Future<List<PublicWork>> list() => _r.list();

  @override
  Future<PublicWork> get(String id) => _r.get(id);
}

class DemoAwareInspections implements InspectionsRepository {
  const DemoAwareInspections({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final InspectionsRepository real;
  final InspectionsRepository sample;
  final bool Function() demo;

  InspectionsRepository get _r => demo() ? sample : real;

  @override
  Future<List<Inspection>> list() => _r.list();

  @override
  Future<Inspection> get(String id) => _r.get(id);

  @override
  Future<Inspection> saveAnswers(String id, Map<String, CheckResult> answers) =>
      _r.saveAnswers(id, answers);

  @override
  Future<List<InspectionTemplate>> templates() => _r.templates();

  @override
  Future<Inspection> create(NewInspection draft) => _r.create(draft);

  @override
  Future<Inspection> addFinding(String id, InspectionFinding finding) =>
      _r.addFinding(id, finding);

  @override
  Future<Inspection> complete(String id, Map<String, CheckResult> answers) =>
      _r.complete(id, answers);
}

class DemoAwareMaintenance implements MaintenanceRepository {
  const DemoAwareMaintenance({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final MaintenanceRepository real;
  final MaintenanceRepository sample;
  final bool Function() demo;

  MaintenanceRepository get _r => demo() ? sample : real;

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      _r.list(indicator);

  @override
  Future<MaintenanceOrder> get(String id) => _r.get(id);

  @override
  Future<List<MaintenanceIndicator>> visibleIndicators() =>
      _r.visibleIndicators();

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  }) => _r.addProgress(
    id,
    executedVolume: executedVolume,
    percent: percent,
    notes: notes,
    photoPaths: photoPaths,
    at: at,
    clientId: clientId,
  );
}

class DemoAwareAccidents implements AccidentsRepository {
  const DemoAwareAccidents({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final AccidentsRepository real;
  final AccidentsRepository sample;
  final bool Function() demo;

  AccidentsRepository get _r => demo() ? sample : real;

  @override
  Future<List<Accident>> list() => _r.list();

  @override
  Future<Accident> get(String id) => _r.get(id);

  @override
  Future<Accident> create(NewAccident draft) => _r.create(draft);
}

class DemoAwareInventory
    implements
        InventoryRepository,
        AssetPhotosSource,
        AssetTemplateSource,
        AssetCatalogSource,
        AssetQrSource,
        AssetHistorySource {
  const DemoAwareInventory({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final InventoryRepository real;
  final InventoryRepository sample;
  final bool Function() demo;

  InventoryRepository get _r => demo() ? sample : real;

  @override
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  }) => _r.page(query, after: after, cancellation: cancellation);

  @override
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  }) => _r.counts(query, cancellation: cancellation);

  @override
  Future<List<AssetTypeOption>> types() => _r.types();

  @override
  Future<InventoryAsset> get(String id) => _r.get(id);

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) => _r.mainPhoto(asset);

  @override
  Future<List<String>> photos(InventoryAsset asset) async {
    final r = _r;
    return r is AssetPhotosSource
        ? (r as AssetPhotosSource).photos(asset)
        : const <String>[];
  }

  @override
  Future<AssetTemplate?> template(String typeCode) async {
    final r = _r;
    return r is AssetTemplateSource
        ? (r as AssetTemplateSource).template(typeCode)
        : null;
  }

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async {
    final r = _r;
    return r is AssetCatalogSource
        ? (r as AssetCatalogSource).catalogs()
        : const <String, List<CatalogOption>>{};
  }

  @override
  Future<InventoryAsset> byQr(String token) {
    final r = _r;
    return r is AssetQrSource
        ? (r as AssetQrSource).byQr(token)
        : Future.error(const InventoryException(InventoryError.notFound));
  }

  @override
  Future<AssetHistoryPage> history(
    String assetId,
    AssetHistoryKind kind, {
    int limit = 5,
  }) {
    final r = _r;
    return r is AssetHistorySource
        ? (r as AssetHistorySource).history(assetId, kind, limit: limit)
        : Future.error(const InventoryException(InventoryError.notAvailable));
  }
}

/// El alta de activos: con datos de ejemplo no hay servidor donde darlos de
/// alta, y el formulario lo dice.
class DemoAwareAssetCapture
    implements AssetCaptureRepository, PendingAssetsSource {
  const DemoAwareAssetCapture({required this.real, required this.demo});

  final AssetCaptureRepository real;
  final bool Function() demo;

  AssetCaptureRepository get _r =>
      demo() ? const UnavailableAssetCaptureRepository() : real;

  @override
  Future<List<AssetTypeOption>> types() => _r.types();

  @override
  Future<AssetTemplate> template(String typeCode) => _r.template(typeCode);

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() => _r.catalogs();

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) =>
      _r.locate(longitude, latitude);

  @override
  Future<CapturedAsset> create(NewAsset draft) => _r.create(draft);

  @override
  Future<List<InventoryAsset>> pendingAssets() async {
    final r = _r;
    return r is PendingAssetsSource
        ? (r as PendingAssetsSource).pendingAssets()
        : const <InventoryAsset>[];
  }
}

class DemoAwareAlerts implements AlertsRepository {
  const DemoAwareAlerts({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final AlertsRepository real;
  final AlertsRepository sample;
  final bool Function() demo;

  AlertsRepository get _r => demo() ? sample : real;

  @override
  Future<List<AppAlert>> list() => _r.list();

  @override
  Future<void> markRead(String id) => _r.markRead(id);

  @override
  Future<void> markAllRead() => _r.markAllRead();
}

class DemoAwareMap
    implements MapRepository, NearbyAssetsSource, AreaPinsSource {
  const DemoAwareMap({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final MapRepository real;
  final MapRepository sample;
  final bool Function() demo;

  @override
  Future<List<MapPin>> pins(MapLayer layer) =>
      (demo() ? sample : real).pins(layer);

  /// Con datos de ejemplo los cercanos se calculan en el telefono.
  @override
  Future<List<NearbyPin>> nearbyAssets(GeoPoint from, double radiusMeters) {
    final r = demo() ? sample : real;
    if (r is! NearbyAssetsSource) {
      return Future.error(const MapException(MapError.notAvailable));
    }
    return (r as NearbyAssetsSource).nearbyAssets(from, radiusMeters);
  }

  /// Los datos de ejemplo son pocos: bajan completos, sin zonas.
  @override
  bool loadsByArea(MapLayer layer) {
    final r = demo() ? sample : real;
    return r is AreaPinsSource && (r as AreaPinsSource).loadsByArea(layer);
  }

  @override
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  }) {
    final r = demo() ? sample : real;
    if (r is! AreaPinsSource) {
      return Future.error(const MapException(MapError.notAvailable));
    }
    return (r as AreaPinsSource).pinsIn(layer, area, cancel: cancel);
  }
}

class DemoAwareRoadSegments implements RoadSegmentsRepository {
  const DemoAwareRoadSegments({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final RoadSegmentsRepository real;
  final RoadSegmentsRepository sample;
  final bool Function() demo;

  @override
  Future<List<RoadSegment>> segments() => (demo() ? sample : real).segments();
}

class DemoAwareCompliance implements ComplianceSource {
  const DemoAwareCompliance({
    required this.real,
    required this.sample,
    required this.demo,
  });

  final ComplianceSource real;
  final ComplianceSource sample;
  final bool Function() demo;

  @override
  Future<ComplianceSummary> load() => (demo() ? sample : real).load();
}
