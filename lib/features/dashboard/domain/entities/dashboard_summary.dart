import 'package:equatable/equatable.dart';

/// Los bloques del dashboard: uno por modulo del que se resume algo.
enum DashboardSection { tickets, accidents, maintenance, inventory }

/// Por que un bloque no se pudo llenar.
enum DashboardError { network, permissionDenied, server, notAvailable }

class TicketsSummary extends Equatable {
  const TicketsSummary({
    required this.open,
    required this.attended,
    required this.overdue,
  });

  final int open;
  final int attended;

  /// Abiertos cuya fecha limite ya paso.
  final int overdue;

  @override
  List<Object?> get props => [open, attended, overdue];
}

class AccidentsSummary extends Equatable {
  const AccidentsSummary({
    required this.recent,
    required this.severe,
    required this.inFollowUp,
  });

  /// Registrados en los ultimos [days] dias.
  final int recent;

  /// De los recientes, los de gravedad alta.
  final int severe;

  /// De los recientes, los que todavia no se cierran.
  final int inFollowUp;

  /// El periodo de "recientes".
  static const days = 30;

  @override
  List<Object?> get props => [recent, severe, inFollowUp];
}

class MaintenanceSummary extends Equatable {
  const MaintenanceSummary({
    required this.open,
    required this.inProgress,
    required this.closed,
    required this.execution,
  });

  final int open;
  final int inProgress;
  final int closed;

  /// Importe ejecutado entre el programado de todos los indicadores, de 0 a 1.
  final double execution;

  int get total => open + inProgress + closed;

  @override
  List<Object?> get props => [open, inProgress, closed, execution];
}

class InventorySummary extends Equatable {
  const InventorySummary({
    required this.good,
    required this.regular,
    required this.poor,
  });

  final int good;
  final int regular;
  final int poor;

  int get total => good + regular + poor;

  @override
  List<Object?> get props => [good, regular, poor];
}

/// El resumen operativo (APP-MOB-04): lo que se pudo resumir de cada modulo y,
/// de lo que no, por que.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.generatedAt,
    this.tickets,
    this.accidents,
    this.maintenance,
    this.inventory,
    this.errors = const {},
  });

  /// Cuando se armo, en UTC.
  final DateTime generatedAt;
  final TicketsSummary? tickets;
  final AccidentsSummary? accidents;
  final MaintenanceSummary? maintenance;
  final InventorySummary? inventory;

  /// Los bloques que no se pudieron llenar.
  final Map<DashboardSection, DashboardError> errors;

  /// Ningun bloque se pudo llenar.
  bool get isEmpty =>
      tickets == null &&
      accidents == null &&
      maintenance == null &&
      inventory == null;

  @override
  List<Object?> get props => [
    generatedAt,
    tickets,
    accidents,
    maintenance,
    inventory,
    errors,
  ];
}
