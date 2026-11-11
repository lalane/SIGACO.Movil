import '../entities/ticket.dart';
import '../entities/ticket_supervision.dart';

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

/// El servidor no acepto una accion sobre el ticket: [reason] es lo que dijo,
/// con su codigo (por ejemplo, otra persona ya lo cambio o el folio del
/// duplicado no existe). Nada se guardo.
class TicketActionRejected implements Exception {
  const TicketActionRejected(this.reason);

  final String reason;

  @override
  String toString() => 'TicketActionRejected($reason)';
}

/// Las acciones del Supervisor sobre un ticket (DTF M11 v0.3, HU-11-24). Cada
/// una devuelve el ticket como quedo. Lanzan [TicketsException] o
/// [TicketActionRejected]; necesitan red (el servidor valida el estado y la
/// version del ticket).
abstract interface class TicketSupervision {
  /// Empresas activas con sus equipos asignables y sus integrantes.
  Future<List<TicketAssignableCompany>> assignableTeams();

  /// Asigna (SIN_VALIDAR) o reasigna con motivo (ABIERTO).
  Future<Ticket> assign(Ticket ticket, TicketAssignment assignment);

  /// Valida y cierra un ticket ATENDIDO.
  Future<Ticket> close(Ticket ticket, TicketClosing closing);

  /// Regresa a ABIERTO un ticket ATENDIDO, con motivo.
  Future<Ticket> returnToOpen(Ticket ticket, String reason);

  /// Reabre un ticket CERRADO, con motivo.
  Future<Ticket> reopen(Ticket ticket, String reason);

  /// Cancela un ticket SIN_VALIDAR o ABIERTO.
  Future<Ticket> cancel(Ticket ticket, TicketCancellation cancellation);
}

/// El catalogo de fallas de la Matriz (indicador, subclasificacion, falla y
/// plazo). Lo implementan los repositorios que hablan con el servidor; sin el,
/// el formulario usa la lista plana de [TicketsRepository.categories].
abstract interface class TicketFailureSource {
  Future<List<TicketFailure>> failures();
}

/// Las carreteras de la concesion activa: el formulario pide elegir una si son
/// varias y el ticket no trae punto ni activo (el servidor no puede deducirla).
abstract interface class TicketRoadSource {
  Future<List<TicketRoad>> roads();
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
