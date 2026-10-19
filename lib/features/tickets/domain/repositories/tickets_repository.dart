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
