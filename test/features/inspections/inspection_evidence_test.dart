import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/composition/location_finding_position_source.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/sample_inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/unavailable_inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/domain/entities/inspection.dart';
import 'package:sigaco_movil/features/inspections/domain/repositories/finding_position_source.dart';
import 'package:sigaco_movil/features/inspections/domain/repositories/inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/presentation/bloc/inspection_detail_cubit.dart';
import 'package:sigaco_movil/features/inspections/presentation/bloc/new_inspection_cubit.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

/// Posicion que se le prepare, o ninguna.
class _Position implements FindingPositionSource {
  _Position(this.value);

  final FindingPosition? value;

  @override
  Future<FindingPosition?> current() async => value;
}

class _ThrowingPosition implements FindingPositionSource {
  @override
  Future<FindingPosition?> current() => Future.error(StateError('sin gps'));
}

const _here = FindingPosition(
  latitude: -18.85,
  longitude: -41.98,
  accuracyMeters: 8.4,
);

void main() {
  final now = DateTime.utc(2026, 10, 21, 15);

  group('crear un monitoreo', () {
    late SampleInspectionsRepository repo;
    setUp(() => repo = SampleInspectionsRepository(clock: () => now));

    test('ofrece los tipos con sus puntos', () async {
      final templates = await repo.templates();
      expect(templates.map((t) => t.type), contains('Señalización'));
      expect(templates.every((t) => t.items.isNotEmpty), isTrue);
    });

    test('nace pendiente, con los puntos de su tipo y un id nuevo', () async {
      final created = await repo.create(
        NewInspection(
          type: 'Barreras',
          title: 'Defensa km 120',
          kmLabel: 'KM 120+000',
          scheduledAt: now,
        ),
      );
      expect(created.id, 'I-507');
      expect(created.status, InspectionStatus.pending);
      expect(created.checklist, hasLength(4));
      expect(created.answered, 0);
      expect(created.checklist.map((i) => i.id).toSet(), hasLength(4));
      expect((await repo.get('I-507')).title, 'Defensa km 120');
      expect((await repo.list()).first.id, 'I-507');
    });

    test('un tipo que no existe da notFound', () async {
      await expectLater(
        repo.create(const NewInspection(type: 'Otro', title: 'x')),
        throwsA(
          isA<InspectionsException>().having(
            (e) => e.error,
            'error',
            InspectionsError.notFound,
          ),
        ),
      );
    });

    test('el formulario pide solo el tipo y arma el nombre si falta', () async {
      final cubit = NewInspectionCubit(repo, clock: () => now);
      await cubit.load();
      expect(cubit.state.status, NewInspectionStatus.ready);
      await cubit.save();
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.showIssues, isTrue);

      cubit
        ..setType('Drenaje')
        ..setKm(' KM 163+200 ')
        ..setSegment('  ');
      await cubit.save();

      expect(cubit.state.saved, isTrue);
      final created = (await repo.list()).first;
      expect(created.title, 'Drenaje · KM 163+200');
      expect(created.kmLabel, 'KM 163+200');
      expect(created.segmentCode, isNull);
      expect(created.scheduledAt, now);
    });

    test('sin endpoints el formulario dice que no hay tipos', () async {
      final cubit = NewInspectionCubit(const UnavailableInspectionsRepository());
      await cubit.load();
      expect(cubit.state.status, NewInspectionStatus.failure);
      cubit.setType('Drenaje');
      await cubit.save();
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.failed, isTrue);
    });
  });

  group('hallazgos y evidencias', () {
    late SampleInspectionsRepository repo;
    setUp(() => repo = SampleInspectionsRepository(clock: () => now));

    InspectionDetailCubit cubitFor(
      String id, {
      FindingPositionSource? position,
    }) => InspectionDetailCubit(
      repo,
      id,
      positionSource: position ?? _Position(_here),
      clock: () => now,
      clientIdGenerator: () => 'f-1',
    );

    test('el hallazgo guarda nota, fotos y posicion de ahora', () async {
      final cubit = cubitFor('I-501');
      await cubit.load();
      await cubit.addFinding(
        itemId: 'I-501-1',
        note: '  Señal borrada  ',
        photoPaths: ['/a.jpg', '/b.jpg'],
      );

      final saved = cubit.state.inspection!;
      expect(saved.evidence, hasLength(1));
      final f = saved.evidence.single;
      expect(f.id, 'f-1');
      expect(f.itemId, 'I-501-1');
      expect(f.note, 'Señal borrada');
      expect(f.photoPaths, ['/a.jpg', '/b.jpg']);
      expect(f.position, _here);
      expect(f.capturedAt, now);
      // Capturar el primer hallazgo ya la pone en proceso.
      expect(saved.status, InspectionStatus.inProgress);
      expect(cubit.state.justSavedFinding, isTrue);
      cubit.findingShown();
      expect(cubit.state.justSavedFinding, isFalse);
      expect((await repo.get('I-501')).evidence, hasLength(1));
    });

    test('sin posicion el hallazgo se guarda igual, sin ella', () async {
      for (final source in [_Position(null), _ThrowingPosition()]) {
        final cubit = cubitFor('I-503', position: source);
        await cubit.load();
        await cubit.addFinding(note: 'Poste inclinado');
        expect(cubit.state.inspection!.evidence.last.position, isNull);
        expect(cubit.state.actionError, isNull);
      }
    });

    test('como mucho tres fotos', () async {
      final cubit = cubitFor('I-501');
      await cubit.load();
      await cubit.addFinding(photoPaths: ['/1', '/2', '/3', '/4', '/5']);
      expect(cubit.state.inspection!.evidence.single.photoPaths, [
        '/1',
        '/2',
        '/3',
      ]);
    });

    test('sin nota ni fotos no hay hallazgo', () async {
      final cubit = cubitFor('I-501');
      await cubit.load();
      await cubit.addFinding(note: '   ');
      expect(cubit.state.inspection!.evidence, isEmpty);
      expect(cubit.state.justSavedFinding, isFalse);
    });

    test('una inspeccion cerrada no acepta hallazgos', () async {
      final cubit = cubitFor('I-505');
      await cubit.load();
      await cubit.addFinding(note: 'Tarde');
      expect(cubit.state.inspection!.evidence, isEmpty);
      await expectLater(
        repo.addFinding(
          'I-505',
          InspectionFinding(id: 'x', capturedAt: now, note: 'Tarde'),
        ),
        throwsA(
          isA<InspectionsException>().having(
            (e) => e.error,
            'error',
            InspectionsError.notEditable,
          ),
        ),
      );
    });

    test('la posicion sale de la ubicacion del telefono', () async {
      final trusted = FakeLocationSource(
        location: UserLocation(
          position: const GeoPoint(-18.9, -41.9),
          accuracyMeters: 5,
          capturedAt: now,
        ),
      );
      expect(
        await LocationFindingPositionSource(trusted).current(),
        const FindingPosition(
          latitude: -18.9,
          longitude: -41.9,
          accuracyMeters: 5,
        ),
      );
      // Una ubicacion simulada nunca se acepta.
      final mocked = FakeLocationSource(
        location: UserLocation(
          position: const GeoPoint(0, 0),
          accuracyMeters: 1,
          capturedAt: now,
          origin: LocationOrigin.mocked,
        ),
      );
      expect(await LocationFindingPositionSource(mocked).current(), isNull);
      // Y si el GPS falla, no hay posicion pero tampoco error.
      final failing = FakeLocationSource(
        failure: LocationFailure.permissionDenied,
      );
      expect(await LocationFindingPositionSource(failing).current(), isNull);
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

    Future<SampleInspectionsRepository> launch(WidgetTester tester) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final repo = SampleInspectionsRepository(clock: () => now);
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'INSPECCIONES', 'INVENTARIO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        inspectionsRepository: repo,
        sampleInspections: true,
        inventoryRepository: SampleInventoryRepository(),
        zoneSource: FixedZoneSource(),
        fileSource: FakeFileSource(
          photo: const SelectedFile(
            name: 'foto.jpg',
            path: '/tmp/foto.jpg',
            sizeBytes: 10,
          ),
        ),
        locationSource: FakeLocationSource(
          location: UserLocation(
            position: const GeoPoint(-18.85, -41.98),
            accuracyMeters: 8,
            capturedAt: now,
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
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Monitoreo'),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> reveal(WidgetTester tester, Key key) =>
        tester.scrollUntilVisible(
          find.byKey(key),
          200,
          scrollable: find.descendant(
            of: find.byKey(const Key('inspection-detail')),
            matching: find.byType(Scrollable),
          ),
        );

    testWidgets('capturar un hallazgo con foto y posicion', (tester) async {
      final repo = await launch(tester);
      await tester.tap(find.byKey(const Key('inspection-I-502')));
      await tester.pumpAndSettle();
      await reveal(tester, const Key('inspection-evidence-empty'));
      expect(find.byKey(const Key('inspection-evidence-empty')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('inspection-detail')),
        const Offset(0, 3000),
      );
      await tester.pumpAndSettle();
      // Responder ya la dejo en proceso: el borrador se guarda solo.
      expect(find.byKey(const Key('inspection-draft-saved')), findsOneWidget);

      await tester.tap(find.byKey(const Key('inspection-action-finding')));
      await tester.pumpAndSettle();

      // Sin nota ni foto no se guarda.
      await tester.tap(find.byKey(const Key('finding-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe una descripción o toma una foto.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('finding-note')),
        'Defensa doblada',
      );
      await tester.tap(find.byKey(const Key('finding-slot-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finding-save')));
      await tester.pumpAndSettle();

      final saved = (await repo.get('I-502')).evidence.single;
      expect(saved.note, 'Defensa doblada');
      expect(saved.photoPaths, ['/tmp/foto.jpg']);
      expect(saved.position?.latitude, -18.85);
      expect(find.byKey(const Key('inspection-finding-saved')), findsOneWidget);
      await reveal(tester, Key('finding-${saved.id}'));
      expect(find.text('Defensa doblada'), findsOneWidget);
      expect(find.byKey(Key('finding-position-${saved.id}')), findsOneWidget);
      expect(find.textContaining('Posición -18.85000, -41.98000'), findsOneWidget);
    });

    testWidgets('una inspeccion cerrada no ofrece capturar hallazgos', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('inspections-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inspections-search')),
        'AL-07',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inspection-I-505')));
      await tester.pumpAndSettle();
      await reveal(tester, const Key('inspection-evidence-empty'));
      expect(find.byKey(const Key('inspection-action-finding')), findsNothing);
      expect(find.byKey(const Key('inspection-evidence-empty')), findsOneWidget);
    });

    testWidgets('crear un monitoreo desde la lista', (tester) async {
      final repo = await launch(tester);
      await tester.tap(find.byKey(const Key('inspections-new')));
      await tester.pumpAndSettle();

      // Sin tipo, avisa.
      await tapVisible(tester, find.byKey(const Key('inspection-form-submit')));
      expect(find.text('Elige el tipo de monitoreo.'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('new-inspection-type')));
      await tester.tap(find.text('Drenaje').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-inspection-km')),
        'KM 170+500',
      );
      await tapVisible(tester, find.byKey(const Key('inspection-form-submit')));

      // Vuelve a la lista con el monitoreo nuevo.
      expect(find.byKey(const Key('inspections-list')), findsOneWidget);
      final created = (await repo.list()).first;
      expect(created.title, 'Drenaje · KM 170+500');
      // El orden de la lista depende del dia de hoy: se baja hasta la tarjeta.
      await tester.scrollUntilVisible(
        find.byKey(Key('inspection-${created.id}')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('inspections-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(Key('inspection-${created.id}')), findsOneWidget);
    });
  });
}
