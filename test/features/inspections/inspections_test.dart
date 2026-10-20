import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/time/concession_zone_source.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/sample_inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/unavailable_inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/domain/entities/inspection.dart';
import 'package:sigaco_movil/features/inspections/domain/repositories/inspections_repository.dart';
import 'package:sigaco_movil/features/inspections/presentation/bloc/inspection_detail_cubit.dart';
import 'package:sigaco_movil/features/inspections/presentation/bloc/inspections_cubit.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  group('dominio y cubits', () {
    late SampleInspectionsRepository repo;
    setUp(() => repo = SampleInspectionsRepository(clock: () => now));

    test('el avance y los hallazgos salen del checklist', () async {
      final i = await repo.get('I-502');
      expect(i.checklist, hasLength(4));
      expect(i.answered, 2);
      expect(i.progress, 0.5);
      expect(i.findings, 1);
      // El hallazgo es de un punto que no es critico.
      expect(i.criticalFindings, 0);
      expect(i.complete, isFalse);
      expect(i.editable, isTrue);
    });

    test('un hallazgo en un punto critico cuenta como critico', () async {
      final i = await repo.get('I-504');
      expect(i.findings, 1);
      expect(i.criticalFindings, 1);
      expect(i.complete, isTrue);
      expect(i.editable, isFalse);
    });

    test('cerrada y cancelada no se pueden llenar', () async {
      for (final id in ['I-505', 'I-506']) {
        final i = await repo.get(id);
        expect(i.editable, isFalse, reason: id);
        await expectLater(
          repo.saveAnswers(id, {i.checklist.first.id: CheckResult.ok}),
          throwsA(
            isA<InspectionsException>().having(
              (e) => e.error,
              'error',
              InspectionsError.notEditable,
            ),
          ),
        );
      }
    });

    test('responder un punto pone la inspeccion en proceso', () async {
      expect((await repo.get('I-501')).status, InspectionStatus.pending);
      final saved = await repo.saveAnswers('I-501', {
        'I-501-1': CheckResult.ok,
      });
      expect(saved.status, InspectionStatus.inProgress);
      expect(saved.answered, 1);
      expect((await repo.get('I-501')).answered, 1);
    });

    test('no se termina con el checklist incompleto', () async {
      await expectLater(
        repo.complete('I-501', {'I-501-1': CheckResult.ok}),
        throwsA(
          isA<InspectionsException>().having(
            (e) => e.error,
            'error',
            InspectionsError.incomplete,
          ),
        ),
      );
      expect((await repo.get('I-501')).status, InspectionStatus.pending);
    });

    test('terminar la deja atendida con su fecha', () async {
      final done = await repo.complete('I-501', {
        'I-501-1': CheckResult.ok,
        'I-501-2': CheckResult.ok,
        'I-501-3': CheckResult.finding,
      });
      expect(done.status, InspectionStatus.attended);
      expect(done.completedAt, now);
      expect(done.editable, isFalse);
    });

    test('una inspeccion que no existe da notFound', () async {
      await expectLater(
        repo.get('I-999'),
        throwsA(
          isA<InspectionsException>().having(
            (e) => e.error,
            'error',
            InspectionsError.notFound,
          ),
        ),
      );
    });

    test('la lista pone primero lo que hay que hacer', () async {
      final cubit = InspectionsCubit(repo);
      await cubit.load();
      expect(cubit.state.visible.map((i) => i.id), [
        'I-502', // en proceso
        'I-503', // pendiente, hoy
        'I-501', // pendiente, manana
        'I-504', // atendida
        'I-505', // cerrada
        'I-506', // cancelada
      ]);
      expect(cubit.state.count(InspectionStatus.pending), 2);
      cubit.setStatus(InspectionStatus.pending);
      expect(cubit.state.visible, hasLength(2));
      cubit.setStatus(null);
      cubit.setQuery('SV-114');
      expect(cubit.state.visible.map((i) => i.id), ['I-501']);
      cubit.clearFilters();
      expect(cubit.state.hasActiveFilters, isFalse);
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = InspectionsCubit(const UnavailableInspectionsRepository());
      await cubit.load();
      expect(cubit.state.status, InspectionsListStatus.failure);
      expect(cubit.state.error, InspectionsError.notAvailable);
    });

    test('responder en la ficha se ve al momento y se guarda', () async {
      final cubit = InspectionDetailCubit(repo, 'I-501');
      await cubit.load();
      await cubit.answer('I-501-2', CheckResult.finding);
      expect(cubit.state.inspection!.answered, 1);
      expect(cubit.state.inspection!.status, InspectionStatus.inProgress);
      expect((await repo.get('I-501')).answered, 1);
    });

    test('terminar con el checklist incompleto avisa y no guarda', () async {
      final cubit = InspectionDetailCubit(repo, 'I-501');
      await cubit.load();
      await cubit.complete();
      expect(cubit.state.actionError, InspectionsError.incomplete);
      expect(cubit.state.inspection!.status, InspectionStatus.pending);
    });

    test('terminar con todo respondido avisa una sola vez', () async {
      final cubit = InspectionDetailCubit(repo, 'I-501');
      await cubit.load();
      for (final item in cubit.state.inspection!.checklist) {
        await cubit.answer(item.id, CheckResult.ok);
      }
      await cubit.complete();
      expect(cubit.state.inspection!.status, InspectionStatus.attended);
      expect(cubit.state.justCompleted, isTrue);
      cubit.completionShown();
      expect(cubit.state.justCompleted, isFalse);
    });

    test('una inspeccion cerrada no acepta respuestas', () async {
      final cubit = InspectionDetailCubit(repo, 'I-505');
      await cubit.load();
      final before = cubit.state.inspection;
      await cubit.answer('I-505-1', CheckResult.finding);
      expect(cubit.state.inspection, before);
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
      InspectionsRepository? inspections,
      bool configured = true,
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
          menu: menuWith(['PANEL', 'INSPECCIONES', 'INVENTARIO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        inspectionsRepository: inspections ?? SampleInspectionsRepository(),
        sampleInspections: sample,
        inventoryRepository: SampleInventoryRepository(),
        zoneSource: configured
            ? FixedZoneSource()
            : const NoConcessionZoneSource(),
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
    }

    Finder card(String id) => find.byKey(Key('inspection-$id'));
    Finder check(String item, String result) =>
        find.byKey(Key('check-$item-$result'));

    testWidgets('el menu abre las inspecciones con su resumen', (tester) async {
      await launch(tester);
      expect(
        find.byKey(const Key('inspections-sample-banner')),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('inspections-stat-pending')),
                matching: find.byType(Text),
              ),
            )
            .first
            .data,
        '2',
      );
      expect(card('I-502'), findsOneWidget);
    });

    testWidgets('buscar por activo y filtrar por estado', (tester) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('inspections-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inspections-search')),
        'SV-114',
      );
      await tester.pumpAndSettle();
      expect(card('I-501'), findsOneWidget);
      expect(card('I-502'), findsNothing);
      await tester.tap(find.byKey(const Key('inspections-filter-button')));
      await tester.pumpAndSettle();
      expect(card('I-502'), findsOneWidget);
    });

    testWidgets('sin endpoints la pantalla lo dice', (tester) async {
      await launch(
        tester,
        inspections: const UnavailableInspectionsRepository(),
        sample: false,
      );
      expect(
        find.byKey(const Key('inspections-state-notAvailable')),
        findsOneWidget,
      );
    });

    testWidgets('llenar el checklist y finalizar la inspeccion', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(card('I-503'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspection-detail')), findsOneWidget);
      expect(find.byKey(const Key('check-I-503-2-critical')), findsOneWidget);

      // Sin responder todo, el boton avisa que faltan puntos.
      await tester.tap(find.byKey(const Key('inspection-action-complete')));
      await tester.pumpAndSettle();
      expect(
        find.text('Faltan puntos del checklist por responder.'),
        findsOneWidget,
      );

      // El aviso tapa la barra de abajo: se espera a que se vaya.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.tap(check('I-503-1', 'ok'));
      await tester.pumpAndSettle();
      await tester.tap(check('I-503-2', 'finding'));
      await tester.pumpAndSettle();
      await tester.tap(check('I-503-3', 'ok'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('inspection-detail-progress')))
            .data,
        '3 de 3 puntos',
      );
      expect(
        find.byKey(const Key('inspection-detail-findings')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inspection-action-complete')));
      await tester.pumpAndSettle();
      // El hallazgo del punto critico se avisa al terminar.
      expect(find.textContaining('Hay hallazgos críticos'), findsOneWidget);
      expect(find.text('Atendida'), findsWidgets);
    });

    testWidgets('una inspeccion cerrada se ve sin poder llenarla', (
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
      await tester.tap(card('I-505'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspection-action-complete')), findsNothing);
      final ok = tester.widget<OutlinedButton>(check('I-505-1', 'ok'));
      expect(ok.onPressed, isNull);
    });

    testWidgets('desde la ficha se abre el activo del catalogo', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('inspections-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inspections-search')),
        'SV-114',
      );
      await tester.pumpAndSettle();
      await tester.tap(card('I-501'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inspection-action-asset')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-detail')), findsOneWidget);
      expect(find.text('Señal vertical SV-114'), findsWidgets);
    });

    testWidgets('sin configuracion de la concesion no se puede responder', (
      tester,
    ) async {
      await launch(tester, configured: false);
      await tester.tap(card('I-503'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspection-no-config')), findsOneWidget);
      expect(find.byKey(const Key('inspection-action-complete')), findsNothing);
      expect(
        tester.widget<OutlinedButton>(check('I-503-1', 'ok')).onPressed,
        isNull,
      );
    });
  });
}
