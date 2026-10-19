// ignore_for_file: invalid_use_of_visible_for_testing_member
// Capturas (1080x2400) del mapa, los tickets, los accidentes y el
// mantenimiento, para compararlos con el mockup nuevo, sin dispositivo y con
// datos de ejemplo.
// Uso: fvm flutter test tool/capture_mockup_test.dart
// Variables: CAPTURE_DIR (salida, por defecto ./capturas) y MATERIAL_ICONS_FONT.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/sample_accidents_repository.dart';
import 'package:sigaco_movil/features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';

import '../test/support/fakes.dart';
import '../test/support/fonts.dart';
import '../test/support/map_fakes.dart';

const _menu = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
    NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
    NavigationItem(code: 'TICKETS', name: 'Tickets'),
    NavigationItem(
      code: 'ANTT',
      name: 'ANTT',
      submodules: [NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes')],
    ),
  ],
  permissions: [PermissionKeys.inventoryView],
);

void main() {
  final outDir = Platform.environment['CAPTURE_DIR'] ?? 'capturas';
  final iconsFont = Platform.environment['MATERIAL_ICONS_FONT'];
  GlobalKey? boundary;

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final render =
          boundary!.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  /// Abre la app con datos de ejemplo y entra con una cuenta de prueba.
  Future<void> boot(WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final onSite = SampleMapRepository.at(150.2, dLat: 0.0004, dLon: -0.0002);
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false)
        ..declineBiometricOffer(),
      navigationRepository: FakeNavigationRepository(menu: _menu),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      mapRepository: SampleMapRepository(),
      locationSource: FakeLocationSource(
        location: fakeLocation(
          position: GeoPoint(onSite.latitude, onSite.longitude),
        ),
      ),
      sampleMap: true,
      ticketsRepository: SampleTicketsRepository(),
      sampleTickets: true,
      accidentsRepository: SampleAccidentsRepository(),
      sampleAccidents: true,
      maintenanceRepository: SampleMaintenanceRepository(),
      sampleMaintenance: true,
      fileSource: FakeFileSource(
        photo: const SelectedFile(
          name: 'f.jpg',
          path: '/x/f.jpg',
          sizeBytes: 1,
        ),
      ),
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
    );
    boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: SigacoApp(dependencies: deps),
      ),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(SigacoApp));
      for (final a in ['pattern', 'tekia_white', 'tekia_dark']) {
        await precacheImage(AssetImage('assets/branding/$a.png'), ctx);
      }
    });
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> openCard(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(GridView), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() => Directory(outDir).createSync(recursive: true));

  testWidgets('capturas del mapa y los tickets', (tester) async {
    await boot(tester);
    await shoot(tester, 'h0_menu.png');

    // Mapa
    await openCard(tester, 'Mapa');
    await shoot(tester, 'm1_mapa.png');
    await tester.tap(find.byKey(const Key('map-results-toggle')));
    await tester.pumpAndSettle();
    await shoot(tester, 'm2_mapa_lista.png');
    await tester.tap(find.byKey(const Key('map-results-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-pin-T-1041')));
    await tester.pumpAndSettle();
    await shoot(tester, 'm3_mapa_ficha.png');

    // Tickets desde la barra inferior
    await tester.tap(find.byKey(const Key('nav-tab-tickets')));
    await tester.pumpAndSettle();
    await shoot(tester, 't1_historial.png');
    await tester.enterText(find.byKey(const Key('tickets-search')), '0035');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-T-0035')));
    await tester.pumpAndSettle();
    await shoot(tester, 't3_ficha.png');
    await tester.tap(find.byKey(const Key('ticket-action-follow-up')));
    await tester.pumpAndSettle();
    await shoot(tester, 't4_seguimiento.png');
  });

  testWidgets('capturas de accidentes y mantenimiento', (tester) async {
    await boot(tester);

    // Accidentes
    await openCard(tester, 'Accidentes');
    await shoot(tester, 'a1_accidentes.png');
    await tester.tap(find.byKey(const Key('accidents-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('accidents-search')), '0035');
    await tester.pumpAndSettle();
    await shoot(tester, 'a2_accidentes_busqueda.png');
    await tester.tap(find.byKey(const Key('accident-A-0035')));
    await tester.pumpAndSettle();
    await shoot(tester, 'a3_accidente_ficha.png');
    await tester.tap(find.byKey(const Key('accident-detail-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accidents-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accident-form-submit')));
    await tester.pumpAndSettle();
    await shoot(tester, 'a4_accidente_nuevo.png');
    await tester.tap(find.byKey(const Key('module-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-back')));
    await tester.pumpAndSettle();

    // Mantenimiento
    await openCard(tester, 'Mantenimientos');
    await shoot(tester, 'k1_indicadores.png');
    await tester.tap(find.byKey(const Key('indicator-sgs')));
    await tester.pumpAndSettle();
    await shoot(tester, 'k2_mantenimiento.png');
    await tester.dragUntilVisible(
      find.byKey(const Key('maintenance-M-210')),
      find.byKey(const Key('maintenance-list')),
      const Offset(0, -300),
    );
    await tester.tap(find.byKey(const Key('maintenance-M-210')));
    await tester.pumpAndSettle();
    await shoot(tester, 'k3_mantenimiento_ficha.png');
  });
}
