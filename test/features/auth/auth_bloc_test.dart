import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_event.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_state.dart';

import '../../support/fakes.dart';

const _login = AuthLoginSubmitted(email: 'a@b.com', password: 'S3creto!x');

AuthBloc _bloc(FakeAuthRepository repo, [FakeCredentialStore? store]) =>
    AuthBloc(repo, store ?? FakeCredentialStore());

void main() {
  group('login', () {
    blocTest<AuthBloc, AuthState>(
      'sin pasos pendientes y con una concesion llega a la sesion',
      build: () => _bloc(FakeAuthRepository()),
      act: (b) => b.add(_login),
      wait: const Duration(milliseconds: 10),
      verify: (b) {
        expect(b.state.step, AuthStep.signedIn);
        expect(b.state.busy, isFalse);
        expect(b.state.user?.fullName, 'Juan Perez');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'MFA primero y despues el cambio obligatorio de contrasena',
      build: () => _bloc(
        FakeAuthRepository(
          result: outcome(mfa: true, force: true, active: 'c0'),
        ),
      ),
      act: (b) => b
        ..add(_login)
        ..add(const AuthMfaSubmitted('123456')),
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.step, AuthStep.changePassword),
    );

    blocTest<AuthBloc, AuthState>(
      'varias concesiones sin activa piden seleccionar',
      build: () => _bloc(FakeAuthRepository(result: outcome(concessions: 2))),
      act: (b) => b.add(_login),
      wait: const Duration(milliseconds: 10),
      verify: (b) => expect(b.state.step, AuthStep.concession),
    );

    blocTest<AuthBloc, AuthState>(
      'elegir concesion completa el acceso',
      build: () => _bloc(FakeAuthRepository(result: outcome(concessions: 2))),
      act: (b) => b
        ..add(_login)
        ..add(const AuthConcessionSelected('c1')),
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.step, AuthStep.signedIn);
        expect(b.state.activeConcessionId, 'c1');
      },
    );

    for (final error in [
      AuthError.invalidCredentials,
      AuthError.accountBlocked,
      AuthError.network,
    ]) {
      blocTest<AuthBloc, AuthState>(
        'error $error: sigue sin sesion y lo informa',
        build: () => _bloc(FakeAuthRepository()..failure = error),
        act: (b) => b.add(_login),
        wait: const Duration(milliseconds: 10),
        verify: (b) {
          expect(b.state.step, AuthStep.signedOut);
          expect(b.state.error, error);
          expect(b.state.busy, isFalse);
        },
      );
    }
  });

  group('sesion', () {
    test('cerrar sesion limpia al usuario', () async {
      final repo = FakeAuthRepository();
      final bloc = _bloc(repo)..add(_login);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      bloc.add(const AuthLogoutRequested());
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedOut);
      expect(repo.calls, contains('logout'));
      await bloc.close();
    });

    test('sesion vencida por el servidor regresa al login con aviso', () async {
      final repo = FakeAuthRepository();
      final bloc = _bloc(repo)..add(_login);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      repo.expired.add(null);
      final s = await bloc.stream.firstWhere((s) => s.sessionExpired);
      expect(s.step, AuthStep.signedOut);
      await bloc.close();
    });
  });

  group('biometria', () {
    test('tras el primer acceso con contrasena se ofrece activarla', () async {
      final bloc = _bloc(FakeAuthRepository())..add(const AuthStarted());
      await bloc.stream.firstWhere((s) => s.biometricAvailable);
      bloc.add(_login);
      final s = await bloc.stream.firstWhere((s) => s.offerBiometric);
      expect(s.step, AuthStep.signedIn);
      await bloc.close();
    });

    test(
      'aceptar guarda las credenciales; rechazar no vuelve a ofrecer',
      () async {
        final store = FakeCredentialStore();
        final bloc = _bloc(FakeAuthRepository(), store)
          ..add(const AuthStarted());
        await bloc.stream.firstWhere((s) => s.biometricAvailable);
        bloc.add(_login);
        await bloc.stream.firstWhere((s) => s.offerBiometric);
        bloc.add(const AuthBiometricOfferAnswered(accepted: true, reason: 'x'));
        await bloc.stream.firstWhere((s) => s.biometricEnabled);
        expect(store.stored?.email, 'a@b.com');
        await bloc.close();
      },
    );

    test(
      'si la contrasena guardada ya no sirve, se desactiva la biometria',
      () async {
        final store = FakeCredentialStore()
          ..stored = (email: 'a@b.com', password: 'vieja');
        await store.enableBiometric('x', store.stored!);
        final repo = FakeAuthRepository()
          ..failure = AuthError.invalidCredentials;
        final bloc = _bloc(repo, store)
          ..add(const AuthBiometricLoginRequested('x'));
        await bloc.stream.firstWhere((s) => s.error != null);
        expect(store.biometricEnabled, isFalse);
        await bloc.close();
      },
    );

    test(
      'un error al teclear la contrasena NO desactiva la biometria',
      () async {
        final store = FakeCredentialStore();
        await store.enableBiometric('x', (email: 'a@b.com', password: 'ok'));
        final repo = FakeAuthRepository()
          ..failure = AuthError.invalidCredentials;
        final bloc = _bloc(repo, store)..add(_login);
        await bloc.stream.firstWhere((s) => s.error != null);
        expect(store.biometricEnabled, isTrue);
        await bloc.close();
      },
    );
  });

  group('recordar correo y contrasena', () {
    const remembered = AuthLoginSubmitted(
      email: 'a@b.com',
      password: 'S3creto!x',
      remember: true,
    );

    test('al recordar guarda ambos y los ofrece tras cerrar sesion', () async {
      final store = FakeCredentialStore();
      final bloc = _bloc(FakeAuthRepository(), store)..add(remembered);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      expect(store.rememberEnabled, isTrue);
      expect(store.stored?.password, 'S3creto!x');

      bloc.add(const AuthLogoutRequested());
      final out = await bloc.stream.firstWhere(
        (s) => s.step == AuthStep.signedOut && s.rememberedPassword != null,
      );
      expect(out.rememberedEmail, 'a@b.com');
      expect(out.rememberedPassword, 'S3creto!x');
      await bloc.close();
    });

    test('sin marcar la casilla no se guarda nada', () async {
      final store = FakeCredentialStore();
      final bloc = _bloc(FakeAuthRepository(), store)..add(_login);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      expect(store.rememberEnabled, isFalse);
      expect(store.stored, isNull);
      await bloc.close();
    });

    test('al desmarcar se borra, salvo que la biometria siga activa', () async {
      final store = FakeCredentialStore();
      await store.enableBiometric('x', (email: 'a@b.com', password: 'clave'));
      await store.setRemembered(
        remember: true,
        credentials: (email: 'a@b.com', password: 'clave'),
      );
      await store.setRemembered(remember: false);
      expect(store.rememberedEmail, isNull);
      expect(store.stored, isNotNull, reason: 'la biometria lo sigue usando');

      await store.disableBiometric();
      expect(store.stored, isNull);
    });

    test('al cambiar la contrasena se actualiza la guardada', () async {
      final store = FakeCredentialStore();
      final bloc = _bloc(
        FakeAuthRepository(result: outcome(force: true, active: 'c0')),
        store,
      )..add(remembered);
      await bloc.stream.firstWhere((s) => s.step == AuthStep.changePassword);
      bloc.add(
        const AuthPasswordChangeSubmitted(
          current: 'S3creto!x',
          next: 'Nueva#123',
          confirm: 'Nueva#123',
        ),
      );
      await bloc.stream.firstWhere((s) => s.step == AuthStep.signedIn);
      expect(store.stored?.password, 'Nueva#123');
      await bloc.close();
    });
  });

  group('trazabilidad sin secretos', () {
    test('eventos y estados no exponen contrasenas ni codigos', () {
      expect(_login.toString(), isNot(contains('S3creto')));
      expect(
        const AuthMfaSubmitted('987654').toString(),
        isNot(contains('987654')),
      );
      expect(
        const AuthPasswordChangeSubmitted(
          current: 'vieja123',
          next: 'nueva456',
          confirm: 'nueva456',
        ).toString(),
        isNot(anyOf(contains('vieja123'), contains('nueva456'))),
      );
      expect(const AuthState().toString(), isNot(contains('token')));
      expect(
        const AuthState(rememberedPassword: 'MiClave99').toString(),
        isNot(contains('MiClave99')),
      );
    });
  });
}
