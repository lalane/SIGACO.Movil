import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/document_preview.dart';
import '../../domain/repositories/documents_repository.dart';

enum DocumentPreviewStatus { loading, ready, failure }

class DocumentPreviewState extends Equatable {
  const DocumentPreviewState({
    this.status = DocumentPreviewStatus.loading,
    this.preview,
    this.error,
  });

  final DocumentPreviewStatus status;
  final DocumentPreview? preview;
  final DocumentsError? error;

  @override
  List<Object?> get props => [status, preview, error];
}

/// Vista previa de un documento (DEV-MOB-071). Solo la representacion para ver,
/// nunca el original.
class DocumentPreviewCubit extends Cubit<DocumentPreviewState> {
  DocumentPreviewCubit(this._repository, this.id)
    : super(const DocumentPreviewState());

  final DocumentsRepository _repository;
  final String id;

  Future<void> load() async {
    emit(const DocumentPreviewState());
    try {
      final preview = await _repository.preview(id);
      if (isClosed) return;
      emit(
        DocumentPreviewState(
          status: DocumentPreviewStatus.ready,
          preview: preview,
        ),
      );
    } on DocumentsException catch (e) {
      if (isClosed) return;
      emit(
        DocumentPreviewState(
          status: DocumentPreviewStatus.failure,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const DocumentPreviewState(
          status: DocumentPreviewStatus.failure,
          error: DocumentsError.server,
        ),
      );
    }
  }
}
