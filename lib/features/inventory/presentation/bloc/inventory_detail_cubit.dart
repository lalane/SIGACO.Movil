import 'dart:typed_data';

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
    this.photo,
  });

  final InventoryDetailStatus status;
  final InventoryAsset? asset;
  final InventoryError? error;

  /// La foto principal ("vista en sitio"); llega despues de la ficha.
  final Uint8List? photo;

  @override
  List<Object?> get props => [status, asset, error, photo];
}

/// La ficha de un activo.
class InventoryDetailCubit extends Cubit<InventoryDetailState> {
  InventoryDetailCubit(this._repository, this.assetId)
    : super(const InventoryDetailState());

  final InventoryRepository _repository;
  final String assetId;

  /// La foto no estorba a la ficha: si no baja, la ficha se queda sin ella.
  Future<void> _loadPhoto(InventoryAsset asset) async {
    if (asset.mainPhotoId == null) return;
    try {
      final photo = await _repository.mainPhoto(asset);
      if (isClosed || photo == null) return;
      emit(
        InventoryDetailState(
          status: InventoryDetailStatus.ready,
          asset: asset,
          photo: photo,
        ),
      );
    } catch (_) {
      // Sin foto.
    }
  }

  Future<void> load() async {
    try {
      final asset = await _repository.get(assetId);
      if (isClosed) return;
      emit(
        InventoryDetailState(status: InventoryDetailStatus.ready, asset: asset),
      );
      await _loadPhoto(asset);
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
