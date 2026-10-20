import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryDetailStatus { loading, ready, failure }

class InventoryDetailState extends Equatable {
  const InventoryDetailState({
    this.status = InventoryDetailStatus.loading,
    this.asset,
    this.error,
  });

  final InventoryDetailStatus status;
  final InventoryAsset? asset;
  final InventoryError? error;

  @override
  List<Object?> get props => [status, asset, error];
}

/// La ficha de un activo.
class InventoryDetailCubit extends Cubit<InventoryDetailState> {
  InventoryDetailCubit(this._repository, this.assetId)
    : super(const InventoryDetailState());

  final InventoryRepository _repository;
  final String assetId;

  Future<void> load() async {
    try {
      final asset = await _repository.get(assetId);
      if (isClosed) return;
      emit(
        InventoryDetailState(status: InventoryDetailStatus.ready, asset: asset),
      );
    } on InventoryException catch (e) {
      if (isClosed) return;
      emit(
        InventoryDetailState(
          status: InventoryDetailStatus.failure,
          error: e.error,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const InventoryDetailState(
          status: InventoryDetailStatus.failure,
          error: InventoryError.server,
        ),
      );
    }
  }
}
