import '../entities/maintenance.dart';

/// Por que no se pudo traer el mantenimiento.
enum MaintenanceError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver ese indicador.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica el mantenimiento de esta concesion.
  notAvailable,

  /// El mantenimiento ya no existe.
  notFound,
}

class MaintenanceException implements Exception {
  const MaintenanceException(this.error);

  final MaintenanceError error;

  @override
  String toString() => 'MaintenanceException($error)';
}

/// El mantenimiento de la concesion activa. Lanza [MaintenanceException].
abstract interface class MaintenanceRepository {
  /// Los mantenimientos de un indicador.
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator);

  Future<MaintenanceOrder> get(String id);
}
