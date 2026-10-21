import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/app/shell/session_lock_overlay.dart';
import 'package:sigaco_movil/core/device/device_unlock.dart';
import 'package:sigaco_movil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sigaco_movil/features/auth/presentation/session/session_lock_cubit.dart';
import 'package:sigaco_movil/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// La sesion movil (RN-M01-37, DEV-BACK-128): vale hasta su vencimiento, el
/// servidor no la corta por inactividad y los minutos sin uso solo bloquean la
/// app, que se abre con el telefono.
void main() {
  const idle = Duration(minutes: 10);
  final start = DateTime.utc(2026, 10, 21, 12);

  group('bloqueo por inactividad', () {
    late FakeAuthRepository repo;
    late DateTime now;
    late SessionLockCubit lock;

    setUp(() {
      repo = FakeAuthRepository();
      now = start;
      lock = SessionLockCubit(
        repo,
        tick: const Duration(days: 1),
        clock: () => now,
      );
    });
    tearDown(() => lock.close());

    void after(Duration d) {
      now = now.add(d);
      lock.check();
    }

    test('con actividad reciente no se bloquea', () {
      lock.start(idle);
      after(const Duration(minutes: 9, seconds: 59));

      expect(lock.state.locked, isFalse);
    });

    test('pasados los minutos sin tocar la pantalla se bloquea', () {
      lock.start(idle);
      after(idle);

      expect(lock.state.locked, isTrue);
      expect(lock.state.expired, isFalse, reason: 'bloquear no cierra sesion');
    });

    test('cada toque reinicia la cuenta', () {
      lock.start(idle);
      after(const Duration(minutes: 9));
      lock.touch();
      after(const Duration(minutes: 9));

      expect(lock.state.locked, isFalse);
      after(const Duration(minutes: 2));
      expect(lock.state.locked, isTrue);
    });

    test('bloqueada, un toque no la abre: hay que desbloquear', () {
      lock.start(idle);
      after(idle);
      lock.touch();

      expect(lock.state.locked, isTrue);

      lock.unlock();
      expect(lock.state.locked, isFalse);
    });

    test('al desbloquear vuelve a contar desde cero', () {
      lock.start(idle);
      after(idle);
      lock.unlock();
      after(const Duration(minutes: 9));

      expect(lock.state.locked, isFalse);
    });

    test('sin sesion vigilada no hace nada', () {
      after(const Duration(hours: 5));

      expect(lock.state, const SessionLockState());
    });

    test('al detenerlo (cerrar sesion) se limpia', () {
      lock.start(idle);
      after(idle);
      lock.stop();

      expect(lock.state, const SessionLockState());
    });
  });

  group('vencimiento de la sesion', () {
    late FakeAuthRepository repo;
    late DateTime now;
    late SessionLockCubit lock;

    setUp(() {
      repo = FakeAuthRepository()
        ..sessionExpiresAt = start.add(const Duration(hours: 10));
      now = start;
      lock = SessionLockCubit(
        repo,
        tick: const Duration(days: 1),
        clock: () => now,
      );
    });
    tearDown(() => lock.close());

    void after(Duration d) {
      now = now.add(d);
      lock.check();
    }

    test('antes del vencimiento sigue valida, aunque este bloqueada', () {
      lock.start(idle);
      after(const Duration(hours: 9, minutes: 59));

      expect(lock.state.expired, isFalse);
    });

    test('al llegar a las 10 h pide entrar de nuevo', () {
      lock.start(idle);
      after(const Duration(hours: 10));

      expect(lock.state.expired, isTrue);
    });

    test('el vencimiento manda sobre el bloqueo', () {
      lock.start(idle);
      after(const Duration(hours: 11));

      expect(lock.state, const SessionLockState(expired: true));
    });

    test('con el reloj del telefono atrasado usa la hora del servidor', () {
      // El telefono va 2 h atrasado: el servidor ya esta en las 10 h.
      repo.serverClockOffset = const Duration(hours: 2);
      lock.start(idle);
      after(const Duration(hours: 8));

      expect(lock.state.expired, isTrue);
    });

    test('una revalidacion que corrige el vencimiento se respeta', () {
      lock.start(idle);
      after(const Duration(hours: 9));
      repo.sessionExpiresAt = start.add(const Duration(hours: 20));
      after(const Duration(hours: 5));

      expect(lock.state.expired, isFalse);
    });

    test('sin vencimiento conocido solo se bloquea por inactividad', () {
      repo.sessionExpiresAt = null;
      lock.start(idle);
      after(const Duration(hours: 30));

      expect(lock.state.expired, isFalse);
      expect(lock.state.locked, isTrue);
    });
  });

  group('pantalla de bloqueo', () {
    late SessionLockCubit lock;
    late FakeDeviceUnlock unlock;
    late DateTime now;

    setUp(() {
      now = start;
      lock = SessionLockCubit(
        FakeAuthRepository(),
        tick: const Duration(days: 1),
        clock: () => now,
      )..start(idle);
      now = now.add(idle);
      lock.check();
      unlock = FakeDeviceUnlock();
    });
    tearDown(() => lock.close());

    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: RepositoryProvider<DeviceUnlock>.value(
            value: unlock,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: lock),
                BlocProvider(
                  create: (_) =>
                      AuthBloc(FakeAuthRepository(), FakeCredentialStore()),
                ),
              ],
              child: const SessionLockOverlay(idleMinutes: 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('al aparecer pide confirmar y, si se logra, se abre', (
      tester,
    ) async {
      await show(tester);

      expect(unlock.attempts, 1);
      expect(lock.state.locked, isFalse);
    });

    testWidgets('si no se confirma, sigue bloqueada y se puede reintentar', (
      tester,
    ) async {
      unlock.result = false;
      await show(tester);

      expect(lock.state.locked, isTrue);
      expect(find.text('Sesión bloqueada'), findsOneWidget);
      expect(
        find.textContaining('Pasaron 10 minutos sin actividad'),
        findsOneWidget,
      );

      unlock.result = true;
      await tester.tap(find.byKey(const Key('session-unlock')));
      await tester.pumpAndSettle();

      expect(unlock.attempts, 2);
      expect(lock.state.locked, isFalse);
    });

    testWidgets('sin bloqueo de pantalla solo queda cerrar sesion', (
      tester,
    ) async {
      unlock.available = false;
      await show(tester);

      expect(unlock.attempts, 0, reason: 'no se pide lo que no existe');
      expect(find.byKey(const Key('session-unlock')), findsNothing);
      expect(find.byKey(const Key('session-lock-signout')), findsOneWidget);
      expect(
        find.textContaining('no tiene un bloqueo de pantalla'),
        findsOneWidget,
      );
      expect(lock.state.locked, isTrue);
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

    testWidgets('una sesion ya vencida devuelve al inicio de sesion', (
      tester,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      SharedPreferences.setMockInitialValues(const {});
      final repo = FakeAuthRepository()
        ..sessionExpiresAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 1),
        );
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: repo,
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(),
        deviceUnlock: FakeDeviceUnlock(),
      );
      await tester.pumpWidget(SigacoApp(dependencies: deps));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
      await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // Entro y, al vigilar la sesion, ya estaba vencida: vuelve al acceso.
      expect(find.byType(EditableText), findsNWidgets(2));
      expect(find.byKey(const Key('session-lock')), findsNothing);
    });
  });
}
