import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_detail_cubit.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

/// Un PNG de 1 x 1 para la vista en sitio.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Como responde el servidor: codigo propio, activos sin evaluar y sin fecha de
/// inspeccion, y una foto principal.
class _ServerInventory implements InventoryRepository {
  _ServerInventory({this.photo, this.failPhoto = false});

  final Uint8List? photo;
  final bool failPhoto;
  int photoCalls = 0;

  static const good = InventoryAsset(
    id: 'g-1',
    code: 'DEFENSA-000001',
    name: 'DEFENSA-000001',
    category: 'Defensa metálica',
    condition: AssetCondition.good,
    kmLabel: 'KM 150+200',
    segmentCode: '381BMG0160',
    mainPhotoId: 'f-1',
  );
  static const unknown = InventoryAsset(
    id: 'g-2',
    code: 'SEN-000002',
    name: 'SEN-000002',
    category: 'Señalización vertical',
    condition: AssetCondition.unknown,
  );

  @override
  Future<List<InventoryAsset>> list() async => [unknown, good];

  @override
  Future<InventoryAsset> get(String id) async {
    for (final a in [good, unknown]) {
      if (a.id == id) return a;
    }
    throw const InventoryException(InventoryError.notFound);
  }

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async {
    photoCalls++;
    if (failPhoto) throw StateError('sin foto');
    return photo;
  }
}

void main() {
  group('cubits', () {
    test('lo que no se evaluo va al final y no cuenta como estado', () async {
      final cubit = InventoryCubit(_ServerInventory());
      await cubit.load();

      expect(cubit.state.total, 2);
      expect(cubit.state.visible.map((a) => a.id), ['g-1', 'g-2']);
      for (final c in AssetCondition.assessed) {
        expect(cubit.state.count(c), c == AssetCondition.good ? 1 : 0);
      }
      expect(cubit.state.count(AssetCondition.unknown), 1);
      // Filtrar por "sin evaluar" deja solo esos.
      cubit.setCondition(AssetCondition.unknown);
      expect(cubit.state.visible.map((a) => a.id), ['g-2']);
    });

    test('sin fechas de inspeccion no hay filtro por fecha', () async {
      final cubit = InventoryCubit(_ServerInventory());
      await cubit.load();
      expect(cubit.state.hasInspectionDates, isFalse);
      cubit.setInspectedFrom(DateTime.utc(2026, 10, 1));
      expect(cubit.state.hasInspectionDates, isTrue);
    });

    test('se busca por el codigo del servidor', () async {
      final cubit = InventoryCubit(_ServerInventory());
      await cubit.load();
      cubit.setQuery('sen-0000');
      expect(cubit.state.visible.map((a) => a.id), ['g-2']);
    });

    test('la ficha trae la foto despues de los datos', () async {
      final repo = _ServerInventory(photo: Uint8List.fromList(_png));
      final cubit = InventoryDetailCubit(repo, 'g-1');
      final states = <InventoryDetailState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.load();
      await sub.cancel();

      expect(states.first.asset?.id, 'g-1');
      expect(states.first.photo, isNull);
      expect(cubit.state.photo, isNotNull);
      expect(cubit.state.asset?.id, 'g-1');
    });

    test('sin foto, o si no baja, la ficha se queda igual', () async {
      final none = InventoryDetailCubit(_ServerInventory(), 'g-1');
      await none.load();
      expect(none.state.status, InventoryDetailStatus.ready);
      expect(none.state.photo, isNull);

      final broken = InventoryDetailCubit(
        _ServerInventory(failPhoto: true),
        'g-1',
      );
      await broken.load();
      expect(broken.state.status, InventoryDetailStatus.ready);
      expect(broken.state.photo, isNull);

      // Un activo sin foto principal ni lo intenta.
      final repo = _ServerInventory(photo: Uint8List.fromList(_png));
      final plain = InventoryDetailCubit(repo, 'g-2');
      await plain.load();
      expect(repo.photoCalls, 0);
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

    Future<void> launch(WidgetTester tester, InventoryRepository repo) async {
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
        inventoryRepository: repo,
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
          matching: find.text('Catálogo'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lo sin evaluar se ve y el resumen solo cuenta los estados', (
      tester,
    ) async {
      await launch(tester, _ServerInventory());

      expect(
        find.descendant(
          of: find.byKey(const Key('inventory-condition-g-2')),
          matching: find.text('Sin evaluar'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventory-stat-all')), findsOneWidget);
      expect(find.byKey(const Key('inventory-stat-good')), findsOneWidget);
      expect(find.byKey(const Key('inventory-stat-unknown')), findsNothing);
      // El servidor aun no publica la fecha de inspeccion.
      expect(find.byKey(const Key('inventory-from')), findsNothing);
    });

    testWidgets('la ficha muestra el codigo y la vista en sitio', (
      tester,
    ) async {
      await launch(tester, _ServerInventory(photo: Uint8List.fromList(_png)));

      await tester.tap(find.byKey(const Key('inventory-g-1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('DEFENSA-000001 · Defensa metálica'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('inventory-detail-photo')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('inventory-detail')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const Key('inventory-detail-photo')), findsOneWidget);
      expect(find.text('Vista en sitio'), findsOneWidget);
    });

    testWidgets('la ficha de un activo sin foto no muestra la seccion', (
      tester,
    ) async {
      await launch(tester, _ServerInventory());

      await tester.tap(find.byKey(const Key('inventory-g-2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inventory-detail')), findsOneWidget);
      expect(find.byKey(const Key('inventory-detail-photo')), findsNothing);
      expect(find.text('Vista en sitio'), findsNothing);
    });
  });
}
