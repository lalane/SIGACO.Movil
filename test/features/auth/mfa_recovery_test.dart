import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/account/mfa_setup_cubit.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_state.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Verificacion en dos pasos: estado que informa el servidor y codigos de
/// recuperacion (DEV-BACK-132, DEV-MOB-052).
void main() {
  group('lo que informa el servidor', () {
    Map<String, dynamic> me({Object? mfa}) => {
      'account': {
        'id': 'u1',
        'username': 'jperez',
        'fullName': 'Juan Perez',
        'email': 'j@x.com',
      },
      'context': {'availableConcessions': []},
      'mfa': mfa,
    };

    test('el perfil trae si esta activa y cuantos codigos quedan', () {
      final p = profileFromJson(
        me(
          mfa: {
            'required': true,
            'active': true,
            'method': 'TOTP',
            'status': 'ACTIVE',
            'recoveryCodesRemaining': 7,
          },
        ),
      );

      expect(p.mfa?.active, isTrue);
      expect(p.mfa?.required, isTrue);
      expect(p.mfa?.recoveryCodesRemaining, 7);
    });

    test('un servidor que no lo informa deja el estado desconocido', () {
      expect(profileFromJson(me()).mfa, isNull);
    });

    test('sin el contador de codigos se cuenta cero', () {
      final p = profileFromJson(me(mfa: {'required': false, 'active': false}));

      expect(p.mfa?.recoveryCodesRemaining, 0);
      expect(p.mfa?.active, isFalse);
    });

    test('los codigos de la respuesta se leen sin vacios', () {
      expect(
        recoveryCodesFromJson({
          'recoveryCodes': ['AAAA-1111', ' BBBB-2222 ', '', 7],
        }),
        ['AAAA-1111', 'BBBB-2222'],
      );
      expect(recoveryCodesFromJson(null), isEmpty);
      expect(recoveryCodesFromJson({}), isEmpty);
    });
  });

  group('al activar la verificacion en el acceso', () {
    Future<AuthBloc> pendingEnrollment(FakeAuthRepository repo) async {
      final bloc = AuthBloc(repo, FakeCredentialStore());
      bloc.add(
        const AuthLoginSubmitted(email: 'a@b.com', password: 'Clave#123'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return bloc;
    }

    test('antes de seguir se muestran los codigos y se confirma', () async {
      final repo = FakeAuthRepository(
        result: outcome(enroll: true, active: 'c0'),
      );
      final bloc = await pendingEnrollment(repo);
      expect(bloc.state.step, AuthStep.mfaEnroll);

      bloc.add(const AuthMfaActivationSubmitted('123456'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.step, AuthStep.mfaCodes);
      expect(bloc.state.recoveryCodes, ['AAAA-1111-BBBB', 'CCCC-2222-DDDD']);
      expect(bloc.state.mfaActive, isTrue);

      bloc.add(const AuthRecoveryCodesAcknowledged());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.step, AuthStep.signedIn);
      expect(
        bloc.state.recoveryCodes,
        isEmpty,
        reason: 'no se muestran de nuevo',
      );
      await bloc.close();
    });

    test('un codigo incorrecto no entrega codigos', () async {
      final repo = FakeAuthRepository(
        result: outcome(enroll: true, active: 'c0'),
      )..activationFailure = AuthError.mfaInvalid;
      final bloc = await pendingEnrollment(repo);

      bloc.add(const AuthMfaActivationSubmitted('000000'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.step, AuthStep.mfaEnroll);
      expect(bloc.state.recoveryCodes, isEmpty);
      expect(bloc.state.error, AuthError.mfaInvalid);
      await bloc.close();
    });

    test('los codigos nunca salen en la traza del estado', () async {
      final repo = FakeAuthRepository(
        result: outcome(enroll: true, active: 'c0'),
      );
      final bloc = await pendingEnrollment(repo);
      bloc.add(const AuthMfaActivationSubmitted('123456'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.toString(), isNot(contains('AAAA')));
      await bloc.close();
    });
  });

  group('desde el perfil', () {
    late FakeAuthRepository repo;
    late MfaSetupCubit cubit;

    setUp(() {
      repo = FakeAuthRepository()
        ..profile = MyProfile(
          user: testProfile.user,
          activeConcession: testProfile.activeConcession,
          profile: testProfile.profile,
          roads: testProfile.roads,
          availableConcessions: testProfile.availableConcessions,
          mfa: const MfaStatus(
            required: true,
            active: true,
            recoveryCodesRemaining: 4,
          ),
        );
      cubit = MfaSetupCubit(repo);
    });
    tearDown(() => cubit.close());

    test('muestra cuantos codigos quedan', () async {
      await cubit.loadStatus();

      expect(cubit.state.recoveryRemaining, 4);
    });

    test('si el servidor no responde, simplemente no hay numero', () async {
      repo.profileFailure = AuthError.network;
      await cubit.loadStatus();

      expect(cubit.state.recoveryRemaining, isNull);
    });

    test('generar codigos nuevos pide el codigo de la app', () async {
      cubit.startRegeneration();
      expect(cubit.state.regenerating, isTrue);

      await cubit.regenerate(' 123456 ');

      expect(repo.calls, contains('regenerate:123456'));
      expect(cubit.state.recoveryCodes, hasLength(2));
      expect(cubit.state.recoveryRemaining, 2);
      expect(cubit.state.done, isFalse, reason: 'no es volver a enrolar');
    });

    test('un codigo de la app incorrecto no cambia nada', () async {
      repo.regenerationFailure = AuthError.mfaInvalid;
      cubit.startRegeneration();

      await cubit.regenerate('000000');

      expect(cubit.state.recoveryCodes, isEmpty);
      expect(cubit.state.error, AuthError.mfaInvalid);
      expect(cubit.state.regenerating, isTrue, reason: 'puede reintentar');
    });

    test('al volver a enrolar tambien entrega codigos', () async {
      await cubit.generate();
      await cubit.confirm('654321');

      expect(cubit.state.done, isTrue);
      expect(cubit.state.recoveryCodes, hasLength(2));

      cubit.acknowledgeCodes();
      expect(cubit.state.recoveryCodes, isEmpty);
    });

    test('la traza del cubit no incluye los codigos', () async {
      await cubit.generate();
      await cubit.confirm('654321');

      expect(cubit.state.toString(), isNot(contains('AAAA')));
    });
  });

  group('en la app', () {
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
      WidgetTester tester,
      FakeAuthRepository repo,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      SharedPreferences.setMockInitialValues(const {});
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
      return repo;
    }

    testWidgets('el acceso acepta un codigo de recuperacion', (tester) async {
      final repo = await launch(
        tester,
        FakeAuthRepository(result: outcome(mfa: true, active: 'c0')),
      );

      await tester.tap(find.byKey(const Key('mfa-toggle-recovery')));
      await tester.pumpAndSettle();
      expect(find.text('Código de recuperación'), findsOneWidget);
      expect(find.text('Usar el código de la app'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, '7KQ2-M9XT-P4RD');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      expect(repo.lastMfaCode, '7KQ2-M9XT-P4RD');
      expect(find.text('MÓDULOS'), findsOneWidget);
    });

    testWidgets('el primer enrolamiento muestra los codigos antes de entrar', (
      tester,
    ) async {
      final repo = await launch(
        tester,
        FakeAuthRepository(result: outcome(enroll: true, active: 'c0')),
      );
      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      expect(repo.calls, contains('activateMfa'));
      expect(find.text('Guarda tus códigos de recuperación'), findsOneWidget);
      expect(find.text('AAAA-1111-BBBB'), findsOneWidget);
      expect(find.text('MÓDULOS'), findsNothing);

      await tester.tap(find.byKey(const Key('recovery-saved')));
      await tester.pumpAndSettle();

      expect(find.text('MÓDULOS'), findsOneWidget);
    });

    testWidgets('el perfil genera codigos nuevos con el codigo de la app', (
      tester,
    ) async {
      final repo = FakeAuthRepository(result: outcome(mfa: true, active: 'c0'))
        ..profile = MyProfile(
          user: testProfile.user,
          activeConcession: testProfile.activeConcession,
          profile: testProfile.profile,
          roads: testProfile.roads,
          availableConcessions: testProfile.availableConcessions,
          mfa: const MfaStatus(
            required: true,
            active: true,
            recoveryCodesRemaining: 3,
          ),
        );
      await launch(tester, repo);
      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Verificación en dos pasos'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Verificación en dos pasos'));
      await tester.pumpAndSettle();

      expect(
        find.text('Te quedan 3 códigos de recuperación sin usar'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('recovery-regenerate')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, '246810');
      await tester.tap(find.byKey(const Key('recovery-confirm')));
      await tester.pumpAndSettle();

      expect(repo.calls, contains('regenerate:246810'));
      expect(find.text('AAAA-1111-BBBB'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recovery-saved')));
      await tester.pumpAndSettle();
      // Sigue en la pantalla de verificacion, ya con el contador nuevo.
      expect(
        find.text('Te quedan 2 códigos de recuperación sin usar'),
        findsOneWidget,
      );
    });

    testWidgets('el perfil toma el estado de la cuenta del servidor', (
      tester,
    ) async {
      // Sin pedir el codigo al entrar, pero el servidor dice que esta activa.
      final repo = FakeAuthRepository()
        ..profile = MyProfile(
          user: testProfile.user,
          activeConcession: testProfile.activeConcession,
          profile: testProfile.profile,
          roads: testProfile.roads,
          availableConcessions: testProfile.availableConcessions,
          mfa: const MfaStatus(required: false, active: true),
        );
      await launch(tester, repo);

      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Verificación en dos pasos'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.textContaining('Activa. Tu código lo genera'),
        findsOneWidget,
      );
    });
  });
}
