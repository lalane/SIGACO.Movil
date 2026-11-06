import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sigaco_movil/features/dashboard/domain/repositories/dashboard_repository.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/surface.dart';

/// El menu del mockup: el panel lateral de indicadores y las tarjetas de
/// resumen.
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

  Future<void> launch(
    WidgetTester tester, {
    required List<String> modules,
    DashboardRepository? dashboard,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(menu: menuWith(modules)),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      dashboardRepository: dashboard,
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  group('panel de indicadores', () {
    testWidgets('el boton del menu abre el panel y buscar filtra', (
      tester,
    ) async {
      await launch(tester, modules: ['PANEL', 'MANTENIMIENTO']);
      await tester.tap(find.byKey(const Key('home-menu-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('indicators-panel')), findsOneWidget);
      expect(find.byKey(const Key('panel-indicator-sgp')), findsOneWidget);
      expect(find.byKey(const Key('panel-indicator-sgs')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('indicators-search')), 'sgs');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-indicator-sgs')), findsOneWidget);
      expect(find.byKey(const Key('panel-indicator-sgp')), findsNothing);

      await tester.enterText(find.byKey(const Key('indicators-search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('indicators-no-match')), findsOneWidget);
    });

    testWidgets('sin mantenimiento en el menu no hay boton ni panel', (
      tester,
    ) async {
      await launch(tester, modules: ['PANEL', 'TICKETS']);
      expect(find.byKey(const Key('home-menu-button')), findsNothing);
    });
  });

  group('tarjetas de resumen', () {
    testWidgets('muestran los registros abiertos y los vencidos', (
      tester,
    ) async {
      await launch(
        tester,
        modules: ['PANEL', 'TICKETS'],
        dashboard: _FixedDashboard(
          DashboardSummary(
            generatedAt: DateTime.utc(2026, 10, 28),
            tickets: const TicketsSummary(open: 12, attended: 5, overdue: 2),
          ),
        ),
      );
      expect(find.byKey(const Key('home-summary-tickets')), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('2 vencidos'), findsOneWidget);
      // Sin esos modulos en el resumen no hay tarjeta.
      expect(find.byKey(const Key('home-summary-accidents')), findsNothing);
    });

    testWidgets(
      'el carrusel es ciclico: hacia atras de la primera sale la ultima',
      (tester) async {
        await launch(
          tester,
          modules: [
            'PANEL',
            'TICKETS',
            'INVENTARIO',
            'ANTT.ACCIDENTES',
            'ALERTAS_OPERATIVAS',
          ],
          dashboard: _FixedDashboard(
            DashboardSummary(
              generatedAt: DateTime.utc(2026, 10, 28),
              tickets: const TicketsSummary(open: 1, attended: 0, overdue: 0),
            ),
          ),
        );
        final carousel = find.byKey(const Key('home-summary'));
        // Abre en la de en medio: las alertas (la ultima) todavia no se ven.
        expect(find.byKey(const Key('home-summary-alerts')), findsNothing);
        final page = tester.getSize(carousel).width * 0.44;
        // Hacia atras dos veces: pasa por la primera y da la vuelta a la ultima.
        for (var i = 0; i < 2; i++) {
          await tester.drag(carousel, Offset(page, 0));
          await tester.pumpAndSettle();
        }
        expect(find.byKey(const Key('home-summary-alerts')), findsOneWidget);
      },
    );

    testWidgets('el carrusel trae registros, activos, accidentes y alertas', (
      tester,
    ) async {
      await launch(
        tester,
        modules: [
          'PANEL',
          'TICKETS',
          'INVENTARIO',
          'ANTT.ACCIDENTES',
          'ALERTAS_OPERATIVAS',
        ],
        dashboard: _FixedDashboard(
          DashboardSummary(
            generatedAt: DateTime.utc(2026, 10, 28),
            tickets: const TicketsSummary(open: 12, attended: 5, overdue: 0),
            inventory: const InventorySummary(good: 1, regular: 1, poor: 0),
            accidents: const AccidentsSummary(
              recent: 3,
              severe: 1,
              inFollowUp: 2,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('home-summary-assets')), findsOneWidget);
      expect(find.byKey(const Key('home-summary-accidents')), findsOneWidget);
      final size = tester.getSize(find.byKey(const Key('home-summary-assets')));
      expect(
        tester.getSize(find.byKey(const Key('home-summary-accidents'))),
        size,
      );
      // Se desliza hasta las alertas.
      await tester.drag(
        find.byKey(const Key('home-summary')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-summary-alerts')), findsOneWidget);
    });

    testWidgets(
      'si el resumen falla las tarjetas muestran guion y el menu sigue',
      (tester) async {
        await launch(
          tester,
          modules: ['PANEL', 'TICKETS'],
          dashboard: _Failing(),
        );
        expect(find.byKey(const Key('home-summary-tickets')), findsOneWidget);
        expect(find.text('—'), findsOneWidget);
      },
    );
  });
}

class _FixedDashboard implements DashboardRepository {
  _FixedDashboard(this._summary);

  final DashboardSummary _summary;

  @override
  Future<DashboardSummary> load() async => _summary;
}

class _Failing implements DashboardRepository {
  @override
  Future<DashboardSummary> load() => Future.error(StateError('sin red'));
}
