import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';

enum NewInspectionStatus { loading, ready, failure }

class NewInspectionState extends Equatable {
  const NewInspectionState({
    this.status = NewInspectionStatus.loading,
    this.templates = const [],
    this.type,
    this.title = '',
    this.kmLabel = '',
    this.segmentCode = '',
    this.direction = '',
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
  });

  final NewInspectionStatus status;

  /// Los tipos que se pueden crear.
  final List<InspectionTemplate> templates;
  final String? type;
  final String title;
  final String kmLabel;
  final String segmentCode;
  final String direction;
  final bool saving;
  final bool saved;
  final bool showIssues;
  final bool failed;

  /// Solo el tipo es obligatorio: decide los puntos del checklist.
  bool get typeMissing => type == null;

  NewInspectionState copyWith({
    NewInspectionStatus? status,
    List<InspectionTemplate>? templates,
    String? type,
    String? title,
    String? kmLabel,
    String? segmentCode,
    String? direction,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
  }) => NewInspectionState(
    status: status ?? this.status,
    templates: templates ?? this.templates,
    type: type ?? this.type,
    title: title ?? this.title,
    kmLabel: kmLabel ?? this.kmLabel,
    segmentCode: segmentCode ?? this.segmentCode,
    direction: direction ?? this.direction,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [
    status,
    templates,
    type,
    title,
    kmLabel,
    segmentCode,
    direction,
    saving,
    saved,
    showIssues,
    failed,
  ];
}

/// El formulario de un monitoreo nuevo (BBP §7.8, "Crear inspeccion"): el tipo
/// decide el checklist; el activo, el tramo y el kilometro son opcionales.
class NewInspectionCubit extends Cubit<NewInspectionState> {
  NewInspectionCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const NewInspectionState());

  final InspectionsRepository _repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(state.copyWith(status: NewInspectionStatus.loading));
    try {
      final templates = await _repository.templates();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: NewInspectionStatus.ready,
          templates: templates,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: NewInspectionStatus.failure));
    }
  }

  void setType(String v) => emit(state.copyWith(type: v));

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setSegment(String v) => emit(state.copyWith(segmentCode: v));

  void setDirection(String v) => emit(state.copyWith(direction: v));

  String? _blankToNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> save() async {
    if (state.saving) return;
    if (state.typeMissing) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, failed: false));
    try {
      final km = _blankToNull(state.kmLabel);
      await _repository.create(
        NewInspection(
          type: state.type!,
          title:
              _blankToNull(state.title) ??
              [state.type!, ?km].join(' · '),
          kmLabel: km,
          segmentCode: _blankToNull(state.segmentCode),
          direction: _blankToNull(state.direction),
          scheduledAt: _clock().toUtc(),
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
