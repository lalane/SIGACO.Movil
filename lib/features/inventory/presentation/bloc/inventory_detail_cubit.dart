import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryDetailStatus { loading, ready, failure }

class InventoryDetailState extends Equatable {
  const InventoryDetailState({
    this.status = InventoryDetailStatus.loading,
    this.asset,
    this.error,
    this.photo,
    this.photos = const [],
    this.catalogs = const {},
  });

  final InventoryDetailStatus status;
  final InventoryAsset? asset;
  final InventoryError? error;

  /// La foto principal ("vista en sitio"); llega despues de la ficha.
  final Uint8List? photo;

  /// Las demas fotos, ya en el telefono (rutas locales); llegan al final.
  final List<String> photos;

  /// Los valores de catalogo, para nombrar los campos CATALOG de la ficha.
  final Map<String, List<CatalogOption>> catalogs;

  /// El nombre de un valor de catalogo en el idioma de la app; null si no se
  /// conoce.
  String? catalogLabel(String catalog, String code, String language) {
    for (final o
        in catalogs[catalog.toUpperCase()] ?? const <CatalogOption>[]) {
      if (o.code == code.toUpperCase()) return o.label(language);
    }
    return null;
  }

  InventoryDetailState copyWith({
    InventoryAsset? asset,
    Uint8List? photo,
    List<String>? photos,
    Map<String, List<CatalogOption>>? catalogs,
  }) => InventoryDetailState(
    status: status,
    asset: asset ?? this.asset,
    error: error,
    photo: photo ?? this.photo,
    photos: photos ?? this.photos,
    catalogs: catalogs ?? this.catalogs,
  );

  @override
  List<Object?> get props => [status, asset, error, photo, photos, catalogs];
}

/// La ficha de un activo: los datos primero; despues, si hacen falta, la ficha
/// de su tipo (para nombrar los campos) y las fotos. Nada de eso estorba a la
/// ficha: si no llega, la ficha se queda sin ello.
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
      emit(state.copyWith(photo: photo));
    } catch (_) {
      // Sin foto.
    }
  }

  /// La ficha del tipo, si el activo no la trae.
  Future<void> _loadTemplate(InventoryAsset asset) async {
    final source = _repository;
    final type = asset.typeCode;
    if (asset.template != null || type == null) return;
    if (source is! AssetTemplateSource) return;
    try {
      final template = await (source as AssetTemplateSource).template(type);
      if (isClosed || template == null) return;
      emit(state.copyWith(asset: state.asset?.withTemplate(template)));
    } catch (_) {
      // Sin ficha: los campos se muestran con su clave.
    }
  }

  /// Los nombres de los valores de catalogo, si la ficha tiene campos CATALOG.
  Future<void> _loadCatalogs() async {
    final source = _repository;
    final template = state.asset?.template;
    if (source is! AssetCatalogSource || template == null) return;
    if (!template.attributes.any((a) => a.type == AttributeType.catalog)) {
      return;
    }
    try {
      final catalogs = await (source as AssetCatalogSource).catalogs();
      if (isClosed || catalogs.isEmpty) return;
      emit(state.copyWith(catalogs: catalogs));
    } catch (_) {
      // Se muestran los codigos.
    }
  }

  Future<void> _loadGallery(InventoryAsset asset) async {
    final source = _repository;
    if (source is! AssetPhotosSource) return;
    try {
      final photos = await (source as AssetPhotosSource).photos(asset);
      if (isClosed || photos.isEmpty) return;
      emit(state.copyWith(photos: photos));
    } catch (_) {
      // Sin galeria.
    }
  }

  Future<void> load() async {
    try {
      final asset = await _repository.get(assetId);
      if (isClosed) return;
      emit(
        InventoryDetailState(status: InventoryDetailStatus.ready, asset: asset),
      );
      await _loadTemplate(asset);
      await _loadCatalogs();
      await _loadPhoto(asset);
      await _loadGallery(asset);
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
