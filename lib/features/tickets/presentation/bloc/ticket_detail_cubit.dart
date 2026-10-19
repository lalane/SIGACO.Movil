import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

enum TicketDetailStatus { loading, ready, failure }

class TicketDetailState extends Equatable {
  const TicketDetailState({
    this.status = TicketDetailStatus.loading,
    this.ticket,
    this.error,
  });

  final TicketDetailStatus status;
  final Ticket? ticket;
  final TicketsError? error;

  @override
  List<Object?> get props => [status, ticket, error];
}

/// La ficha de un ticket.
class TicketDetailCubit extends Cubit<TicketDetailState> {
  TicketDetailCubit(this._repository, this.ticketId)
    : super(const TicketDetailState());

  final TicketsRepository _repository;
  final String ticketId;

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
}
