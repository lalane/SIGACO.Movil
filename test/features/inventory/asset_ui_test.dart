import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/in_memory_inventory.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_template.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/asset_capture_repository.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

const _token = '8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60';

const _oae = InventoryAsset(
  id: 'a-1',
  code: 'OAE-000094',
  name: 'OAE-000094',
  category: 'Obra de arte especial',
  typeCode: 'OAE',
  condition: AssetCondition.good,
  lifecycle: AssetLifecycle.active,
  inMaintenance: true,
  openTicketCount: 2,
  source: 'WEBGIS',
  externalLayerCode: 'oae2026',
  externalId: '1',
  brand: 'Acme',
  attributes: {'longitud_m': 35.5},
  externalAttributes: {'identific': 'OAE 381 MG 146+900'},
  template: AssetTemplate(
    typeCode: 'OAE',
    number: 3,
    attributes: [
      AttributeDefinition(
        key: 'longitud_m',
        labelEs: 'Longitud',
        type: AttributeType.decimal,
        unit: 'm',
      ),
    ],
  ),
);

const _pending = InventoryAsset(
  id: 'a-2',
  code: 'POSTE-000001',
  name: 'POSTE-000001',
  category: 'Poste',
  condition: AssetCondition.unknown,
  lifecycle: AssetLifecycle.pendingValidation,
);

class _Inventory with InMemoryInventory implements AssetQrSource {
  @override
  Future<List<InventoryAsset>> allAssets() async => const [_oae, _pending];

  @override
  Future<InventoryAsset> get(String id) async =>
      id == _pending.id ? _pending : _oae;

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;

  @override
  Future<InventoryAsset> byQr(String token) async {
    if (token != _token) {
      throw const InventoryException(InventoryError.notFound);
    }
    return _oae;
  }
}

class _Capture implements AssetCaptureRepository {
  NewAsset? created;

  @override
  Future<List<AssetTypeOption>> types() async => const [
    AssetTypeOption(code: 'POSTE', labelEs: 'Poste', geometryType: 'POINT'),
  ];

