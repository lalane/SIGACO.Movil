import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaOtra = OfflineScope(userId: 'ana', concessionId: 'c2');

class _Remote implements SyncRemote {
  final sent = <String>[];
  final answers = <String, SyncOutcome>{};
  SyncOutcome fallback = const SyncAccepted();
  Duration delay = Duration.zero;

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    sent.add(operation.id);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return answers[operation.id] ?? fallback;
  }
}

/// Espera a que algo ocurra (hasta 5 s) en lugar de dormir un tiempo fijo: las
/// pruebas corren en paralelo y una maquina cargada se tarda mas.
Future<void> _until(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('No ocurrio a tiempo${reason == null ? '' : ': $reason'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Para comprobar que algo NO pasa: se deja correr un rato.
Future<void> _quiet([int ms = 150]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Estado de la sincronizacion y cuando se envia (DEV-MOB-063 y 064).
void main() {
  sqfliteFfiInit();

  late OfflineDatabase db;
  late OperationQueue queue;
  late _Remote remote;
  late SyncCubit cubit;
  late DateTime now;

  SyncCubit make({
    Duration backoff = const Duration(milliseconds: 30),
    Duration resumeGap = Duration.zero,
  }) {
    final engine = SyncEngine(
      queue,
      remote,
      clock: () => now,
      backoff: (_) => backoff,
    );
    return SyncCubit(queue, engine, resumeGap: resumeGap, clock: () => now);
  }

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 10);
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db, clock: () => now);
    remote = _Remote();
    cubit = make();
  });

  tearDown(() async {
    await cubit.close();
    await queue.dispose();
    await db.close();
  });

  Future<PendingOperation> doc([
    OfflineScope scope = _ana,
    String name = 'a',
  ]) => queue.enqueue(
    scope,
    entity: 'documento',
    kind: OperationKind.insert,
    payload: {'name': name},
  );

  /// La pasada terminó y lo que se ve ya refleja la cola.
  bool settled() => !cubit.state.running && cubit.state.lastReport != null;

  test('empieza vacio y sin alcance', () {
    expect(cubit.state.scope, isNull);
    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.pending, 0);
    expect(cubit.state.attention, 0);
    expect(cubit.state.running, isFalse);
    expect(cubit.state.enabled, isTrue);
  });

  group('al iniciar sesion', () {
    test('muestra lo pendiente y lo envia solo si hay conexion', () async {
      final a = await doc();
      await cubit.setScope(_ana);
      await _until(
        () =>
            settled() &&
            cubit.state.items.isEmpty &&
            cubit.state.lastSyncAt != null,
      );

      expect(remote.sent, [a.id]);
      expect(cubit.state.lastSyncAt, now);
      expect(cubit.state.lastReport?.accepted, 1);
    });

    test('sin conexion se ve lo pendiente pero no se envia', () async {
      cubit.setOnline(false);
      await doc();
      await doc(_ana, 'b');
      await cubit.setScope(_ana);
      await _quiet();

      expect(remote.sent, isEmpty);
      expect(cubit.state.pending, 2);
      expect(cubit.state.lastSyncAt, isNull);
    });

    test('lo que quedo enviandose al cerrar la app vuelve a la cola', () async {
      cubit.setOnline(false);
      final a = await doc();
      await queue.markSending(a.id);
      await cubit.setScope(_ana);
      expect(cubit.state.items.single.status, OperationStatus.pending);
    });

    test('al cerrar sesion no queda nada a la vista', () async {
      cubit.setOnline(false);
      await doc();
      await cubit.setScope(_ana);
      expect(cubit.state.pending, 1);
      await cubit.setScope(null);
      expect(cubit.state.scope, isNull);
      expect(cubit.state.isEmpty, isTrue);
    });

    test('cada concesion ve solo lo suyo', () async {
      cubit.setOnline(false);
      await doc(_ana, 'de c1');
      await doc(_anaOtra, 'de c2');
      await cubit.setScope(_ana);
      expect(cubit.state.items.single.payload['name'], 'de c1');
      await cubit.setScope(_anaOtra);
      expect(cubit.state.items.single.payload['name'], 'de c2');
    });

    test('el mismo alcance no se vuelve a cargar', () async {
      cubit.setOnline(false);
      await cubit.setScope(_ana);
      final before = cubit.state;
      await cubit.setScope(_ana);
      expect(identical(cubit.state, before), isTrue);
    });
  });

  group('cuando se envia', () {
    test('al recuperar la conexion', () async {
      cubit.setOnline(false);
      await doc();
      await cubit.setScope(_ana);
      await _quiet();
      expect(remote.sent, isEmpty);

      cubit.setOnline(true);
      await _until(() => settled() && cubit.state.pending == 0);
      expect(remote.sent, hasLength(1));
    });

    test('un aviso de conexion que no cambia no envia', () async {
      await cubit.setScope(_ana);
      await _until(settled);
      await doc();
      cubit.setOnline(true);
      await _quiet();
      expect(remote.sent, isEmpty);
    });

    test('despues de encolar, al pedirlo', () async {
      await cubit.setScope(_ana);
      await _until(settled);
      await doc();
      await cubit.syncNow();
      expect(remote.sent, hasLength(1));
    });

    test('al volver a la app no repite una pasada reciente', () async {
      await cubit.close();
      cubit = make(resumeGap: const Duration(seconds: 30));
      await cubit.setScope(_ana);
      await _until(settled);
      await doc();

      now = now.add(const Duration(seconds: 10));
      await cubit.onResume();
      expect(remote.sent, isEmpty, reason: 'hace poco que se sincronizo');

      now = now.add(const Duration(seconds: 25));
      await cubit.onResume();
      expect(remote.sent, hasLength(1));
    });

    test('sin sesion no hace nada', () async {
      await cubit.syncNow();
      expect(remote.sent, isEmpty);
      expect(cubit.state.running, isFalse);
    });

    test('mientras se envia indica que esta corriendo', () async {
      remote.delay = const Duration(milliseconds: 200);
      cubit.setOnline(false);
      await doc();
      await cubit.setScope(_ana);
      cubit.setOnline(true);
      await _until(() => cubit.state.running, reason: 'debia empezar');
      await _until(() => !cubit.state.running, reason: 'debia terminar');
      expect(remote.sent, hasLength(1));
    });

    test('dos pedidos juntos no envian dos veces', () async {
      remote.delay = const Duration(milliseconds: 80);
      cubit.setOnline(false);
      await doc();
      await cubit.setScope(_ana);
      cubit.setOnline(true);
      await cubit.syncNow();
      await cubit.syncNow();
      await _until(() => settled() && cubit.state.pending == 0);
      expect(remote.sent, hasLength(1));
    });

    test(
      'no se lanza sola en bucle: sin novedades no vuelve a enviar',
      () async {
        final a = await doc();
        remote.answers[a.id] = const SyncRejected('no');
        await cubit.setScope(_ana);
        await _until(() => settled() && cubit.state.rejected == 1);
        await _quiet();
        final runs = remote.sent.length;
        await _quiet(250);
        expect(remote.sent.length, runs);
        expect(cubit.state.rejected, 1);
      },
    );
  });

  group('reintentos', () {
    test('un fallo de red se reintenta a la hora indicada', () async {
      final a = await doc();
      remote.answers[a.id] = const SyncRetryLater('sin red');
      await cubit.setScope(_ana);
      await _until(() => settled() && cubit.state.lastReport!.networkFailed);
      expect(cubit.state.pending, 1);
      expect(cubit.state.lastSyncAt, isNull);

      // El servidor vuelve; la hora de reintento ya paso (reloj de prueba).
      remote.answers.clear();
      now = now.add(const Duration(seconds: 1));
      await _until(
        () => cubit.state.pending == 0 && cubit.state.lastSyncAt != null,
        reason: 'reintento',
      );
      expect(remote.sent.length, greaterThanOrEqualTo(2));
    });

    test('la espera de reintento queda a la vista', () async {
      final a = await doc();
      remote.answers[a.id] = const SyncRetryLater(
        'sin red',
        retryAfter: Duration(minutes: 5),
      );
      await cubit.setScope(_ana);
      await _until(() => cubit.state.nextRetryAt != null);
      expect(cubit.state.nextRetryAt, now.add(const Duration(minutes: 5)));
    });
  });

  group('lo que pide una decision', () {
    test('cuenta rechazadas y conflictos', () async {
      final a = await doc();
      final b = await doc(_ana, 'b');
      await doc(_ana, 'c');
      remote.answers[a.id] = const SyncRejected('no');
      remote.answers[b.id] = const SyncConflicted(serverVersion: 2);
      await cubit.setScope(_ana);
      await _until(() => settled() && cubit.state.attention == 2);

      expect(cubit.state.rejected, 1);
      expect(cubit.state.conflicts, 1);
      expect(cubit.state.pending, 0);
      expect(cubit.state.items.map((o) => o.status), [
        OperationStatus.rejected,
        OperationStatus.conflict,
      ]);
    });

    test('el conflicto trae ambas versiones', () async {
      final a = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.update,
        payload: const {'name': 'mio'},
        recordId: 'd1',
        baseVersion: 3,
      );
      remote.answers[a.id] = const SyncConflicted(
        serverVersion: 4,
        serverPayload: {'name': 'otro'},
      );
      await cubit.setScope(_ana);
      await _until(() => cubit.state.conflicts == 1);
      final c = (await cubit.conflictOf(a.id))!;
      expect((c.localVersion, c.serverVersion), (3, 4));
      expect(c.serverPayload, {'name': 'otro'});
    });

    test('reintentar una rechazada la vuelve a enviar', () async {
      final a = await doc();
      remote.answers[a.id] = const SyncRejected('no');
      await cubit.setScope(_ana);
      await _until(() => cubit.state.rejected == 1);

      remote.answers.clear();
      await cubit.retry(a.id);
      await _until(() => cubit.state.items.isEmpty, reason: 'reenvio');
      expect(remote.sent.where((id) => id == a.id), hasLength(2));
    });

    test(
      'resolver un conflicto con la version del servidor reenvia sobre ella',
      () async {
        final a = await queue.enqueue(
          _ana,
          entity: 'documento',
          kind: OperationKind.update,
          payload: const {},
          recordId: 'd1',
          baseVersion: 3,
        );
        remote.answers[a.id] = const SyncConflicted(serverVersion: 4);
        await cubit.setScope(_ana);
        await _until(() => cubit.state.conflicts == 1);

        remote.answers.clear();
        await cubit.retry(a.id, baseVersion: 4);
        await _until(() => cubit.state.items.isEmpty, reason: 'reenvio');
        expect((await queue.find(a.id))!.baseVersion, 4);
        expect((await queue.find(a.id))!.status, OperationStatus.accepted);
      },
    );

    test('descartar quita la operacion de la lista', () async {
      cubit.setOnline(false);
      final a = await doc();
      await cubit.setScope(_ana);
      expect(cubit.state.pending, 1);
      expect(await cubit.discard(a.id), isTrue);
      await _until(() => cubit.state.isEmpty);
    });
  });

  group('cambio de alcance mientras se envia', () {
    test('lo que termine de otro alcance no mancha el nuevo', () async {
      remote.delay = const Duration(milliseconds: 200);
      cubit.setOnline(false);
      await doc(_ana, 'de c1');
      await cubit.setScope(_ana);
      cubit.setOnline(true);
      await _until(() => cubit.state.running, reason: 'debia empezar');

      await cubit.setScope(_anaOtra);
      await _until(() => remote.sent.isNotEmpty);
      await _quiet(400);
      expect(cubit.state.scope, _anaOtra);
      expect(cubit.state.items, isEmpty);
      expect(
        remote.sent,
        hasLength(1),
        reason: 'solo la de la primera concesion',
      );
      // Si hay informe, es de la pasada vacia de la concesion nueva, no de la vieja.
      expect(cubit.state.lastReport?.accepted ?? 0, 0);
    });
  });

  group('sin base local', () {
    test('el cubit deshabilitado no hace nada', () async {
      final off = SyncCubit.disabled();
      expect(off.state.enabled, isFalse);
      await off.setScope(_ana);
      off.setOnline(true);
      await off.syncNow();
      await off.onResume();
      await off.retry('x');
      expect(await off.discard('x'), isFalse);
      expect(await off.conflictOf('x'), isNull);
      expect(off.state.scope, isNull);
      expect(off.state.isEmpty, isTrue);
      await off.close();
    });
  });
}
