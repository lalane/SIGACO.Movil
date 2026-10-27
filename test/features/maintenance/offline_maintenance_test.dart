import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/api_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/offline_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/sync/maintenance_sync_remote.dart';
import 'package:sigaco_movil/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_api.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');
const _id = '3f2b8a52-0000-4000-8000-000000000010';
const _clientId = 'c0a80101-0000-4000-8000-000000000002';

Map<String, Object?> _dto() => {
  'id': _id,
  'folio': 'MP-1',
  'subsystemCode': 'SGS',
  'activity': 'Revision de luminarias',
  'location': 'Tunel Norte',
  'status': 'EN_EJECUCION',
  'totalVolume': 100,
  'executedVolume': 64,
  'unit': 'PZA',
};

/// El avance de mantenimiento capturado sin red: se guarda en la cola y sale por
/// `/api/sync/operations` cuando vuelve la conexion.
void main() {
  sqfliteFfiInit();

  late FakeApi api;
  late OfflineDatabase db;
  late OperationQueue queue;
  late OfflineMaintenanceRepository repo;

  setUp(() async {
    api = FakeApi()
      ..on('GET /api/preventive-maintenance/$_id', FakeReply(200, _dto()));
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db);
    repo = OfflineMaintenanceRepository(
      ApiMaintenanceRepository(api.client()),
      queue,
      clock: () => DateTime(2026, 10, 27, 9, 30),
    );
    await repo.bind(_scope);
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
  });

  group('captura sin red', () {
    test('con red el avance sale directo y la cola queda vacia', () async {
      api.on(
        'POST /api/preventive-maintenance/$_id/progress',
        const FakeReply(200, {'id': 'p1'}),
      );
      final order = await repo.addProgress(_id, percent: 70);
      expect(order.id, _id);
      expect(await queue.list(_scope), isEmpty);
    });

    test('sin red queda en la cola con su clave y el dia de captura', () async {
      api.offline = true;
      await repo.addProgress(
        _id,
        percent: 70.5,
        executedVolume: 12,
        notes: '  La mitad  ',
        clientId: _clientId,
      );
      final op = (await queue.list(_scope)).single;
      expect(op.id, _clientId);
      expect(op.entity, 'MAINTENANCE_PROGRESS');
      expect(op.kind, OperationKind.insert);
      expect(op.recordId, _id);
      expect(op.payload, {
        'progressPercent': 70.5,
        'reportedOn': '2026-10-27',
        'executedVolume': 12,
        'notes': 'La mitad',
      });
    });

    test(
      'sin red el aviso es de guardado aunque no haya ficha que traer',
      () async {
        api.offline = true;
        final order = await repo.addProgress(
          _id,
          percent: 10,
          clientId: _clientId,
        );
        expect(order.id, _id);
        expect(await queue.list(_scope), hasLength(1));
      },
    );

    test('reintentar el mismo formulario no duplica la cola', () async {
      api.offline = true;
      await repo.addProgress(_id, percent: 10, clientId: _clientId);
      await repo.addProgress(_id, percent: 10, clientId: _clientId);
      expect(await queue.list(_scope), hasLength(1));
    });

    test('un error que no es de red no se guarda en la cola', () async {
      api.on(
        'POST /api/preventive-maintenance/$_id/progress',
        const FakeReply(403),
      );
      await expectLater(
        repo.addProgress(_id, percent: 10),
        throwsA(
          isA<MaintenanceException>().having(
            (e) => e.error,
            'error',
            MaintenanceError.permissionDenied,
          ),
        ),
      );
      expect(await queue.list(_scope), isEmpty);
    });

    test('sin sesion activa no hay donde guardarlo', () async {
      await repo.bind(null);
      api.offline = true;
      await expectLater(
        repo.addProgress(_id, percent: 10),
        throwsA(isA<MaintenanceException>()),
      );
    });
  });

  group('envio', () {
    MaintenanceSyncRemote remote({String? device = 'phone-1'}) =>
        MaintenanceSyncRemote(api.client(), () async => device);

    Future<PendingOperation> queued() async {
      api.offline = true;
      await repo.addProgress(
        _id,
        percent: 70,
        executedVolume: 5,
        clientId: _clientId,
      );
      api.offline = false;
      return (await queue.list(_scope)).single;
    }

    FakeReply result(String status, {Object? error}) => FakeReply(200, {
      'serverTime': '2026-10-27T16:00:00Z',
      'operations': [
        {
          'idempotencyKey': _clientId,
          'status': status,
          'recordId': 'p1',
          'result': null,
          'error': error,
          'conflictId': null,
          'clockSkewSeconds': 0,
        },
      ],
    });

    test(
      'manda la operacion con el mantenimiento como registro padre',
      () async {
        final op = await queued();
        api.on('POST /api/sync/operations', result('APLICADA'));

        final outcome = await remote().send(op);

        expect(outcome, isA<SyncAccepted>());
        final body = api.to('POST /api/sync/operations').single.data as Map;
        expect(body['deviceIdentifier'], 'phone-1');
        final sent = (body['operations'] as List).single as Map;
        expect(sent['idempotencyKey'], _clientId);
        expect(sent['entity'], 'MAINTENANCE_PROGRESS');
        expect(sent['operation'], 'INSERT');
        expect(sent['recordId'], _id);
        expect(sent['payload'], {
          'progressPercent': 70,
          'reportedOn': '2026-10-27',
          'executedVolume': 5,
        });
      },
    );

    test('un avance duplicado se da por aceptado', () async {
      final op = await queued();
      api.on('POST /api/sync/operations', result('DUPLICADA'));
      final outcome = await remote().send(op);
      expect((outcome as SyncAccepted).duplicate, isTrue);
    });

    test('rechazado: queda el motivo del servidor', () async {
      final op = await queued();
      api.on(
        'POST /api/sync/operations',
        result(
          'RECHAZADA',
          error: {'code': 'PERMISSION_DENIED', 'message': 'Sin permiso'},
        ),
      );
      final outcome = await remote().send(op);
      expect(outcome, isA<SyncRejected>());
      expect((outcome as SyncRejected).message, 'Sin permiso');
    });

    test('sin red o sin telefono registrado se reintenta despues', () async {
      final op = await queued();
      expect(await remote(device: null).send(op), isA<SyncRetryLater>());
      api.offline = true;
      expect(await remote().send(op), isA<SyncRetryLater>());
    });

    test('no envia lo que no es un avance', () async {
      final op = await queued();
      final other = PendingOperation(
        id: op.id,
        scope: op.scope,
        entity: 'TICKET',
        kind: OperationKind.insert,
        payload: const {},
        status: OperationStatus.pending,
        createdAt: op.createdAt,
        capturedAt: op.capturedAt,
        updatedAt: op.updatedAt,
      );
      expect(await remote().send(other), isA<SyncRejected>());
    });
  });
}
