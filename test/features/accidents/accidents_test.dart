import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/sample_accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/unavailable_accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/domain/entities/accident.dart';
import 'package:sigaco_movil/features/accidents/domain/repositories/accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/presentation/bloc/accident_detail_cubit.dart';
import 'package:sigaco_movil/features/accidents/presentation/bloc/accidents_cubit.dart';
import 'package:sigaco_movil/features/accidents/presentation/bloc/new_accident_cubit.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

const _menu = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(
      code: 'ANTT',
      name: 'ANTT',
      submodules: [NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes')],
    ),
  ],
);

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  group('dominio y cubits', () {
    late SampleAccidentsRepository repo;
    setUp(() => repo = SampleAccidentsRepository(clock: () => now));

    test('cuenta y reparte el total por tipo', () async {
      final cubit = AccidentsCubit(repo);
      await cubit.load();
      final s = cubit.state;
      expect(s.status, AccidentsStatus.ready);
      expect(s.total, 8);
      expect(s.count(AccidentFilter.collision), 3);
      expect(s.count(AccidentFilter.rollover), 3);
      expect(s.count(AccidentFilter.fire), 2);
      expect(s.share(AccidentFilter.collision), closeTo(37.5, 0.01));
      expect(
        s.share(AccidentFilter.collision) +
            s.share(AccidentFilter.rollover) +
            s.share(AccidentFilter.runOver) +
            s.share(AccidentFilter.fire) +
            s.share(AccidentFilter.other),
        closeTo(100, 0.01),
      );
    });

    test('filtra por tipo y por gravedad, y busca', () async {
      final cubit = AccidentsCubit(repo);
      await cubit.load();
      cubit.setFilter(AccidentFilter.rollover);
      expect(cubit.state.visible, hasLength(3));
      cubit.setSeverity(AccidentSeverity.serious);
      expect(cubit.state.visible.map((a) => a.id), ['A-0036']);
      cubit.clearFilters();
      expect(cubit.state.visible, hasLength(8));
      cubit.setQuery('túnel');
      expect(cubit.state.visible.map((a) => a.id), ['A-0038']);
      cubit.setQuery('0037');
      expect(cubit.state.visible.map((a) => a.id), ['A-0037']);
    });

    test('lo mas reciente va primero', () async {
      final cubit = AccidentsCubit(repo);
      await cubit.load();
      expect(cubit.state.visible.first.id, 'A-0036');
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = AccidentsCubit(const UnavailableAccidentsRepository());
      await cubit.load();
      expect(cubit.state.status, AccidentsStatus.failure);
      expect(cubit.state.error, AccidentsError.notAvailable);
      expect(cubit.state.share(AccidentFilter.fire), 0);
    });

    test('la ficha carga o falla con notFound', () async {
      final ok = AccidentDetailCubit(repo, 'A-0035');
      await ok.load();
      expect(ok.state.accident!.code, '0035');
      final missing = AccidentDetailCubit(repo, 'A-9999');
      await missing.load();
      expect(missing.state.error, AccidentsError.notFound);
    });

    test('el registro pide titulo y tipo', () async {
      final cubit = NewAccidentCubit(repo);
      await cubit.save();
      expect(cubit.state.issues, [
        NewAccidentIssue.title,
        NewAccidentIssue.type,
      ]);
      expect(cubit.state.saved, isFalse);
    });

    test('cada vehiculo pide su tipo y cada victima su gravedad', () async {
      final cubit = NewAccidentCubit(repo)
        ..setTitle('Choque')
        ..setType(AccidentType.collision)
        ..setVehicleCount(2)
        ..setVictimCount(2);
      expect(cubit.state.vehicles, [null, null]);
      expect(cubit.state.issues, [
        NewAccidentIssue.vehicle,
        NewAccidentIssue.victim,
      ]);
      await cubit.save();
      expect(cubit.state.saved, isFalse);

      cubit
        ..setVehicleType(0, VehicleType.vehicle)
        ..setVehicleType(1, VehicleType.motorcycle)
        ..setVictimSeverity(0, AccidentSeverity.minor)
        ..setVictimSeverity(1, AccidentSeverity.fatal);
      expect(cubit.state.issues, isEmpty);
    });

    test(
      'la cantidad decide los renglones y baja conservando los primeros',
      () {
        final cubit = NewAccidentCubit(repo)
          ..setVehicleCount(3)
          ..setVehicleType(0, VehicleType.livestock)
          ..setVehicleType(2, VehicleType.fixedObject)
          ..setVehicleCount(1);
        expect(cubit.state.vehicles, [VehicleType.livestock]);
        cubit.setVictimCount(accidentMaxParties + 5);
        expect(cubit.state.victims, hasLength(accidentMaxParties));
        cubit.setVictimCount(-3);
        expect(cubit.state.victims, isEmpty);
      },
    );

    test('un renglon fuera de rango se ignora', () {
      final cubit = NewAccidentCubit(repo)
        ..setVehicleCount(1)
        ..setVehicleType(5, VehicleType.vehicle)
        ..setVictimSex(0, VictimSex.male)
        ..setVictimSeverity(-1, AccidentSeverity.fatal);
      expect(cubit.state.vehicles, [null]);
      expect(cubit.state.victims, isEmpty);
    });

    test('la gravedad del accidente es la de su victima mas grave', () {
      final cubit = NewAccidentCubit(repo);
      expect(cubit.state.severity, AccidentSeverity.unharmed);
      cubit
        ..setVictimCount(3)
        ..setVictimSeverity(0, AccidentSeverity.minor)
        ..setVictimSeverity(1, AccidentSeverity.fatal)
        ..setVictimSeverity(2, AccidentSeverity.serious);
      expect(cubit.state.severity, AccidentSeverity.fatal);
    });

    test('lo capturado llega completo al repositorio', () async {
      final cubit = NewAccidentCubit(repo)
        ..setTitle('Atropello km 150')
        ..setType(AccidentType.runOver)
        ..setZone(AccidentZone.urban)
        ..setWeather(AccidentWeather.fog)
        ..setPavementCondition(RoadCondition.poor)
        ..setLayout(RoadLayout.verticalCurve)
        ..setPavementType(PavementType.rigid)
        ..setSignageCondition(RoadCondition.fair)
        ..setCause(AccidentCause.speeding)
        ..setPlace(AccidentPlace.tollBooth)
        ..setVehicleCount(1)
        ..setVehicleType(0, VehicleType.motorcycle)
        ..setVictimCount(2)
        ..setVictimSex(0, VictimSex.female)
        ..setVictimSeverity(0, AccidentSeverity.serious)
        ..setVictimSeverity(1, AccidentSeverity.unharmed);
      await cubit.save();

      final a = (await repo.list()).first;
      expect(a.type, AccidentType.runOver);
      expect(a.severity, AccidentSeverity.serious);
      expect(a.zone, AccidentZone.urban);
      expect(a.weather, AccidentWeather.fog);
      expect(a.pavementCondition, RoadCondition.poor);
      expect(a.layout, RoadLayout.verticalCurve);
      expect(a.pavementType, PavementType.rigid);
      expect(a.signageCondition, RoadCondition.fair);
      expect(a.cause, AccidentCause.speeding);
      expect(a.place, AccidentPlace.tollBooth);
      expect(a.vehicles, [const AccidentVehicle(type: VehicleType.motorcycle)]);
      expect(a.victims, [
        const AccidentVictim(
          severity: AccidentSeverity.serious,
          sex: VictimSex.female,
        ),
        const AccidentVictim(severity: AccidentSeverity.unharmed),
      ]);
    });

    test('registra el accidente con lo capturado', () async {
      final cubit = NewAccidentCubit(repo)
        ..setTitle('  Choque en la caseta ')
        ..setType(AccidentType.collision)
        ..setKm('KM 149+500')
        ..setPhoto(1, '/tmp/b.jpg')
        ..setPhoto(7, '/tmp/fuera.jpg');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      final created = (await repo.list()).first;
      expect(created.title, 'Choque en la caseta');
      expect(created.status, AccidentStatus.registered);
      expect(created.photoPaths, ['/tmp/b.jpg']);
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

    late SampleAccidentsRepository repo;

    Future<void> launch(
      WidgetTester tester, {
      AccidentsRepository? accidents,
      bool sample = true,
      Size surface = TestSurface.largePhone,
      double textScale = 1.0,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, surface, textScale: textScale);
      SharedPreferences.setMockInitialValues({});
      repo = SampleAccidentsRepository();
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(menu: _menu),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        accidentsRepository: accidents ?? repo,
        zoneSource: FixedZoneSource(),
        sampleAccidents: sample,
        fileSource: FakeFileSource(
          photo: const SelectedFile(
            name: 'foto.jpg',
            path: '/no/existe/foto.jpg',
            sizeBytes: 10,
          ),
        ),
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

    Future<void> open(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Accidentes'),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder card(String id) => find.byKey(Key('accident-$id'));
    Finder stat(String id) => find.descendant(
      of: find.byKey(Key('accidents-stat-$id')),
      matching: find.byType(Text),
    );

    testWidgets('abre desde el menu con el resumen por tipo', (tester) async {
      await launch(tester);
      await open(tester);
      expect(find.byKey(const Key('accidents-sample-banner')), findsOneWidget);
      expect(find.text('Accidentes'), findsOneWidget);
      // Cada cifra del resumen es una columna: valor, nombre y porcentaje.
      expect(tester.widgetList<Text>(stat('all')).map((t) => t.data), [
        '8',
        'Total',
        '100% total',
      ]);
      expect(tester.widgetList<Text>(stat('collision')).map((t) => t.data), [
        '3',
        'Choque',
        '37.5%',
      ]);
      expect(card('A-0036'), findsOneWidget);
    });

    testWidgets('filtrar por tipo deja solo esos accidentes', (tester) async {
      await launch(tester);
      await open(tester);
      // Con cuatro pestanas la fila se desliza: se lleva el Incendio a la vista.
      await tester.drag(
        find.byKey(const Key('accidents-chips')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accidents-filter-fire')));
      await tester.pumpAndSettle();
      expect(card('A-0037'), findsOneWidget);
      expect(card('A-0036'), findsNothing);
    });

    testWidgets('la lupa muestra la busqueda', (tester) async {
      await launch(tester);
      await open(tester);
      expect(find.byKey(const Key('accidents-search')), findsNothing);
      await tester.tap(find.byKey(const Key('accidents-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('accidents-search')), '0036');
      await tester.pumpAndSettle();
      expect(card('A-0036'), findsOneWidget);
      expect(card('A-0037'), findsNothing);
      // Cerrar la busqueda la limpia.
      await tester.tap(find.byKey(const Key('accidents-search-button')));
      await tester.pumpAndSettle();
      expect(card('A-0036'), findsOneWidget);
    });

    testWidgets('la hoja de filtros acota por gravedad', (tester) async {
      await launch(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('accidents-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('accidents-sheet-severity-serious')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accidents-sheet-done')));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(card('A-0036'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo avisa', (tester) async {
      await launch(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('accidents-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('accidents-search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accidents-state-empty')), findsOneWidget);
      expect(
        find.text('Ningún accidente coincide con los filtros.'),
        findsOneWidget,
      );
    });

    testWidgets('sin endpoints dice que no esta disponible', (tester) async {
      await launch(tester, accidents: const UnavailableAccidentsRepository());
      await open(tester);
      expect(
        find.byKey(const Key('accidents-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('accidents-stat-all')), findsNothing);
    });

    testWidgets('la ficha muestra tipo, gravedad y datos', (tester) async {
      await launch(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('accidents-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('accidents-search')), '0035');
      await tester.pumpAndSettle();
      await tester.tap(card('A-0035'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accident-detail')), findsOneWidget);
      expect(find.text('ID ACCIDENTE #0035'), findsOneWidget);
      expect(find.text('En proceso'), findsOneWidget);
      expect(find.byKey(const Key('accident-info')), findsOneWidget);
      expect(find.text('KM 513+615'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accident-action-edit')));
      await tester.pump();
      expect(
        find.text('Esta acción estará disponible pronto.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('accident-detail-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accidents-list')), findsOneWidget);
    });

    testWidgets(
      'la ficha muestra las condiciones, los vehiculos y las victimas',
      (tester) async {
        await launch(tester);
        await open(tester);
        await tester.tap(find.byKey(const Key('accidents-search-button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('accidents-search')),
          '0036',
        );
        await tester.pumpAndSettle();
        await tester.tap(card('A-0036'));
        await tester.pumpAndSettle();

        final conditions = find.byKey(const Key('accident-conditions'));
        await tester.ensureVisible(conditions);
        await tester.pumpAndSettle();
        expect(conditions, findsOneWidget);
        for (final text in [
          'Rural',
          'Normal',
          'Curva horizontal',
          'Exceso de velocidad',
          'Pavimento',
        ]) {
          expect(find.text(text), findsWidgets, reason: text);
        }
        expect(
          find.byKey(const Key('accident-detail-vehicle-0')),
          findsOneWidget,
        );
        expect(find.text('Vehículo 1 · Vehículo'), findsOneWidget);
        expect(
          find.byKey(const Key('accident-detail-victim-0')),
          findsOneWidget,
        );
        expect(
          find.text('Víctima 1 · Masculino · Heridas graves'),
          findsOneWidget,
        );
      },
    );

    testWidgets('un accidente sin esos datos no muestra las secciones vacias', (
      tester,
    ) async {
      await launch(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('accidents-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('accidents-search')), '0038');
      await tester.pumpAndSettle();
      await tester.tap(card('A-0038'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('accident-detail')), findsOneWidget);
      expect(find.byKey(const Key('accident-conditions')), findsNothing);
      expect(find.byKey(const Key('accident-detail-vehicle-0')), findsNothing);
      expect(find.byKey(const Key('accident-detail-victim-0')), findsNothing);
    });

    testWidgets('registrar un accidente nuevo lo suma al historial', (
      tester,
    ) async {
      await launch(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('accidents-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accident-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un título.'), findsOneWidget);
      expect(find.text('Elige el tipo de accidente.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('new-accident-title')),
        'Choque en la caseta',
      );
      await tester.tap(find.byKey(const Key('new-accident-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Incendio').last);
      await tester.pumpAndSettle();
      // Un vehiculo y una victima: cada uno pide sus datos.
      final plusVehicle = find.byKey(const Key('accident-vehicles-plus'));
      await tester.ensureVisible(plusVehicle);
      await tester.pumpAndSettle();
      await tester.tap(plusVehicle);
      await tester.pumpAndSettle();
      final plusVictim = find.byKey(const Key('accident-victims-plus'));
      await tester.ensureVisible(plusVictim);
      await tester.pumpAndSettle();
      await tester.tap(plusVictim);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('accident-form-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accident-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Elige el tipo de vehículo.'), findsOneWidget);
      expect(find.text('Elige la gravedad de la víctima.'), findsOneWidget);
      final vehicle = find.byKey(const Key('new-accident-vehicle-0'));
      await tester.ensureVisible(vehicle);
      await tester.pumpAndSettle();
      await tester.tap(vehicle);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Motocicleta').last);
      await tester.pumpAndSettle();
      final victim = find.byKey(const Key('new-accident-victim-severity-0'));
      await tester.ensureVisible(victim);
      await tester.pumpAndSettle();
      await tester.tap(victim);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ileso').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('new-accident-derived-severity')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('accident-photo-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accident-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Accidente registrado.'), findsOneWidget);
      expect(stat('all').evaluate().isNotEmpty, isTrue);
      expect(tester.widgetList<Text>(stat('all')).first.data, '9');
      expect((await repo.list()).first.photoPaths, ['/no/existe/foto.jpg']);
    });

    testWidgets('se ve bien en un telefono pequeno y con texto grande', (
      tester,
    ) async {
      await launch(tester, surface: TestSurface.smallPhone, textScale: 1.5);
      await open(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('accidents-new')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
