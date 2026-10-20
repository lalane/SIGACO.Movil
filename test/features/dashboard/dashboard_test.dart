import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/sample_accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/unavailable_accidents_repository.dart';
import 'package:sigaco_movil/app/composition/composed_dashboard_repository.dart';
import 'package:sigaco_movil/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:sigaco_movil/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sigaco_movil/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/unavailable_maintenance_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/unavailable_tickets_repository.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  ComposedDashboardRepository composed({
    bool tickets = true,
    bool accidents = true,
    bool maintenance = true,
  }) => ComposedDashboardRepository(
    tickets: tickets
        ? SampleTicketsRepository(clock: () => now)
        : const UnavailableTicketsRepository(),
    accidents: accidents
        ? SampleAccidentsRepository(clock: () => now)
        : const UnavailableAccidentsRepository(),
    maintenance: maintenance
        ? SampleMaintenanceRepository(clock: () => now)
        : const UnavailableMaintenanceRepository(),
    inventory: SampleInventoryRepository(clock: () => now),
    clock: () => now,
  );

  group('resumen', () {
    test('cuenta lo mismo que ven las listas', () async {
      final summary = await composed().load();
      expect(summary.errors, isEmpty);
      expect(summary.generatedAt, now);

      final tickets = summary.tickets!;
      expect(tickets.open, greaterThan(0));
      expect(tickets.overdue, inInclusiveRange(1, tickets.open));
      final all = await SampleTicketsRepository(clock: () => now).list();
      expect(tickets.open + tickets.attended, all.length);

      final maintenance = summary.maintenance!;
      expect(maintenance.total, greaterThan(0));
      expect(maintenance.execution, inInclusiveRange(0, 1));

      final inventory = summary.inventory!;
      expect(inventory.total, 12);
      expect(inventory.poor, 2);
      expect(inventory.regular, 4);
      expect(inventory.good, 6);
    });

    test('los accidentes son los de los ultimos 30 dias', () async {
      final summary = await composed().load();
      final accidents = summary.accidents!;
      final all = await SampleAccidentsRepository(clock: () => now).list();
      final since = now.subtract(const Duration(days: AccidentsSummary.days));
      expect(
        accidents.recent,
        all.where((a) => !a.createdAt.isBefore(since)).length,
      );
      expect(accidents.severe, lessThanOrEqualTo(accidents.recent));
      expect(accidents.inFollowUp, lessThanOrEqualTo(accidents.recent));
    });

    test('un bloque que falla no tumba a los demas', () async {
      final summary = await composed(tickets: false, maintenance: false).load();
      expect(summary.tickets, isNull);
      expect(summary.maintenance, isNull);
      expect(summary.accidents, isNotNull);
      expect(summary.inventory, isNotNull);
      expect(summary.errors, {
        DashboardSection.tickets: DashboardError.notAvailable,
        DashboardSection.maintenance: DashboardError.notAvailable,
      });
      expect(summary.isEmpty, isFalse);
    });

    test('sin ningun modulo publicado el resumen queda vacio', () async {
      final summary = await composed(
        tickets: false,
        accidents: false,
        maintenance: false,
      ).load();
      // El inventario de ejemplo si responde: solo falta lo demas.
      expect(summary.inventory, isNotNull);
      expect(summary.errors.keys, hasLength(3));
    });
  });

  group('cubit', () {
    test('carga el resumen', () async {
      final cubit = DashboardCubit(composed());
      expect(cubit.state.status, DashboardStatus.loading);
      await cubit.load();
      expect(cubit.state.status, DashboardStatus.ready);
      expect(cubit.state.summary!.tickets, isNotNull);
    });

    test('si todo falla conserva lo que ya tenia', () async {
      final repo = _Flaky(composed());
      final cubit = DashboardCubit(repo);
      await cubit.load();
      final before = cubit.state.summary;
      repo.fail = true;
      await cubit.refresh();
      expect(cubit.state.status, DashboardStatus.failure);
      expect(cubit.state.summary, before);
    });
  });

  group('pantalla', () {
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
      bool maintenance = true,
      bool tickets = true,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'TICKETS', 'MANTENIMIENTO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        ticketsRepository: tickets
            ? SampleTicketsRepository()
            : const UnavailableTicketsRepository(),
        sampleTickets: tickets,
        maintenanceRepository: maintenance
            ? SampleMaintenanceRepository()
            : const UnavailableMaintenanceRepository(),
        sampleMaintenance: maintenance,
        inventoryRepository: SampleInventoryRepository(),
        sampleInventory: true,
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
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Dashboard'),
        ),
      );
      await tester.pumpAndSettle();
    }

    String figure(WidgetTester tester, String key) => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;

    testWidgets('el menu abre el dashboard con un bloque por modulo', (
      tester,
    ) async {
      await launch(tester);
      expect(find.byKey(const Key('dashboard-sample-banner')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-tickets')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-accidents')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-maintenance')), findsOneWidget);
      expect(
        find.byKey(const Key('dashboard-inventory'), skipOffstage: false),
        findsOneWidget,
      );
      expect(figure(tester, 'dashboard-tickets-open'), isNot('0'));
    });

    testWidgets('el inventario cuenta por estado', (tester) async {
      await launch(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard-inventory-good')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('dashboard-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(figure(tester, 'dashboard-inventory-good'), '6');
      expect(figure(tester, 'dashboard-inventory-regular'), '4');
      expect(figure(tester, 'dashboard-inventory-poor'), '2');
    });

    testWidgets('un modulo sin publicar lo dice en su bloque', (tester) async {
      await launch(tester, maintenance: false);
      expect(
        find.byKey(const Key('dashboard-maintenance-error')),
        findsOneWidget,
      );
      expect(find.text('Aún no disponible en esta concesión.'), findsWidgets);
      // Lo demas se sigue viendo.
      expect(figure(tester, 'dashboard-tickets-open'), isNot('0'));
    });

    testWidgets('un bloque abre su modulo', (tester) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('dashboard-tickets')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('module-nav')), findsOneWidget);
    });
  });
}

/// Un repositorio que se puede hacer fallar para probar el reintento.
class _Flaky implements DashboardRepository {
  _Flaky(this._inner);

  final ComposedDashboardRepository _inner;
  bool fail = false;

  @override
  Future<DashboardSummary> load() =>
      fail ? Future.error(StateError('sin red')) : _inner.load();
}
