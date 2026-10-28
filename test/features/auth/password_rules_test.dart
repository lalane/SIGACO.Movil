import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';
import 'package:sigaco_movil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/account/change_password_cubit.dart';
import 'package:sigaco_movil/features/auth/presentation/account/password_rules_cubit.dart';
import 'package:sigaco_movil/features/auth/presentation/auth_error_text.dart';
import 'package:sigaco_movil/l10n/app_localizations_es.dart';
import 'package:sigaco_movil/l10n/app_localizations_pt.dart';

import '../../support/fake_api.dart';
import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Las reglas de contrasena que se ven antes de escribirla y el motivo cuando el
/// servidor no la acepta (APP-MOB-01, DEV-MOB-042).
void main() {
  group('reglas', () {
    const rules = PasswordRules();

    test('piden por omision lo mismo que el servidor', () {
      expect(rules.minLength, 8);
      expect(rules.required, [
        PasswordRuleKind.length,
        PasswordRuleKind.uppercase,
        PasswordRuleKind.lowercase,
        PasswordRuleKind.digit,
        PasswordRuleKind.special,
      ]);
    });

    test('cada regla se marca por separado', () {
      expect(rules.isMet(PasswordRuleKind.length, 'abcdefg'), isFalse);
      expect(rules.isMet(PasswordRuleKind.length, 'abcdefgh'), isTrue);
      expect(rules.isMet(PasswordRuleKind.uppercase, 'abc'), isFalse);
      expect(rules.isMet(PasswordRuleKind.uppercase, 'aBc'), isTrue);
      expect(rules.isMet(PasswordRuleKind.lowercase, 'ABC'), isFalse);
      expect(rules.isMet(PasswordRuleKind.lowercase, 'ABc'), isTrue);
      expect(rules.isMet(PasswordRuleKind.digit, 'abc'), isFalse);
      expect(rules.isMet(PasswordRuleKind.digit, 'ab3'), isTrue);
      expect(rules.isMet(PasswordRuleKind.special, 'abc123'), isFalse);
      expect(rules.isMet(PasswordRuleKind.special, 'abc!'), isTrue);
    });

    test('las letras con acento cuentan como letras, no como especiales', () {
      expect(rules.isMet(PasswordRuleKind.uppercase, 'Árbol'), isTrue);
      expect(rules.isMet(PasswordRuleKind.lowercase, 'ñandú'), isTrue);
      expect(rules.isMet(PasswordRuleKind.special, 'Ñandú1'), isFalse);
      expect(rules.isMet(PasswordRuleKind.special, 'Ñandú1_'), isTrue);
    });

    test('un espacio no es un caracter especial (como en el servidor)', () {
      expect(rules.isMet(PasswordRuleKind.special, 'abc def'), isFalse);
    });

    test('solo se piden las reglas activas', () {
      const light = PasswordRules(
        minLength: 12,
        requireUppercase: false,
        requireLowercase: true,
        requireDigit: false,
        requireSpecial: false,
      );
      expect(light.required, [
        PasswordRuleKind.length,
        PasswordRuleKind.lowercase,
      ]);
      expect(light.isSatisfiedBy('abcdefghijkl'), isTrue);
      expect(light.isSatisfiedBy('abcdefghijk'), isFalse);
      expect(rules.isSatisfiedBy('Abcdef1!'), isTrue);
      expect(rules.isSatisfiedBy('abcdef1!'), isFalse);
    });

    test('se leen del servidor, con los valores por omision si faltan', () {
      final read = passwordRulesFromJson({
        'minLength': 10,
        'requireUppercase': false,
        'requireLowercase': true,
        'requireDigit': true,
        'requireSpecial': false,
      });
      expect(read.minLength, 10);
      expect(read.requireUppercase, isFalse);
      expect(read.requireSpecial, isFalse);
      expect(passwordRulesFromJson({}), const PasswordRules());
    });
  });

  group('con el servidor', () {
    late FakeApi api;
    late AuthRepositoryImpl repo;

    setUp(() {
      api = FakeApi();
      repo = AuthRepositoryImpl(api.client());
    });

    test('lee las reglas vigentes', () async {
      api.on(
        'GET /api/auth/password-policy',
        const FakeReply(200, {
          'minLength': 12,
          'requireUppercase': true,
          'requireLowercase': true,
          'requireDigit': false,
          'requireSpecial': true,
        }),
      );
      final rules = await repo.passwordRules();
      expect(rules?.minLength, 12);
      expect(rules?.requireDigit, isFalse);
    });

    test('si no las puede leer, no hay reglas y nada se rompe', () async {
      api.on('GET /api/auth/password-policy', const FakeReply(403));
      expect(await repo.passwordRules(), isNull);
      api.offline = true;
      expect(await repo.passwordRules(), isNull);
    });

    test('el servidor que rechaza la contrasena explica por que', () async {
      api.on(
        'POST /api/auth/me/password',
        const FakeReply(400, {
          'title': 'Uno o más campos no son válidos.',
          'errors': {
            'newPassword': [
              'Debe tener al menos 8 caracteres.',
              'Debe contener al menos un número.',
            ],
            'confirmPassword': ['Debe contener al menos un número.'],
          },
        }),
      );
      await expectLater(
        repo.changePassword(current: 'a', next: 'abc', confirm: 'abc'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.error, 'error', AuthError.validation)
              .having((e) => e.details, 'details', [
                'Debe tener al menos 8 caracteres.',
                'Debe contener al menos un número.',
              ]),
        ),
      );
    });

    test('un rechazo sin motivos deja la lista vacia', () async {
      api.on('POST /api/auth/me/password', const FakeReply(400, {}));
      await expectLater(
        repo.changePassword(current: 'a', next: 'abc', confirm: 'abc'),
        throwsA(
          isA<AuthException>().having((e) => e.details, 'details', isEmpty),
        ),
      );
    });
  });

  group('mensaje', () {
    final es = AppLocalizationsEs();
    final pt = AppLocalizationsPt();

    test('con motivos del servidor se muestran esos', () {
      expect(
        authErrorMessage(es, AuthError.validation, const ['A.', 'B.']),
        'A.\nB.',
      );
    });

    test(
      'sin motivos, un texto general que no habla de un error del servidor',
      () {
        final text = authErrorMessage(es, AuthError.validation);
        expect(text, es.errValidation);
        expect(text, isNot(es.errServer));
        expect(authErrorMessage(pt, AuthError.validation), pt.errValidation);
      },
    );

    test('los demas errores no cambian', () {
      expect(
        authErrorMessage(es, AuthError.network, const ['x']),
        es.errNetwork,
      );
    });
  });

  group('cubits', () {
    test('las reglas se cargan una vez y, si fallan, quedan en null', () async {
      final repo = FakeAuthRepository()
        ..rules = const PasswordRules(minLength: 9);
      final cubit = PasswordRulesCubit(repo);
      expect(cubit.state, isNull);
      await cubit.load();
      expect(cubit.state?.minLength, 9);

      repo.rules = null;
      final empty = PasswordRulesCubit(repo);
      await empty.load();
      expect(empty.state, isNull);
    });

    test('el cambio rechazado conserva los motivos del servidor', () async {
      final repo = FakeAuthRepository()
        ..changePasswordError = const AuthException(
          AuthError.validation,
          details: ['Debe tener al menos 8 caracteres.'],
        );
      final cubit = ChangePasswordCubit(repo, FakeCredentialStore());
      await cubit.submit(current: 'a', next: 'abc', confirm: 'abc');
      expect(cubit.state.error, AuthError.validation);
      expect(cubit.state.details, ['Debe tener al menos 8 caracteres.']);
      expect(cubit.state.success, isFalse);
    });
  });

  group('pantalla', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.1.0',
        buildNumber: '7',
        buildSignature: '',
      ),
    );

    Future<void> openPassword(
      WidgetTester tester,
      FakeAuthRepository repo,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
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
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cambiar contraseña'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra las reglas y las marca mientras se escribe', (
      tester,
    ) async {
      await openPassword(tester, FakeAuthRepository());

      expect(find.byKey(const Key('password-rules')), findsOneWidget);
      expect(find.text('La contraseña debe tener:'), findsOneWidget);
      expect(find.text('Al menos 8 caracteres'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));

      // Campo de contrasena nueva: el segundo (actual, nueva, confirmar).
      await tester.enterText(find.byType(EditableText).at(1), 'Abcdef1!');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

      await tester.enterText(find.byType(EditableText).at(1), 'abcdefgh');
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('si el servidor no da las reglas, la pantalla sigue igual', (
      tester,
    ) async {
      await openPassword(tester, FakeAuthRepository()..rules = null);
      expect(find.byKey(const Key('password-rules')), findsNothing);
      expect(find.byType(EditableText), findsNWidgets(3));
    });

    testWidgets('si el servidor la rechaza, dice por que', (tester) async {
      final repo = FakeAuthRepository()
        ..changePasswordError = const AuthException(
          AuthError.validation,
          details: ['La contraseña ya se usó antes.'],
        );
      await openPassword(tester, repo);

      await tester.enterText(find.byType(EditableText).at(0), 'S3creto!x');
      await tester.enterText(find.byType(EditableText).at(1), 'Abcdef1!');
      await tester.enterText(find.byType(EditableText).at(2), 'Abcdef1!');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      expect(find.text('La contraseña ya se usó antes.'), findsOneWidget);
      expect(
        find.text('Ocurrió un error en el servidor. Inténtalo más tarde.'),
        findsNothing,
      );
    });
  });
}
