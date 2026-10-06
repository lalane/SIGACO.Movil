import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/features/navigation/presentation/bloc/navigation_bloc.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

/// Los accesos se vuelven a consultar durante la sesion (M01-05, M02-02-04) y
/// los estados "sin permiso" y "error de autorizacion" se ven en el inicio
/// (MQ-MOB-08).
void main() {
  group('NavigationBloc: refresco de accesos', () {
    NavigationBloc make(
      FakeNavigationRepository repo, {
      Duration gap = Duration.zero,
      DateTime Function()? clock,
    }) => NavigationBloc(
      repo,
      minRefreshGap: gap,
      deniedRefreshGap: gap,
      clock: clock,
    );

    Future<NavigationBloc> loaded(FakeNavigationRepository repo) async {
      final bloc = make(repo);
      bloc.add(const NavigationRequested());
      await settle();
      return bloc;
    }

    test('actualiza el menu sin vaciarlo y avisa que cambio', () async {
      final repo = FakeNavigationRepository(
        menu: menuWith(['PANEL', 'TICKETS']),
      );
      final bloc = await loaded(repo);
      final seen = <NavigationStatus>[];
      bloc.stream.listen((s) => seen.add(s.status));

      repo.menu = menuWith(['TICKETS']);
      bloc.add(const NavigationRefreshed());
      await settle();

      expect(bloc.state.status, NavigationStatus.ready);
      expect(bloc.state.menu.has('PANEL'), isFalse);
      expect(bloc.state.menu.has('TICKETS'), isTrue);
      expect(bloc.state.accessChanges, 1);
      expect(bloc.state.refreshing, isFalse);
      expect(
        seen,
        everyElement(NavigationStatus.ready),
        reason: 'el menu anterior sigue a la vista mientras se consulta',
      );
      await bloc.close();
    });

    test('si los accesos son los mismos no avisa', () async {
      final repo = FakeNavigationRepository();
      final bloc = await loaded(repo);
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(repo.loads, 2);
      expect(bloc.state.accessChanges, 0);
      await bloc.close();
    });

    test('sin conexion conserva el menu que ya tenia', () async {
      final repo = FakeNavigationRepository();
      final bloc = await loaded(repo);
      repo.failure = NavigationError.network;
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(bloc.state.status, NavigationStatus.ready);
      expect(bloc.state.menu.has('PANEL'), isTrue);
      expect(bloc.state.refreshing, isFalse);
      expect(bloc.state.accessChanges, 0);
      await bloc.close();
    });

    test('si el servidor ya no deja ver nada pasa a sin permiso', () async {
      final repo = FakeNavigationRepository();
      final bloc = await loaded(repo);
      repo.failure = NavigationError.permissionDenied;
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(bloc.state.status, NavigationStatus.failure);
      expect(bloc.state.error, NavigationError.permissionDenied);
      expect(bloc.state.accessChanges, 1);
      await bloc.close();
    });

    test('al volver a la app no consulta antes del tiempo minimo', () async {
      var now = DateTime(2026, 10, 6, 9);
      final repo = FakeNavigationRepository();
      final bloc = NavigationBloc(
        repo,
        minRefreshGap: const Duration(seconds: 30),
        clock: () => now,
      );
      bloc.add(const NavigationRequested());
      await settle();
      expect(repo.loads, 1);

      now = now.add(const Duration(seconds: 10));
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(repo.loads, 1, reason: 'pasaron solo 10 s');

      now = now.add(const Duration(seconds: 25));
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(repo.loads, 2);

      // Jalar para actualizar siempre consulta.
      bloc.add(const NavigationRefreshed(gap: Duration.zero));
      await settle();
      expect(repo.loads, 3);
      await bloc.close();
    });

    test('una accion negada por el servidor vuelve a consultar', () async {
      final repo = FakeNavigationRepository(
        menu: menuWith(['PANEL', 'TICKETS']),
      );
      final bloc = await loaded(repo);
      repo.menu = menuWith(['PANEL']);
      repo.denied.add(null);
      await settle();
      expect(repo.loads, 2);
      expect(bloc.state.menu.has('TICKETS'), isFalse);
      expect(bloc.state.accessChanges, 1);
      await bloc.close();
    });

    test('sin sesion no consulta nada', () async {
      final repo = FakeNavigationRepository();
      final bloc = make(repo);
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(repo.loads, 0);
      expect(bloc.state.status, NavigationStatus.idle);
      await bloc.close();
    });

    test('un menu que fallo se pide completo al refrescar', () async {
      final repo = FakeNavigationRepository(failure: NavigationError.server);
      final bloc = make(repo);
      bloc.add(const NavigationRequested());
      await settle();
      expect(bloc.state.status, NavigationStatus.failure);

      repo.failure = null;
      bloc.add(const NavigationRefreshed());
      await settle();
      expect(bloc.state.status, NavigationStatus.ready);
      await bloc.close();
    });

    test('la respuesta tardia de otro ambiente no pisa el menu', () async {
      final repo = FakeNavigationRepository();
      final bloc = await loaded(repo);
      repo.delay = const Duration(milliseconds: 60);
      repo.menu = menuWith(['REPORTES']);
      bloc.add(const NavigationRefreshed());
      await settle();
      // Se cierra la sesion mientras la consulta sigue en vuelo.
      bloc.add(const NavigationCleared());
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(bloc.state.status, NavigationStatus.idle);
      expect(bloc.state.menu.modules, isEmpty);
      await bloc.close();
    });
  });

  group('inicio: acceso y permisos', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    Future<(FakeNavigationRepository, FakeAuthRepository)> launch(
      WidgetTester tester, {
      NavigationMenu? menu,
      NavigationError? failure,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      SharedPreferences.setMockInitialValues({});
      final nav = FakeNavigationRepository(menu: menu, failure: failure);
      final auth = FakeAuthRepository();
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: auth,
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: nav,
        accessRefreshGap: Duration.zero,
      );
      await tester.pumpWidget(SigacoApp(dependencies: deps));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
      await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      return (nav, auth);
    }

    const changedNotice = 'Tus accesos cambiaron. Se actualizó el menú.';

    testWidgets('si el servidor niega todo, muestra "Sin permiso"', (
      tester,
    ) async {
      final (_, auth) = await launch(
        tester,
        failure: NavigationError.permissionDenied,
      );
      expect(find.text('Sin permiso'), findsOneWidget);
      expect(find.textContaining('contacta al administrador'), findsOneWidget);
      // Nunca se ven codigos ni mensajes tecnicos.
      expect(find.textContaining('403'), findsNothing);
      expect(find.textContaining('PERMISSION'), findsNothing);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(auth.calls, contains('logout'));
    });

    testWidgets('si no se pueden comprobar los accesos, permite reintentar', (
      tester,
    ) async {
      final (nav, _) = await launch(tester, failure: NavigationError.server);
      expect(find.text('No pudimos verificar tus accesos'), findsOneWidget);
      expect(find.text('Sin permiso'), findsNothing);

      nav.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos verificar tus accesos'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('sin conexion se conserva el aviso sencillo con reintento', (
      tester,
    ) async {
      await launch(tester, failure: NavigationError.network);
      expect(find.text('No se pudo cargar tu menú.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('un perfil sin modulos ve "Sin permiso" y puede reintentar', (
      tester,
    ) async {
      final (nav, _) = await launch(tester, menu: const NavigationMenu());
      expect(find.text('Sin permiso'), findsOneWidget);
      expect(
        find.textContaining('no tiene módulos habilitados'),
        findsOneWidget,
      );

      nav.menu = menuWith(['PANEL']);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Sin permiso'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('jalar hacia abajo actualiza los modulos y avisa', (
      tester,
    ) async {
      final (nav, _) = await launch(
        tester,
        menu: menuWith(['PANEL', 'TICKETS']),
      );
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text(changedNotice), findsNothing);

      nav.menu = menuWith(['TICKETS']);
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);
      expect(find.text(changedNotice), findsOneWidget);
    });

    testWidgets('al volver a la app se vuelven a consultar los accesos', (
      tester,
    ) async {
      final (nav, _) = await launch(
        tester,
        menu: menuWith(['PANEL', 'TICKETS']),
      );
      final before = nav.loads;
      nav.menu = menuWith(['TICKETS']);

      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pumpAndSettle();

      expect(nav.loads, before + 1);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text(changedNotice), findsOneWidget);
    });

    testWidgets('si el servidor niega una accion se actualiza el menu', (
      tester,
    ) async {
      final (nav, _) = await launch(
        tester,
        menu: menuWith(['PANEL', 'TICKETS']),
      );
      nav.menu = menuWith(['TICKETS']);
      nav.denied.add(null);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNothing);
      expect(find.text(changedNotice), findsOneWidget);
    });
  });
}
