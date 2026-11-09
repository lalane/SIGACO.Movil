import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/routed_sync_remote.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/api_asset_capture_repository.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/inventory_json.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/offline_asset_capture_repository.dart';
import 'package:sigaco_movil/features/inventory/data/sync/assets_sync_remote.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/asset_capture_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_api.dart';
import '../../support/fakes.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');
const _clientId = 'c0a80101-0000-4000-8000-0000000000aa';

/// Altas de activos capturadas sin red (contrato de Activos): se guardan en la
/// cola con su `clientUuid` y salen por `/api/sync/operations` cuando vuelve la
/// conexion; las fotos se suben despues al activo ya creado.
void main() {
  sqfliteFfiInit();

  late FakeApi api;
  late OfflineDatabase db;
  late OperationQueue queue;
  late ApiAssetCaptureRepository online;
  late MemoryFileStore files;
  late OfflineAssetCaptureRepository repo;
  String? sessionRoad;

  setUp(() async {
    api = FakeApi();
    sessionRoad = 'road-1';
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db);
    online = ApiAssetCaptureRepository(
      api.client(),
      roadId: () async => sessionRoad,
    );
    files = MemoryFileStore();
    repo = OfflineAssetCaptureRepository(online, queue, files);
    await repo.bind(_scope);
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
  });

  NewAsset draft({List<String> photos = const [], String? roadId}) => NewAsset(
    clientId: _clientId,
    typeCode: 'POSTE',
    typeLabel: 'Poste',
    capturedAt: DateTime.utc(2026, 11, 8, 15),
    roadId: roadId,
    kmStart: 150.2,
    direction: 'CRECIENTE',
    position: const AssetPosition(latitude: -18.85, longitude: -41.98),
    attributes: const {'altura_m': 7.5},
    photoPaths: photos,
  );

  group('captura sin red', () {
    test('con red sale directo y la cola queda vacia', () async {
      api.on(
        'POST /api/assets',
        const FakeReply(201, {
          'asset': {'id': 'a-1', 'code': 'POSTE-000001'},
        }),
      );
      final result = await repo.create(draft());
      expect(result.queued, isFalse);
      expect(result.id, 'a-1');
      expect(await queue.list(_scope), isEmpty);
    });

    test('sin red queda en la cola con su clave y se ve pendiente', () async {
      // Con red se aprendio la carretera (al abrir el formulario).
      await online.warmRoad();
      api.offline = true;

      final result = await repo.create(draft(photos: ['/tmp/foto.jpg']));

      expect(result.queued, isTrue);
      expect(result.id, _clientId);
      final op = (await queue.list(_scope)).single;
      expect(op.id, _clientId);
      expect(op.entity, 'ASSET');
      expect(op.kind, OperationKind.insert);
      expect(op.payload['assetTypeCode'], 'POSTE');
      expect(op.payload['roadId'], 'road-1');
      expect(op.payload['clientUuid'], _clientId);
      expect(op.payload['attributes'], {'altura_m': 7.5});
      // La foto se copio a un lugar propio de la app.
      expect(op.payload['_photos'], [files.kept.keys.single]);
      expect(op.payload['_name'], 'Poste · KM 150+200');

      final pending = await repo.pendingAssets();
      expect(pending.single.id, _clientId);
      expect(pending.single.pendingSync, isTrue);
      expect(pending.single.lifecycle, AssetLifecycle.pendingValidation);
      expect(pending.single.kmLabel, 'KM 150+200');
      expect(pending.single.category, 'Poste');
    });

    test('capturar dos veces el mismo formulario no duplica la cola', () async {
      await online.warmRoad();
      api.offline = true;
      await repo.create(draft());
      await repo.create(draft());
      expect(await queue.list(_scope), hasLength(1));
    });

    test(
      'sin saber la carretera no se guarda algo que el servidor rechazaria',
      () async {
        sessionRoad = null;
        api.offline = true;
        await expectLater(
          repo.create(draft()),
          throwsA(
            isA<AssetCaptureException>().having(
              (e) => e.error,
              'error',
              AssetCaptureError.network,
            ),
          ),
        );
        expect(await queue.list(_scope), isEmpty);
      },
    );

    test('un error que no es de red no se guarda en la cola', () async {
      api.on('POST /api/assets', const FakeReply(403));
      await expectLater(
        repo.create(draft(roadId: 'road-1')),
        throwsA(isA<AssetCaptureException>()),
      );
      expect(await queue.list(_scope), isEmpty);
    });
  });

  group('envio', () {
    late Directory dir;
    late File photo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('aso_');
      photo = File('${dir.path}/poste.jpg')..writeAsBytesSync([1, 2, 3]);
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // Lo recoge el sistema.
        }
      });
    });

    AssetsSyncRemote remote() =>
        AssetsSyncRemote(api.client(), online, () async => 'phone-1');

    Future<PendingOperation> queued({List<String> photos = const []}) async {
      api.offline = true;
      // MemoryFileStore solo anota: la cola guarda la ruta original.
      repo = OfflineAssetCaptureRepository(online, queue, _SameFiles());
      await repo.bind(_scope);
      await repo.create(draft(photos: photos, roadId: 'road-1'));
      api.offline = false;
      return (await queue.list(_scope)).single;
    }

    FakeReply result(String status, {String? recordId}) => FakeReply(200, {
      'serverTime': '2026-11-08T16:00:00Z',
      'operations': [
        {
          'idempotencyKey': _clientId,
          'status': status,
          'recordId': recordId,
          'result': null,
          'error': null,
          'conflictId': null,
          'clockSkewSeconds': 0,
        },
      ],
    });

    test(
      'manda el alta con su clave, sin datos propios, y sube las fotos',
      () async {
        final op = await queued(photos: [photo.path]);
        api.on(
          'POST /api/sync/operations',
          result('APLICADA', recordId: 'a-9'),
        );
        api.on(
          'POST /api/assets/a-9/attachments',
          const FakeReply(201, {'id': 'f-1'}),
        );
        api.on(
          'POST /api/assets/a-9/attachments/f-1/main',
          const FakeReply(200, {}),
        );

        final outcome = await remote().send(op);

        expect(outcome, isA<SyncAccepted>());
        final body = api.to('POST /api/sync/operations').single.data as Map;
        final sent = (body['operations'] as List).single as Map;
        expect(sent['idempotencyKey'], _clientId);
        expect(sent['entity'], 'ASSET');
        expect(sent['operation'], 'INSERT');
        final payload = sent['payload'] as Map;
        expect(payload['assetTypeCode'], 'POSTE');
        expect(payload.keys.where((k) => '$k'.startsWith('_')), isEmpty);
        // La foto lleva la misma clave que tendria con red: no se duplica.
        final upload = api.to('POST /api/assets/a-9/attachments').single;
        final fields = {
          for (final f in (upload.data as FormData).fields) f.key: f.value,
        };
        expect(fields['clientUuid'], InventoryJson.photoKey(_clientId, 0));
        expect(fields['latitude'], '-18.85');
      },
    );

    test('la foto que falla deja la operacion para reintentar', () async {
      final op = await queued(photos: [photo.path]);
      api.on('POST /api/sync/operations', result('APLICADA', recordId: 'a-9'));
      api.on(
        'POST /api/assets/a-9/attachments',
        const FakeReply(500, {'title': 'x'}),
      );
      expect(await remote().send(op), isA<SyncRetryLater>());
    });

    test(
      'el motor envia lo pendiente y deja de verse como pendiente',
      () async {
        final op = await queued();
        api.on(
          'POST /api/sync/operations',
          result('DUPLICADA', recordId: 'a-9'),
        );
        final engine = SyncEngine(queue, RoutedSyncRemote({'ASSET': remote()}));

        final report = await engine.run(_scope);

        expect(report.accepted, 1);
        expect((await queue.find(op.id))!.status, OperationStatus.accepted);
        expect(await repo.pendingAssets(), isEmpty);
      },
    );
  });
}

/// No copia nada: devuelve la misma ruta (la foto de la prueba ya esta en
/// disco).
class _SameFiles extends MemoryFileStore {
  @override
  Future<String> keep(String sourcePath, {required String name}) async =>
      sourcePath;
}
