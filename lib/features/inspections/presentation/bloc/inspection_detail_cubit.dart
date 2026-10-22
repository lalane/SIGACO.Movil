import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/finding_position_source.dart';
import '../../domain/repositories/inspections_repository.dart';

enum InspectionDetailStatus { loading, ready, failure }

class InspectionDetailState extends Equatable {
  const InspectionDetailState({
    this.status = InspectionDetailStatus.loading,
    this.inspection,
    this.error,
    this.actionError,
    this.busy = false,
    this.justCompleted = false,
    this.justSavedFinding = false,
  });

  final InspectionDetailStatus status;
  final Inspection? inspection;

  /// Por que no se pudo cargar (con [status] failure).
  final InspectionsError? error;

  /// Por que fallo la ultima accion (guardar, terminar); no tumba la ficha.
  final InspectionsError? actionError;

  /// Se esta guardando o terminando.
  final bool busy;

  /// Se acaba de terminar: la pantalla avisa una vez.
  final bool justCompleted;

  /// Se acaba de guardar un hallazgo: la pantalla avisa una vez.
  final bool justSavedFinding;

  InspectionDetailState copyWith({
    InspectionDetailStatus? status,
    Inspection? inspection,
    InspectionsError? error,
    InspectionsError? actionError,
    bool clearActionError = false,
    bool? busy,
    bool? justCompleted,
    bool? justSavedFinding,
  }) => InspectionDetailState(
    status: status ?? this.status,
    inspection: inspection ?? this.inspection,
    error: error ?? this.error,
    actionError: clearActionError ? null : (actionError ?? this.actionError),
    busy: busy ?? this.busy,
    justCompleted: justCompleted ?? this.justCompleted,
    justSavedFinding: justSavedFinding ?? this.justSavedFinding,
  );

  @override
  List<Object?> get props => [
    status,
    inspection,
    error,
    actionError,
    busy,
    justCompleted,
    justSavedFinding,
  ];
}

/// La ficha de una inspeccion y su checklist. Cada respuesta se ve al momento y
/// se guarda sola (eso es el borrador); los hallazgos se capturan con sus fotos
/// y la posicion del telefono; terminar exige el checklist completo.
class InspectionDetailCubit extends Cubit<InspectionDetailState> {
  InspectionDetailCubit(
    this._repository,
    this.inspectionId, {
    FindingPositionSource positionSource = const NoFindingPositionSource(),
    DateTime Function()? clock,
    String Function()? clientIdGenerator,
  }) : _positions = positionSource,
       _clock = clock ?? DateTime.now,
       _newId = clientIdGenerator ?? newClientId,
       super(const InspectionDetailState());

  final InspectionsRepository _repository;
  final String inspectionId;
  final FindingPositionSource _positions;
  final DateTime Function() _clock;
  final String Function() _newId;

  Future<void> load() async {
    try {
      final inspection = await _repository.get(inspectionId);
      if (isClosed) return;
      emit(
        InspectionDetailState(
          status: InspectionDetailStatus.ready,
          inspection: inspection,
        ),
      );
    } on InspectionsException catch (e) {
      if (isClosed) return;
      emit(
        InspectionDetailState(
          status: InspectionDetailStatus.failure,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const InspectionDetailState(
          status: InspectionDetailStatus.failure,
          error: InspectionsError.server,
        ),
      );
    }
  }

  /// Responde un punto del checklist. Se refleja de inmediato; si guardar falla,
  /// la respuesta se queda en pantalla y se avisa.
  Future<void> answer(String itemId, CheckResult result) async {
    final current = state.inspection;
    if (current == null || !current.editable || state.busy) return;
    final draft = current.withAnswers({itemId: result});
    emit(state.copyWith(inspection: draft, clearActionError: true));
    try {
      final saved = await _repository.saveAnswers(inspectionId, {
        for (final i in draft.checklist) i.id: i.result,
      });
      if (isClosed) return;
      emit(state.copyWith(inspection: saved));
    } on InspectionsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(actionError: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(actionError: InspectionsError.server));
    }
  }

  /// Termina la inspeccion; sin el checklist completo no hace nada.
  Future<void> complete() async {
    final current = state.inspection;
    if (current == null || !current.editable || state.busy) return;
    if (!current.complete) {
      emit(state.copyWith(actionError: InspectionsError.incomplete));
      return;
    }
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      final done = await _repository.complete(inspectionId, {
        for (final i in current.checklist) i.id: i.result,
      });
      if (isClosed) return;
      emit(state.copyWith(inspection: done, busy: false, justCompleted: true));
    } on InspectionsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, actionError: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, actionError: InspectionsError.server));
    }
  }

  /// La pantalla ya aviso que se termino.
  void completionShown() => emit(state.copyWith(justCompleted: false));

  /// Captura un hallazgo con su nota, sus fotos (hasta
  /// [InspectionFinding.maxPhotos]) y la posicion de ahora. Sin nota ni fotos no
  /// hace nada. Si no hay posicion el hallazgo se guarda igual, sin ella.
  Future<void> addFinding({
    String? itemId,
    String note = '',
    List<String> photoPaths = const [],
  }) async {
    final current = state.inspection;
    if (current == null || !current.editable || state.busy) return;
    final text = note.trim();
    final photos = photoPaths.take(InspectionFinding.maxPhotos).toList();
    if (text.isEmpty && photos.isEmpty) return;
    emit(state.copyWith(busy: true, clearActionError: true));
    FindingPosition? position;
    try {
      position = await _positions.current();
    } catch (_) {
      position = null;
    }
    try {
      final saved = await _repository.addFinding(
        inspectionId,
        InspectionFinding(
          id: _newId(),
          itemId: itemId,
          note: text,
          photoPaths: photos,
          position: position,
          capturedAt: _clock().toUtc(),
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(inspection: saved, busy: false, justSavedFinding: true),
      );
    } on InspectionsException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, actionError: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, actionError: InspectionsError.server));
    }
  }

  /// La pantalla ya aviso que se guardo el hallazgo.
  void findingShown() => emit(state.copyWith(justSavedFinding: false));
}
