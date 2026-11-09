import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/unavailable_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_detail_cubit.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  group('dominio y cubits', () {
    late SampleInventoryRepository repo;
    setUp(() => repo = SampleInventoryRepository(clock: () => now));

    test('son los mismos elementos que el mapa de ejemplo', () async {
      final assets = await repo.allAssets();
      expect(assets, hasLength(12));
      final pins = await SampleMapRepository().pins(MapLayer.inventory);
      expect(assets.map((a) => a.id), pins.map((p) => p.id));
      for (final a in assets) {
        final pin = pins.singleWhere((p) => p.id == a.id);
        expect(a.latitude, closeTo(pin.position.latitude, 1e-5), reason: a.id);
        expect(
          a.longitude,
          closeTo(pin.position.longitude, 1e-5),
          reason: a.id,
        );
        expect(a.segmentCode, pin.segmentCode, reason: a.id);
        expect(a.hasLocation, isTrue, reason: a.id);
      }
    });

    test('un activo que no existe da notFound', () async {
      await expectLater(
        repo.get('A-999'),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.error,
            'error',
            InventoryError.notFound,
          ),
        ),
      );
      expect((await repo.get('A-001')).name, 'Defensa metálica');
    });

    test('la busqueda encuentra por nombre, tramo o kilometro', () {
      const asset = InventoryAsset(
        id: 'A-001',
        name: 'Defensa metálica',
        category: 'Barrera',
        condition: AssetCondition.good,
        kmLabel: 'KM 147+200',
        segmentCode: '381BMG0160',
      );
      expect(asset.matches(''), isTrue);
      expect(asset.matches('defensa'), isTrue);
      expect(asset.matches('0160'), isTrue);
      expect(asset.matches('147+2'), isTrue);
      expect(asset.matches('semáforo'), isFalse);
      expect(asset.hasLocation, isFalse);
    });

    test('el cubit cuenta por estado y reparte el total', () async {
      final cubit = InventoryCubit(repo);
      await cubit.load();
      final s = cubit.state;
      expect(s.status, InventoryListStatus.ready);
      expect(s.total, 12);
      expect(
        AssetCondition.values.fold<int>(0, (sum, c) => sum + s.count(c)),
        12,
      );
      expect(
        AssetCondition.values.fold<double>(0, (sum, c) => sum + s.share(c)),
        closeTo(100, 0.001),
      );
      expect(s.count(AssetCondition.good), 6);
      expect(s.count(AssetCondition.regular), 4);
      expect(s.count(AssetCondition.poor), 2);
      expect(s.share(AssetCondition.regular), closeTo(33.33, 0.01));
    });

    test('los que mas atencion piden van primero', () async {
      final cubit = InventoryCubit(repo);
      await cubit.load();
      final order = cubit.state.visible.map((a) => a.condition.index).toList();
      expect([...order]..sort((a, b) => b.compareTo(a)), order);
      // Entre los malos, por nombre.
      expect(cubit.state.visible.take(2).map((a) => a.id), ['A-008', 'A-005']);
    });

    test('filtra por estado, tipo y fecha de inspeccion, y busca', () async {
      final cubit = InventoryCubit(repo, searchDelay: Duration.zero);
      await cubit.load();
      final all = cubit.state.total;

      await cubit.setCondition(AssetCondition.poor);
      expect(
        cubit.state.visible.every((a) => a.condition == AssetCondition.poor),
        isTrue,
      );
      await cubit.setCondition(null);
      expect(cubit.state.visible, hasLength(all));

      // Sin codigo de tipo, el nombre hace de codigo.
      expect(
        cubit.state.typeOptions('es').map((t) => t.code),
        contains('Señal vertical'),
      );
      await cubit.setType('Señal vertical');
      expect(cubit.state.visible, isNotEmpty);
      expect(
        cubit.state.visible.every((a) => a.category == 'Señal vertical'),
        isTrue,
      );
      await cubit.setType(null);

      // El primero se inspecciono hace 3 dias y cada uno hace 17 mas.
      await cubit.setInspectedFrom(DateTime.utc(2026, 10, 15 - 3));
      expect(cubit.state.visible.map((a) => a.id), ['A-001']);
      await cubit.setInspectedFrom(null);

      // Hasta: el primero (hace 3 dias) queda fuera si el tope es anterior, y
      // el rango desde-hasta deja solo lo que cae dentro, extremos incluidos.
      await cubit.setInspectedTo(DateTime.utc(2026, 10, 15 - 4));
      expect(cubit.state.visible.map((a) => a.id), isNot(contains('A-001')));
      await cubit.setInspectedFrom(DateTime.utc(2026, 10, 15 - 3));
      expect(cubit.state.visible, isEmpty);
      await cubit.setInspectedTo(DateTime.utc(2026, 10, 15 - 3));
      expect(cubit.state.visible.map((a) => a.id), ['A-001']);
      expect(cubit.state.hasActiveFilters, isTrue);
      await cubit.clearFilters();
      expect(cubit.state.inspectedTo, isNull);
      expect(cubit.state.inspectedFrom, isNull);

      await cubit.setQuery('SV-114');
      expect(cubit.state.visible.map((a) => a.id), ['A-002']);
      expect(cubit.state.hasActiveFilters, isTrue);
      await cubit.clearFilters();
      expect(cubit.state.hasActiveFilters, isFalse);
      expect(cubit.state.visible, hasLength(all));
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = InventoryCubit(const UnavailableInventoryRepository());
      await cubit.load();
      expect(cubit.state.status, InventoryListStatus.failure);
      expect(cubit.state.error, InventoryError.notAvailable);
    });

    test('la ficha carga o falla con notFound', () async {
      final ok = InventoryDetailCubit(repo, 'A-002');
      await ok.load();
      expect(ok.state.asset!.name, 'Señal vertical SV-114');
      final missing = InventoryDetailCubit(repo, 'A-999');
      await missing.load();
      expect(missing.state.error, InventoryError.notFound);
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
      InventoryRepository? inventory,
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
          menu: menuWith(['PANEL', 'INVENTARIO']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        inventoryRepository: inventory ?? SampleInventoryRepository(),
        sampleInventory: sample,
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
    }

    Future<void> openInventory(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Catálogo'),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// La busqueda sale cuando se deja de escribir.
    Future<void> search(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    Finder card(String id) => find.byKey(Key('inventory-$id'));
    Finder stat(String id) => find.descendant(
      of: find.byKey(Key('inventory-stat-$id')),
      matching: find.byType(Text),
    );

    testWidgets('el menu abre el inventario con su resumen', (tester) async {
      await launch(tester);
      await openInventory(tester);
      expect(find.byKey(const Key('inventory-sample-banner')), findsOneWidget);
      expect(find.byKey(const Key('module-nav')), findsOneWidget);
      expect(tester.widgetList<Text>(stat('all')).map((t) => t.data), [
        '12',
        'Total',
        '100% total',
      ]);
      expect(card('A-008'), findsOneWidget);
    });

    testWidgets('filtrar por estado y quitar los filtros', (tester) async {
      await launch(tester);
      await openInventory(tester);
      await tester.tap(find.byKey(const Key('inventory-condition-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Malo').last);
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      await tester.tap(find.byKey(const Key('inventory-filter-button')));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      expect(card('A-008'), findsOneWidget);
    });

    testWidgets('buscar por tramo o kilometro', (tester) async {
      await launch(tester);
      await openInventory(tester);
      await tester.tap(find.byKey(const Key('inventory-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inventory-search')),
        'SV-114',
      );
      await search(tester);
      expect(card('A-002'), findsOneWidget);
      expect(card('A-008'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('inventory-search')),
        'no existe',
      );
      await search(tester);
      expect(find.byKey(const Key('inventory-state-empty')), findsOneWidget);
      expect(
        find.text('Ningún activo coincide con los filtros.'),
        findsOneWidget,
      );
    });

    testWidgets('sin endpoints la pantalla lo dice', (tester) async {
      await launch(
        tester,
        inventory: const UnavailableInventoryRepository(),
        sample: false,
      );
      await openInventory(tester);
      expect(
        find.byKey(const Key('inventory-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventory-sample-banner')), findsNothing);
    });

    testWidgets('la ficha muestra los datos y abre el activo en el mapa', (
      tester,
    ) async {
      await launch(tester);
      await openInventory(tester);
      // Se busca para que la tarjeta quede arriba, fuera de la barra de abajo.
      await tester.tap(find.byKey(const Key('inventory-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inventory-search')),
        'SV-114',
      );
      await search(tester);
      await tester.tap(card('A-002'));
      await tester.pumpAndSettle();
      expect(
        find.text('Señal vertical SV-114'),
        findsWidgets,
        reason: 'titulo de la ficha',
      );
      expect(find.byKey(const Key('inventory-info')), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-detail-condition')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inventory-action-map')));
      await tester.pumpAndSettle();
      // El mapa se abre en la pestana de inventario con ese activo elegido.
      expect(find.byKey(const Key('map-detail')), findsOneWidget);
      expect(find.text('Señal vertical SV-114'), findsWidgets);
    });
  });
}
