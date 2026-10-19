import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

enum AccidentDetailStatus { loading, ready, failure }

class AccidentDetailState extends Equatable {
  const AccidentDetailState({
    this.status = AccidentDetailStatus.loading,
    this.accident,
    this.error,
  });

  final AccidentDetailStatus status;
  final Accident? accident;
  final AccidentsError? error;

  @override
  List<Object?> get props => [status, accident, error];
}

/// La ficha de un accidente.
class AccidentDetailCubit extends Cubit<AccidentDetailState> {
  AccidentDetailCubit(this._repository, this.accidentId)
    : super(const AccidentDetailState());

  final AccidentsRepository _repository;
  final String accidentId;

  Future<void> load() async {
    try {
      final accident = await _repository.get(accidentId);
      if (isClosed) return;
      emit(
        AccidentDetailState(
          status: AccidentDetailStatus.ready,
          accident: accident,
        ),
      );
    } on AccidentsException catch (e) {
      if (isClosed) return;
      emit(
        AccidentDetailState(
          status: AccidentDetailStatus.failure,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const AccidentDetailState(
          status: AccidentDetailStatus.failure,
          error: AccidentsError.server,
        ),
      );
    }
  }
}
