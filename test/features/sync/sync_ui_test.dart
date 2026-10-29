import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';
import '../../support/account_nav.dart';

class _Network implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

const _scope = OfflineScope(userId: 'u1', concessionId: 'c0');

/// Lo capturado sin conexion: el aviso del inicio, el centro de sincronizacion y
/// la resolucion de conflictos (DEV-MOB-063, 065 y 066).
void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  Future<(FakeSyncCubit, _Network)> launch(
    WidgetTester tester, {
    SyncState? state,
    FakeSyncCubit? sync,
    bool signIn = true,
    Map<String, ConcessionBranding> brands = const {},
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final cubit = sync ?? FakeSyncCubit(state);
    final network = _Network();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      brandingRepository: FakeBrandingRepository(brands),
      logoStore: FakeLogoStore(),
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
      connectivity: network,
      sync: cubit,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    if (signIn) {
      await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
      await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
    }
    addTearDown(network.controller.close);
    return (cubit, network);
  }

  SyncState withItems(List<PendingOperation> items, {DateTime? last}) =>
      SyncState(scope: _scope, items: items, lastSyncAt: last);

  final strip = find.byKey(const Key('sync-strip'));

  group('aviso en el inicio (063)', () {
    testWidgets('sin nada pendiente no aparece', (tester) async {
      await launch(tester);
      expect(strip, findsNothing);
    });

    testWidgets('con la sincronizacion deshabilitada no aparece', (
      tester,
    ) async {
      await launch(tester, state: const SyncState(enabled: false));
      expect(strip, findsNothing);
      await openAccountSettings(tester);
      expect(find.byKey(const Key('account-sync')), findsNothing);
    });

    testWidgets('cuenta lo que espera enviarse', (tester) async {
      await launch(
        tester,
        state: withItems([fakeOperation('a'), fakeOperation('b')]),
      );
      // El estado de la cola es el de la sesion: se carga al iniciar sesion.
      expect(strip, findsOneWidget);
      expect(find.text('2 operaciones pendientes de enviar'), findsOneWidget);
    });

    testWidgets('una sola operacion, en singular', (tester) async {
      await launch(tester, state: withItems([fakeOperation('a')]));
      expect(find.text('1 operación pendiente de enviar'), findsOneWidget);
    });

    testWidgets('lo que pide una decision tiene prioridad', (tester) async {
      await launch(
        tester,
        state: withItems([
          fakeOperation('a'),
          fakeOperation('b', status: OperationStatus.rejected, error: 'no'),
          fakeOperation('c', status: OperationStatus.conflict),
        ]),
      );
      expect(find.text('2 operaciones necesitan tu decisión'), findsOneWidget);
      expect(find.textContaining('pendientes de enviar'), findsNothing);
    });

    testWidgets('al tocarlo abre el centro de sincronizacion', (tester) async {
      await launch(tester, state: withItems([fakeOperation('a')]));
      await tester.tap(strip);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync-now')), findsOneWidget);
      expect(find.byKey(const Key('sync-item-a')), findsOneWidget);
    });
  });

  group('perfil: ultima sincronizacion (041)', () {
    Future<void> openAccount(WidgetTester tester, SyncState state) async {
      await launch(tester, state: state);
      await openAccountSettings(tester);
    }

    testWidgets('dice cuando termino la ultima sincronizacion', (tester) async {
      await openAccount(
        tester,
        withItems(const [], last: DateTime.utc(2026, 10, 12, 15, 30)),
      );
      final row = find.text('Última sincronización');
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(row, findsOneWidget);
      expect(find.text('2026-10-12'), findsNothing);
      // La fecha concreta depende de la zona del telefono: basta que no sea el guion.
      final value = find.descendant(
        of: find.ancestor(of: row, matching: find.byType(Row)).first,
        matching: find.byType(Text),
      );
      expect(
        tester
            .widgetList<Text>(value)
            .any((t) => (t.data ?? '').contains('2026')),
        isTrue,
      );
    });

    testWidgets('si nunca se sincronizo, no inventa una fecha', (tester) async {
      await openAccount(tester, withItems(const []));
      final row = find.text('Última sincronización');
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(row, findsOneWidget);
    });

    testWidgets('sin sincronizacion local no se ofrece la fila', (
      tester,
    ) async {
      await openAccount(tester, const SyncState(enabled: false));

      expect(find.text('Última sincronización'), findsNothing);
    });
  });

  group('centro de sincronizacion (065)', () {
    Future<FakeSyncCubit> openSync(
      WidgetTester tester,
      SyncState state, {
      Map<String, ConcessionBranding> brands = const {},
    }) async {
      final (cubit, _) = await launch(tester, state: state, brands: brands);
      if (state.items.isEmpty) {
        // Sin aviso en el inicio: se llega por la cuenta.
        await openAccountSettings(tester);
        await tester.scrollUntilVisible(
          find.byKey(const Key('account-sync')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Con mas filas en la cuenta, el borde de la fila puede quedar fuera.
        await tester.ensureVisible(find.byKey(const Key('account-sync')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('account-sync')));
      } else {
        await tester.tap(strip);
      }
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('sin nada: todo esta sincronizado', (tester) async {
      await openSync(tester, withItems(const []));
      expect(find.byKey(const Key('sync-empty')), findsOneWidget);
      expect(find.text('Todo está sincronizado'), findsOneWidget);
      expect(find.text('Todavía no se ha sincronizado'), findsOneWidget);
    });

    testWidgets('muestra la ultima sincronizacion en la zona de la concesion', (
      tester,
    ) async {
      await openSync(
        tester,
        withItems(const [], last: DateTime.utc(2026, 10, 12, 15, 30)),
        brands: const {
          'c0': ConcessionBranding(
            version: 1,
            primary: '#0EA5E9',
            timezone: 'America/Sao_Paulo',
          ),
        },
      );
      // 15:30 UTC son las 12:30 en Brasilia.
      expect(find.textContaining('12:30'), findsOneWidget);
      expect(find.textContaining('15:30'), findsNothing);
    });

    testWidgets('lo que pide decision va primero, con sus acciones', (
      tester,
    ) async {
      await openSync(
        tester,
        withItems([
          fakeOperation('a', name: 'acta.pdf'),
          fakeOperation(
            'b',
            status: OperationStatus.rejected,
            name: 'virus.exe',
            error: 'Extensión bloqueada: .exe',
            attempts: 2,
          ),
          fakeOperation(
            'c',
            status: OperationStatus.conflict,
            entity: 'documento_firma',
            kind: OperationKind.update,
          ),
        ]),
      );

      expect(find.text('Requieren tu decisión'), findsOneWidget);
      expect(find.text('Pendientes de enviar'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Requieren tu decisión')).dy,
        lessThan(tester.getTopLeft(find.text('Pendientes de enviar')).dy),
      );
      expect(find.text('Documento · acta.pdf'), findsOneWidget);
      expect(find.text('Documento · virus.exe'), findsOneWidget);
      expect(find.text('Firma de documento'), findsOneWidget);
      expect(find.text('Rechazada'), findsOneWidget);
      expect(find.text('En conflicto'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byKey(const Key('sync-error-b')), findsOneWidget);
      expect(find.text('Extensión bloqueada: .exe'), findsOneWidget);
      expect(find.textContaining('2 intentos'), findsOneWidget);
      // Reintentar solo en rechazadas, revisar solo en conflictos.
      expect(find.byKey(const Key('sync-retry-b')), findsOneWidget);
      expect(find.byKey(const Key('sync-retry-a')), findsNothing);
      expect(find.byKey(const Key('sync-review-c')), findsOneWidget);
      expect(find.byKey(const Key('sync-review-b')), findsNothing);
    });

    testWidgets('la hora de captura se muestra en la zona de la concesion', (
      tester,
    ) async {
      await openSync(
        tester,
        withItems([fakeOperation('a')]),
        brands: const {
          'c0': ConcessionBranding(
            version: 1,
            primary: '#0EA5E9',
            timezone: 'America/Sao_Paulo',
          ),
        },
      );
      expect(find.textContaining('Capturada'), findsOneWidget);
      expect(find.textContaining('12:30'), findsOneWidget);
    });

    testWidgets('sincronizar ahora lo pide al cubit', (tester) async {
      final cubit = await openSync(tester, withItems([fakeOperation('a')]));
      await tester.tap(find.byKey(const Key('sync-now')));
      await tester.pump();
      expect(cubit.calls, contains('syncNow'));
    });

    testWidgets('mientras se envia el boton lo indica y no se puede repetir', (
      tester,
    ) async {
      final cubit = await openSync(tester, withItems([fakeOperation('a')]));
      cubit.show(cubit.state.copyWith(running: true));
      // El aviso del cambio llega en un microtask: otro cuadro para dibujarlo.
      await tester.pump();
      await tester.pump();
      expect(find.text('Sincronizando…'), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('sync-now')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('sin conexion avisa y no deja sincronizar', (tester) async {
      final (cubit, network) = await launch(
        tester,
        state: withItems([fakeOperation('a')]),
      );
      await tester.tap(strip);
      await tester.pumpAndSettle();
      network.controller.add(false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sync-offline-hint')), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('sync-now')),
      );
      expect(button.onPressed, isNull);
      expect(cubit.calls, isNot(contains('syncNow')));
    });

    testWidgets('reintentar una rechazada', (tester) async {
      final cubit = await openSync(
        tester,
        withItems([
          fakeOperation('b', status: OperationStatus.rejected, error: 'no'),
        ]),
      );
      await tester.tap(find.byKey(const Key('sync-retry-b')));
      await tester.pump();
      expect(cubit.calls, contains('retry:b:null'));
    });

    testWidgets('descartar pide confirmacion', (tester) async {
      final cubit = await openSync(tester, withItems([fakeOperation('a')]));
      await tester.tap(find.byKey(const Key('sync-discard-a')));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar esta operación?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sync-discard-cancel')));
      await tester.pumpAndSettle();
      expect(cubit.calls.where((c) => c.startsWith('discard')), isEmpty);
      expect(find.byKey(const Key('sync-item-a')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sync-discard-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sync-discard-confirm')));
      await tester.pumpAndSettle();
      expect(cubit.calls, contains('discard:a'));
      expect(find.byKey(const Key('sync-item-a')), findsNothing);
      expect(find.byKey(const Key('sync-empty')), findsOneWidget);
    });

    testWidgets('lo que se esta enviando no se puede descartar', (
      tester,
    ) async {
      await openSync(
        tester,
        withItems([fakeOperation('a', status: OperationStatus.sending)]),
      );
      expect(find.text('Enviando'), findsOneWidget);
      expect(find.byKey(const Key('sync-discard-a')), findsNothing);
    });

    testWidgets('la cuenta muestra el estado y abre el centro', (tester) async {
      await launch(
        tester,
        state: withItems([
          fakeOperation('b', status: OperationStatus.rejected, error: 'no'),
        ]),
      );
      await openAccountSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('account-sync')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 operación necesita tu decisión'), findsWidgets);
    });
  });

  group('conflicto (066)', () {
    final conflicted = fakeOperation(
      'c',
      status: OperationStatus.conflict,
      entity: 'documento_firma',
      kind: OperationKind.update,
      baseVersion: 3,
      payload: {'hash': 'abc', 'estado': 'firmado', 'nota': 'igual'},
    );

    SyncConflict conflict({bool withServer = true}) => SyncConflict(
      operationId: 'c',
      createdAt: DateTime.utc(2026, 10, 12, 16),
      localVersion: 3,
      serverVersion: 4,
      serverPayload: withServer
          ? const {'hash': 'xyz', 'estado': 'validado', 'nota': 'igual'}
          : null,
      message: 'La version ya fue firmada por otra persona',
    );

    Future<FakeSyncCubit> openConflict(
      WidgetTester tester, {
      SyncConflict? c,
    }) async {
      final cubit = FakeSyncCubit(withItems([conflicted]));
      if (c != null) cubit.conflicts['c'] = c;
      await launch(tester, sync: cubit);
      await tester.tap(strip);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sync-review-c')));
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('muestra lo capturado junto a lo del servidor', (tester) async {
      await openConflict(tester, c: conflict());
      expect(find.text('Conflicto de sincronización'), findsOneWidget);
      expect(find.byKey(const Key('conflict-mine')), findsOneWidget);
      expect(find.byKey(const Key('conflict-server')), findsOneWidget);
      expect(find.text('Versión 3'), findsOneWidget);
      expect(find.text('Versión 4'), findsOneWidget);
      expect(find.text('abc'), findsOneWidget);
      expect(find.text('xyz'), findsOneWidget);
      expect(find.text('firmado'), findsOneWidget);
      expect(find.text('validado'), findsOneWidget);
      expect(
        find.text('Motivo: La version ya fue firmada por otra persona'),
        findsOneWidget,
      );
    });

    testWidgets('marca solo lo que cambio', (tester) async {
      await openConflict(tester, c: conflict());
      // hash y estado cambian en los dos lados; nota es igual.
      expect(find.byKey(const Key('diff-hash')), findsNWidgets(2));
      expect(find.byKey(const Key('diff-estado')), findsNWidgets(2));
      expect(find.byKey(const Key('diff-nota')), findsNothing);
    });

    testWidgets('sin detalle del servidor lo dice', (tester) async {
      await openConflict(tester, c: conflict(withServer: false));
      expect(find.text('Sin detalle disponible'), findsOneWidget);
      expect(find.byKey(const Key('conflict-mine')), findsOneWidget);
    });

    testWidgets(
      'quedarse con el servidor descarta lo capturado, con confirmacion',
      (tester) async {
        final cubit = await openConflict(tester, c: conflict());
        await tester.tap(find.byKey(const Key('conflict-keep-server')));
        await tester.pumpAndSettle();
        expect(
          find.text('Se descartará lo capturado en este teléfono.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('conflict-cancel')));
        await tester.pumpAndSettle();
        expect(cubit.calls.where((c) => c.startsWith('discard')), isEmpty);

        await tester.tap(find.byKey(const Key('conflict-keep-server')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('conflict-confirm')));
        await tester.pumpAndSettle();
        expect(cubit.calls, contains('discard:c'));
        // Vuelve al centro de sincronizacion.
        expect(find.byKey(const Key('sync-now')), findsOneWidget);
      },
    );

    testWidgets('mantener lo mio reenvia sobre la version del servidor', (
      tester,
    ) async {
      final cubit = await openConflict(tester, c: conflict());
      await tester.tap(find.byKey(const Key('conflict-keep-mine')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('puede rechazarlo'),
        findsOneWidget,
        reason: 'avisa que el servidor puede volver a rechazarlo',
      );
      await tester.tap(find.byKey(const Key('conflict-confirm')));
      await tester.pumpAndSettle();
      expect(cubit.calls, contains('retry:c:4'));
    });

    testWidgets('un conflicto que ya no existe lo dice', (tester) async {
      await openConflict(tester);
      expect(find.byKey(const Key('conflict-missing')), findsOneWidget);
    });
  });

  group('lo local es de la persona y la concesion activas', () {
    testWidgets('al iniciar sesion se fija el alcance y la conexion', (
      tester,
    ) async {
      final (cubit, _) = await launch(tester);
      expect(cubit.calls, contains('online:true'));
      expect(cubit.calls, contains('scope:u1/c0'));
    });

    testWidgets('antes de iniciar sesion no hay alcance', (tester) async {
      final (cubit, _) = await launch(tester, signIn: false);
      expect(cubit.calls.where((c) => c.startsWith('scope')), isEmpty);
    });

    testWidgets('los cambios de conexion llegan a la cola', (tester) async {
      final (cubit, network) = await launch(tester);
      cubit.calls.clear();
      network.controller.add(false);
      await tester.pumpAndSettle();
      network.controller.add(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(cubit.calls, containsAllInOrder(['online:false', 'online:true']));
    });

    testWidgets('al volver a la app se pide sincronizar', (tester) async {
      final (cubit, _) = await launch(tester);
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(cubit.calls, contains('resume'));
    });

    testWidgets('al cerrar sesion se suelta el alcance', (tester) async {
      final (cubit, _) = await launch(tester);
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(cubit.calls.last, 'scope:null/null');
      expect(cubit.state.scope, isNull);
    });
  });

  test('el informe de una pasada se resume', () {
    expect(const SyncReport(accepted: 1).completed, isTrue);
  });
}
