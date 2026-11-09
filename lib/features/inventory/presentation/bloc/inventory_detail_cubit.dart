import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

enum InventoryDetailStatus { loading, ready, failure }

enum AssetHistoryStatus { loading, ready, failure }

/// Un tipo de la historia operativa en la ficha: sus ultimos registros y
/// cuantos hay.
class AssetHistorySection extends Equatable {
  const AssetHistorySection({
    required this.count,
    this.status = AssetHistoryStatus.loading,
    this.items = const [],
  });

  /// Abiertos y total, de la ficha del activo.
  final AssetHistoryCount count;
  final AssetHistoryStatus status;

  /// Los ultimos registros, del mas reciente al mas viejo.
  final List<AssetHistoryEntry> items;

  @override
  List<Object?> get props => [count, status, items];
}

class InventoryDetailState extends Equatable {
  const InventoryDetailState({
    this.status = InventoryDetailStatus.loading,
    this.asset,
    this.error,
    this.photo,
    this.photos = const [],
    this.catalogs = const {},
    this.history = const {},
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

  /// La historia operativa, por tipo, solo de los modulos que la persona puede
  /// ver; vacia si el servidor no da los conteos.
  final Map<AssetHistoryKind, AssetHistorySection> history;

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
    Map<AssetHistoryKind, AssetHistorySection>? history,
  }) => InventoryDetailState(
    status: status,
    asset: asset ?? this.asset,
    error: error,
    photo: photo ?? this.photo,
    photos: photos ?? this.photos,
    catalogs: catalogs ?? this.catalogs,
    history: history ?? this.history,
  );

  @override
  List<Object?> get props => [
    status,
    asset,
    error,
    photo,
    photos,
    catalogs,
    history,
  ];
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

  /// Cuantos registros de cada tipo se muestran en la ficha.
  static const historyLimit = 5;

  /// La historia operativa: con los conteos de la ficha se pintan los tipos que
  /// la persona puede ver y se piden los ultimos registros de los que tienen
  /// alguno. Un tipo que no baja se queda con su conteo y un aviso.
  Future<void> _loadHistory(InventoryAsset asset) async {
    final counts = asset.history;
    if (counts == null || asset.pendingSync) return;
    final kinds = counts.visible;
    if (kinds.isEmpty) return;
    final source = _repository;
    final canList = source is AssetHistorySource;
    emit(
      state.copyWith(
        history: {
          for (final k in kinds)
            k: AssetHistorySection(
              count: counts.of(k)!,
              status: counts.of(k)!.total == 0
                  ? AssetHistoryStatus.ready
                  : canList
                  ? AssetHistoryStatus.loading
                  : AssetHistoryStatus.failure,
            ),
        },
      ),
    );
    if (!canList) return;
    Future<void> fetch(AssetHistoryKind kind) async {
      final count = counts.of(kind)!;
      AssetHistorySection section;
      try {
        final page = await (source as AssetHistorySource).history(
          asset.id,
          kind,
          limit: historyLimit,
        );
        section = AssetHistorySection(
          count: AssetHistoryCount(
            open: count.open,
            total: page.total < page.items.length
                ? page.items.length
                : page.total,
          ),
          status: AssetHistoryStatus.ready,
          items: page.items,
        );
      } catch (_) {
        section = AssetHistorySection(
          count: count,
          status: AssetHistoryStatus.failure,
        );
      }
      if (isClosed) return;
      emit(state.copyWith(history: {...state.history, kind: section}));
    }

    await Future.wait([
      for (final k in kinds)
        if (counts.of(k)!.total > 0) fetch(k),
    ]);
  }

  /// Despues de levantar un ticket desde la ficha: el activo (sus conteos y si
  /// esta en mantenimiento) y su historia, sin volver a pedir la ficha del tipo
  /// ni las fotos. Si no se puede, la ficha se queda como estaba.
  Future<void> refresh() async {
    if (state.asset == null) return;
    try {
      final fresh = await _repository.get(assetId);
      if (isClosed) return;
      final asset = fresh.template == null
          ? fresh.withTemplate(state.asset?.template)
          : fresh;
      emit(state.copyWith(asset: asset));
      await _loadHistory(asset);
    } catch (_) {
      // Sin red: se queda lo que ya se veia.
    }
  }

  Future<void> load() async {
    try {
      final asset = await _repository.get(assetId);
      if (isClosed) return;
      emit(
        InventoryDetailState(status: InventoryDetailStatus.ready, asset: asset),
      );
      // La historia no espera a la ficha del tipo ni a las fotos.
      final history = _loadHistory(asset);
      await _loadTemplate(asset);
      await _loadCatalogs();
      await _loadPhoto(asset);
      await _loadGallery(asset);
      await history;
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
