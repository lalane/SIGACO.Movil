import '../entities/inspection.dart';

/// Por que no se pudieron traer o guardar las inspecciones.
enum InspectionsError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede hacerlo.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica las inspecciones de esta concesion.
  notAvailable,

  /// La inspeccion ya no existe.
  notFound,

  /// La inspeccion ya no se puede modificar (cerrada, cancelada o atendida).
  notEditable,

  /// Faltan puntos del checklist por responder.
  incomplete,
}

class InspectionsException implements Exception {
  const InspectionsException(this.error);

  final InspectionsError error;

  @override
  String toString() => 'InspectionsException($error)';
}

/// Las inspecciones de la concesion activa. Lanza [InspectionsException].
abstract interface class InspectionsRepository {
  Future<List<Inspection>> list();

  Future<Inspection> get(String id);

  /// Guarda las respuestas del checklist (`itemId` -> resultado) sin cerrar la
  /// inspeccion: queda en proceso. Devuelve la inspeccion ya con ellas.
  Future<Inspection> saveAnswers(String id, Map<String, CheckResult> answers);

  /// Termina la inspeccion: exige el checklist completo y la deja atendida.
  Future<Inspection> complete(String id, Map<String, CheckResult> answers);
}
