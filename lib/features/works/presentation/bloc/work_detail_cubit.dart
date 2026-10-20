import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';

enum WorkDetailStatus { loading, ready, failure }

class WorkDetailState extends Equatable {
  const WorkDetailState({
    this.status = WorkDetailStatus.loading,
    this.work,
    this.error,
  });

  final WorkDetailStatus status;
  final PublicWork? work;
  final WorksError? error;

  @override
  List<Object?> get props => [status, work, error];
}

/// La ficha de una obra.
class WorkDetailCubit extends Cubit<WorkDetailState> {
  WorkDetailCubit(this._repository, this.workId)
    : super(const WorkDetailState());

  final WorksRepository _repository;
  final String workId;

  Future<void> load() async {
    try {
      final work = await _repository.get(workId);
      if (isClosed) return;
      emit(WorkDetailState(status: WorkDetailStatus.ready, work: work));
    } on WorksException catch (e) {
      if (isClosed) return;
      emit(WorkDetailState(status: WorkDetailStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        const WorkDetailState(
          status: WorkDetailStatus.failure,
          error: WorksError.server,
        ),
      );
    }
  }
}
