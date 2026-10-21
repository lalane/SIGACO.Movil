import '../entities/app_alert.dart';

/// Por que no se pudieron traer o actualizar las alertas.
enum AlertsError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver las alertas.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica las alertas de la persona.
  notAvailable,
}

class AlertsException implements Exception {
  const AlertsException(this.error);

  final AlertsError error;

  @override
  String toString() => 'AlertsException($error)';
}

/// Las alertas de la persona en la concesion activa. Lanza [AlertsException].
abstract interface class AlertsRepository {
  /// Las mas recientes primero.
  Future<List<AppAlert>> list();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
