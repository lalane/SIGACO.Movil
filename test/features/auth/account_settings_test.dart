import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// El idioma, la apariencia y la verificacion en dos pasos se manejan desde el
/// perfil; el resto de las pantallas no tiene esos selectores.
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

  Future<FakeAuthRepository> launch(
    WidgetTester tester, {
    FakeAuthRepository? auth,
    Map<String, Object> prefsValues = const {},
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues(prefsValues);
    final repo = auth ?? FakeAuthRepository();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: repo,
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> openAccount(WidgetTester tester) async {
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  SigacoPalette palette(WidgetTester tester) => Theme.of(
    tester.element(find.byType(Scaffold).first),
  ).extension<SigacoPalette>()!;

  group('sin selectores fuera del perfil', () {
    testWidgets('ni el login, ni la recuperacion, ni el inicio los tienen', (
      tester,
    ) async {
      await launch(tester);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.palette_outlined), findsNothing);

      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.palette_outlined), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await signIn(tester);
      expect(find.text('MÓDULOS'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byIcon(Icons.palette_outlined), findsNothing);
    });

    testWidgets('antes de iniciar sesion se usa el idioma del telefono', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await launch(tester);
      expect(find.text('Bem-vindo'), findsOneWidget);
    });
  });

  group('idioma y apariencia en el perfil', () {
    testWidgets('se cambia el idioma y se recuerda', (tester) async {
      await launch(tester);
      await signIn(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Preferencias');

      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Português'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'pt');
      // El perfil ya esta en portugues y la fila muestra el idioma elegido.
      expect(find.text('Preferências'), findsOneWidget);
      expect(find.text('Preferencias'), findsNothing);
      expect(find.text('Português'), findsOneWidget);
    });

    testWidgets('se cambia la apariencia y se recuerda', (tester) async {
      await launch(tester);
      await signIn(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Preferencias');
      expect(palette(tester).lightBottom, isFalse);

      await tester.tap(find.text('Apariencia'));
      await tester.pumpAndSettle();
      // La opcion actual aparece en la fila y en la hoja.
      expect(find.text('Original'), findsNWidgets(2));
      await tester.tap(find.text('Día'));
      await tester.pumpAndSettle();

      expect(palette(tester).lightBottom, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appearance'), 'day');
      // El valor elegido se ve en la fila.
      expect(find.text('Día'), findsOneWidget);
    });

    testWidgets('la opcion elegida queda marcada en la hoja', (tester) async {
      await launch(tester, prefsValues: {'appearance': 'night'});
      await signIn(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Preferencias');
      await tester.tap(find.text('Apariencia'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('verificacion en dos pasos en el perfil', () {
    testWidgets('si un administrador no la activo, solo informa', (
      tester,
    ) async {
      final repo = await launch(tester);
      await signIn(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Verificación en dos pasos');

      expect(
        find.textContaining('No está habilitada para tu cuenta'),
        findsOneWidget,
      );
      await tester.tap(find.text('Verificación en dos pasos'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('la activa o desactiva un administrador'),
        findsOneWidget,
      );
      // No cambia nada en el servidor ni abre otra pantalla.
      expect(repo.calls, isNot(contains('activateMfa')));
      expect(find.text('Generar clave nueva'), findsNothing);
    });

    Future<void> signInWithMfa(WidgetTester tester) async {
      await signIn(tester);
      // La cuenta exige codigo: se verifica y se llega al menu.
      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      expect(find.text('MÓDULOS'), findsOneWidget);
    }

    testWidgets('con MFA activa se puede volver a configurar', (tester) async {
      final repo = await launch(
        tester,
        auth: FakeAuthRepository(result: outcome(mfa: true, active: 'c0')),
      );
      await signInWithMfa(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Verificación en dos pasos');
      expect(
        find.textContaining('Activa. Tu código lo genera'),
        findsOneWidget,
      );

      await tester.tap(find.text('Verificación en dos pasos'));
      await tester.pumpAndSettle();
      // Antes de generar nada, se explica lo que pasa con la clave actual.
      expect(find.textContaining('dejará de funcionar'), findsOneWidget);
      expect(find.text('SECRET'), findsNothing);

      await tester.tap(find.text('Generar clave nueva'));
      await tester.pumpAndSettle();
      expect(find.text('SECRET'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '654321');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('activateMfa'));
      // El servidor entrega codigos de recuperacion nuevos: se ven una sola vez
      // y hay que confirmar que se guardaron.
      expect(find.byKey(const Key('recovery-codes')), findsOneWidget);
      expect(find.text('AAAA-1111-BBBB'), findsOneWidget);
      await tester.tap(find.byKey(const Key('recovery-saved')));
      await tester.pumpAndSettle();
      expect(
        find.text('Verificación en dos pasos actualizada.'),
        findsOneWidget,
      );
      // Vuelve al perfil.
      expect(find.text('Configuración de usuario'), findsOneWidget);
    });

    testWidgets('un codigo incorrecto lo informa y permite reintentar', (
      tester,
    ) async {
      final repo = FakeAuthRepository(result: outcome(mfa: true, active: 'c0'))
        ..activationFailure = AuthError.mfaInvalid;
      await launch(tester, auth: repo);
      await signInWithMfa(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Verificación en dos pasos');
      await tester.tap(find.text('Verificación en dos pasos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generar clave nueva'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '000000');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      expect(find.text('El código no es válido.'), findsOneWidget);
      // La clave sigue a la vista para reintentar.
      expect(find.text('SECRET'), findsOneWidget);

      repo.activationFailure = null;
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recovery-saved')));
      await tester.pumpAndSettle();
      expect(find.text('Configuración de usuario'), findsOneWidget);
    });

    testWidgets('sin conexion al generar la clave lo informa', (tester) async {
      final repo = FakeAuthRepository(result: outcome(mfa: true, active: 'c0'))
        ..enrollmentFailure = AuthError.network;
      await launch(tester, auth: repo);
      await signInWithMfa(tester);
      await openAccount(tester);
      await scrollTo(tester, 'Verificación en dos pasos');
      await tester.tap(find.text('Verificación en dos pasos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generar clave nueva'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No hay conexión con el servidor'),
        findsOneWidget,
      );
      expect(find.text('Generar clave nueva'), findsOneWidget);
    });
  });

  group('estado de MFA en el bloc', () {
    Future<AuthBloc> loggedIn(FakeAuthRepository repo) async {
      final bloc = AuthBloc(repo, FakeCredentialStore());
      bloc.add(
        const AuthLoginSubmitted(email: 'a@b.com', password: 'Clave#123'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return bloc;
    }

    test('sin MFA de por medio no esta activa', () async {
      final bloc = await loggedIn(FakeAuthRepository());
      expect(bloc.state.mfaActive, isFalse);
      await bloc.close();
    });

    test(
      'si la cuenta pide el codigo, esta activa y lo sigue estando',
      () async {
        final bloc = await loggedIn(
          FakeAuthRepository(result: outcome(mfa: true, active: 'c0')),
        );
        expect(bloc.state.mfaActive, isTrue);
        bloc.add(const AuthMfaSubmitted('123456'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.mfaRequired, isFalse);
        expect(bloc.state.mfaActive, isTrue);
        await bloc.close();
      },
    );

    test('si pide enrolarla, tambien esta activa', () async {
      final bloc = await loggedIn(
        FakeAuthRepository(result: outcome(enroll: true, active: 'c0')),
      );
      expect(bloc.state.mfaActive, isTrue);
      await bloc.close();
    });
  });
}
