import 'dart:async';

import '../../../../core/files/local_file_store.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/operation_queue.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/asset_capture_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'api_asset_capture_repository.dart';
import 'inventory_json.dart';

/// El alta de activos que no se pierde sin red: si el activo no puede enviarse
/// porque no hay conexion, queda en la cola local con su clave (`clientUuid`) y
/// sale por `/api/sync/operations` cuando vuelve la senal; las fotos se suben
/// despues, al activo ya creado. Cualquier otro fallo se avisa como siempre.
///
/// Para armar un alta sin red hace falta haber visto antes los tipos, la ficha y
/// la carretera de la concesion: al abrir el formulario con red se aprenden (y
/// quedan guardados en el telefono).
class OfflineAssetCaptureRepository
    implements AssetCaptureRepository, PendingAssetsSource, ScopeBound {
  OfflineAssetCaptureRepository(this._online, this._queue, this._files);

  final ApiAssetCaptureRepository _online;
  final OperationQueue _queue;
  final LocalFileStore _files;
  OfflineScope? _scope;

  /// El tipo de operacion de la cola, con el nombre que le da el servidor
  /// (`SyncEntities.Asset`).
  static const assetEntity = 'ASSET';

  /// Datos propios de la app dentro de lo que se guarda en la cola; no viajan al
  /// servidor (empiezan con guion bajo).
  static const photosKey = '_photos';
  static const atKey = '_at';
  static const latKey = '_lat';
  static const lngKey = '_lng';
  static const nameKey = '_name';
  static const typeLabelKey = '_type';

  @override
  Future<void> bind(OfflineScope? scope) async => _scope = scope;

  @override
  Future<void> clear() async {}

  @override
  Future<List<AssetTypeOption>> types() async {
    final types = await _online.types();
    // Se aprende la carretera mientras hay red, por si el alta sale sin ella.
    unawaited(_online.warmRoad());
    return types;
  }

  @override
  Future<AssetTemplate> template(String typeCode) => _online.template(typeCode);

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() => _online.catalogs();

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) =>
      _online.locate(longitude, latitude);

  @override
  Future<CapturedAsset> create(NewAsset draft) async {
    try {
      return await _online.create(draft);
    } on AssetCaptureException catch (e) {
      final scope = _scope;
      if (e.error != AssetCaptureError.network || scope == null) rethrow;
      final body = await _online.body(draft);
      // Sin carretera el servidor lo rechazaria: se avisa ahora, no despues.
      if (body['roadId'] == null) rethrow;
      final photos = await _keep(draft.photoPaths);
      final position = draft.position;
      final label = draft.typeLabel ?? draft.typeCode;
      await _queue.enqueue(
        scope,
        entity: assetEntity,
        kind: OperationKind.insert,
        key: draft.clientId,
        capturedAt: draft.capturedAt,
        payload: {
          ...body,
          if (photos.isNotEmpty) photosKey: photos,
          atKey: draft.capturedAt.toUtc().toIso8601String(),
          latKey: ?position?.latitude,
          lngKey: ?position?.longitude,
          nameKey: [label, ?kmLabel(draft.kmStart, draft.kmEnd)].join(' · '),
          typeLabelKey: label,
        },
      );
      return CapturedAsset(id: draft.clientId, queued: true);
    }
  }

  /// Las fotos se copian a un lugar propio: las de la camara pueden ser
  /// temporales y la cola las necesita dias despues.
  Future<List<String>> _keep(List<String> paths) async {
    final kept = <String>[];
    for (final path in paths) {
      final name = path.split(RegExp(r'[\\/]')).last;
      try {
        kept.add(await _files.keep(path, name: name));
      } catch (_) {
        // Una foto que no se pudo copiar no detiene el alta.
      }
    }
    return kept;
  }

  /// Las altas que siguen en el telefono (por enviar, rechazadas o en
  /// conflicto), como activos "Pendiente de validacion" sin enviar.
  @override
  Future<List<InventoryAsset>> pendingAssets() async {
    final scope = _scope;
    if (scope == null) return const [];
    final ops = await _queue.list(
      scope,
      statuses: {
        OperationStatus.pending,
        OperationStatus.sending,
        OperationStatus.rejected,
        OperationStatus.conflict,
      },
      newestFirst: true,
    );
    return [
      for (final op in ops)
        if (op.entity == assetEntity && op.kind == OperationKind.insert)
          pendingAsset(op),
    ];
  }

  /// Un alta de la cola vista como activo.
  static InventoryAsset pendingAsset(PendingOperation op) {
    final m = op.payload;
    final type =
        InventoryJson.text(m[typeLabelKey]) ??
        InventoryJson.text(m['assetTypeCode']) ??
        '';
    final kmStart = InventoryJson.number(m['kmStart']);
    final kmEnd = InventoryJson.number(m['kmEnd']);
    return InventoryAsset(
      id: op.id,
      name: type,
      category: type,
      typeCode: InventoryJson.text(m['assetTypeCode']),
      condition: AssetCondition.unknown,
      lifecycle: AssetLifecycle.pendingValidation,
      kmLabel: kmLabel(kmStart, kmEnd),
      direction: InventoryJson.text(m['direction']),
      latitude: InventoryJson.number(m[latKey]),
      longitude: InventoryJson.number(m[lngKey]),
      description: InventoryJson.text(m['description']),
      notes: InventoryJson.text(m['notes']),
      attributes: InventoryJson.map(m['attributes']) ?? const {},
      source: 'MOVIL',
      pendingSync: true,
    );
  }
}
