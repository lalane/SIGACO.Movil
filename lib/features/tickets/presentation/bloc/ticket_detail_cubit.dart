import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_supervision.dart';
import '../../domain/repositories/tickets_repository.dart';

enum TicketDetailStatus { loading, ready, failure }

/// Como termino la ultima accion del Supervisor.
enum TicketActionOutcome { done, rejected, failed }

class TicketDetailState extends Equatable {
  const TicketDetailState({
    this.status = TicketDetailStatus.loading,
    this.ticket,
    this.error,
    this.acting = false,
    this.lastAction,
    this.outcome,
    this.actionError,
    this.rejection,
  });

  final TicketDetailStatus status;
  final Ticket? ticket;
  final TicketsError? error;

  /// Una accion del Supervisor va en camino: los botones esperan.
  final bool acting;

  /// La ultima accion que se intento y como termino, para avisarlo.
  final TicketAction? lastAction;
  final TicketActionOutcome? outcome;

  /// Por que fallo (sin red, sin permiso...) o lo que dijo el servidor al
  /// rechazarla.
  final TicketsError? actionError;
  final String? rejection;

  @override
  List<Object?> get props => [
    status,
    ticket,
    error,
    acting,
    lastAction,
    outcome,
    actionError,
    rejection,
  ];
}

/// La ficha de un ticket y las acciones del Supervisor sobre el (asignar,
/// cerrar, regresar, reabrir y cancelar), cuando el servidor las ofrece.
class TicketDetailCubit extends Cubit<TicketDetailState> {
  TicketDetailCubit(this._repository, this.ticketId)
    : super(const TicketDetailState());

  final TicketsRepository _repository;
  final String ticketId;

  /// La fuente sabe hacer las acciones del Supervisor.
  bool get canSupervise => _repository is TicketSupervision;

  TicketSupervision? get _supervision {
    final r = _repository;
    return r is TicketSupervision ? r as TicketSupervision : null;
  }

  Future<void> load() async {
    // Al volver de un seguimiento se conserva lo que ya se ve.
    if (state.ticket == null) emit(const TicketDetailState());
    try {
      final ticket = await _repository.get(ticketId);
      if (isClosed) return;
      emit(TicketDetailState(status: TicketDetailStatus.ready, ticket: ticket));
    } on TicketsException catch (e) {
      if (isClosed) return;
      emit(
        TicketDetailState(
          status: TicketDetailStatus.failure,
          ticket: state.ticket,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        TicketDetailState(
          status: TicketDetailStatus.failure,
          ticket: state.ticket,
          error: TicketsError.server,
        ),
      );
    }
  }

  /// Empresas y equipos para asignar. Lanza [TicketsException].
  Future<List<TicketAssignableCompany>> assignableTeams() async {
    final s = _supervision;
    if (s == null) throw const TicketsException(TicketsError.notAvailable);
    return s.assignableTeams();
  }

  Future<bool> assign(TicketAssignment assignment) {
    final reassign = state.ticket?.stage == TicketStage.open;
    return _run(
      reassign ? TicketAction.reassign : TicketAction.assign,
      (s, t) => s.assign(t, assignment),
    );
  }

  /// Valida y cierra (no confundir con [close], que cierra el cubit).
  Future<bool> closeTicket(TicketClosing closing) =>
      _run(TicketAction.close, (s, t) => s.close(t, closing));

  Future<bool> returnToOpen(String reason) =>
      _run(TicketAction.returnToOpen, (s, t) => s.returnToOpen(t, reason));

  Future<bool> reopen(String reason) =>
      _run(TicketAction.reopen, (s, t) => s.reopen(t, reason));

  Future<bool> cancel(TicketCancellation cancellation) =>
      _run(TicketAction.cancel, (s, t) => s.cancel(t, cancellation));

  /// Corre la accion sobre el ticket que se ve y deja el ticket como quedo; si
  /// falla, el ticket queda como estaba y el estado dice por que.
  Future<bool> _run(
    TicketAction action,
    Future<Ticket> Function(TicketSupervision s, Ticket t) body,
  ) async {
    final s = _supervision;
    final ticket = state.ticket;
    if (s == null || ticket == null || state.acting) return false;
    emit(
      TicketDetailState(
        status: state.status,
        ticket: ticket,
        acting: true,
        lastAction: action,
      ),
    );
    try {
      final updated = await body(s, ticket);
      if (isClosed) return true;
      emit(
        TicketDetailState(
          status: TicketDetailStatus.ready,
          ticket: updated,
          lastAction: action,
          outcome: TicketActionOutcome.done,
        ),
      );
      return true;
    } on TicketActionRejected catch (e) {
      _failed(action, ticket, rejection: e.reason);
    } on TicketsException catch (e) {
      _failed(action, ticket, error: e.error);
    } catch (_) {
      _failed(action, ticket, error: TicketsError.server);
    }
    return false;
  }

  void _failed(
    TicketAction action,
    Ticket ticket, {
    TicketsError? error,
    String? rejection,
  }) {
    if (isClosed) return;
    emit(
      TicketDetailState(
        status: state.status,
        ticket: ticket,
        lastAction: action,
        outcome: rejection != null
            ? TicketActionOutcome.rejected
            : TicketActionOutcome.failed,
        actionError: error,
        rejection: rejection,
      ),
    );
  }
}
