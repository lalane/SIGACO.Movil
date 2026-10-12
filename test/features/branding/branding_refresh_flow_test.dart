import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/mobile_module.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

class _Network implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

const _blue = ConcessionBranding(
  version: 1,
  primary: '#0EA5E9',
  headerStart: '#0B1F3A',
  timezone: 'America/Sao_Paulo',
);

const _orange = ConcessionBranding(
  version: 2,
  primary: '#F97316',
  timezone: 'America/Manaus',
);

/// La marca se vuelve a consultar con la sesion abierta (DEV-MOB-088) y la zona
/// horaria de la concesion llega a la cuenta (DEV-MOB-057). Ademas, la app
/// nunca muestra Configuracion (DEV-MOB-087, decision D1 del DTF).
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

  Future<(_Network, FakeBrandingRepository, FakeNavigationRepository)> launch(
    WidgetTester tester, {
    FakeNavigationRepository? nav,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final network = _Network();
    final repo = FakeBrandingRepository({'c0': _blue});
    final navigation = nav ?? FakeNavigationRepository();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: navigation,
      brandingRepository: repo,
      logoStore: FakeLogoStore(),
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
      connectivity: network,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    addTearDown(network.controller.close);
    return (network, repo, navigation);
  }

  SigacoPalette palette(WidgetTester tester) => Theme.of(
    tester.element(find.byType(Scaffold).first),
  ).extension<SigacoPalette>()!;

  Future<void> backgroundAndBack(WidgetTester tester) async {
    // El ciclo de vida solo admite las transiciones validas de Flutter.
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('refresco de la marca con la sesion abierta', () {
    testWidgets('al volver a la app llega el cambio hecho en el portal', (
      tester,
    ) async {
      final (_, repo, _) = await launch(tester);
      expect(palette(tester).accent, const Color(0xFF0EA5E9));

      repo.brands['c0'] = _orange;
      await backgroundAndBack(tester);

      expect(palette(tester).accent, const Color(0xFFF97316));
    });

    testWidgets('sin cambios en el portal la pantalla no se mueve', (
      tester,
    ) async {
      final (_, repo, _) = await launch(tester);
      repo.loads.clear();
      await backgroundAndBack(tester);
      expect(repo.loads, ['c0'], reason: 'si pregunto por la version');
      expect(palette(tester).accent, const Color(0xFF0EA5E9));
    });

    testWidgets('al recuperar la conexion llega el cambio', (tester) async {
      final (network, repo, _) = await launch(tester);

      network.controller.add(false);
      await tester.pumpAndSettle();
      repo.brands['c0'] = _orange;
      network.controller.add(true);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(palette(tester).accent, const Color(0xFFF97316));
    });

    testWidgets(
      'sin red el refresco falla en silencio y se conserva la marca',
      (tester) async {
        final (_, repo, _) = await launch(tester);
        repo.failing = true;
        repo.brands['c0'] = _orange;
        await backgroundAndBack(tester);
        expect(palette(tester).accent, const Color(0xFF0EA5E9));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('antes de iniciar sesion no se consulta la marca', (
      tester,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      SharedPreferences.setMockInitialValues({});
      final repo = FakeBrandingRepository({'c0': _blue});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(),
        brandingRepository: repo,
        brandingRefreshGap: Duration.zero,
      );
      await tester.pumpWidget(SigacoApp(dependencies: deps));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await backgroundAndBack(tester);
      expect(repo.loads, isEmpty);
    });
  });

  group('zona horaria de la concesion en la cuenta', () {
    Future<void> openAccount(WidgetTester tester) async {
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
    }

    testWidgets('la cuenta muestra la zona y su desfase', (tester) async {
      await launch(tester);
      await openAccount(tester);
      expect(find.text('Zona horaria de la concesión'), findsOneWidget);
      expect(find.text('America/Sao_Paulo (UTC-03:00)'), findsOneWidget);
    });

    testWidgets(
      'un cambio de zona en el portal se refleja al volver a la app',
      (tester) async {
        final (_, repo, _) = await launch(tester);
        repo.brands['c0'] = _orange;
        await backgroundAndBack(tester);
        await openAccount(tester);
        expect(find.text('America/Manaus (UTC-04:00)'), findsOneWidget);
      },
    );
  });

  group('la app movil no muestra Configuracion (D1)', () {
    test('ningun modulo movil se habilita con codigos de Configuracion', () {
      const codes = [
        'CONFIGURACION',
        'CONFIGURACION_SISTEMA',
        'CONFIGURACION.IDENTIDAD_VISUAL',
        'CONFIGURACION.REGIONAL',
        'CONFIGURACION.SEGURIDAD',
        'CONFIGURACION.DOCUMENTAL',
        'USUARIOS',
        'ROLES',
        'PERMISOS',
        'M15',
      ];
      for (final m in MobileModule.values) {
        expect(
          m.catalogCodes.where(codes.contains),
          isEmpty,
          reason:
              '${m.name} no debe habilitarse con un codigo de Configuracion',
        );
      }
      // Aunque el backend enviara el modulo completo, no aparece nada.
      expect(MobileModule.availableIn(menuWith(codes)), isEmpty);
    });

    test('el backend puede enviar Configuracion junto a modulos moviles', () {
      final available = MobileModule.availableIn(
        menuWith(['PANEL', 'CONFIGURACION', 'CONFIGURACION.REGIONAL']),
      );
      expect(available, [MobileModule.map, MobileModule.dashboard]);
    });

    testWidgets('el inicio no ofrece Configuracion aunque el menu la traiga', (
      tester,
    ) async {
      await launch(
        tester,
        nav: FakeNavigationRepository(
          menu: menuWith([
            'PANEL',
            'TICKETS',
            'CONFIGURACION',
            'CONFIGURACION.IDENTIDAD_VISUAL',
          ]),
        ),
      );
      expect(find.text('MÓDULOS'), findsOneWidget);
      expect(find.textContaining('Configuración del Sistema'), findsNothing);
      expect(find.textContaining('Identidad visual'), findsNothing);
      expect(find.byKey(const Key('module-config')), findsNothing);
    });
  });
}
