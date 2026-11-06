import '../entities/ticket.dart';

/// Por que no se pudieron traer o guardar los tickets.
enum TicketsError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede hacerlo.
  permissionDenied,

  /// Error del servidor.
  server,

  /// El servidor todavia no publica los tickets para esta concesion.
  notAvailable,

  /// El ticket ya no existe.
  notFound,
}

class TicketsException implements Exception {
  const TicketsException(this.error);

  final TicketsError error;

  @override
  String toString() => 'TicketsException($error)';
}

/// El registro (o el seguimiento) ya quedo guardado en el servidor, pero faltó
/// una parte: por ejemplo las fotos no se pudieron subir. [reason] es lo que dijo
/// el servidor. No es un fallo del guardado: la persona no debe repetirlo.
class TicketPartiallySavedException implements Exception {
  const TicketPartiallySavedException(this.reason);

  final String reason;

  @override
  String toString() => 'TicketPartiallySavedException($reason)';
}

/// El catalogo de fallas de la Matriz (indicador, subclasificacion, falla y
/// plazo). Lo implementan los repositorios que hablan con el servidor; sin el,
/// el formulario usa la lista plana de [TicketsRepository.categories].
abstract interface class TicketFailureSource {
  Future<List<TicketFailure>> failures();
}

/// Distancia maxima del punto de un ticket a la carretera; la misma que valida
/// el servidor (RoadLocator.TicketToleranceMeters, decision del 06/11/2026).
const ticketAxisToleranceMeters = 100;

/// Ubica el punto del ticket sobre la carretera antes de guardar.
abstract interface class TicketPlacementSource {
  Future<TicketPlacement> place(double longitude, double latitude);
}

/// Los tickets de la concesion activa. Lanza [TicketsException].
abstract interface class TicketsRepository {
  Future<List<Ticket>> list();

  Future<Ticket> get(String id);

  /// Agrega el seguimiento y devuelve el ticket ya con el.
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp);

  Future<Ticket> create(NewTicket draft);

  /// Tipos de ticket del catalogo.
  Future<List<String>> categories();
}
