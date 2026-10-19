import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'follow_up_cubit.dart';

enum NewTicketIssue { title, category }

class NewTicketState extends Equatable {
  const NewTicketState({
    this.categories = const [],
    this.categoriesLoaded = false,
    this.title = '',
    this.category,
    this.kmLabel = '',
    this.description = '',
    this.photos = const [null, null, null],
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
  });

  final List<String> categories;
  final bool categoriesLoaded;
  final String title;
  final String? category;
  final String kmLabel;
  final String description;
  final List<String?> photos;
  final bool saving;
  final bool saved;
  final bool showIssues;
  final bool failed;

  List<NewTicketIssue> get issues => [
    if (title.trim().isEmpty) NewTicketIssue.title,
    if (category == null) NewTicketIssue.category,
  ];

  NewTicketState copyWith({
    List<String>? categories,
    bool? categoriesLoaded,
    String? title,
    String? category,
    String? kmLabel,
    String? description,
    List<String?>? photos,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
  }) => NewTicketState(
    categories: categories ?? this.categories,
    categoriesLoaded: categoriesLoaded ?? this.categoriesLoaded,
    title: title ?? this.title,
    category: category ?? this.category,
    kmLabel: kmLabel ?? this.kmLabel,
    description: description ?? this.description,
    photos: photos ?? this.photos,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [
    categories,
    categoriesLoaded,
    title,
    category,
    kmLabel,
    description,
    photos,
    saving,
    saved,
    showIssues,
    failed,
  ];
}

/// El formulario de un ticket nuevo.
class NewTicketCubit extends Cubit<NewTicketState> {
  NewTicketCubit(this._repository) : super(const NewTicketState());

  final TicketsRepository _repository;

  Future<void> load() async {
    try {
      final categories = await _repository.categories();
      if (isClosed) return;
      emit(state.copyWith(categories: categories, categoriesLoaded: true));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(categoriesLoaded: true));
    }
  }

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setCategory(String v) => emit(state.copyWith(category: v));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  void setPhoto(int slot, String? path) {
    final photos = [...state.photos];
    if (slot >= 0 && slot < ticketPhotoSlots) photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  Future<void> save() async {
    if (state.saving) return;
    if (state.issues.isNotEmpty) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, failed: false));
    try {
      await _repository.create(
        NewTicket(
          title: state.title.trim(),
          category: state.category!,
          kmLabel: state.kmLabel.trim().isEmpty ? null : state.kmLabel.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
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
