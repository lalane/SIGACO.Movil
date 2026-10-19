import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Mientras el backend no publique los endpoints de tickets, la pantalla dice
/// que no estan disponibles en lugar de inventar datos. Con `SAMPLE_TICKETS=true`
/// se usa [SampleTicketsRepository].
class UnavailableTicketsRepository implements TicketsRepository {
  const UnavailableTicketsRepository();

  static const _error = TicketsException(TicketsError.notAvailable);

  @override
  Future<List<Ticket>> list() => Future.error(_error);

  @override
  Future<Ticket> get(String id) => Future.error(_error);

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) =>
      Future.error(_error);

  @override
  Future<Ticket> create(NewTicket draft) => Future.error(_error);

  @override
  Future<List<String>> categories() => Future.error(_error);
}
