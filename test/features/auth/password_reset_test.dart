import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_state.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Restablecer la contrasena (FEAT-M01-03): el enlace del correo se abre en el
/// navegador, ahi se define la nueva y el portal devuelve al usuario a la app
/// con `sigaco://app/login?reset=ok`.
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

  group('bloc', () {
    blocTest<AuthBloc, AuthState>(
      'pedir el enlace lo marca como enviado',
      build: () => AuthBloc(FakeAuthRepository(), FakeCredentialStore()),
      act: (b) => b.add(const AuthRecoveryRequested(' a@b.com ')),
      wait: const Duration(milliseconds: 10),
      verify: (b) {
        expect(b.state.recoverySent, isTrue);
        expect(b.state.busy, isFalse);
        expect(b.state.error, isNull);
      },
    );

    for (final error in [AuthError.network, AuthError.server]) {
      blocTest<AuthBloc, AuthState>(
        'si la solicitud no llega ($error) no dice que se envio',
        build: () => AuthBloc(
          FakeAuthRepository()..recoveryFailure = error,
          FakeCredentialStore(),
        ),
        act: (b) => b.add(const AuthRecoveryRequested('a@b.com')),
        wait: const Duration(milliseconds: 10),
        verify: (b) {
          expect(b.state.recoverySent, isFalse);
          expect(b.state.error, error);
          expect(b.state.busy, isFalse);
        },
      );
    }

    blocTest<AuthBloc, AuthState>(
      'al abrir la pantalla se descarta el envio anterior',
      build: () => AuthBloc(FakeAuthRepository(), FakeCredentialStore()),
      act: (b) async {
        b.add(const AuthRecoveryRequested('a@b.com'));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        b.add(const AuthRecoveryOpened());
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.recoverySent, isFalse),
    );

    test('al volver del navegador se olvida la contrasena guardada', () async {
      final store = FakeCredentialStore();
      await store.setRemembered(
        remember: true,
        credentials: (email: 'a@b.com', password: 'Vieja#123'),
      );
      await store.enableBiometric('x', (
        email: 'a@b.com',
        password: 'Vieja#123',
      ));
      final bloc = AuthBloc(FakeAuthRepository(), store)
        ..add(const AuthStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state.rememberedPassword, 'Vieja#123');
      expect(bloc.state.biometricEnabled, isTrue);

      bloc.add(const AuthPasswordResetReturned());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.passwordResetDone, isTrue);
      expect(bloc.state.rememberedPassword, isNull);
      expect(bloc.state.rememberedEmail, 'a@b.com');
      expect(bloc.state.biometricEnabled, isFalse);
      expect(await store.readRememberedPassword(), isNull);
      await bloc.close();
    });

    test(
      'el aviso se quita al iniciar sesion con la nueva contrasena',
      () async {
        final bloc = AuthBloc(FakeAuthRepository(), FakeCredentialStore())
          ..add(const AuthPasswordResetReturned());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.passwordResetDone, isTrue);

        bloc.add(
          const AuthLoginSubmitted(email: 'a@b.com', password: 'Nueva#1234'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(bloc.state.step, AuthStep.signedIn);
        expect(bloc.state.passwordResetDone, isFalse);
        await bloc.close();
      },
    );
  });

  group('pantallas', () {
    Future<(FakeAuthRepository, FakeCredentialStore)> launch(
      WidgetTester tester, {
      FakeAuthRepository? repo,
      FakeCredentialStore? store,
      String? deepLink,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      if (deepLink != null) {
        tester.platformDispatcher.defaultRouteNameTestValue = deepLink;
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      }
      SharedPreferences.setMockInitialValues({});
      final authRepo = repo ?? FakeAuthRepository();
      final credentials =
          store ?? FakeCredentialStore(supportsBiometrics: false);
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: authRepo,
        credentialStore: credentials,
        navigationRepository: FakeNavigationRepository(),
      );
      await tester.pumpWidget(SigacoApp(dependencies: deps));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      return (authRepo, credentials);
    }

    testWidgets('pide el correo antes de enviar', (tester) async {
      final (repo, _) = await launch(tester);
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
      expect(repo.calls, isNot(contains('recovery')));

      await tester.enterText(find.byType(EditableText).first, 'sin-arroba');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ingresa un correo electrónico válido.'),
        findsOneWidget,
      );
      expect(repo.calls, isNot(contains('recovery')));
    });

    testWidgets('tras pedir el enlace explica como volver a la app', (
      tester,
    ) async {
      final (repo, _) = await launch(tester);
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.text('Qué hacer ahora'), findsNothing);

      await tester.enterText(find.byType(EditableText).first, 'a@b.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('recovery'));
      expect(find.text('Qué hacer ahora'), findsOneWidget);
      expect(find.textContaining('Volver a la aplicación'), findsOneWidget);
      expect(find.text('Reenviar enlace'), findsOneWidget);

      await tester.tap(find.text('Volver a iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido'), findsOneWidget);

      // Al abrir de nuevo la pantalla no queda el resultado anterior.
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.text('Qué hacer ahora'), findsNothing);
    });

    testWidgets('sin conexion no dice que el correo se envio', (tester) async {
      final (_, _) = await launch(
        tester,
        repo: FakeAuthRepository()..recoveryFailure = AuthError.network,
      );
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'a@b.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No hay conexión con el servidor'),
        findsOneWidget,
      );
      expect(find.text('Qué hacer ahora'), findsNothing);
    });

    testWidgets('el enlace de regreso muestra el aviso y limpia lo guardado', (
      tester,
    ) async {
      final store = FakeCredentialStore();
      await store.setRemembered(
        remember: true,
        credentials: (email: 'a@b.com', password: 'Vieja#123'),
      );
      await store.enableBiometric('x', (
        email: 'a@b.com',
        password: 'Vieja#123',
      ));

      await launch(tester, store: store, deepLink: '/login?reset=ok');

      expect(
        find.text(
          'Contraseña actualizada. Inicia sesión con tu nueva contraseña.',
        ),
        findsOneWidget,
      );
      final fields = tester.widgetList<EditableText>(find.byType(EditableText));
      expect(fields.first.controller.text, 'a@b.com');
      expect(fields.last.controller.text, isEmpty);
      expect(store.biometricEnabled, isFalse);
      expect(await store.readRememberedPassword(), isNull);
    });

    testWidgets('sin el enlace de regreso no aparece el aviso', (tester) async {
      await launch(tester);
      expect(find.textContaining('Contraseña actualizada'), findsNothing);
    });
  });
}
