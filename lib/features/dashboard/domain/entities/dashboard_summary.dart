import 'package:equatable/equatable.dart';

/// Los bloques del dashboard: uno por modulo del que se resume algo.
enum DashboardSection { compliance, tickets, accidents, maintenance, inventory }

/// Por que un bloque no se pudo llenar.
enum DashboardError { network, permissionDenied, server, notAvailable }

/// Quien genero tickets y cuantos (grafico "Usuarios que mas tickets han
/// generado", BBP §7.8).
class TicketCreator extends Equatable {
  const TicketCreator({required this.name, required this.count});

  final String name;
  final int count;

  @override
  List<Object?> get props => [name, count];
}

class TicketsSummary extends Equatable {
  const TicketsSummary({
    required this.open,
    required this.attended,
    required this.overdue,
    this.creators = const [],
  });

  final int open;
  final int attended;

  /// Abiertos cuya fecha limite ya paso.
  final int overdue;

  /// Quienes mas tickets generaron, de mas a menos.
  final List<TicketCreator> creators;

  @override
  List<Object?> get props => [open, attended, overdue, creators];
}

/// Estado de un indicador (BBP §7.8): en proceso, buen estado, estado
/// intermedio o mal estado. Las reglas que lo deciden (formulas y umbrales por
/// indicador) las define TEKIA; la app solo muestra lo que informa el servidor.
enum IndicatorStatus { inProcess, good, intermediate, bad }

/// El cumplimiento de un indicador: el codigo (`sgp`, `sgs`...), su porcentaje
/// de 0 a 100, su estado y si ya se cumplio.
class IndicatorCompliance extends Equatable {
  const IndicatorCompliance({
    required this.code,
    required this.percent,
    required this.status,
    required this.met,
  });

  final String code;
  final double percent;
  final IndicatorStatus status;
  final bool met;

  @override
  List<Object?> get props => [code, percent, status, met];
}

/// Cuantos tickets tiene un indicador o subsistema.
class SubsystemTickets extends Equatable {
  const SubsystemTickets({required this.code, required this.count});

  final String code;
  final int count;

  @override
  List<Object?> get props => [code, count];
}

/// Cumplimiento general y por indicador, con el grafico de tickets por
/// subsistema (BBP §7.8, pantalla Dashboard).
class ComplianceSummary extends Equatable {
  const ComplianceSummary({
    required this.overall,
    required this.overallStatus,
    required this.indicators,
    this.ticketsBySubsystem = const [],
  });

  /// De 0 a 100.
  final double overall;
  final IndicatorStatus overallStatus;
  final List<IndicatorCompliance> indicators;
  final List<SubsystemTickets> ticketsBySubsystem;

  int get total => indicators.length;
  int get met => indicators.where((i) => i.met).length;

  int count(IndicatorStatus s) => indicators.where((i) => i.status == s).length;

  @override
  List<Object?> get props => [
    overall,
    overallStatus,
    indicators,
    ticketsBySubsystem,
  ];
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
    this.compliance,
    this.tickets,
    this.accidents,
    this.maintenance,
    this.inventory,
    this.errors = const {},
  });

  /// Cuando se armo, en UTC.
  final DateTime generatedAt;
  final ComplianceSummary? compliance;
  final TicketsSummary? tickets;
  final AccidentsSummary? accidents;
  final MaintenanceSummary? maintenance;
  final InventorySummary? inventory;

  /// Los bloques que no se pudieron llenar.
  final Map<DashboardSection, DashboardError> errors;

  /// Ningun bloque se pudo llenar.
  bool get isEmpty =>
      compliance == null &&
      tickets == null &&
      accidents == null &&
      maintenance == null &&
      inventory == null;

  @override
  List<Object?> get props => [
    generatedAt,
    compliance,
    tickets,
    accidents,
    maintenance,
    inventory,
    errors,
  ];
}
