import '../../features/accidents/domain/entities/accident.dart';
import '../../features/accidents/domain/repositories/accidents_repository.dart';
import '../../features/inventory/domain/entities/inventory_asset.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/maintenance/domain/entities/maintenance.dart';
import '../../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../../features/tickets/domain/entities/ticket.dart';
import '../../features/tickets/domain/repositories/tickets_repository.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';

/// Arma el resumen con lo que ya consultan los modulos. Mientras el backend no
/// publique un endpoint de resumen, las cifras son las mismas que se ven en las
/// listas; cuando exista, se cambia esta clase por la que lo llame.
class ComposedDashboardRepository implements DashboardRepository {
  ComposedDashboardRepository({
    required this.tickets,
    required this.accidents,
    required this.maintenance,
    required this.inventory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TicketsRepository tickets;
  final AccidentsRepository accidents;
  final MaintenanceRepository maintenance;
  final InventoryRepository inventory;
  final DateTime Function() _clock;

  @override
  Future<DashboardSummary> load() async {
    final now = _clock().toUtc();
    final errors = <DashboardSection, DashboardError>{};

    Future<T?> block<T>(
      DashboardSection section,
      Future<T> Function() run,
    ) async {
      try {
        return await run();
      } on TicketsException catch (e) {
        errors[section] = _fromTickets(e.error);
      } on AccidentsException catch (e) {
        errors[section] = _fromAccidents(e.error);
      } on MaintenanceException catch (e) {
        errors[section] = _fromMaintenance(e.error);
      } on InventoryException catch (e) {
        errors[section] = _fromInventory(e.error);
      } catch (_) {
        errors[section] = DashboardError.server;
      }
      return null;
    }

    final results = await Future.wait([
      block(DashboardSection.tickets, () => _tickets(now)),
      block(DashboardSection.accidents, () => _accidents(now)),
      block(DashboardSection.maintenance, _maintenance),
      block(DashboardSection.inventory, _inventory),
    ]);
    return DashboardSummary(
      generatedAt: now,
      tickets: results[0] as TicketsSummary?,
      accidents: results[1] as AccidentsSummary?,
      maintenance: results[2] as MaintenanceSummary?,
      inventory: results[3] as InventorySummary?,
      errors: errors,
    );
  }

  Future<TicketsSummary> _tickets(DateTime now) async {
    final all = await tickets.list();
    final open = all.where((t) => t.status == TicketStatus.open).toList();
    return TicketsSummary(
      open: open.length,
      attended: all.length - open.length,
      overdue: open.where((t) => t.dueAt?.isBefore(now) ?? false).length,
    );
  }

  Future<AccidentsSummary> _accidents(DateTime now) async {
    final since = now.subtract(const Duration(days: AccidentsSummary.days));
    final recent = [
      for (final a in await accidents.list())
        if (!a.createdAt.isBefore(since)) a,
    ];
    return AccidentsSummary(
      recent: recent.length,
      severe: recent.where((a) => a.severity == AccidentSeverity.high).length,
      inFollowUp: recent.where((a) => a.status != AccidentStatus.closed).length,
    );
  }

  Future<MaintenanceSummary> _maintenance() async {
    final orders = [
      for (final list in await Future.wait([
        for (final i in MaintenanceIndicator.values) maintenance.list(i),
      ]))
        ...list,
    ];
    int count(MaintenanceStatus s) => orders.where((o) => o.status == s).length;
    final programmed = orders.fold(
      0.0,
      (n, o) => n + (o.programmedAmount ?? 0),
    );
    final executed = orders.fold(0.0, (n, o) => n + (o.executedAmount ?? 0));
    return MaintenanceSummary(
      open: count(MaintenanceStatus.open),
      inProgress: count(MaintenanceStatus.inProgress),
      closed: count(MaintenanceStatus.closed),
      execution: programmed <= 0 ? 0 : (executed / programmed).clamp(0.0, 1.0),
    );
  }

  Future<InventorySummary> _inventory() async {
    final assets = await inventory.list();
    int count(AssetCondition c) => assets.where((a) => a.condition == c).length;
    return InventorySummary(
      good: count(AssetCondition.good),
      regular: count(AssetCondition.regular),
      poor: count(AssetCondition.poor),
    );
  }

  static DashboardError _fromTickets(TicketsError e) => switch (e) {
    TicketsError.network => DashboardError.network,
    TicketsError.permissionDenied => DashboardError.permissionDenied,
    TicketsError.notAvailable => DashboardError.notAvailable,
    TicketsError.server || TicketsError.notFound => DashboardError.server,
  };

  static DashboardError _fromAccidents(AccidentsError e) => switch (e) {
    AccidentsError.network => DashboardError.network,
    AccidentsError.permissionDenied => DashboardError.permissionDenied,
    AccidentsError.notAvailable => DashboardError.notAvailable,
    AccidentsError.server || AccidentsError.notFound => DashboardError.server,
  };

  static DashboardError _fromMaintenance(MaintenanceError e) => switch (e) {
    MaintenanceError.network => DashboardError.network,
    MaintenanceError.permissionDenied => DashboardError.permissionDenied,
    MaintenanceError.notAvailable => DashboardError.notAvailable,
    MaintenanceError.server ||
    MaintenanceError.notFound => DashboardError.server,
  };

  static DashboardError _fromInventory(InventoryError e) => switch (e) {
    InventoryError.network => DashboardError.network,
    InventoryError.permissionDenied => DashboardError.permissionDenied,
    InventoryError.notAvailable => DashboardError.notAvailable,
    InventoryError.server || InventoryError.notFound => DashboardError.server,
  };
}
