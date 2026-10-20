import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/works/data/repositories/sample_works_repository.dart';
import 'package:sigaco_movil/features/works/data/repositories/unavailable_works_repository.dart';
import 'package:sigaco_movil/features/works/domain/entities/public_work.dart';
import 'package:sigaco_movil/features/works/domain/repositories/works_repository.dart';
import 'package:sigaco_movil/features/works/presentation/bloc/work_detail_cubit.dart';
import 'package:sigaco_movil/features/works/presentation/bloc/works_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  group('dominio y cubits', () {
    late SampleWorksRepository repo;
    setUp(() => repo = SampleWorksRepository(clock: () => now));

    test('el atraso es lo que falta contra el programa, nunca negativo', () {
      const late = PublicWork(
        id: 'x',
        name: 'x',
        status: WorkStatus.delayed,
        physicalProgress: 0.6,
        programmedProgress: 0.9,
      );
      expect(late.lag, closeTo(0.3, 1e-9));
      const ahead = PublicWork(
        id: 'y',
        name: 'y',
        status: WorkStatus.inProgress,
        physicalProgress: 0.7,
        programmedProgress: 0.5,
      );
      expect(ahead.lag, 0);
    });

    test('lo pendiente del presupuesto no baja de cero', () {
      const over = PublicWork(
        id: 'x',
        name: 'x',
        status: WorkStatus.finished,
        physicalProgress: 1,
        programmedProgress: 1,
        budget: 100,
        executedAmount: 130,
      );
      expect(over.pendingAmount, 0);
      const none = PublicWork(
        id: 'y',
        name: 'y',
        status: WorkStatus.notStarted,
        physicalProgress: 0,
        programmedProgress: 0,
      );
      expect(none.pendingAmount, isNull);
    });

    test('las tres primeras son las del mapa de ejemplo', () async {
      final works = await repo.list();
      expect(works, hasLength(5));
      final pins = await SampleMapRepository().pins(MapLayer.works);
      expect(pins.map((p) => p.id), ['O-031', 'O-032', 'O-033']);
      for (final pin in pins) {
        final work = works.singleWhere((w) => w.id == pin.id);
        expect(work.latitude, closeTo(pin.position.latitude, 1e-5));
        expect(work.longitude, closeTo(pin.position.longitude, 1e-5));
        expect(work.segmentCode, pin.segmentCode);
        expect(work.hasLocation, isTrue);
      }
      expect(works.where((w) => !w.hasLocation).map((w) => w.id), [
        'O-034',
        'O-035',
      ]);
    });

    test('una obra que no existe da notFound', () async {
      await expectLater(
        repo.get('O-999'),
        throwsA(
          isA<WorksException>().having(
            (e) => e.error,
            'error',
            WorksError.notFound,
          ),
        ),
      );
    });

    test('el cubit cuenta por estado y pone primero lo mas atrasado', () async {
      final cubit = WorksCubit(repo);
      await cubit.load();
      final s = cubit.state;
      expect(s.status, WorksListStatus.ready);
      expect(s.total, 5);
      expect(s.count(WorkStatus.inProgress), 2);
      expect(s.count(WorkStatus.delayed), 1);
      expect(s.count(WorkStatus.finished), 1);
      expect(s.count(WorkStatus.notStarted), 1);
      expect(s.visible.first.id, 'O-032');
    });

    test('filtra por estado y busca por nombre, contratista o tramo', () async {
      final cubit = WorksCubit(repo);
      await cubit.load();
      cubit.setStatus(WorkStatus.inProgress);
      expect(cubit.state.visible.map((w) => w.id).toSet(), {'O-031', 'O-033'});
      cubit.setStatus(null);
      cubit.setQuery('rio doce');
      expect(cubit.state.visible.map((w) => w.id), ['O-033']);
      cubit.setQuery('0170');
      expect(cubit.state.visible.map((w) => w.id), ['O-032']);
      expect(cubit.state.hasActiveFilters, isTrue);
      cubit.clearFilters();
      expect(cubit.state.hasActiveFilters, isFalse);
      expect(cubit.state.visible, hasLength(5));
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = WorksCubit(const UnavailableWorksRepository());
      await cubit.load();
      expect(cubit.state.status, WorksListStatus.failure);
      expect(cubit.state.error, WorksError.notAvailable);
    });

    test('la ficha carga o falla con notFound', () async {
      final ok = WorkDetailCubit(repo, 'O-032');
      await ok.load();
      expect(ok.state.work!.name, 'Refuerzo del puente');
      final missing = WorkDetailCubit(repo, 'O-999');
      await missing.load();
      expect(missing.state.error, WorksError.notFound);
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
      WorksRepository? works,
      bool sample = true,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'OBRAS']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        worksRepository: works ?? SampleWorksRepository(),
        sampleWorks: sample,
        mapRepository: SampleMapRepository(),
        roadSegmentsRepository: FakeRoadSegmentsRepository(),
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
          matching: find.text('Obras'),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder card(String id) => find.byKey(Key('work-$id'));
    String stat(WidgetTester tester, String key) => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;

    testWidgets('el menu abre las obras con su resumen', (tester) async {
      await launch(tester);
      expect(find.byKey(const Key('works-sample-banner')), findsOneWidget);
      expect(stat(tester, 'works-stat-inProgress'), '2');
      expect(stat(tester, 'works-stat-delayed'), '1');
      expect(stat(tester, 'works-stat-finished'), '1');
      expect(stat(tester, 'works-stat-notStarted'), '1');
      // La mas atrasada va primero.
      expect(card('O-032'), findsOneWidget);
    });

    testWidgets('filtrar por estado y quitar los filtros', (tester) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('works-status-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Con atraso').last);
      await tester.pumpAndSettle();
      expect(card('O-032'), findsOneWidget);
      expect(card('O-031'), findsNothing);
      expect(find.byType(Badge), findsOneWidget);
      await tester.tap(find.byKey(const Key('works-filter-button')));
      await tester.pumpAndSettle();
      expect(card('O-031'), findsOneWidget);
    });

    testWidgets('sin endpoints la pantalla lo dice', (tester) async {
      await launch(
        tester,
        works: const UnavailableWorksRepository(),
        sample: false,
      );
      expect(find.byKey(const Key('works-state-notAvailable')), findsOneWidget);
    });

    testWidgets('la ficha muestra avance, importes y abre el mapa', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(card('O-032'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-detail')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('work-detail-physical'))).data,
        '80%',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('work-detail-programmed')))
            .data,
        '95%',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('work-detail-lag'))).data,
        'Atraso: 15%',
      );
      expect(find.byKey(const Key('work-info')), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-action-map')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-detail')), findsOneWidget);
      expect(find.text('Refuerzo del puente'), findsWidgets);
    });

    testWidgets('una obra sin ubicacion avisa en lugar de abrir el mapa', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('works-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('works-search')),
        'señalización',
      );
      await tester.pumpAndSettle();
      await tester.tap(card('O-034'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('work-action-map')));
      await tester.pump();
      expect(find.text('Esta obra no tiene ubicación.'), findsOneWidget);
      expect(find.byKey(const Key('map-detail')), findsNothing);
    });
  });
}
