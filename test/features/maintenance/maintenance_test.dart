import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/unavailable_maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:sigaco_movil/features/maintenance/presentation/bloc/maintenance_cubit.dart';
import 'package:sigaco_movil/features/maintenance/presentation/bloc/maintenance_detail_cubit.dart';
import 'package:sigaco_movil/features/maintenance/presentation/bloc/maintenance_progress_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Guarda los avances que recibe y, si se le pide, falla.
class _ProgressRepo extends SampleMaintenanceRepository {
  _ProgressRepo({this.fail});

  final MaintenanceError? fail;
  final calls = <Map<String, Object?>>[];

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    required double percent,
    double? executedVolume,
    String? notes,
    String? clientId,
  }) async {
    final error = fail;
    if (error != null) throw MaintenanceException(error);
    calls.add({
      'id': id,
      'percent': percent,
      'volume': executedVolume,
      'notes': notes,
      'clientId': clientId,
    });
    return get(id);
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  group('dominio y cubits', () {
    late SampleMaintenanceRepository repo;
    setUp(() => repo = SampleMaintenanceRepository(clock: () => now));

    test('el avance sale del volumen ejecutado', () async {
      final o = await repo.get('M-210');
      expect(o.progress, closeTo(0.64, 0.001));
      expect(o.pendingAmount, 36000);
    });

    test('el avance nunca pasa de 100 ni baja de 0', () {
      const base = MaintenanceOrder(
        id: 'x',
        indicator: MaintenanceIndicator.sgs,
        title: 't',
        activity: 'a',
        status: MaintenanceStatus.open,
        totalVolume: 10,
        executedVolume: 25,
        unit: 'PZA',
        programmedAmount: 100,
        executedAmount: 150,
      );
      expect(base.progress, 1);
      expect(base.pendingAmount, 0);
      const none = MaintenanceOrder(
        id: 'y',
        indicator: MaintenanceIndicator.sgs,
        title: 't',
        activity: 'a',
        status: MaintenanceStatus.open,
        totalVolume: 0,
        executedVolume: 0,
        unit: 'PZA',
      );
      expect(none.progress, 0);
      expect(none.pendingAmount, isNull);
    });

    test('lista solo los mantenimientos del indicador', () async {
      final sgs = await repo.list(MaintenanceIndicator.sgs);
      expect(sgs, hasLength(4));
      expect(sgs.every((o) => o.indicator == MaintenanceIndicator.sgs), isTrue);
      expect(await repo.list(MaintenanceIndicator.sgtec), isEmpty);
    });

    test('un mantenimiento que no existe da notFound', () async {
      await expectLater(
        repo.get('M-999'),
        throwsA(
          isA<MaintenanceException>().having(
            (e) => e.error,
            'error',
            MaintenanceError.notFound,
          ),
        ),
      );
    });

    test('el cubit cuenta por estado y reparte el total', () async {
      final cubit = MaintenanceCubit(repo, MaintenanceIndicator.sgs);
      await cubit.load();
      final s = cubit.state;
      expect(s.status, MaintenanceListStatus.ready);
      expect(s.total, 4);
      expect(s.count(MaintenanceStatus.open), 2);
      expect(s.count(MaintenanceStatus.inProgress), 1);
      expect(s.count(MaintenanceStatus.closed), 1);
      expect(s.share(MaintenanceStatus.open), 50);
    });

    test('filtra por estado, por fechas y busca', () async {
      final cubit = MaintenanceCubit(repo, MaintenanceIndicator.sgs);
      await cubit.load();
      cubit.setStatus(MaintenanceStatus.open);
      expect(cubit.state.visible, hasLength(2));
      cubit.setStatus(null);
      expect(cubit.state.visible, hasLength(4));
      // Hoy es dia 15: M-213 empieza en +2 dias, M-212 en -6 y M-210 en -9.
      final today = now;
      cubit.setFrom(today.subtract(const Duration(days: 7)));
      expect(cubit.state.visible.map((o) => o.id).toSet(), {'M-212', 'M-213'});
      cubit.setTo(today);
      expect(cubit.state.visible.map((o) => o.id), ['M-212']);
      cubit.clearFilters();
      expect(cubit.state.hasActiveFilters, isFalse);
      cubit.setQuery('cctv');
      expect(cubit.state.visible.map((o) => o.id), ['M-211']);
    });

    test('lo mas reciente (por inicio) va primero', () async {
      final cubit = MaintenanceCubit(repo, MaintenanceIndicator.sgs);
      await cubit.load();
      expect(cubit.state.visible.first.id, 'M-213');
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = MaintenanceCubit(
        const UnavailableMaintenanceRepository(),
        MaintenanceIndicator.sgs,
      );
      await cubit.load();
      expect(cubit.state.status, MaintenanceListStatus.failure);
      expect(cubit.state.error, MaintenanceError.notAvailable);
    });

    test(
      'el avance se valida y se manda con su clave de idempotencia',
      () async {
        final repo = _ProgressRepo();
        final cubit = MaintenanceProgressCubit(
          repo,
          'M-210',
          currentProgress: 0.64,
          clientIdGenerator: () => 'uuid-1',
        );
        expect(cubit.state.percent, '64');

        cubit.setPercent('120');
        await cubit.save();
        expect(cubit.state.showIssues, isTrue);
        expect(cubit.state.issues, [ProgressIssue.percent]);
        cubit.setPercent('70,5');
        cubit.setVolume('abc');
        expect(cubit.state.issues, [ProgressIssue.volume]);
        await cubit.save();
        expect(repo.calls, isEmpty);

        cubit.setVolume('12,5');
        cubit.setNotes('  Se coloco la mitad  ');
        await cubit.save();
        expect(cubit.state.saved, isTrue);
        expect(repo.calls, hasLength(1));
        expect(repo.calls.single, {
          'id': 'M-210',
          'percent': 70.5,
          'volume': 12.5,
          'notes': '  Se coloco la mitad  ',
          'clientId': 'uuid-1',
        });
      },
    );

    test('un avance sin volumen ni notas manda solo el porcentaje', () async {
      final repo = _ProgressRepo();
      final cubit = MaintenanceProgressCubit(repo, 'M-210');
      expect(cubit.state.percent, isEmpty);
      await cubit.save();
      expect(cubit.state.issues, [ProgressIssue.percent]);
      cubit.setPercent('100');
      await cubit.save();
      expect(repo.calls.single['volume'], isNull);
      expect(repo.calls.single['percent'], 100);
    });

    test('si falla, dice por que y deja reintentar', () async {
      for (final e in [
        MaintenanceError.network,
        MaintenanceError.permissionDenied,
      ]) {
        final cubit = MaintenanceProgressCubit(
          _ProgressRepo(fail: e),
          'M-210',
          currentProgress: 0.5,
        );
        await cubit.save();
        expect(cubit.state.saved, isFalse);
        expect(cubit.state.saving, isFalse);
        expect(cubit.state.error, e);
        cubit.setPercent('60');
        expect(cubit.state.error, isNull, reason: 'al corregir se limpia');
      }
    });

    test('la ficha carga o falla con notFound', () async {
      final ok = MaintenanceDetailCubit(repo, 'M-210');
      await ok.load();
      expect(ok.state.order!.title, 'Túnel Norte - Portal Norte');
      final missing = MaintenanceDetailCubit(repo, 'M-999');
      await missing.load();
      expect(missing.state.error, MaintenanceError.notFound);
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

    Future<void> launch(
      WidgetTester tester, {
      MaintenanceRepository? maintenance,
      bool sample = true,
      Size surface = TestSurface.largePhone,
      double textScale = 1.0,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, surface, textScale: textScale);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'MANTENIMIENTO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        maintenanceRepository: maintenance ?? SampleMaintenanceRepository(),
        sampleMaintenance: sample,
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

    Future<void> openIndicators(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Mantenimientos'),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openIndicator(WidgetTester tester, String name) async {
      await openIndicators(tester);
      await tester.tap(find.byKey(Key('indicator-$name')));
      await tester.pumpAndSettle();
    }

    Finder card(String id) => find.byKey(Key('maintenance-$id'));
    Finder stat(String id) => find.descendant(
      of: find.byKey(Key('maintenance-stat-$id')),
      matching: find.byType(Text),
    );

    testWidgets('el menu abre los ocho indicadores', (tester) async {
      await launch(tester);
      await openIndicators(tester);
      expect(find.text('Seleccione un indicador'), findsOneWidget);
      for (final i in MaintenanceIndicator.values) {
        expect(
          find.byKey(Key('indicator-${i.name}'), skipOffstage: false),
          findsOneWidget,
          reason: i.name,
        );
      }
      expect(find.byKey(const Key('module-nav')), findsOneWidget);
    });

    testWidgets('un indicador abre su lista con el resumen', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      expect(
        find.byKey(const Key('maintenance-sample-banner')),
        findsOneWidget,
      );
      expect(tester.widgetList<Text>(stat('all')).map((t) => t.data), [
        '4',
        'Total',
        '100% total',
      ]);
      expect(tester.widgetList<Text>(stat('open')).map((t) => t.data), [
        '2',
        'Abiertos',
        '50% del total',
      ]);
      expect(card('M-213'), findsOneWidget);
    });

    testWidgets('un indicador sin mantenimientos lo dice', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgtec');
      expect(find.byKey(const Key('maintenance-state-empty')), findsOneWidget);
      expect(
        find.text('No hay mantenimientos para este indicador.'),
        findsOneWidget,
      );
    });

    testWidgets('filtrar por estado y quitar los filtros', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('maintenance-status-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrado').last);
      await tester.pumpAndSettle();
      expect(card('M-211'), findsOneWidget);
      expect(card('M-213'), findsNothing);
      expect(find.byType(Badge), findsOneWidget);
      await tester.tap(find.byKey(const Key('maintenance-filter-button')));
      await tester.pumpAndSettle();
      expect(card('M-213'), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('la lupa muestra la busqueda', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('maintenance-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('maintenance-search')),
        'balizamiento',
      );
      await tester.pumpAndSettle();
      expect(card('M-213'), findsOneWidget);
      expect(find.byKey(const Key('maintenance-M-211')), findsNothing);
    });

    testWidgets('el avance de la tarjeta sale del volumen', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('maintenance-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('maintenance-search')),
        'LED',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('maintenance-progress-M-210')))
            .data,
        '64%',
      );
      expect(find.text('Volumen Total: 350'), findsOneWidget);
      expect(find.text('Descripción: PZA'), findsOneWidget);
    });

    testWidgets('la ficha muestra avance, importes y detalles', (tester) async {
      await launch(tester);
      await openIndicator(tester, 'sgs');
      await tester.tap(find.byKey(const Key('maintenance-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('maintenance-search')),
        'LED',
      );
      await tester.pumpAndSettle();
      await tester.tap(card('M-210'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('maintenance-detail')), findsOneWidget);
      expect(find.text('Túnel Norte - Portal Norte'), findsOneWidget);
      expect(
        find.text('Actividad: Revisión de luminarias LED'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('maintenance-detail-progress')))
            .data,
        '64%',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('maintenance-executed-amount')))
            .data,
        r'$64,000',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('maintenance-pending-amount')))
            .data,
        r'$36,000',
      );
      expect(find.byKey(const Key('maintenance-info')), findsOneWidget);
      expect(find.text('016 + 100'), findsOneWidget);
      await tester.tap(find.byKey(const Key('maintenance-action-edit')));
      await tester.pump();
      expect(
        find.text('Esta acción estará disponible pronto.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('maintenance-detail-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('maintenance-list')), findsOneWidget);
    });

    testWidgets('el + de la ficha registra un avance y vuelve a la ficha', (
      tester,
    ) async {
      final repo = _ProgressRepo();
      await launch(tester, maintenance: repo);
      await openIndicator(tester, 'sgs');
      await tester.tap(card('M-210'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('maintenance-action-add')));
      await tester.pumpAndSettle();
      expect(find.text('Registrar avance'), findsWidgets);
      expect(find.text('Volumen ejecutado (PZA)'), findsOneWidget);
      final percentField = find.byKey(
        const Key('maintenance-progress-percent'),
      );
      expect(
        tester.widget<TextFormField>(percentField).initialValue,
        '64',
        reason: 'parte del avance actual',
      );

      await tester.enterText(percentField, '150');
      await tester.tap(find.byKey(const Key('maintenance-progress-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un avance entre 0 y 100.'), findsOneWidget);
      expect(repo.calls, isEmpty);

      await tester.enterText(percentField, '75');
      await tester.tap(find.byKey(const Key('maintenance-progress-submit')));
      await tester.pumpAndSettle();
      expect(repo.calls.single['percent'], 75);
      expect(find.byKey(const Key('maintenance-detail')), findsOneWidget);
      expect(find.text('Avance guardado.'), findsOneWidget);
    });

    testWidgets('si no hay red el avance avisa y no cierra', (tester) async {
      await launch(
        tester,
        maintenance: _ProgressRepo(fail: MaintenanceError.network),
      );
      await openIndicator(tester, 'sgs');
      await tester.tap(card('M-210'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('maintenance-action-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('maintenance-progress-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('Sin conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('maintenance-progress-percent')),
        findsOneWidget,
      );
    });

    testWidgets('sin endpoints dice que no esta disponible', (tester) async {
      await launch(
        tester,
        maintenance: const UnavailableMaintenanceRepository(),
      );
      await openIndicator(tester, 'sgs');
      expect(
        find.byKey(const Key('maintenance-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('maintenance-stat-all')), findsNothing);
    });

    testWidgets('la barra inferior lleva al mapa y de vuelta', (tester) async {
      await launch(tester);
      await openIndicators(tester);
      await tester.tap(find.byKey(const Key('nav-tab-tickets')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-list')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-tab-maintenance')));
      await tester.pumpAndSettle();
      expect(find.text('Seleccione un indicador'), findsOneWidget);
    });

    testWidgets('se ve bien en un telefono pequeno y con texto grande', (
      tester,
    ) async {
      await launch(tester, surface: TestSurface.smallPhone, textScale: 1.5);
      await openIndicator(tester, 'sgs');
      expect(tester.takeException(), isNull);
    });
  });
}
