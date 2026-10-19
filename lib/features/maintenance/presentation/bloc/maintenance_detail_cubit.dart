import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

enum MaintenanceDetailStatus { loading, ready, failure }

class MaintenanceDetailState extends Equatable {
  const MaintenanceDetailState({
    this.status = MaintenanceDetailStatus.loading,
    this.order,
    this.error,
  });

  final MaintenanceDetailStatus status;
  final MaintenanceOrder? order;
  final MaintenanceError? error;

  @override
  List<Object?> get props => [status, order, error];
}

/// La ficha de un mantenimiento.
class MaintenanceDetailCubit extends Cubit<MaintenanceDetailState> {
  MaintenanceDetailCubit(this._repository, this.orderId)
    : super(const MaintenanceDetailState());

  final MaintenanceRepository _repository;
  final String orderId;

  Future<void> load() async {
    try {
      final order = await _repository.get(orderId);
      if (isClosed) return;
      emit(
        MaintenanceDetailState(
          status: MaintenanceDetailStatus.ready,
          order: order,
        ),
      );
    } on MaintenanceException catch (e) {
      if (isClosed) return;
      emit(
        MaintenanceDetailState(
          status: MaintenanceDetailStatus.failure,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const MaintenanceDetailState(
          status: MaintenanceDetailStatus.failure,
          error: MaintenanceError.server,
        ),
      );
    }
  }
}
