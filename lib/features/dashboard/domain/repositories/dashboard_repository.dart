import '../entities/dashboard_summary.dart';

/// El resumen de la concesion activa. Nunca lanza por un bloque que falle: ese
/// bloque queda en [DashboardSummary.errors] y los demas se ven.
abstract interface class DashboardRepository {
  Future<DashboardSummary> load();
}
