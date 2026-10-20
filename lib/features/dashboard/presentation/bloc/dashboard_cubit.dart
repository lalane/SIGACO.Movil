import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

enum DashboardStatus { loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({this.status = DashboardStatus.loading, this.summary});

  final DashboardStatus status;
  final DashboardSummary? summary;

  @override
  List<Object?> get props => [status, summary];
}

/// El resumen operativo: carga y se vuelve a pedir al jalar o reintentar.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;

  Future<void> load() async {
    emit(const DashboardState());
    await refresh();
  }

  /// Vuelve a consultar sin borrar lo que ya se ve.
  Future<void> refresh() async {
    try {
      final summary = await _repository.load();
      if (isClosed) return;
      emit(DashboardState(status: DashboardStatus.ready, summary: summary));
    } catch (_) {
      if (isClosed) return;
      emit(
        DashboardState(status: DashboardStatus.failure, summary: state.summary),
      );
    }
  }
}
