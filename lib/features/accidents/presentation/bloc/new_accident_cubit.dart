import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

/// Cuantas fotos admite el registro (las del mockup).
const accidentPhotoSlots = 3;

enum NewAccidentIssue { title, type, severity }

class NewAccidentState extends Equatable {
  const NewAccidentState({
    this.title = '',
    this.type,
    this.severity,
    this.kmLabel = '',
    this.description = '',
    this.photos = const [null, null, null],
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
  });

  final String title;
  final AccidentType? type;
  final AccidentSeverity? severity;
  final String kmLabel;
  final String description;
  final List<String?> photos;
  final bool saving;
  final bool saved;

  /// Se activa al intentar guardar: antes no se regana por un campo vacio.
  final bool showIssues;
  final bool failed;

  List<NewAccidentIssue> get issues => [
    if (title.trim().isEmpty) NewAccidentIssue.title,
    if (type == null) NewAccidentIssue.type,
    if (severity == null) NewAccidentIssue.severity,
  ];

  NewAccidentState copyWith({
    String? title,
    AccidentType? type,
    AccidentSeverity? severity,
    String? kmLabel,
    String? description,
    List<String?>? photos,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
  }) => NewAccidentState(
    title: title ?? this.title,
    type: type ?? this.type,
    severity: severity ?? this.severity,
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
    title,
    type,
    severity,
    kmLabel,
    description,
    photos,
    saving,
    saved,
    showIssues,
    failed,
  ];
}

/// El formulario de un accidente nuevo.
class NewAccidentCubit extends Cubit<NewAccidentState> {
  NewAccidentCubit(
    this._repository, {
    DateTime Function()? clock,
    String Function()? clientIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       super(const NewAccidentState()) {
    _clientId = (clientIdGenerator ?? newClientId)();
    // La hora del registro es la de abrir el formulario, en UTC.
    _capturedAt = _clock().toUtc();
  }

  final AccidentsRepository _repository;
  final DateTime Function() _clock;
  late final DateTime _capturedAt;
  late final String _clientId;

  /// Identificador unico de este registro (`cliente_uuid`).
  String get clientId => _clientId;

  /// Cuando se abrio el formulario, en UTC.
  DateTime get capturedAt => _capturedAt;

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setType(AccidentType v) => emit(state.copyWith(type: v));

  void setSeverity(AccidentSeverity v) => emit(state.copyWith(severity: v));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  void setPhoto(int slot, String? path) {
    if (slot < 0 || slot >= accidentPhotoSlots) return;
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
    try {
      await _repository.create(
        NewAccident(
          title: state.title.trim(),
          type: state.type!,
          severity: state.severity!,
          kmLabel: state.kmLabel.trim().isEmpty ? null : state.kmLabel.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          photoPaths: [for (final p in state.photos) ?p],
          capturedAt: _capturedAt,
          deviceClockAt: _clock().toUtc(),
          clientId: _clientId,
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
