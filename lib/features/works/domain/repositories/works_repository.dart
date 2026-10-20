import '../entities/public_work.dart';

/// Por que no se pudieron traer las obras.
enum WorksError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede ver las obras.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica las obras de esta concesion.
  notAvailable,

  /// La obra ya no existe.
  notFound,
}

class WorksException implements Exception {
  const WorksException(this.error);

  final WorksError error;

  @override
  String toString() => 'WorksException($error)';
}

/// Las obras de la concesion activa. Lanza [WorksException].
abstract interface class WorksRepository {
  Future<List<PublicWork>> list();

  Future<PublicWork> get(String id);
}
