import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaOtra = OfflineScope(userId: 'ana', concessionId: 'c2');
const _luis = OfflineScope(userId: 'luis', concessionId: 'c1');

/// Cola local de operaciones capturadas sin conexion (DEV-MOB-060 y 062).
void main() {
  sqfliteFfiInit();

  late OfflineDatabase db;
  late OperationQueue queue;
  late DateTime now;

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 10);
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db, clock: () => now);
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
  });

  Future<PendingOperation> doc([
    OfflineScope scope = _ana,
    Map<String, Object?> payload = const {'name': 'acta.pdf'},
  ]) => queue.enqueue(
    scope,
    entity: 'documento',
    kind: OperationKind.insert,
    payload: payload,
  );

  group('uuid', () {
    test('es un UUID v4 y no se repite', () {
      final ids = {for (var i = 0; i < 200; i++) newUuid()};
      expect(ids, hasLength(200));
      for (final id in ids) {
        expect(isUuid(id), isTrue, reason: id);
        expect(id[14], '4', reason: 'version 4');
        expect('89ab'.contains(id[19]), isTrue, reason: 'variante RFC 4122');
      }
    });

    test('isUuid rechaza lo que no lo es', () {
      expect(isUuid('hola'), isFalse);
      expect(isUuid('3f1a9c02-1111-4222-8333'), isFalse);
    });
  });

  group('enqueue', () {
    test('deja la operacion pendiente, con su clave y la hora UTC', () async {
      final op = await doc();
      expect(isUuid(op.id), isTrue);
      expect(op.status, OperationStatus.pending);
      expect(op.scope, _ana);
      expect(op.entity, 'documento');
      expect(op.kind, OperationKind.insert);
      expect(op.payload, {'name': 'acta.pdf'});
      expect(op.attempts, 0);
      expect(op.createdAt, now);
      expect(op.capturedAt, now);
      expect(op.createdAt.isUtc, isTrue);
      expect(op.isOpen, isTrue);
      expect(op.needsAttention, isFalse);
    });

    test(
      'guarda la hora en que se capturo, distinta de la de entrada',
      () async {
        final captured = DateTime.utc(2026, 10, 12, 7, 30);
        final op = await queue.enqueue(
          _ana,
          entity: 'documento',
          kind: OperationKind.insert,
          payload: const {},
          capturedAt: captured,
        );
        expect(op.capturedAt, captured);
        expect(op.createdAt, now);
      },
    );

    test('la misma clave no se encola dos veces', () async {
      final first = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: const {'name': 'a'},
        key: '3f1a9c02-9c02-4a40-8cde-111111111111',
      );
      final second = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: const {'name': 'otro'},
        key: '3f1a9c02-9c02-4a40-8cde-111111111111',
      );
      expect(second.id, first.id);
      expect(second.payload, {'name': 'a'}, reason: 'se conserva la primera');
      expect(await queue.list(_ana), hasLength(1));
    });

    test('una clave de otra persona no se puede reusar', () async {
      await queue.enqueue(
        _luis,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: const {},
        key: '3f1a9c02-9c02-4a40-8cde-222222222222',
      );
      expect(
        () => queue.enqueue(
          _ana,
          entity: 'documento',
          kind: OperationKind.insert,
          payload: const {},
          key: '3f1a9c02-9c02-4a40-8cde-222222222222',
        ),
        throwsStateError,
      );
    });

    test('update y delete exigen el registro y la version base', () async {
      for (final kind in [OperationKind.update, OperationKind.delete]) {
        expect(
          () => queue.enqueue(
            _ana,
            entity: 'documento',
            kind: kind,
            payload: const {},
          ),
          throwsArgumentError,
        );
        expect(
          () => queue.enqueue(
            _ana,
            entity: 'documento',
            kind: kind,
            payload: const {},
            recordId: 'd1',
          ),
          throwsArgumentError,
          reason: 'falta la version base',
        );
      }
      final ok = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.update,
        payload: const {'name': 'nuevo'},
        recordId: 'd1',
        baseVersion: 3,
      );
      expect(ok.recordId, 'd1');
      expect(ok.baseVersion, 3);
    });

    test('la entidad no puede ir vacia', () {
      expect(
        () => queue.enqueue(
          _ana,
          entity: ' ',
          kind: OperationKind.insert,
          payload: const {},
        ),
        throwsArgumentError,
      );
    });

    test('conserva payloads anidados', () async {
      final op = await doc(_ana, const {
        'name': 'acta.pdf',
        'meta': {
          'tipo': 'CONTRATO',
          'etiquetas': ['a', 'b'],
        },
        'size': 1024,
      });
      final read = (await queue.find(op.id))!;
      expect(read.payload['meta'], {
        'tipo': 'CONTRATO',
        'etiquetas': ['a', 'b'],
      });
      expect(read.payload['size'], 1024);
    });
  });

  group('aislamiento por persona y concesion', () {
    test('cada alcance solo ve lo suyo', () async {
      final a = await doc(_ana);
      await doc(_anaOtra);
      await doc(_luis);
      expect((await queue.list(_ana)).map((o) => o.id), [a.id]);
      expect(await queue.list(_anaOtra), hasLength(1));
      expect(await queue.list(_luis), hasLength(1));
    });

    test('las cuentas tampoco se mezclan', () async {
      await doc(_ana);
      await doc(_ana);
      await doc(_luis);
      expect((await queue.counts(_ana))[OperationStatus.pending], 2);
      expect((await queue.counts(_luis))[OperationStatus.pending], 1);
      expect(await queue.counts(_anaOtra), isEmpty);
    });

    test('lo pendiente de otro alcance no se envia', () async {
      await doc(_luis);
      expect(await queue.due(_ana), isEmpty);
      expect(await queue.due(_luis), hasLength(1));
    });

    test('la ultima sincronizacion es por alcance', () async {
      await queue.setLastSync(_ana, now);
      expect(await queue.lastSync(_ana), now);
      expect(await queue.lastSync(_anaOtra), isNull);
      expect(await queue.lastSync(_luis), isNull);
    });
  });

  group('lectura', () {
    test('en orden de captura, y mas recientes primero si se pide', () async {
      final a = await doc();
      now = now.add(const Duration(minutes: 1));
      final b = await doc();
      now = now.add(const Duration(minutes: 1));
      final c = await doc();
      expect((await queue.list(_ana)).map((o) => o.id), [a.id, b.id, c.id]);
      expect((await queue.list(_ana, newestFirst: true)).map((o) => o.id), [
        c.id,
        b.id,
        a.id,
      ]);
    });

    test(
      'operaciones de la misma hora conservan el orden de entrada',
      () async {
        final ids = [for (var i = 0; i < 5; i++) (await doc()).id];
        expect((await queue.list(_ana)).map((o) => o.id), ids);
      },
    );

    test('filtra por estado', () async {
      final a = await doc();
      final b = await doc();
      await queue.markSending(b.id);
      await queue.markRejected(b.id, error: 'no');
      final pending = await queue.list(
        _ana,
        statuses: {OperationStatus.pending},
      );
      expect(pending.map((o) => o.id), [a.id]);
      expect(await queue.list(_ana, statuses: {}), isEmpty);
    });

    test('find de una clave que no existe devuelve null', () async {
      expect(await queue.find('no-existe'), isNull);
    });
  });

  group('transiciones', () {
    test('enviar cuenta un intento y la deja enviando', () async {
      final op = await doc();
      await queue.markSending(op.id);
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.sending);
      expect(read.attempts, 1);
      expect(read.isOpen, isTrue);
    });

    test('aceptada guarda la respuesta del servidor', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markAccepted(
        op.id,
        response: const {'id': 'd9', 'version': 1},
      );
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.accepted);
      expect(read.response, {'id': 'd9', 'version': 1});
      expect(read.isOpen, isFalse);
    });

    test('rechazada guarda el motivo y pide atencion', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markRejected(op.id, error: 'Extension bloqueada: .exe');
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.rejected);
      expect(read.lastError, 'Extension bloqueada: .exe');
      expect(read.needsAttention, isTrue);
    });

    test('un reintento la devuelve a la cola, con espera', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markRetry(
        op.id,
        error: 'sin red',
        backoff: const Duration(seconds: 30),
      );
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.pending);
      expect(read.lastError, 'sin red');
      expect(read.attempts, 1);
      expect(read.nextAttemptAt, now.add(const Duration(seconds: 30)));

      expect(await queue.due(_ana), isEmpty, reason: 'todavia en espera');
      expect(
        await queue.nextRetryAt(_ana),
        now.add(const Duration(seconds: 30)),
      );
      now = now.add(const Duration(seconds: 31));
      expect((await queue.due(_ana)).map((o) => o.id), [op.id]);
    });

    test('una operacion ya aceptada no cambia de estado', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markAccepted(op.id);
      await queue.markRejected(op.id, error: 'tarde');
      await queue.markRetry(op.id, error: 'tarde');
      await queue.markConflict(op.id, message: 'tarde');
      expect((await queue.find(op.id))!.status, OperationStatus.accepted);
    });

    test('enviar solo vale desde pendiente', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markSending(op.id);
      expect(
        (await queue.find(op.id))!.attempts,
        1,
        reason: 'no cuenta dos veces',
      );
    });
  });

  group('conflictos', () {
    Future<PendingOperation> sign() => queue.enqueue(
      _ana,
      entity: 'documento_firma',
      kind: OperationKind.insert,
      payload: const {'version_id': 'v1', 'hash': 'abc'},
    );

    test('guarda la version local y la del servidor', () async {
      final op = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.update,
        payload: const {'name': 'mio.pdf'},
        recordId: 'd1',
        baseVersion: 3,
      );
      await queue.markSending(op.id);
      await queue.markConflict(
        op.id,
        serverVersion: 4,
        serverPayload: const {'name': 'otro.pdf'},
        message: 'El documento cambio',
      );
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.conflict);
      expect(read.needsAttention, isTrue);
      final c = (await queue.conflictOf(op.id))!;
      expect(c.localVersion, 3);
      expect(c.serverVersion, 4);
      expect(c.serverPayload, {'name': 'otro.pdf'});
      expect(c.message, 'El documento cambio');
      expect(c.isOpen, isTrue);
    });

    test(
      'reenviar sobre la version del servidor resuelve el conflicto',
      () async {
        final op = await queue.enqueue(
          _ana,
          entity: 'documento',
          kind: OperationKind.update,
          payload: const {},
          recordId: 'd1',
          baseVersion: 3,
        );
        await queue.markSending(op.id);
        await queue.markConflict(op.id, serverVersion: 4);
        now = now.add(const Duration(minutes: 5));
        await queue.requeue(op.id, baseVersion: 4);

        final read = (await queue.find(op.id))!;
        expect(read.status, OperationStatus.pending);
        expect(read.baseVersion, 4);
        expect(read.attempts, 0);
        final c = (await queue.conflictOf(op.id))!;
        expect(c.resolution, ConflictResolution.retried);
        expect(c.resolvedAt, now);
        expect(c.isOpen, isFalse);
      },
    );

    test('descartar borra la operacion y su conflicto', () async {
      final op = await sign();
      await queue.markSending(op.id);
      await queue.markConflict(op.id, message: 'ya la firmo otra persona');
      expect(await queue.discard(op.id), isTrue);
      expect(await queue.find(op.id), isNull);
      expect(await queue.conflictOf(op.id), isNull);
    });

    test(
      'un conflicto nuevo reemplaza al anterior de la misma operacion',
      () async {
        final op = await sign();
        await queue.markSending(op.id);
        await queue.markConflict(op.id, serverVersion: 4, message: 'uno');
        await queue.requeue(op.id);
        await queue.markSending(op.id);
        await queue.markConflict(op.id, serverVersion: 5, message: 'dos');
        final c = (await queue.conflictOf(op.id))!;
        expect(c.serverVersion, 5);
        expect(c.message, 'dos');
        expect(c.isOpen, isTrue);
      },
    );

    test('solo se resuelve lo que esta en conflicto o rechazado', () async {
      final op = await doc();
      await queue.requeue(op.id, baseVersion: 9);
      expect((await queue.find(op.id))!.baseVersion, isNull);
    });
  });

  group('reintentar y descartar', () {
    test('una rechazada vuelve a la cola desde cero', () async {
      final op = await doc();
      await queue.markSending(op.id);
      await queue.markRejected(op.id, error: 'no');
      await queue.requeue(op.id);
      final read = (await queue.find(op.id))!;
      expect(read.status, OperationStatus.pending);
      expect(read.attempts, 0);
      expect(read.lastError, isNull);
    });

    test(
      'se puede descartar lo pendiente y lo rechazado, no lo aceptado ni lo que se esta enviando',
      () async {
        final pending = await doc();
        final rejected = await doc();
        final accepted = await doc();
        final sending = await doc();
        await queue.markSending(rejected.id);
        await queue.markRejected(rejected.id, error: 'no');
        await queue.markSending(accepted.id);
        await queue.markAccepted(accepted.id);
        await queue.markSending(sending.id);

        expect(await queue.discard(pending.id), isTrue);
        expect(await queue.discard(rejected.id), isTrue);
        expect(await queue.discard(accepted.id), isFalse);
        expect(await queue.discard(sending.id), isFalse);
        expect(await queue.discard('no-existe'), isFalse);
        expect(await queue.list(_ana), hasLength(2));
      },
    );
  });

  group('mantenimiento', () {
    test('al arrancar, lo que quedo enviando vuelve a la cola', () async {
      final a = await doc();
      final b = await doc();
      await queue.markSending(a.id);
      await queue.markSending(b.id);
      await queue.markAccepted(b.id);

      expect(await queue.resetInterrupted(), 1);
      expect((await queue.find(a.id))!.status, OperationStatus.pending);
      expect((await queue.find(b.id))!.status, OperationStatus.accepted);
    });

    test('borra las aceptadas viejas y deja el resto', () async {
      final old = await doc();
      await queue.markSending(old.id);
      await queue.markAccepted(old.id);
      final pending = await doc();
      now = now.add(const Duration(days: 8));
      final recent = await doc();
      await queue.markSending(recent.id);
      await queue.markAccepted(recent.id);

      expect(await queue.purgeAccepted(), 1);
      expect(await queue.find(old.id), isNull);
      expect(await queue.find(pending.id), isNotNull);
      expect(await queue.find(recent.id), isNotNull);
    });
  });

  group('avisos de cambio', () {
    test('cada cambio avisa y lo que no cambia, no', () async {
      var n = 0;
      final sub = queue.changes.listen((_) => n++);
      final op = await doc();
      await Future<void>.delayed(Duration.zero);
      expect(n, 1);

      await queue.markSending(op.id);
      await queue.markAccepted(op.id);
      await Future<void>.delayed(Duration.zero);
      expect(n, 3);

      await queue.markRejected(
        op.id,
        error: 'tarde',
      ); // ya aceptada: nada cambia
      await queue.discard(op.id); // aceptada: no se descarta
      await Future<void>.delayed(Duration.zero);
      expect(n, 3);
      await sub.cancel();
    });

    test('encolar la misma clave otra vez no avisa de nuevo', () async {
      var n = 0;
      final sub = queue.changes.listen((_) => n++);
      const key = '3f1a9c02-9c02-4a40-8cde-333333333333';
      for (var i = 0; i < 2; i++) {
        await queue.enqueue(
          _ana,
          entity: 'documento',
          kind: OperationKind.insert,
          payload: const {},
          key: key,
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(n, 1);
      await sub.cancel();
    });
  });
}
