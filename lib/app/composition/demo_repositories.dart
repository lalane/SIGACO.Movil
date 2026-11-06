import 'dart:typed_data';

import '../../features/accidents/domain/entities/accident.dart';
import '../../features/accidents/domain/repositories/accidents_repository.dart';
import '../../features/alerts/domain/entities/app_alert.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/repositories/compliance_source.dart';
import '../../features/inspections/domain/entities/inspection.dart';
import '../../features/inspections/domain/repositories/inspections_repository.dart';
import '../../features/inventory/domain/entities/inventory_asset.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/maintenance/domain/entities/maintenance.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/map/domain/entities/map_pin.dart';
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

class DemoAwareInventory implements InventoryRepository {
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
  Future<List<InventoryAsset>> list() => _r.list();

  @override
  Future<InventoryAsset> get(String id) => _r.get(id);

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) => _r.mainPhoto(asset);
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

class DemoAwareMap implements MapRepository {
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
