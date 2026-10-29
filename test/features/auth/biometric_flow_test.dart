import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';
import '../../support/account_nav.dart';

/// Acceso con biometria: tras entrar con correo y contrasena la app ofrece
/// activarla; una vez activa, el boton de huella entra sin escribir nada.
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

  Future<FakeCredentialStore> launch(
    WidgetTester tester, {
    FakeCredentialStore? store,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final credentials = store ?? FakeCredentialStore();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: credentials,
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return credentials;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  const offerTitle = 'Activar acceso con biometría';

  testWidgets('tras el primer acceso ofrece activar la biometria', (
    tester,
  ) async {
    final store = await launch(tester);
    await signIn(tester);

    expect(find.text(offerTitle), findsOneWidget);

    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    expect(store.biometricEnabled, isTrue);
    expect(find.text(offerTitle), findsNothing);
  });

  testWidgets('"Ahora no" se recuerda y no vuelve a insistir', (tester) async {
    final store = await launch(tester);
    await signIn(tester);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(store.biometricEnabled, isFalse);
    expect(store.biometricOfferDeclined, isTrue);
  });

  testWidgets('tocar fuera del aviso no lo rechaza para siempre', (
    tester,
  ) async {
    final store = await launch(tester);
    await signIn(tester);
    expect(find.text(offerTitle), findsOneWidget);

    // El aviso no se cierra tocando el fondo.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text(offerTitle), findsOneWidget);

    // Con el boton atras solo se pospone.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(offerTitle), findsNothing);
    expect(store.biometricOfferDeclined, isFalse);
    expect(store.biometricEnabled, isFalse);
  });

  testWidgets('con la biometria activa, el boton de huella entra directo', (
    tester,
  ) async {
    final store = FakeCredentialStore();
    await store.enableBiometric('x', (email: 'a@b.com', password: 'S3creto!x'));
    await launch(tester, store: store);

    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();

    expect(find.text('MÓDULOS'), findsOneWidget);
    // Ya esta activa: no se ofrece de nuevo.
    expect(find.text(offerTitle), findsNothing);
  });

  testWidgets('sin biometria activa, el boton explica que hacer', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();
    expect(find.textContaining('aún no está activada'), findsOneWidget);
  });

  group('desde la cuenta', () {
    Future<void> openAccountBiometricTile(WidgetTester tester) async {
      await openAccountSettings(tester);
      await tester.scrollUntilVisible(
        find.text('Acceso con biometría'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('permite desactivarla', (tester) async {
      final store = FakeCredentialStore();
      await store.enableBiometric('x', (
        email: 'a@b.com',
        password: 'S3creto!x',
      ));
      await launch(tester, store: store);
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();
      await openAccountBiometricTile(tester);

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(store.biometricEnabled, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(find.text('Acceso con biometría desactivado.'), findsOneWidget);
    });

    testWidgets('permite activarla sin cerrar sesion, tras rechazar el aviso', (
      tester,
    ) async {
      final store = await launch(tester);
      await signIn(tester);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(store.biometricEnabled, isFalse);

      await openAccountBiometricTile(tester);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(store.biometricEnabled, isTrue);
      expect(store.stored?.email, 'a@b.com');
      expect(store.stored?.password, 'S3creto!x');
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
      expect(find.text('Acceso con biometría activado.'), findsOneWidget);
    });

    testWidgets('tocar la fila completa tambien la activa', (tester) async {
      final store = await launch(tester);
      await signIn(tester);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      await openAccountBiometricTile(tester);
      await tester.tap(find.text('Acceso con biometría'));
      await tester.pumpAndSettle();
      expect(store.biometricEnabled, isTrue);
    });
  });

  group('bloc', () {
    test('al cambiar la contrasena en sesion se guarda la nueva', () async {
      final store = FakeCredentialStore();
      final bloc = AuthBloc(FakeAuthRepository(), store)
        ..add(const AuthStarted());
      bloc.add(
        const AuthLoginSubmitted(email: 'a@b.com', password: 'Vieja#1234'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      bloc
        ..add(const AuthPasswordUpdated('Nueva#1234'))
        ..add(const AuthBiometricEnableRequested('x'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(store.biometricEnabled, isTrue);
      expect(store.stored?.password, 'Nueva#1234');
      await bloc.close();
    });

    test('al cerrar sesion se olvida la contrasena de la sesion', () async {
      final store = FakeCredentialStore();
      final bloc = AuthBloc(FakeAuthRepository(), store);
      bloc.add(
        const AuthLoginSubmitted(email: 'a@b.com', password: 'Vieja#1234'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const AuthLogoutRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Ya no hay con que activarla: no hace nada.
      bloc.add(const AuthBiometricEnableRequested('x'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(store.biometricEnabled, isFalse);
      await bloc.close();
    });
  });
}
