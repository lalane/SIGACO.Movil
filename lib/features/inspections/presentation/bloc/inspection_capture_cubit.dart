import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inspection_capture.dart';
import '../../domain/repositories/finding_position_source.dart';
import '../../domain/repositories/inspection_capture_repository.dart';
import '../../domain/repositories/inspections_repository.dart';

enum CaptureStatus { loading, ready, failure }

/// Lo que paso con la ultima accion, para avisar en pantalla.
enum CaptureNotice {
  saved,
  savedOffline,
  finalized,
  finalizedOffline,
  accepted,
  rejected,
  started,
  photoAdded,
  findingAdded,
}

class InspectionCaptureState extends Equatable {
  const InspectionCaptureState({
    this.status = CaptureStatus.loading,
    this.view,
    this.answers = const {},
    this.dirty = false,
    this.busy = false,
    this.error,
    this.issues = const [],
    this.notice,
    this.failures = const [],
    this.askJustification,
  });

  final CaptureStatus status;
  final InspectionCaptureView? view;

  /// Lo que se esta llenando (puede no estar guardado aun).
  final Map<String, dynamic> answers;
  final bool dirty;
  final bool busy;
  final InspectionsError? error;

  /// Lo que falta para finalizar (del telefono o del servidor).
  final List<CaptureIssue> issues;
  final CaptureNotice? notice;
  final List<FailureChoice> failures;

  /// El servidor pide justificar la ubicacion: el mensaje con la distancia.
  final String? askJustification;

  InspectionCaptureState copyWith({
    CaptureStatus? status,
    InspectionCaptureView? view,
    Map<String, dynamic>? answers,
    bool? dirty,
    bool? busy,
    InspectionsError? error,
    bool clearError = false,
    List<CaptureIssue>? issues,
    CaptureNotice? notice,
    bool clearNotice = false,
    List<FailureChoice>? failures,
    String? askJustification,
    bool clearJustification = false,
  }) => InspectionCaptureState(
    status: status ?? this.status,
    view: view ?? this.view,
    answers: answers ?? this.answers,
    dirty: dirty ?? this.dirty,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    issues: issues ?? this.issues,
    notice: clearNotice ? null : (notice ?? this.notice),
    failures: failures ?? this.failures,
    askJustification: clearJustification
        ? null
        : (askJustification ?? this.askJustification),
  );

  @override
  List<Object?> get props => [
    status,
    view,
    answers,
    dirty,
    busy,
    error,
    issues,
    notice,
    failures,
    askJustification,
  ];
}

/// Captura en campo de una inspeccion con su plantilla (HU-08-07 a HU-08-10):
/// llenar por secciones, guardar borrador (sin red queda en la cola), fotos
/// con posicion por campo, hallazgos con falla y finalizar diciendo que falta.
class InspectionCaptureCubit extends Cubit<InspectionCaptureState> {
  InspectionCaptureCubit(
    this._repository,
    this._id, {
    FindingPositionSource positionSource = const NoFindingPositionSource(),
    DateTime Function()? clock,
  }) : _positions = positionSource,
       _clock = clock ?? DateTime.now,
       super(const InspectionCaptureState());

