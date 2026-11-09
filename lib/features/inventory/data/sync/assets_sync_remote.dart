import '../../../../core/api/api_client.dart';
import '../../../../core/offline/api_sync_remote.dart';
import '../../../../core/offline/operation.dart';
import '../../domain/entities/asset_capture.dart';
import '../repositories/api_asset_capture_repository.dart';
import '../repositories/offline_asset_capture_repository.dart';

/// Envia al servidor las altas de activos capturadas sin conexion (ver
/// [ApiSyncRemote]). La clave de la operacion es el `clientUuid` del activo:
/// reenviarla devuelve el mismo activo. Las fotos no viajan en el lote: se suben
/// al activo ya creado, cada una con su propia clave.
class AssetsSyncRemote extends ApiSyncRemote {
  AssetsSyncRemote(
    ApiClient api,
    this._assets,
    Future<String?> Function() deviceIdentifier,
  ) : super(api, deviceIdentifier);

  final ApiAssetCaptureRepository _assets;

  @override
  Set<String> get entities => const {OfflineAssetCaptureRepository.assetEntity};

  @override
  Future<void> afterApplied(
    PendingOperation operation,
    String? recordId,
  ) async {
    final payload = operation.payload;
    final photos = [
      for (final p
          in (payload[OfflineAssetCaptureRepository.photosKey] as List?) ??
              const [])
        if (p is String) p,
    ];
    if (recordId == null || photos.isEmpty) return;
    final lat = payload[OfflineAssetCaptureRepository.latKey];
    final lng = payload[OfflineAssetCaptureRepository.lngKey];
    await _assets.attachPhotos(
      recordId,
      operation.id,
      photos,
      capturedAt:
          DateTime.tryParse(
            '${payload[OfflineAssetCaptureRepository.atKey] ?? ''}',
          ) ??
          operation.capturedAt,
      position: lat is num && lng is num
          ? AssetPosition(latitude: lat.toDouble(), longitude: lng.toDouble())
          : null,
    );
  }
}
