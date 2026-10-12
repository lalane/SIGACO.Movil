import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/documents_repository.dart';

enum DocumentDetailStatus { loading, ready, failure }

class DocumentDetailState extends Equatable {
  const DocumentDetailState({
    this.status = DocumentDetailStatus.loading,
    this.detail,
    this.error,
    this.favoriteFailed = 0,
  });

  final DocumentDetailStatus status;
  final DocumentDetail? detail;
  final DocumentsError? error;
  final int favoriteFailed;

  DocumentDetailState copyWith({
    DocumentDetailStatus? status,
    DocumentDetail? detail,
    DocumentsError? error,
    bool clearError = false,
    int? favoriteFailed,
  }) => DocumentDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    error: clearError ? null : (error ?? this.error),
    favoriteFailed: favoriteFailed ?? this.favoriteFailed,
  );

  @override
  List<Object?> get props => [status, detail, error, favoriteFailed];
}

/// Ficha de un documento (DEV-MOB-070): la version vigente, sin historial.
class DocumentDetailCubit extends Cubit<DocumentDetailState> {
  DocumentDetailCubit(this._repository, this.id)
    : super(const DocumentDetailState());

  final DocumentsRepository _repository;
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
}
