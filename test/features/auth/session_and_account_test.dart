import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/account/account_cubit.dart';
import 'package:sigaco_movil/features/auth/presentation/account/change_password_cubit.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_state.dart';

import '../../support/fakes.dart';

const _login = AuthLoginSubmitted(email: 'a@b.com', password: 'S3creto!x');

void main() {
  group('requisitos que el servidor exige a mitad de sesion', () {
    Future<AuthBloc> signedIn([LoginOutcome? result]) async {
      final bloc = AuthBloc(
        FakeAuthRepository(
          result: result ?? outcome(active: 'c0', concessions: 2),
        ),
        FakeCredentialStore(),
      )..add(_login);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      return bloc;
    }

    test('PASSWORD_CHANGE_REQUIRED lleva al cambio de contrasena', () async {
      final bloc = await signedIn();
      bloc.add(
        const AuthRequirementReceived(SessionRequirement.passwordChange),
      );
      final s = await bloc.stream.firstWhere(
        (s) => s.step != AuthStep.signedIn,
      );
      expect(s.step, AuthStep.changePassword);
      await bloc.close();
    });

    test(
      'MFA_REQUIRED y MFA_ENROLLMENT_REQUIRED llevan a su pantalla',
      () async {
        final bloc = await signedIn();
        bloc.add(const AuthRequirementReceived(SessionRequirement.mfa));
        expect(
          (await bloc.stream.firstWhere((s) => s.mfaRequired)).step,
          AuthStep.mfa,
        );
        await bloc.close();
      },
    );

    test('CONTEXT_REQUIRED con varias concesiones pide elegir', () async {
      final bloc = await signedIn();
      bloc.add(const AuthRequirementReceived(SessionRequirement.concession));
      final s = await bloc.stream.firstWhere(
        (s) => s.step != AuthStep.signedIn,
      );
      expect(s.step, AuthStep.concession);
      await bloc.close();
    });

    test('el codigo de la API se traduce al requisito', () {
      expect(requirementForCode('MFA_REQUIRED'), SessionRequirement.mfa);
      expect(
        requirementForCode('PASSWORD_CHANGE_REQUIRED'),
        SessionRequirement.passwordChange,
      );
      expect(
        requirementForCode('CONTEXT_REQUIRED'),
        SessionRequirement.concession,
      );
      expect(requirementForCode('PERMISSION_DENIED'), isNull);
    });
  });

  group('perfil propio y cambio de contrasena', () {
    blocTest<AccountCubit, AccountState>(
      'carga el perfil',
      build: () => AccountCubit(FakeAuthRepository()),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, AccountStatus.ready);
        expect(c.state.profile?.user.username, 'jperez');
        expect(c.state.profile?.profile?.localizedName('pt'), 'Manutenção');
        expect(c.state.profile?.profile?.localizedName('es'), 'Mantenimiento');
      },
    );

    blocTest<AccountCubit, AccountState>(
      'informa el fallo',
      build: () => AccountCubit(
        FakeAuthRepository()..profileFailure = AuthError.network,
      ),
      act: (c) => c.load(),
      verify: (c) => expect(c.state.status, AccountStatus.failure),
    );

    test('el contrato JSON de /api/auth/me se interpreta', () {
      final p = profileFromJson({
        'account': {
          'id': 'u1',
          'username': 'jperez',
          'fullName': 'Juan Perez',
          'email': 'j@x.com',
          'organizationArea': 'Atlixco',
          'jobTitle': 'Supervisor de obra',
          'companyName': '  ',
        },
        'context': {
          'activeConcession': {'id': 'c1', 'code': 'C1', 'name': 'NOVA 381'},
          'profile': {
            'code': 'SUPERVISION',
            'nameEs': 'Supervisión',
            'namePt': null,
          },
          'roads': [
            {'id': 'r1', 'code': 'BR381', 'name': 'BR-381'},
          ],
          'availableConcessions': [
            {'id': 'c1', 'code': 'C1', 'name': 'NOVA 381'},
          ],
          'selectionRequired': false,
        },
      });
      expect(p.user.organizationArea, 'Atlixco');
      expect(p.user.jobTitle, 'Supervisor de obra');
      expect(
        p.user.companyName,
        isNull,
        reason: 'un texto en blanco es ausente',
      );
      expect(p.activeConcession?.name, 'NOVA 381');
      expect(
        p.profile?.localizedName('pt'),
        'Supervisión',
        reason: 'sin traduccion usa es',
      );
      expect(p.roads.single.code, 'BR381');
    });

    test('contrasenas distintas no llegan al servidor', () async {
      final repo = FakeAuthRepository();
      final c = ChangePasswordCubit(repo, FakeCredentialStore());
      await c.submit(current: 'a', next: 'b', confirm: 'c');
      expect(c.state.error, AuthError.passwordMismatch);
      expect(repo.calls, isNot(contains('changePassword')));
      await c.close();
    });

    test('al cambiarla actualiza la guardada en el dispositivo', () async {
      final store = FakeCredentialStore();
      await store.setRemembered(
        remember: true,
        credentials: (email: 'a@b.com', password: 'vieja'),
      );
      final c = ChangePasswordCubit(FakeAuthRepository(), store);
      await c.submit(current: 'vieja', next: 'Nueva#123', confirm: 'Nueva#123');
      expect(c.state.success, isTrue);
      expect(store.stored?.password, 'Nueva#123');
      await c.close();
    });

    test('el estado no expone contrasenas', () {
      expect(
        const ChangePasswordState(error: AuthError.server).toString(),
        isNot(contains('Nueva')),
      );
    });
  });
}