  @override
  Future<AssetTemplate> template(String typeCode) async => const AssetTemplate(
    typeCode: 'POSTE',
    number: 1,
    attributes: [
      AttributeDefinition(
        key: 'altura_m',
        labelEs: 'Altura',
        type: AttributeType.decimal,
        unit: 'm',
        required: true,
        min: 0,
        max: 12,
      ),
      AttributeDefinition(
        key: 'iluminado',
        labelEs: 'Iluminado',
        type: AttributeType.boolean,
      ),
      AttributeDefinition(
        key: 'material',
        labelEs: 'Material',
        type: AttributeType.catalog,
        catalogCode: 'MATERIAL',
      ),
    ],
  );

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async => const {
    'MATERIAL': [CatalogOption(code: 'ACERO', labelEs: 'Acero')],
  };

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) async =>
      const RoadPlacement(
        status: RoadPlacementStatus.onRoad,
        roadId: 'road-9',
        roadCode: 'BR-381',
        direction: 'CRECIENTE',
        km: 150.2,
        segmentCode: '381BMG0160',
        distanceMeters: 12,
      );

  @override
  Future<CapturedAsset> create(NewAsset draft) async {
    created = draft;
    return const CapturedAsset(id: 'a-3', code: 'POSTE-000002');
  }
}

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

  late _Capture capture;

  Future<void> launch(WidgetTester tester, {bool canCreate = true}) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    capture = _Capture();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(
        menu: menuWith(
          ['PANEL', 'INVENTARIO'],
          permissions: [
            PermissionKeys.inventoryView,
            if (canCreate) PermissionKeys.inventoryCreate.first,
          ],
        ),
      ),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      inventoryRepository: _Inventory(),
      assetCaptureRepository: capture,
      locationSource: FakeLocationSource(
        location: UserLocation(
          position: const GeoPoint(-18.85, -41.98),
          accuracyMeters: 5,
          capturedAt: DateTime.utc(2026, 11, 8, 12),
        ),
      ),
      zoneSource: FixedZoneSource(),
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

  Future<void> scrollTo(WidgetTester tester, Finder target, Key list) =>
      tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.descendant(
          of: find.byKey(list),
          matching: find.byType(Scrollable),
        ),
      );

  testWidgets('la lista marca lo pendiente y lo que esta en mantenimiento', (
    tester,
  ) async {
    await launch(tester);
    expect(find.byKey(const Key('inventory-a-2-status')), findsOneWidget);
    expect(find.text('Pendiente de validación'), findsOneWidget);
    expect(find.byKey(const Key('inventory-a-1-maintenance')), findsOneWidget);
    // Lo activo no se marca en la lista.
    expect(find.byKey(const Key('inventory-a-1-status')), findsNothing);
  });

  testWidgets('sin permiso de alta no se ofrece el boton', (tester) async {
    await launch(tester, canCreate: false);
    expect(find.byKey(const Key('inventory-new')), findsNothing);
  });

  testWidgets('el alta arma el formulario con la ficha y lo guarda', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const Key('inventory-new')));
    await tester.pumpAndSettle();

    // El GPS ya ubico el punto sobre la carretera.
    expect(find.textContaining('BR-381 · KM 150+200'), findsOneWidget);
    expect(find.byKey(const Key('asset-field-altura_m')), findsNothing);

    await tester.tap(find.byKey(const Key('asset-new-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poste').last);
    await tester.pumpAndSettle();

    // Los campos salen de la ficha: decimal con unidad, si/no y catalogo.
    expect(find.byKey(const Key('asset-field-altura_m')), findsOneWidget);
    expect(find.text('Altura (m) *'), findsOneWidget);
    expect(find.byKey(const Key('asset-field-iluminado')), findsOneWidget);
    expect(find.byKey(const Key('asset-field-material')), findsOneWidget);

    // Sin el obligatorio no se guarda.
    await tester.tap(find.byKey(const Key('asset-new-submit')));
    await tester.pumpAndSettle();
    expect(capture.created, isNull);
    expect(find.text('Es obligatorio.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('asset-field-altura_m')),
      '7,5',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('asset-new-submit')));
    await tester.pumpAndSettle();

    final draft = capture.created!;
    expect(draft.typeCode, 'POSTE');
    expect(draft.roadId, 'road-9');
    expect(draft.direction, 'CRECIENTE');
    expect(draft.attributes, {'altura_m': 7.5});
    expect(find.byKey(const Key('asset-new-saved')), findsOneWidget);
    expect(find.textContaining('POSTE-000002'), findsOneWidget);
    // De vuelta en la lista.
    expect(find.byKey(const Key('inventory-new')), findsOneWidget);
  });

  testWidgets('la ficha muestra la plantilla, el WebGIS y la gestion', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const Key('inventory-a-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-detail-status')), findsOneWidget);
    expect(
      find.byKey(const Key('inventory-detail-maintenance')),
      findsOneWidget,
    );
    expect(find.text('En mantenimiento'), findsOneWidget);

    await scrollTo(
      tester,
      find.byKey(const Key('inventory-template')),
      const Key('inventory-detail'),
    );
    expect(find.text('Longitud'), findsOneWidget);
    expect(find.text('35.5 m'), findsOneWidget);

    await scrollTo(
      tester,
      find.byKey(const Key('inventory-webgis')),
      const Key('inventory-detail'),
    );
    expect(find.text('Datos del WebGIS'), findsOneWidget);
    expect(find.text('OAE 381 MG 146+900'), findsOneWidget);
    expect(find.text('Capa oae2026 · elemento 1'), findsOneWidget);

    await scrollTo(
      tester,
      find.byKey(const Key('inventory-management')),
      const Key('inventory-detail'),
    );
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('WebGIS'), findsOneWidget);
  });

  testWidgets('el QR (escrito a mano) abre la ficha del activo', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const Key('inventory-scan-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('asset-qr-camera')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('asset-qr-manual')), 'nada');
    await tester.tap(find.byKey(const Key('asset-qr-go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('asset-qr-status-invalid')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('asset-qr-manual')),
      'https://sigaco.app/qr/$_token',
    );
    await tester.tap(find.byKey(const Key('asset-qr-go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inventory-detail')), findsOneWidget);
    expect(find.textContaining('OAE-000094'), findsWidgets);
  });
}
