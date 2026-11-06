import '../entities/maintenance.dart';

/// Por que no se pudo traer o guardar el mantenimiento.
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

  /// El servidor rechazo el avance (por ejemplo, supera el volumen total o
  /// baja el avance); [MaintenanceException.message] trae su motivo.
  invalid,

  /// El avance quedo guardado, pero alguna foto no subio.
  photosNotSaved,
}

class MaintenanceException implements Exception {
  const MaintenanceException(this.error, {this.message});

  final MaintenanceError error;

  /// El motivo que dio el servidor, si lo dio.
  final String? message;

  @override
  String toString() => 'MaintenanceException($error)';
}

/// El mantenimiento de la concesion activa. Lanza [MaintenanceException].
abstract interface class MaintenanceRepository {
  /// Los indicadores que la persona tiene asignados en la concesion activa
  /// (`/api/maintenance/navigation`), en el orden del selector. Si el servidor
  /// no lo dice, todos.
  Future<List<MaintenanceIndicator>> visibleIndicators();

  /// Los mantenimientos de un indicador.
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator);

  Future<MaintenanceOrder> get(String id);

  /// Registra un seguimiento (HU-MC-10) y devuelve la orden ya con el.
  ///
  /// Se manda una de dos cosas, nunca las dos:
  ///  - [executedVolume]: lo ejecutado EN ESTE seguimiento; el servidor lo suma
  ///    al acumulado (10 de 40 son 25 %);
  ///  - [percent]: si no se conoce el volumen, el avance ACUMULADO de 0 a 100;
  ///    no puede bajar.
  ///
  /// [photoPaths] son las evidencias del seguimiento (hasta tres). [at] es
  /// cuando se capturo y [clientId] hace el registro idempotente.
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  });
}
