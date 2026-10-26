import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/files/local_file_store.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/routed_sync_remote.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/offline_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/data/sync/tickets_sync_remote.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_api.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');

const _config = {
  'operationalCatalogs': {
    'ticketTypes': [
      {'code': 'BACHE', 'labelEs': 'Bache', 'sortOrder': 1, 'active': true},
    ],
  },
};

/// No copia nada: devuelve la misma ruta (las pruebas no tocan el disco).
class _SameFiles implements LocalFileStore {
  @override
  Future<String> keep(String sourcePath, {required String name}) async =>
      sourcePath;

  @override
  Future<void> remove(String path) async {}
}

Map<String, Object?> _dto(String id) => {
  'id': id,
  'folio': 'TK-2026-0001',
  'ticketTypeLabel': 'Bache',
  'status': 'NUEVO',
  'description': 'Bache en carril',
  'detectedAt': '2026-10-26T15:00:00Z',
  'rowVersion': 1,
};

/// Tickets y seguimientos capturados sin red (MOB-016): se guardan en la cola y
/// salen por `/api/sync/operations` cuando vuelve la conexion.
void main() {
  sqfliteFfiInit();

  late FakeApi api;
  late OfflineDatabase db;
  late OperationQueue queue;
  late ApiTicketsRepository online;
  late OfflineTicketsRepository repo;

  setUp(() async {
    api = FakeApi()
      ..on('GET /api/app-configuration', const FakeReply(200, _config));
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db);
    online = ApiTicketsRepository(api.client(), roadId: () async => 'road-1');
    repo = OfflineTicketsRepository(online, queue, _SameFiles());
    await repo.bind(_scope);
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
  });

  final draft = NewTicket(
    title: 'Bache',
    category: 'Bache',
    kmLabel: 'KM 513+615',
    description: 'Cerca del puente',
    capturedAt: DateTime.utc(2026, 10, 26, 15),
    clientId: 'c0a80101-0000-4000-8000-000000000001',
    location: const TicketLocation(
      latitude: -18.84,
      longitude: -41.98,
      origin: TicketLocationOrigin.gps,
    ),
  );

  group('captura sin red', () {
    test('con red el ticket sale directo y la cola queda vacia', () async {
      await repo.categories();
      api.on('POST /api/tickets', FakeReply(201, _dto('t1')));
      final ticket = await repo.create(draft);
      expect(ticket.code, 'TK-2026-0001');
      expect(await queue.list(_scope), isEmpty);
    });

    test('sin red el ticket queda en la cola con su clave', () async {
      await repo.categories();
      api.offline = true;
      final ticket = await repo.create(draft);
      expect(ticket.id, draft.clientId);
      expect(ticket.title, 'Bache');
      final ops = await queue.list(_scope);
      expect(ops, hasLength(1));
      expect(ops.single.id, draft.clientId);
      expect(ops.single.entity, 'TICKET');
      expect(ops.single.kind, OperationKind.insert);
      expect(ops.single.payload['ticketTypeCode'], 'BACHE');
      expect(ops.single.payload['clientUuid'], draft.clientId);
      expect(ops.single.payload['kmStart'], 513.615);
    });

    test('capturar dos veces el mismo formulario no duplica la cola', () async {
      await repo.categories();
      api.offline = true;
      await repo.create(draft);
      await repo.create(draft);
      expect(await queue.list(_scope), hasLength(1));
    });

    test('un error que no es de red no se guarda en la cola', () async {
      await repo.categories();
      api.on('POST /api/tickets', const FakeReply(403));
      await expectLater(
        repo.create(draft),
        throwsA(
          isA<TicketsException>().having(
            (e) => e.error,
            'error',
            TicketsError.permissionDenied,
          ),
        ),
      );
      expect(await queue.list(_scope), isEmpty);
    });

    test('sin conocer los tipos de ticket no hay con que armarlo', () async {
      api.offline = true;
      await expectLater(repo.create(draft), throwsA(isA<TicketsException>()));
      expect(await queue.list(_scope), isEmpty);
    });

    test('el seguimiento sin red queda en la cola sobre su ticket', () async {
      api.offline = true;
      await repo.addFollowUp(
        't1',
        NewFollowUp(
          at: DateTime.utc(2026, 10, 26, 16),
          status: TicketStatus.attended,
          description: 'Ya se tapo',
        ),
      );
      final op = (await queue.list(_scope)).single;
      expect(op.entity, 'TICKET_FOLLOW_UP');
      expect(op.recordId, 't1');
      expect(op.payload['description'], 'Ya se tapo');
      expect(op.payload['_attended'], isTrue);
    });
  });

  group('envio', () {
    late Directory dir;
    late File photo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('tko_');
      photo = File('${dir.path}/f.jpg')..writeAsBytesSync([1, 2, 3]);
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // Lo recoge el sistema.
        }
      });
    });

    TicketsSyncRemote remote({String? device = 'phone-1'}) =>
        TicketsSyncRemote(api.client(), online, () async => device);

    Future<PendingOperation> queued({List<String> photos = const []}) async {
      await repo.categories();
      api.offline = true;
      await repo.create(
        NewTicket(
          title: draft.title,
          category: draft.category,
          capturedAt: draft.capturedAt,
          clientId: draft.clientId,
          photoPaths: photos,
          location: draft.location,
        ),
      );
      api.offline = false;
      return (await queue.list(_scope)).single;
    }

    FakeReply result(String status, {String? recordId, Object? error}) =>
        FakeReply(200, {
          'serverTime': '2026-10-26T16:00:00Z',
          'operations': [
            {
              'idempotencyKey': draft.clientId,
              'status': status,
              'recordId': recordId,
              'result': null,
              'error': error,
              'conflictId': null,
              'clockSkewSeconds': 0,
            },
          ],
        });

    test(
      'manda la operacion con el telefono, la clave y sin datos propios',
      () async {
        final op = await queued(photos: [photo.path]);
        api.on('POST /api/sync/operations', result('APLICADA', recordId: 't1'));
        api.on(
          'POST /api/tickets/t1/attachments',
          const FakeReply(201, {'id': 'a1'}),
        );

        final outcome = await remote().send(op);

        expect(outcome, isA<SyncAccepted>());
        final body = api.to('POST /api/sync/operations').single.data as Map;
        expect(body['deviceIdentifier'], 'phone-1');
        final sent = (body['operations'] as List).single as Map;
        expect(sent['idempotencyKey'], draft.clientId);
        expect(sent['entity'], 'TICKET');
        expect(sent['operation'], 'INSERT');
        final payload = sent['payload'] as Map;
        expect(payload['ticketTypeCode'], 'BACHE');
        expect(payload.keys.where((k) => '$k'.startsWith('_')), isEmpty);
        expect(api.to('POST /api/tickets/t1/attachments'), hasLength(1));
      },
    );

    test('una operacion duplicada se da por aceptada', () async {
      final op = await queued();
      api.on('POST /api/sync/operations', result('DUPLICADA', recordId: 't1'));
      final outcome = await remote().send(op);
      expect(outcome, isA<SyncAccepted>());
      expect((outcome as SyncAccepted).duplicate, isTrue);
    });

    test('rechazada: queda el motivo del servidor', () async {
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

    test('sin red se reintenta; sin sesion se detiene', () async {
      final op = await queued();
      api.offline = true;
      expect(await remote().send(op), isA<SyncRetryLater>());
      api.offline = false;
      api.on('POST /api/sync/operations', const FakeReply(401, {'title': 'x'}));
      expect(await remote().send(op), isA<SyncSessionLost>());
    });

    test('sin telefono registrado espera', () async {
      final op = await queued();
      expect(await remote(device: null).send(op), isA<SyncRetryLater>());
      expect(api.to('POST /api/sync/operations'), isEmpty);
    });

    test('la foto que falla deja la operacion para reintentar', () async {
      final op = await queued(photos: [photo.path]);
      api.on('POST /api/sync/operations', result('APLICADA', recordId: 't1'));
      api.on(
        'POST /api/tickets/t1/attachments',
        const FakeReply(500, {'title': 'x'}),
      );
      expect(await remote().send(op), isA<SyncRetryLater>());
    });

    test('el motor envia lo pendiente y lo deja aceptado', () async {
      final op = await queued();
      api.on('POST /api/sync/operations', result('APLICADA', recordId: 't1'));
      final engine = SyncEngine(
        queue,
        RoutedSyncRemote({'TICKET': remote(), 'TICKET_FOLLOW_UP': remote()}),
      );
      final report = await engine.run(_scope);
      expect(report.accepted, 1);
      expect((await queue.find(op.id))!.status, OperationStatus.accepted);
    });

    test('un tipo que nadie atiende se rechaza', () async {
      final op = await queued();
      final outcome = await const RoutedSyncRemote({}).send(op);
      expect(outcome, isA<SyncRejected>());
    });
  });
}
