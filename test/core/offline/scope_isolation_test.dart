import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/sync_revalidation.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/core/session/session_scope.dart';
import 'package:sigaco_movil/features/documents/data/cache/documents_cache.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fakes.dart';

const _anaC1 = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaC2 = OfflineScope(userId: 'ana', concessionId: 'c2');
const _luisC1 = OfflineScope(userId: 'luis', concessionId: 'c1');

class _Remote implements SyncRemote {
  final sent = <String>[];

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    sent.add('${operation.scope.userId}/${operation.scope.concessionId}');
    return const SyncAccepted();
  }
}

DocumentSummary _doc(String id) => DocumentSummary(
  id: id,
  name: '$id.pdf',
  typeCode: 'TD01',
  typeLabel: 'Informe',
  ownerUsername: 'ana',
  modifiedAt: DateTime.utc(2026, 10, 10),
);

/// Pruebas de aislamiento de cache y de operaciones pendientes por persona y
/// concesion (DEV-MOB-053, HU-TR-02-01, RN-CTX-02): lo capturado y lo consultado
/// en un ambiente nunca se ve ni se envia desde otro.
void main() {
  sqfliteFfiInit();

  late OfflineDatabase db;
  late OperationQueue queue;
  late Directory cacheDir;

  setUp(() async {
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db);
    cacheDir = await Directory.systemTemp.createTemp('isolation_test');
  });

  tearDown(() async {
    await db.close();
    if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
  });

  Future<PendingOperation> capture(OfflineScope scope, String entity) =>
      queue.enqueue(
        scope,
        entity: entity,
        kind: OperationKind.insert,
        payload: {'name': '$entity-${scope.concessionId}.pdf'},
      );

  test('un envio solo manda lo de la persona y concesion activas', () async {
    await capture(_anaC1, 'documento');
    await capture(_anaC2, 'documento');
    await capture(_luisC1, 'documento');
    final remote = _Remote();
    final engine = SyncEngine(queue, remote);

    await engine.run(_anaC2);

    expect(remote.sent, ['ana/c2']);
    expect(
      (await queue.list(_anaC1, statuses: {OperationStatus.pending})).length,
      1,
    );
    expect(
      (await queue.list(_luisC1, statuses: {OperationStatus.pending})).length,
      1,
    );
  });

  test('revalidar los permisos de un ambiente no toca los de otro', () async {
    final mine = await capture(_anaC1, 'documento_firma');
    final other = await capture(_anaC2, 'documento_firma');
    final revalidation = SyncRevalidation(
      revalidate: () async => fakeRevalidation(),
      queue: queue,
      requiredPermissions: const {
        'documento_firma': [PermissionKeys.documentsSign],
      },
    );

    await revalidation(_anaC1);

    expect((await queue.find(mine.id))!.status, OperationStatus.rejected);
    expect((await queue.find(other.id))!.status, OperationStatus.pending);
  });

  test('cambiar de concesion muestra solo lo pendiente de la nueva', () async {
    await capture(_anaC1, 'documento');
    await capture(_anaC2, 'documento_firma');
    await capture(_anaC2, 'documento');
    final cubit = SyncCubit(queue, SyncEngine(queue, _Remote()));
    addTearDown(cubit.close);
    cubit.setOnline(false);

    await cubit.setScope(_anaC1);
    expect(cubit.state.items.map((o) => o.entity), ['documento']);

    await cubit.setScope(_anaC2);
    expect(cubit.state.items.map((o) => o.entity), [
      'documento_firma',
      'documento',
    ]);

    await cubit.setScope(null);
    expect(cubit.state.items, isEmpty);
    // Cerrar sesion no borra lo capturado: sigue guardado para esa persona.
    expect(
      (await queue.list(_anaC1, statuses: {OperationStatus.pending})).length,
      1,
    );
  });

  test('descartar en un ambiente no borra los archivos de otro', () async {
    final mine = await queue.enqueue(
      _anaC1,
      entity: 'documento',
      kind: OperationKind.insert,
      payload: {'name': 'a.pdf', 'localPath': '/kept/c1/a.pdf'},
    );
    await queue.enqueue(
      _anaC2,
      entity: 'documento',
      kind: OperationKind.insert,
      payload: {'name': 'b.pdf', 'localPath': '/kept/c2/b.pdf'},
    );
    final removed = <String>[];
    final cubit = SyncCubit(
      queue,
      SyncEngine(queue, _Remote()),
      onDiscarded: (op) async => removed.add('${op.payload['localPath']}'),
    );
    addTearDown(cubit.close);

    await cubit.discard(mine.id);

    expect(removed, ['/kept/c1/a.pdf']);
    expect((await queue.list(_anaC2)).length, 1);
  });

  group('lo consultado (cache) y lo capturado (cola) son de cosas distintas', () {
    late FileDocumentsCache cache;

    setUp(() async {
      cache = FileDocumentsCache(root: () async => cacheDir);
      await cache.bind(_anaC1);
      await cache.saveList(const DocumentQuery(), [_doc('a')]);
      await capture(_anaC1, 'documento');
    });

    test(
      'al cambiar de concesion se vacia lo consultado, no lo capturado',
      () async {
        await cache.bind(_anaC2);

        expect(await cache.readList(const DocumentQuery()), isNull);
        // La captura de la otra concesion sigue esperando su turno.
        expect(
          (await queue.list(
            _anaC1,
            statuses: {OperationStatus.pending},
          )).length,
          1,
        );
      },
    );

    test('al cerrar sesion se vacia lo consultado, no lo capturado', () async {
      await cache.bind(null);
      await cache.bind(_anaC1);

      expect(await cache.readList(const DocumentQuery()), isNull);
      expect(
        (await queue.list(_anaC1, statuses: {OperationStatus.pending})).length,
        1,
      );
    });

    test(
      'otra persona en el mismo telefono no ve ni lo consultado ni lo capturado',
      () async {
        await cache.bind(_luisC1);

        expect(await cache.readList(const DocumentQuery()), isNull);
        expect(await queue.list(_luisC1), isEmpty);
      },
    );

    test(
      'el registro de sesion vacia el cache al cambiar de ambiente',
      () async {
        final scope = SessionScope()..register(cache);

        await scope.bind(_anaC2);

        expect(await cache.readList(const DocumentQuery()), isNull);
      },
    );
  });
}
