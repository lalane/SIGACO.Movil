import '../entities/accident.dart';

/// Por que no se pudieron traer o guardar los accidentes.
enum AccidentsError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede hacerlo.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica los accidentes para esta concesion.
  notAvailable,

  /// El accidente ya no existe.
  notFound,
}

class AccidentsException implements Exception {
  const AccidentsException(this.error);

  final AccidentsError error;

  @override
  String toString() => 'AccidentsException($error)';
}

/// Los accidentes de la concesion activa. Lanza [AccidentsException].
abstract interface class AccidentsRepository {
  Future<List<Accident>> list();

  Future<Accident> get(String id);

  Future<Accident> create(NewAccident draft);
}
