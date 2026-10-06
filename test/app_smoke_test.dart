import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';
import 'support/surface.dart';

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

  testWidgets('arranca con la marca, pasa al login y valida campos vacios', (
    tester,
  ) async {
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(),
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));

    // Splash: marca visible; despues pasa al login.
    expect(find.bySemanticsLabel('SIGACO'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(
      find.text('Sistema de Gestión de Activos de Concesión'),
      findsOneWidget,
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });

  testWidgets('un acceso correcto lleva al inicio', (tester) async {
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // Menu principal: saludo y solo los modulos que el backend autoriza.
    expect(find.text('Juan Perez'), findsOneWidget);
    // La cabecera refleja la concesion activa.
    expect(find.text('Concesion 0'), findsOneWidget);
    expect(find.text('MÓDULOS'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Accidentes'), findsNothing);
    expect(find.text('Reportes'), findsNothing);
  });

  testWidgets('desde el menu se abre la informacion de la cuenta', (
    tester,
  ) async {
    useSurface(tester, TestSurface.phone);
    // Con la fuente de prueba (cuadrada y ancha) las filas ocupan mas de lo
    // real y la lista no construye las acciones del final.
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();

    expect(find.text('Información de la cuenta'), findsOneWidget);
    expect(find.text('jperez'), findsOneWidget);
    expect(find.text('Concesion 0'), findsOneWidget);
    expect(find.text('Cambiar de concesión'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
  });

  testWidgets('avisa cuando la sesion esta por vencer por inactividad', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeAuthRepository()
      ..activity = DateTime.now().subtract(
        const Duration(minutes: 9, seconds: 30),
      );
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: repo,
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    // El aviso espera a que el router termine de cambiar de pantalla.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión está por vencer'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    // Continuar consulta al servidor y cierra el aviso.
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión está por vencer'), findsNothing);
    expect(repo.calls, contains('profile'));
  });

  testWidgets(
    'con una sola concesion entra directo; con varias pide elegirla primero',
    (tester) async {
      useSurface(tester, TestSurface.phone);
      Future<void> signIn(FakeAuthRepository repo) async {
        SharedPreferences.setMockInitialValues({});
        final deps = AppDependencies(
          prefs: await SharedPreferences.getInstance(),
          authRepository: repo,
          credentialStore: FakeCredentialStore(supportsBiometrics: false),
          navigationRepository: FakeNavigationRepository(),
        );
        await tester.pumpWidget(SigacoApp(dependencies: deps));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
        await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
      }

      // Una concesion: el servidor la deja activa y no hay nada que elegir.
      await signIn(FakeAuthRepository(result: outcome(active: 'c0')));
      expect(find.text('Selecciona tu concesión'), findsNothing);
      expect(find.text('MÓDULOS'), findsOneWidget);

      // Varias sin activa: aparece el selector antes del menu.
      await tester.pumpWidget(const SizedBox());
      await signIn(FakeAuthRepository(result: outcome(concessions: 2)));
      expect(find.text('Selecciona tu concesión'), findsOneWidget);
      expect(find.text('Concesion 1'), findsOneWidget);
      expect(find.text('MÓDULOS'), findsNothing);

      await tester.tap(find.text('Concesion 1'));
      await tester.pumpAndSettle();
      expect(find.text('MÓDULOS'), findsOneWidget);
    },
  );

  for (final (lang, maintenance) in [
    ('es', 'Mantenimientos'),
    ('pt', 'Manutenções'),
  ]) {
    testWidgets('el menu con todos los modulos no desborda ($lang)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_locale': lang});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(loadAppFonts);
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: const NavigationMenu(
            modules: [
              NavigationItem(code: 'PANEL', name: 'Panel'),
              NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
              NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
              NavigationItem(code: 'REPORTES', name: 'Reportes'),
              NavigationItem(code: 'TICKETS', name: 'Tickets'),
              NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
              NavigationItem(
                code: 'ANTT',
                name: 'ANTT',
                submodules: [
                  NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(SigacoApp(dependencies: deps));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
      await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Un desborde de pixeles haria fallar la prueba por si solo.
      expect(find.text(maintenance), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
