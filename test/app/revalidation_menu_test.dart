import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/surface.dart';

class _Network implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

/// Al confirmar la sesion con el servidor, la navegacion se reconstruye si los
/// accesos cambiaron (HU-M01-08-04, CA-03) y al volver la conexion se revalida.
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

  late FakeAuthRepository auth;
  late FakeNavigationRepository nav;
  late _Network network;

  Future<void> launch(WidgetTester tester) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    nav = FakeNavigationRepository(
      menu: menuWith(['PANEL', 'TICKETS', 'INVENTARIO']),
    );
    network = _Network();
    addTearDown(network.controller.close);
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: auth,
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: nav,
      accessRefreshGap: Duration.zero,
      connectivity: network,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  testWidgets('si los accesos son los mismos, no se vuelve a pedir el menu', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Registros'), findsWidgets);
    final before = nav.loads;

    auth.revalidated.add(
      fakeRevalidation(
        modules: ['PANEL', 'TICKETS', 'INVENTARIO'],
        permissions: nav.menu.permissions,
      ),
    );
    await tester.pumpAndSettle();

    expect(nav.loads, before);
  });

  testWidgets('si ya no tiene un modulo, el menu se reconstruye sin el', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Registros'), findsWidgets);
    final before = nav.loads;

    // Mientras no habia red, un administrador le quito Tickets.
    nav.menu = menuWith(['PANEL', 'INVENTARIO']);
    auth.revalidated.add(
      fakeRevalidation(
        modules: ['PANEL', 'INVENTARIO'],
        permissions: nav.menu.permissions,
      ),
    );
    await tester.pumpAndSettle();

    expect(nav.loads, greaterThan(before));
    expect(find.text('Registros'), findsNothing);
  });

  testWidgets('si cambian solo los permisos, tambien se reconstruye', (
    tester,
  ) async {
    await launch(tester);
    final before = nav.loads;

    auth.revalidated.add(
      fakeRevalidation(
        modules: ['PANEL', 'TICKETS', 'INVENTARIO'],
        permissions: const ['TICKETS:LEER'],
      ),
    );
    await tester.pumpAndSettle();

    expect(nav.loads, greaterThan(before));
  });

  testWidgets('una respuesta sin menu no cambia nada', (tester) async {
    await launch(tester);
    final before = nav.loads;

    auth.revalidated.add(fakeRevalidation());
    await tester.pumpAndSettle();

    expect(nav.loads, before);
  });

  testWidgets('al volver la conexion se confirma la sesion con el servidor', (
    tester,
  ) async {
    await launch(tester);
    expect(auth.calls, isNot(contains('revalidate')));

    network.controller.add(false);
    await tester.pumpAndSettle();
    expect(auth.calls, isNot(contains('revalidate')), reason: 'sin red no hay');

    network.controller.add(true);
    await tester.pumpAndSettle();

    expect(auth.calls, contains('revalidate'));
  });

  testWidgets('si no hay respuesta, se sigue como estaba y se reintenta', (
    tester,
  ) async {
    await launch(tester);
    auth.revalidationFailure = AuthError.network;

    network.controller.add(false);
    await tester.pumpAndSettle();
    network.controller.add(true);
    await tester.pumpAndSettle();

    expect(auth.calls, contains('revalidate'));
    expect(find.text('Registros'), findsWidgets);
  });

  testWidgets('si el servidor revoco la sesion, vuelve al acceso', (
    tester,
  ) async {
    await launch(tester);
    auth.revalidationFailure = AuthError.sessionExpired;

    network.controller.add(false);
    await tester.pumpAndSettle();
    network.controller.add(true);
    await tester.pumpAndSettle();

    // El 401 SESSION_REVOKED devuelve al inicio de sesion.
    expect(find.byType(EditableText), findsNWidgets(2));
    expect(find.text('Registros'), findsNothing);
  });
}