  final InspectionCaptureRepository _repository;
  final String _id;
  final FindingPositionSource _positions;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(state.copyWith(status: CaptureStatus.loading, clearError: true));
    try {
      final view = await _repository.capture(_id);
      _show(view);
      _loadFailures(view.typeId);
    } on InspectionsException catch (e) {
      emit(state.copyWith(status: CaptureStatus.failure, error: e.error));
    }
  }

  Future<void> _loadFailures(String typeId) async {
    try {
      final list = await _repository.failures(typeId);
      if (!isClosed) emit(state.copyWith(failures: list));
    } on InspectionsException {
      // Sin fallas a mano: el hallazgo se registra con severidad.
    }
  }

  void _show(InspectionCaptureView view, {CaptureNotice? notice}) {
    if (isClosed) return;
    emit(
      InspectionCaptureState(
        status: CaptureStatus.ready,
        view: view,
        answers: Map<String, dynamic>.from(view.answers),
        issues: view.missing,
        notice: notice,
        failures: state.failures,
      ),
    );
  }

  /// Cambia un valor en el formulario (sin guardarlo aun); [row] en secciones repetibles.
  void setValue(String section, String field, Object? value, {int? row}) {
    final answers = Map<String, dynamic>.from(state.answers);
    if (section.isEmpty) {
      answers[field] = value;
    } else if (row != null) {
      final rows = [
        for (final r in (answers[section] as List?) ?? const [])
          Map<String, dynamic>.from(r as Map),
      ];
      while (rows.length <= row) {
        rows.add(<String, dynamic>{});
      }
      rows[row][field] = value;
      answers[section] = rows;
    } else {
      final current = Map<String, dynamic>.from(
        (answers[section] as Map?) ?? const {},
      );
      current[field] = value;
      answers[section] = current;
    }
    _setAnswers(answers);
  }

  void addRow(String section) {
    final answers = Map<String, dynamic>.from(state.answers);
    answers[section] = [
      ...((answers[section] as List?) ?? const []),
      <String, dynamic>{},
    ];
    _setAnswers(answers);
  }

  void removeRow(String section, int row) {
    final answers = Map<String, dynamic>.from(state.answers);
    final rows = [...((answers[section] as List?) ?? const [])]..removeAt(row);
    answers[section] = rows;
    _setAnswers(answers);
  }

  void _setAnswers(Map<String, dynamic> answers) {
    final view = state.view;
    if (view == null) return;
    final preview = view.copyWith(answers: answers).recomputed();
    emit(
      state.copyWith(
        answers: answers,
        dirty: true,
        issues: preview.missing,
        view: view.copyWith(
          computedCondition: preview.computedCondition,
          computedNative: preview.computedNative,
        ),
        clearNotice: true,
      ),
    );
  }

  Future<void> save() => _run(() async {
    final saved = await _repository.save(state.view!, state.answers);
    _show(
      saved,
      notice: saved.pendingSync
          ? CaptureNotice.savedOffline
          : CaptureNotice.saved,
    );
  });

  Future<void> start() => _run(
    () async => _show(
      await _repository.start(_id, state.view!.rowVersion),
      notice: CaptureNotice.started,
    ),
  );

  Future<void> accept() => _run(
    () async => _show(
      await _repository.accept(state.view!),
      notice: CaptureNotice.accepted,
    ),
  );

  Future<void> reject(String reason) => _run(
    () async => _show(
      await _repository.reject(state.view!, reason),
      notice: CaptureNotice.rejected,
    ),
  );

  /// Foto de un campo de evidencia, con la posicion del telefono (RB-08-11).
  Future<void> addPhoto(String path, {String? fieldKey}) => _run(() async {
    final view = await _saveIfDirty();
    final position = await _positions.current();
    _show(
      await _repository.addPhoto(
        view,
        path,
        fieldKey: fieldKey,
        position: position,
        capturedAt: _clock().toUtc(),
      ),
      notice: CaptureNotice.photoAdded,
    );
  });

  Future<void> addFinding({
    required String description,
    String? failureCode,
    String? severity,
    List<String> photos = const [],
  }) => _run(() async {
    final view = await _saveIfDirty();
    final position = await _positions.current();
    _show(
      await _repository.addFinding(
        view,
        description: description,
        failureCode: failureCode,
        severity: severity,
        photoPaths: photos,
        position: position,
        capturedAt: _clock().toUtc(),
      ),
      notice: CaptureNotice.findingAdded,
    );
  });

  /// Finaliza: lo que falta se dice antes de enviar; fuera de la tolerancia pide justificacion.
  Future<void> finalize({String? justification}) async {
    final view = state.view;
    if (view == null || state.busy) return;
    emit(
      state.copyWith(
        busy: true,
        clearError: true,
        clearJustification: true,
        clearNotice: true,
      ),
    );
    try {
      final current = await _saveIfDirty();
      final position = await _positions.current();
      final done = await _repository.finalize(
        current,
        position: position,
        justification: justification,
        executedAt: _clock().toUtc(),
      );
      _show(
        done,
        notice: done.pendingSync
            ? CaptureNotice.finalizedOffline
            : CaptureNotice.finalized,
      );
    } on InspectionIncompleteException catch (e) {
      final location = e.location;
      emit(
        state.copyWith(
          busy: false,
          issues: location == null ? e.issues : state.issues,
          askJustification: location?.message,
          error: InspectionsError.incomplete,
        ),
      );
    } on InspectionsException catch (e) {
      emit(state.copyWith(busy: false, error: e.error));
    }
  }

  void dismissJustification() => emit(state.copyWith(clearJustification: true));

  Future<InspectionCaptureView> _saveIfDirty() async {
    if (!state.dirty) return state.view!;
    final saved = await _repository.save(state.view!, state.answers);
    emit(state.copyWith(view: saved, dirty: false));
    return saved;
  }

  Future<void> _run(Future<void> Function() body) async {
    if (state.view == null || state.busy) return;
    emit(state.copyWith(busy: true, clearError: true, clearNotice: true));
    try {
      await body();
    } on InspectionIncompleteException catch (e) {
      emit(
        state.copyWith(
          busy: false,
          issues: e.issues,
          error: InspectionsError.incomplete,
        ),
      );
    } on InspectionsException catch (e) {
      emit(state.copyWith(busy: false, error: e.error));
    }
  }
}
