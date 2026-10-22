import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/unavailable_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/app/composition/maintenance_reports_repository.dart';
import 'package:sigaco_movil/features/reports/domain/entities/indicator_report.dart';
import 'package:sigaco_movil/features/reports/domain/repositories/reports_repository.dart';
import 'package:sigaco_movil/features/reports/presentation/bloc/report_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);
  const sgs = ReportIndicator.sgs;

  late SampleMaintenanceRepository maintenance;
  late MaintenanceReportsRepository repo;
  setUp(() {
    maintenance = SampleMaintenanceRepository(clock: () => now);
    repo = MaintenanceReportsRepository(maintenance, clock: () => now);
  });

  group('reporte', () {
    test('sin periodo trae todos los mantenimientos del indicador', () async {
      final report = await repo.generate(sgs);
      final all = await maintenance.list(MaintenanceIndicator.sgs);
      expect(report.total, all.length);
      expect(report.generatedAt, now);
      expect(
        ReportLineStatus.values.fold<int>(0, (n, s) => n + report.count(s)),
        report.total,
      );
      expect(
        report.programmedAmount,
        all.fold<double>(0, (n, o) => n + (o.programmedAmount ?? 0)),
      );
      expect(
        report.executedAmount,
        all.fold<double>(0, (n, o) => n + (o.executedAmount ?? 0)),
      );
      expect(report.execution, inInclusiveRange(0, 1));
      expect(
        report.pendingAmount,
        closeTo(report.programmedAmount - report.executedAmount, 0.001),
      );
    });

    test('el mas reciente va primero', () async {
      final report = await repo.generate(sgs);
      expect(report.lines.first.id, 'M-213');
      final starts = report.lines.map((o) => o.startDate!).toList();
      expect([...starts]..sort((a, b) => b.compareTo(a)), starts);
    });

    test(
      'el periodo acota por fecha de inicio, con ambos dias incluidos',
      () async {
        // M-212 empieza 6 dias antes de hoy, M-213 dos despues y M-210 nueve antes.
        final from = DateTime.utc(2026, 10, 15 - 7);
        final since = await repo.generate(sgs, from: from);
        expect(since.lines.map((o) => o.id).toSet(), {'M-212', 'M-213'});
        final range = await repo.generate(
          sgs,
          from: from,
          to: DateTime.utc(2026, 10, 15),
        );
        expect(range.lines.map((o) => o.id), ['M-212']);
        final until = await repo.generate(
          sgs,
          to: DateTime.utc(2026, 10, 15 - 9),
        );
        expect(until.lines.map((o) => o.id).toSet(), {'M-210', 'M-211'});
      },
    );

    test('un periodo vacio da un reporte en ceros', () async {
      final report = await repo.generate(sgs, from: DateTime.utc(2030));
      expect(report.lines, isEmpty);
      expect(report.total, 0);
      expect(report.programmedAmount, 0);
      expect(report.execution, 0);
      expect(report.pendingAmount, 0);
    });

    test('un indicador sin mantenimientos da un reporte vacio', () async {
      final report = await repo.generate(ReportIndicator.sgtec);
      expect(report.total, 0);
    });

    test('sin mantenimiento publicado dice que no esta disponible', () async {
      final none = MaintenanceReportsRepository(
        const UnavailableMaintenanceRepository(),
      );
      await expectLater(
        none.generate(sgs),
        throwsA(
          isA<ReportException>().having(
            (e) => e.error,
            'error',
            ReportError.notAvailable,
          ),
        ),
      );
    });
  });

  group('cubit', () {
    test('empieza sin reporte y lo genera con el periodo elegido', () async {
      final cubit = ReportCubit(repo, sgs);
      expect(cubit.state.status, ReportStatus.idle);
      expect(cubit.state.report, isNull);
      cubit.setFrom(DateTime.utc(2026, 10, 8));
      await cubit.generate();
      expect(cubit.state.status, ReportStatus.ready);
      expect(cubit.state.report!.total, 2);
      expect(cubit.state.stale, isFalse);
    });

    test('cambiar el periodo marca el reporte como desactualizado', () async {
      final cubit = ReportCubit(repo, sgs);
      await cubit.generate();
      expect(cubit.state.stale, isFalse);
      cubit.setTo(DateTime.utc(2026, 10, 1));
      expect(cubit.state.stale, isTrue);
      expect(cubit.state.report!.total, 4);
      await cubit.generate();
      expect(cubit.state.stale, isFalse);
    });

    test('un periodo al reves se acomoda', () async {
      final cubit = ReportCubit(repo, sgs);
      cubit.setFrom(DateTime.utc(2026, 10, 15));
      cubit.setTo(DateTime.utc(2026, 10, 8));
      await cubit.generate();
      expect(cubit.state.from, DateTime.utc(2026, 10, 8));
      expect(cubit.state.to, DateTime.utc(2026, 10, 15));
      expect(cubit.state.report!.lines.map((o) => o.id), ['M-212']);
    });

    test('falla con el error del repositorio', () async {
      final cubit = ReportCubit(
        MaintenanceReportsRepository(const UnavailableMaintenanceRepository()),
        sgs,
      );
      await cubit.generate();
      expect(cubit.state.status, ReportStatus.failure);
      expect(cubit.state.error, ReportError.notAvailable);
    });
  });

  group('pantallas', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    Future<void> launch(WidgetTester tester, {bool unavailable = false}) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'REPORTES', 'MANTENIMIENTO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        maintenanceRepository: unavailable
            ? const UnavailableMaintenanceRepository()
            : SampleMaintenanceRepository(),
        sampleMaintenance: !unavailable,
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

    Future<void> openIndicator(WidgetTester tester, String name) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Reportes'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('report-indicator-$name')));
      await tester.pumpAndSettle();
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    testWidgets('el menu abre los once indicadores del BBP', (tester) async {
      await launch(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Reportes'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Seleccione un indicador'), findsOneWidget);
      expect(ReportIndicator.values, hasLength(11));
      for (final i in ReportIndicator.values) {
        expect(
          find.byKey(Key('report-indicator-${i.name}'), skipOffstage: false),
          findsOneWidget,
          reason: i.name,
        );
      }
    });

    testWidgets('Reportes de la barra inferior abre los reportes', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('home-bottom-bar')),
          matching: find.text('Reportes'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seleccione un indicador'), findsOneWidget);
    });

    testWidgets('un indicador pide generar el reporte', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      expect(find.byKey(const Key('report-idle')), findsOneWidget);
      expect(find.byKey(const Key('report-sample-banner')), findsOneWidget);
      expect(find.text('Generar reporte'), findsOneWidget);
    });

    testWidgets('generar muestra el resumen y los mantenimientos', (
      tester,
    ) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('report-generate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-result')), findsOneWidget);
      expect(text(tester, 'report-period'), 'Todo el historial');
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('report-count-all')),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data),
        ['4', 'Total'],
      );
      expect(find.byKey(const Key('report-execution')), findsOneWidget);
      expect(find.byKey(const Key('report-line-M-213')), findsOneWidget);
      expect(find.text('Actualizar reporte'), findsOneWidget);
    });

    testWidgets('un mantenimiento del reporte abre su ficha', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('report-generate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-line-M-213')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('maintenance-detail')), findsOneWidget);
    });

    testWidgets('un indicador sin mantenimientos da un reporte vacio', (
      tester,
    ) async {
      await launch(tester);
      await openIndicator(tester, 'sgtec');
      await tester.tap(find.byKey(const Key('report-generate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-empty')), findsOneWidget);
    });

    testWidgets('sin datos publicados lo dice', (tester) async {
      await launch(tester, unavailable: true);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('report-generate')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('report-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('report-sample-banner')), findsNothing);
    });
  });
}
