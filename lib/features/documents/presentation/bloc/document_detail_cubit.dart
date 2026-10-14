import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/offline/operation.dart';
import '../../../../core/offline/sync_cubit.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/documents_repository.dart';

enum DocumentDetailStatus { loading, ready, failure }

/// Lo que paso al intentar firmar, para avisarlo una vez.
enum SignFeedback {
  /// El servidor confirmo la firma.
  signed,

  /// Sin conexion: la firma quedo en la cola y se aplicara al sincronizar.
  queued,

  /// Otra persona ya valido esta version.
  alreadySigned,

  /// El archivo guardado no coincide con el hash de la version.
  contentMismatch,

  /// La cuenta no tiene un perfil firmante en la concesion.
  signerProfileRequired,

  /// No se pudo firmar ni guardar para despues.
  failed,
}

class DocumentDetailState extends Equatable {
  const DocumentDetailState({
    this.status = DocumentDetailStatus.loading,
    this.detail,
    this.error,
    this.favoriteFailed = 0,
    this.signing = false,
    this.feedback,
    this.feedbackSeq = 0,
  });

  final DocumentDetailStatus status;
  final DocumentDetail? detail;
  final DocumentsError? error;
  final int favoriteFailed;

  /// Se esta firmando (el boton no se puede volver a tocar).
  final bool signing;

  /// El ultimo aviso de firma; [feedbackSeq] cambia con cada uno para que el
  /// mismo aviso dos veces se vuelva a mostrar.
  final SignFeedback? feedback;
  final int feedbackSeq;

  DocumentDetailState copyWith({
    DocumentDetailStatus? status,
    DocumentDetail? detail,
    DocumentsError? error,
    bool clearError = false,
    int? favoriteFailed,
    bool? signing,
    SignFeedback? feedback,
  }) => DocumentDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    error: clearError ? null : (error ?? this.error),
    favoriteFailed: favoriteFailed ?? this.favoriteFailed,
    signing: signing ?? this.signing,
    feedback: feedback ?? this.feedback,
    feedbackSeq: feedback == null ? feedbackSeq : feedbackSeq + 1,
  );

  @override
  List<Object?> get props => [
    status,
    detail,
    error,
    favoriteFailed,
    signing,
    feedback,
    feedbackSeq,
  ];
}

/// Ficha de un documento (DEV-MOB-070): la version vigente, sin historial. Desde
/// aqui se firma la version vigente (DEV-MOB-074, 075, 084).
class DocumentDetailCubit extends Cubit<DocumentDetailState> {
  DocumentDetailCubit(this._repository, this.id, {this._sync})
    : super(const DocumentDetailState());

  final DocumentsRepository _repository;
  final SyncCubit? _sync;
  final String id;

  Future<void> load() async {
    emit(
      state.copyWith(status: DocumentDetailStatus.loading, clearError: true),
    );
    try {
      final detail = await _repository.detail(id);
      if (isClosed) return;
      emit(state.copyWith(status: DocumentDetailStatus.ready, detail: detail));
    } on DocumentsException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: DocumentDetailStatus.failure, error: e.error),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DocumentDetailStatus.failure,
          error: DocumentsError.server,
        ),
      );
    }
  }

  Future<void> toggleFavorite() async {
    final current = state.detail;
    if (current == null) return;
    final target = !current.summary.isFavorite;
    emit(state.copyWith(detail: current.withFavorite(target)));
    try {
      await _repository.setFavorite(id, favorite: target);
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          detail: current,
          favoriteFailed: state.favoriteFailed + 1,
        ),
      );
    }
  }

  /// Firma la version vigente que se ve en la ficha. Con conexion la firma se
  /// confirma en el servidor; sin ella (o si la red falla a medias) queda
  /// pendiente en la cola con el documento, la version, su hash y la version
  /// base (DTF M03 §3.2) y no se presenta como firmada hasta que el servidor la
  /// acepte. Repetir la firma de la misma persona no crea otra.
  Future<void> sign({required bool online}) async {
    final current = state.detail;
    if (current == null || state.signing) return;
    emit(state.copyWith(signing: true));
    if (online) {
      try {
        final status = await _repository.sign(id, current.versionId);
        if (isClosed) return;
        emit(
          state.copyWith(
            detail: current.withSignature(status),
            signing: false,
            feedback: SignFeedback.signed,
          ),
        );
        return;
      } on DocumentsException catch (e) {
        if (isClosed) return;
        if (e.error != DocumentsError.network) {
          emit(state.copyWith(signing: false, feedback: _feedbackFor(e.error)));
          // Otra persona ya la firmo: la ficha debe decirlo.
          if (e.error == DocumentsError.alreadySigned) await load();
          return;
        }
        // Sin red a medias: se guarda para despues.
      } catch (_) {
        if (isClosed) return;
        emit(state.copyWith(signing: false, feedback: SignFeedback.failed));
        return;
      }
    }
    await _queue(current);
  }

  Future<void> _queue(DocumentDetail current) async {
    final sync = _sync;
    PendingOperation? operation;
    if (sync != null) {
      operation = await sync.enqueue(
        entity: 'documento_firma',
        kind: OperationKind.insert,
        recordId: id,
        baseVersion: current.version,
        payload: {
          'name': current.summary.name,
          'version': 'V${current.version}',
          'versionId': current.versionId,
          'checksum': current.checksum,
        },
        capturedAt: DateTime.now().toUtc(),
      );
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        signing: false,
        feedback: operation == null ? SignFeedback.failed : SignFeedback.queued,
      ),
    );
  }

  static SignFeedback _feedbackFor(DocumentsError error) => switch (error) {
    DocumentsError.alreadySigned => SignFeedback.alreadySigned,
    DocumentsError.contentMismatch => SignFeedback.contentMismatch,
    DocumentsError.signerProfileRequired => SignFeedback.signerProfileRequired,
    _ => SignFeedback.failed,
  };
}
