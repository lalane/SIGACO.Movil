import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _luis = OfflineScope(userId: 'luis', concessionId: 'c1');

/// Servidor de prueba: responde lo que se le indique por operacion y guarda lo
/// que recibio, en orden.
class _Remote implements SyncRemote {
  final sent = <PendingOperation>[];
  final statusesWhenSent = <OperationStatus?>[];
  final answers = <String, SyncOutcome Function(PendingOperation)>{};
  SyncOutcome Function(PendingOperation) fallback = (_) => const SyncAccepted();
  Object? throwError;
  OperationQueue? queue;

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    sent.add(operation);
    statusesWhenSent.add((await queue?.find(operation.id))?.status);
    if (throwError != null) throw throwError!;
    return (answers[operation.id] ?? fallback)(operation);
  }
}

/// Envio de la cola local al servidor (DEV-MOB-064 y 067).
void main() {
  sqfliteFfiInit();

  late OfflineDatabase db;
  late OperationQueue queue;
  late _Remote remote;
  late DateTime now;
  late SyncEngine engine;
  SyncGate gate = SyncGate.proceed;
  final gateCalls = <OfflineScope>[];

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 10);
    gate = SyncGate.proceed;
    gateCalls.clear();
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db, clock: () => now);
    remote = _Remote()..queue = queue;
    engine = SyncEngine(
      queue,
      remote,
      clock: () => now,
      preflight: (scope) async {
        gateCalls.add(scope);
        return gate;
      },
    );
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
  });

  Future<PendingOperation> insert(
    String name, {
    OfflineScope scope = _ana,
    String? recordId,
    String entity = 'documento',
  }) {
    now = now.add(const Duration(seconds: 1));
    return queue.enqueue(
      scope,
      entity: entity,
      kind: OperationKind.insert,
      payload: {'name': name},
      recordId: recordId,
    );
  }

  Future<PendingOperation> update(String recordId, {int base = 1}) {
    now = now.add(const Duration(seconds: 1));
    return queue.enqueue(
      _ana,
      entity: 'documento',
      kind: OperationKind.update,
      payload: {'name': 'v$base'},
      recordId: recordId,
      baseVersion: base,
    );
  }

  Future<OperationStatus> statusOf(PendingOperation op) async =>
      (await queue.find(op.id))!.status;

  group('envio ordenado', () {
    test('envia lo pendiente en el orden en que se capturo', () async {
      final a = await insert('a');
      final b = await insert('b');
      final c = await insert('c');

      final report = await engine.run(_ana);

      expect(remote.sent.map((o) => o.id), [a.id, b.id, c.id]);
      expect(report.accepted, 3);
      expect(report.completed, isTrue);
      for (final op in [a, b, c]) {
        expect(await statusOf(op), OperationStatus.accepted);
      }
    });

    test('cada operacion viaja con su clave de idempotencia', () async {
      final a = await insert('a');
      await engine.run(_ana);
      expect(remote.sent.single.id, a.id);
      expect(remote.sent.single.payload, {'name': 'a'});
    });

    test('mientras se envia esta en estado enviando', () async {
      await insert('a');
      await engine.run(_ana);
      expect(remote.statusesWhenSent.single, OperationStatus.sending);
    });

    test('lo ya aceptado no se vuelve a enviar', () async {
      await insert('a');
      await engine.run(_ana);
      remote.sent.clear();
      final again = await engine.run(_ana);
      expect(remote.sent, isEmpty);
      expect(again.accepted, 0);
      expect(again.completed, isTrue);
    });

    test('guarda la respuesta del servidor', () async {
      final a = await insert('a');
      remote.answers[a.id] = (_) =>
          const SyncAccepted(response: {'id': 'srv-1', 'version': 1});
      await engine.run(_ana);
      expect((await queue.find(a.id))!.response, {'id': 'srv-1', 'version': 1});
    });

    test(
      'si el servidor ya la tenia (clave repetida) cuenta como aceptada',
      () async {
        final a = await insert('a');
        remote.answers[a.id] = (_) => const SyncAccepted(duplicate: true);
        final report = await engine.run(_ana);
        expect(report.accepted, 1);
        expect(await statusOf(a), OperationStatus.accepted);
      },
    );

    test('una cola vacia termina bien y marca la sincronizacion', () async {
      final report = await engine.run(_ana);
      expect(report.completed, isTrue);
      expect(report.changedAnything, isFalse);
      expect(await queue.lastSync(_ana), now);
    });

    test('solo envia lo de su persona y concesion', () async {
      await insert('de ana');
      await insert('de luis', scope: _luis);
      await engine.run(_ana);
      expect(remote.sent.map((o) => o.payload['name']), ['de ana']);
      expect((await queue.counts(_luis))[OperationStatus.pending], 1);
    });
  });

  group('rechazos (varios archivos, DEV-MOB-083)', () {
    test('un rechazo no detiene los demas', () async {
      final a = await insert('a.pdf');
      final b = await insert('b.exe');
      final c = await insert('c.pdf');
      remote.answers[b.id] = (_) =>
          const SyncRejected('Extension bloqueada: .exe');

      final report = await engine.run(_ana);

      expect(report.accepted, 2);
      expect(report.rejected, 1);
      expect(await statusOf(a), OperationStatus.accepted);
      expect(await statusOf(b), OperationStatus.rejected);
      expect(await statusOf(c), OperationStatus.accepted);
      expect((await queue.find(b.id))!.lastError, 'Extension bloqueada: .exe');
      expect(
        report.completed,
        isTrue,
        reason: 'un rechazo no es un fallo de red',
      );
    });

    test('lo rechazado no se reintenta solo', () async {
      final a = await insert('a');
      remote.answers[a.id] = (_) => const SyncRejected('no');
      await engine.run(_ana);
      remote.sent.clear();
      await engine.run(_ana);
      expect(remote.sent, isEmpty);
    });

    test('lo siguiente sobre el mismo registro espera', () async {
      final first = await update('d1', base: 1);
      final second = await update('d1', base: 2);
      final other = await update('d2');
      remote.answers[first.id] = (_) => const SyncRejected('sin permiso');

      final report = await engine.run(_ana);

      expect(await statusOf(first), OperationStatus.rejected);
      expect(
        await statusOf(second),
        OperationStatus.pending,
        reason: 'espera a la primera',
      );
      expect(
        await statusOf(other),
        OperationStatus.accepted,
        reason: 'otro registro sigue',
      );
      expect(report.skipped, 1);
    });

    test('al reintentar la rechazada, la siguiente sigue su turno', () async {
      final first = await update('d1', base: 1);
      final second = await update('d1', base: 2);
      remote.answers[first.id] = (_) => const SyncRejected('sin permiso');
      await engine.run(_ana);

      remote.answers.clear();
      await queue.requeue(first.id);
      remote.sent.clear();
      await engine.run(_ana);

      expect(remote.sent.map((o) => o.id), [first.id, second.id]);
    });
  });

  group('conflictos (firma sin conexion, DEV-MOB-085)', () {
    test(
      'nunca se aplica en silencio: queda en conflicto con ambas versiones',
      () async {
        final sign = await queue.enqueue(
          _ana,
          entity: 'documento_firma',
          kind: OperationKind.update,
          payload: const {'hash': 'abc'},
          recordId: 'v1',
          baseVersion: 3,
        );
        remote.answers[sign.id] = (_) => const SyncConflicted(
          serverVersion: 4,
          serverPayload: {'estado': 'validado'},
          message: 'La version ya fue firmada',
        );

        final report = await engine.run(_ana);

        expect(report.conflicts, 1);
        expect(report.accepted, 0);
        expect(await statusOf(sign), OperationStatus.conflict);
        final c = (await queue.conflictOf(sign.id))!;
        expect(c.localVersion, 3);
        expect(c.serverVersion, 4);
        expect(c.serverPayload, {'estado': 'validado'});
      },
    );

    test('una operacion en conflicto no se reenvia sola', () async {
      final sign = await update('v1', base: 3);
      remote.answers[sign.id] = (_) => const SyncConflicted(serverVersion: 4);
      await engine.run(_ana);
      remote.sent.clear();
      await engine.run(_ana);
      expect(remote.sent, isEmpty);
    });

    test('resuelta con la version del servidor, se reenvia', () async {
      final op = await update('d1', base: 3);
      remote.answers[op.id] = (_) => const SyncConflicted(serverVersion: 4);
      await engine.run(_ana);

      remote.answers.clear();
      await queue.requeue(op.id, baseVersion: 4);
      await engine.run(_ana);

      expect(remote.sent.last.baseVersion, 4);
      expect(await statusOf(op), OperationStatus.accepted);
    });
  });

  group('falta de red', () {
    test('detiene la pasada: lo demas se queda en la cola', () async {
      final a = await insert('a');
      final b = await insert('b');
      final c = await insert('c');
      remote.answers[b.id] = (_) => const SyncRetryLater('sin red');

      final report = await engine.run(_ana);

      expect(remote.sent.map((o) => o.id), [
        a.id,
        b.id,
      ], reason: 'c ni se intenta');
      expect(report.accepted, 1);
      expect(report.retried, 1);
      expect(report.skipped, 1);
      expect(report.networkFailed, isTrue);
      expect(report.completed, isFalse);
      expect(await statusOf(a), OperationStatus.accepted);
      expect(await statusOf(b), OperationStatus.pending);
      expect(await statusOf(c), OperationStatus.pending);
      expect(
        (await queue.find(c.id))!.attempts,
        0,
        reason: 'no gasto un intento',
      );
    });

    test('no marca la sincronizacion como completa', () async {
      final a = await insert('a');
      remote.answers[a.id] = (_) => const SyncRetryLater('sin red');
      await engine.run(_ana);
      expect(await queue.lastSync(_ana), isNull);
    });

    test('espera antes de reintentar, y la espera crece', () async {
      final a = await insert('a');
      remote.answers[a.id] = (_) => const SyncRetryLater('sin red');

      await engine.run(_ana);
      expect(
        (await queue.find(a.id))!.nextAttemptAt,
        now.add(defaultBackoff(1)),
      );

      // Todavia en espera: ni se intenta.
      remote.sent.clear();
      final early = await engine.run(_ana);
      expect(remote.sent, isEmpty);
      expect(early.skipped, 1);
      expect(early.networkFailed, isFalse);

      now = now.add(defaultBackoff(1) + const Duration(seconds: 1));
      await engine.run(_ana);
      expect(remote.sent, hasLength(1));
      expect((await queue.find(a.id))!.attempts, 2);
      expect(
        (await queue.find(a.id))!.nextAttemptAt,
        now.add(defaultBackoff(2)),
      );
    });

    test('al volver la conexion se envia todo en orden', () async {
      final a = await insert('a');
      final b = await insert('b');
      remote.fallback = (_) => const SyncRetryLater('sin red');
      await engine.run(_ana);
      expect(await statusOf(a), OperationStatus.pending);

      remote.fallback = (_) => const SyncAccepted();
      remote.sent.clear();
      now = now.add(const Duration(minutes: 20));
      final report = await engine.run(_ana);

      expect(remote.sent.map((o) => o.id), [a.id, b.id]);
      expect(report.accepted, 2);
      expect(report.completed, isTrue);
    });

    test('una excepcion del envio cuenta como falla pasajera', () async {
      final a = await insert('a');
      remote.throwError = StateError('socket cerrado');
      final report = await engine.run(_ana);
      expect(report.networkFailed, isTrue);
      expect(await statusOf(a), OperationStatus.pending);
      expect((await queue.find(a.id))!.lastError, contains('socket cerrado'));
    });

    test('el servidor puede pedir cuanto esperar', () async {
      final a = await insert('a');
      remote.answers[a.id] = (_) =>
          const SyncRetryLater('ocupado', retryAfter: Duration(minutes: 2));
      await engine.run(_ana);
      expect(
        (await queue.find(a.id))!.nextAttemptAt,
        now.add(const Duration(minutes: 2)),
      );
    });

    test(
      'lo siguiente sobre el mismo registro espera su turno de reintento',
      () async {
        final first = await update('d1', base: 1);
        final second = await update('d1', base: 2);
        remote.answers[first.id] = (_) => const SyncRetryLater('sin red');
        await engine.run(_ana);
        remote.sent.clear();
        remote.answers.clear();

        // Pasada siguiente, antes de la hora del reintento: ninguna sale.
        await engine.run(_ana);
        expect(remote.sent, isEmpty);

        now = now.add(const Duration(minutes: 1));
        await engine.run(_ana);
        expect(remote.sent.map((o) => o.id), [first.id, second.id]);
      },
    );

    test('la espera de reintento se detiene en 15 minutos', () {
      expect(defaultBackoff(1), const Duration(seconds: 5));
      expect(defaultBackoff(2), const Duration(seconds: 10));
      expect(defaultBackoff(3), const Duration(seconds: 20));
      expect(defaultBackoff(7), const Duration(minutes: 5, seconds: 20));
      expect(defaultBackoff(8), const Duration(minutes: 10, seconds: 40));
      expect(defaultBackoff(9), const Duration(minutes: 15));
      expect(defaultBackoff(40), const Duration(minutes: 15));
      expect(defaultBackoff(0), const Duration(seconds: 5));
    });
  });

  group('sesion y revalidacion previa (DEV-MOB-094)', () {
    test('revalida antes de enviar, con el alcance de la pasada', () async {
      await insert('a');
      await engine.run(_ana);
      expect(gateCalls, [_ana]);
    });

    test(
      'si la revalidacion pide esperar, no se envia nada y se conserva todo',
      () async {
        final a = await insert('a');
        gate = SyncGate.hold;

        final report = await engine.run(_ana);

        expect(remote.sent, isEmpty);
        expect(report.held, isTrue);
        expect(report.completed, isFalse);
        expect(await statusOf(a), OperationStatus.pending);
        expect((await queue.find(a.id))!.attempts, 0);
        expect(await queue.lastSync(_ana), isNull);
      },
    );

    test('cuando la sesion vuelve a valer, lo retenido se envia', () async {
      final a = await insert('a');
      gate = SyncGate.hold;
      await engine.run(_ana);
      gate = SyncGate.proceed;
      await engine.run(_ana);
      expect(await statusOf(a), OperationStatus.accepted);
    });

    test(
      'si la sesion se pierde a mitad, se detiene sin gastar espera',
      () async {
        final a = await insert('a');
        final b = await insert('b');
        remote.answers[a.id] = (_) => const SyncSessionLost();

        final report = await engine.run(_ana);

        expect(report.sessionLost, isTrue);
        expect(report.completed, isFalse);
        expect(remote.sent.map((o) => o.id), [a.id], reason: 'b ni se intenta');
        expect(await statusOf(a), OperationStatus.pending);
        expect((await queue.find(a.id))!.nextAttemptAt, isNull);
        expect(await statusOf(b), OperationStatus.pending);
      },
    );

    test('un motor sin revalidacion envia directo', () async {
      final plain = SyncEngine(queue, remote, clock: () => now);
      await insert('a');
      final report = await plain.run(_ana);
      expect(report.accepted, 1);
    });
  });

  group('una pasada a la vez', () {
    test('dos llamadas juntas comparten la misma pasada', () async {
      await insert('a');
      final r1 = engine.run(_ana);
      final r2 = engine.run(_ana);
      expect(identical(r1, r2), isTrue);
      expect(engine.isRunning(_ana), isTrue);
      await Future.wait([r1, r2]);
      expect(remote.sent, hasLength(1), reason: 'no se envia dos veces');
      expect(engine.isRunning(_ana), isFalse);
    });

    test('alcances distintos pueden correr a la vez', () async {
      await insert('a');
      await insert('b', scope: _luis);
      final both = await Future.wait([engine.run(_ana), engine.run(_luis)]);
      expect(both.map((r) => r.accepted), [1, 1]);
    });

    test('despues de terminar se puede volver a empezar', () async {
      await insert('a');
      await engine.run(_ana);
      await insert('b');
      final report = await engine.run(_ana);
      expect(report.accepted, 1);
    });
  });

  group('reinicio de la app', () {
    test(
      'lo que se estaba enviando vuelve a la cola y no se duplica',
      () async {
        final a = await insert('a');
        await queue.markSending(a.id); // la app se cerro a mitad del envio
        expect(await queue.resetInterrupted(), 1);

        await engine.run(_ana);

        expect(remote.sent.map((o) => o.id), [
          a.id,
        ], reason: 'misma clave de idempotencia');
        expect(await statusOf(a), OperationStatus.accepted);
      },
    );
  });

  group('informe', () {
    test('describe lo ocurrido', () {
      const report = SyncReport(accepted: 2, rejected: 1, networkFailed: true);
      expect(report.changedAnything, isTrue);
      expect(report.completed, isFalse);
      expect(report.toString(), contains('aceptadas: 2'));
      expect(const SyncReport().changedAnything, isFalse);
    });
  });
}
