import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/time/concession_zone.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Cuantas fotos admite un seguimiento (las del mockup).
const ticketPhotoSlots = 3;

/// Lo que se puede reclamar de un seguimiento antes de guardarlo.
enum FollowUpIssue { status, description }

class FollowUpState extends Equatable {
  const FollowUpState({
    required this.date,
    required this.minutes,
    this.status,
    this.description = '',
    this.photos = const [null, null, null],
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
  });

  /// Dia elegido (solo la fecha cuenta).
  final DateTime date;

  /// Hora elegida, en minutos desde la medianoche.
  final int minutes;
  final TicketStatus? status;
  final String description;

  /// Una ruta por hueco; null = hueco vacio.
  final List<String?> photos;
  final bool saving;
  final bool saved;

  /// Se activa al intentar guardar: antes no se regana a nadie por un campo
  /// vacio.
  final bool showIssues;
  final bool failed;

  List<FollowUpIssue> get issues => [
    if (status == null) FollowUpIssue.status,
    if (description.trim().isEmpty) FollowUpIssue.description,
  ];

  FollowUpState copyWith({
    DateTime? date,
    int? minutes,
    TicketStatus? status,
    String? description,
    List<String?>? photos,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
  }) => FollowUpState(
    date: date ?? this.date,
    minutes: minutes ?? this.minutes,
    status: status ?? this.status,
    description: description ?? this.description,
    photos: photos ?? this.photos,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [
    date,
    minutes,
    status,
    description,
    photos,
    saving,
    saved,
    showIssues,
    failed,
  ];
}

/// El formulario de seguimiento de un ticket.
class FollowUpCubit extends Cubit<FollowUpState> {
  FollowUpCubit(
    this._repository,
    this.ticketId, {
    ConcessionZone? zone,
    DateTime Function()? clock,
  }) : _zone = zone,
       super(
         _initial(inConcessionZone((clock ?? DateTime.now)().toUtc(), zone)),
       );

  final TicketsRepository _repository;
  final String ticketId;
  final ConcessionZone? _zone;

  static FollowUpState _initial(DateTime now) => FollowUpState(
    date: DateTime(now.year, now.month, now.day),
    minutes: now.hour * 60 + now.minute,
  );

  void setDate(DateTime day) =>
      emit(state.copyWith(date: DateTime(day.year, day.month, day.day)));

  void setMinutes(int minutes) => emit(state.copyWith(minutes: minutes));

  void setStatus(TicketStatus status) => emit(state.copyWith(status: status));

  void setDescription(String text) => emit(state.copyWith(description: text));

  void setPhoto(int slot, String? path) {
    final photos = [...state.photos];
    photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  Future<void> save() async {
    if (state.saving) return;
    if (state.issues.isNotEmpty) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, failed: false));
    final wall = DateTime(
      state.date.year,
      state.date.month,
      state.date.day,
      state.minutes ~/ 60,
      state.minutes % 60,
    );
    try {
      await _repository.addFollowUp(
        ticketId,
        NewFollowUp(
          at: wallClockToUtc(wall, _zone),
          status: state.status!,
          description: state.description.trim(),
          photoPaths: [for (final p in state.photos) ?p],
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, failed: true));
    }
  }
}
