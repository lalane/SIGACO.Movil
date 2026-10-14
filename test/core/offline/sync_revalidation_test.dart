import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/sync_revalidation.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fakes.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');

class _Remote implements SyncRemote {
  final sent = <String>[];

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    sent.add(operation.id);
    return const SyncAccepted();
  }
}

NavigationMenu _menu(List<String> permissions) =>
    NavigationMenu(permissions: permissions);

/// Antes de enviar se revalida la sesion y los permisos (DEV-MOB-094 y 095,
/// DTF M03 §3.2, CA-HU-MOB-03-02-04).
void main() {
  sqfliteFfiInit();

  late OfflineDatabase db;
  late OperationQueue queue;
  late FakeNavigationRepository navigation;
  late SyncRevalidation revalidation;

  setUp(() async {
    db = await OfflineDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    queue = OperationQueue(db);
    navigation = FakeNavigationRepository(
      menu: _menu([
        PermissionKeys.documentsView,
        PermissionKeys.documentsUpload,
        PermissionKeys.documentsSign,
      ]),
    );
    revalidation = SyncRevalidation(
      navigation: navigation,
      queue: queue,
      requiredPermissions: const {
        'documento': [
          PermissionKeys.documentsView,
          PermissionKeys.documentsUpload,
        ],
        'documento_firma': [
          PermissionKeys.documentsView,
          PermissionKeys.documentsSign,
        ],
      },
    );
  });

  tearDown(() => db.close());

  Future<PendingOperation> add(String entity) => queue.enqueue(
    _ana,
    entity: entity,
    kind: OperationKind.insert,
    payload: {'name': '$entity.pdf'},
  );

  test('con la sesion y los permisos vigentes, se envia', () async {
    final op = await add('documento');

    expect(await revalidation(_ana), SyncGate.proceed);

    expect((await queue.find(op.id))!.status, OperationStatus.pending);
    expect(navigation.loads, 1);
  });

  test('si el servidor no confirma la sesion, no se envia nada', () async {
    final op = await add('documento');
    for (final failure in NavigationError.values) {
      navigation.failure = failure;

      expect(await revalidation(_ana), SyncGate.hold);
    }
    // Lo capturado se conserva tal cual para otro intento.
    expect((await queue.find(op.id))!.status, OperationStatus.pending);
  });

  test(
    'una operacion cuyo permiso se retiro queda rechazada, no se envia',
    () async {
      final upload = await add('documento');
      final sign = await add('documento_firma');
      navigation.menu = _menu([
        PermissionKeys.documentsView,
        PermissionKeys.documentsUpload,
      ]);

      expect(await revalidation(_ana), SyncGate.proceed);

      expect((await queue.find(upload.id))!.status, OperationStatus.pending);
      final rejected = (await queue.find(sign.id))!;
      expect(rejected.status, OperationStatus.rejected);
      expect(rejected.lastError, SyncRevalidation.withdrawnMessage);
    },
  );

  test('sin Ver tampoco se envia nada del gestor documental', () async {
    final upload = await add('documento');
    navigation.menu = _menu([PermissionKeys.documentsUpload]);

    await revalidation(_ana);

    expect((await queue.find(upload.id))!.status, OperationStatus.rejected);
  });

  test(
    'un tipo de registro que no exige permiso conocido sigue su curso',
    () async {
      final other = await add('ticket');
      navigation.menu = _menu(const []);

      await revalidation(_ana);

      expect((await queue.find(other.id))!.status, OperationStatus.pending);
    },
  );

  test('solo mira lo de la persona y concesion activas', () async {
    const luis = OfflineScope(userId: 'luis', concessionId: 'c1');
    final suya = await queue.enqueue(
      luis,
      entity: 'documento_firma',
      kind: OperationKind.insert,
      payload: {'name': 'a'},
    );
    navigation.menu = _menu(const []);

    await revalidation(_ana);

    expect((await queue.find(suya.id))!.status, OperationStatus.pending);
  });

  test(
    'con el motor: una operacion sin permiso nunca llega al servidor',
    () async {
      final upload = await add('documento');
      final sign = await add('documento_firma');
      navigation.menu = _menu([
        PermissionKeys.documentsView,
        PermissionKeys.documentsUpload,
      ]);
      final remote = _Remote();
      final engine = SyncEngine(queue, remote, preflight: revalidation.call);

      final report = await engine.run(_ana);

      expect(remote.sent, [upload.id]);
      expect(report.accepted, 1);
      expect((await queue.find(sign.id))!.status, OperationStatus.rejected);
    },
  );

  test('con el motor: sin sesion confirmada se retiene la pasada', () async {
    await add('documento');
    navigation.failure = NavigationError.permissionDenied;
    final remote = _Remote();
    final engine = SyncEngine(queue, remote, preflight: revalidation.call);

    final report = await engine.run(_ana);

    expect(report.held, isTrue);
    expect(remote.sent, isEmpty);
  });

  group('descartar', () {
    test('avisa para borrar el archivo que se guardo en el telefono', () async {
      final op = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: {'name': 'a.pdf', 'localPath': '/kept/1/a.pdf'},
      );
      final discarded = <String>[];
      final cubit = SyncCubit(
        queue,
        SyncEngine(queue, _Remote()),
        onDiscarded: (o) async => discarded.add('${o.payload['localPath']}'),
      );
      addTearDown(cubit.close);

      expect(await cubit.discard(op.id), isTrue);

      expect(discarded, ['/kept/1/a.pdf']);
      expect(await queue.find(op.id), isNull);
    });

    test('lo que no se pudo descartar no borra nada', () async {
      final op = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: {'name': 'a.pdf', 'localPath': '/kept/1/a.pdf'},
      );
      await queue.markSending(op.id);
      await queue.markAccepted(op.id);
      final discarded = <String>[];
      final cubit = SyncCubit(
        queue,
        SyncEngine(queue, _Remote()),
        onDiscarded: (o) async => discarded.add(o.id),
      );
      addTearDown(cubit.close);

      // Una aceptada nunca se descarta.
      expect(await cubit.discard(op.id), isFalse);

      expect(discarded, isEmpty);
    });

    test('si borrar el archivo falla, el descarte igual se hace', () async {
      final op = await queue.enqueue(
        _ana,
        entity: 'documento',
        kind: OperationKind.insert,
        payload: {'name': 'a.pdf', 'localPath': '/kept/1/a.pdf'},
      );
      final cubit = SyncCubit(
        queue,
        SyncEngine(queue, _Remote()),
        onDiscarded: (o) async => throw StateError('disco'),
      );
      addTearDown(cubit.close);

      expect(await cubit.discard(op.id), isTrue);
      expect(await queue.find(op.id), isNull);
    });
  });
}
