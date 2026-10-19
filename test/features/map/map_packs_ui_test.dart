import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pack.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_settings.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_pack_manager.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/map_pack_fakes.dart';
import '../../support/surface.dart';

NavigationMenu get _menu => const NavigationMenu(
  modules: [NavigationItem(code: 'INVENTARIO', name: 'Inventario')],
  permissions: [PermissionKeys.inventoryView],
);

/// Mapas sin conexion de punta a punta: la pantalla de paquetes y como el mapa
/// usa el paquete instalado.
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

  final pack = packFor(
    packBytes(52428800),
    name: 'BR-381 Valadares',
    version: 3,
  );

  Future<void> launch(
    WidgetTester tester,
    FakeMapPackManager manager, {
    FakeConnectivity? connectivity,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(menu: _menu),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      mapRepository: SampleMapRepository(),
      locationSource: FakeLocationSource(location: fakeLocation()),
      sampleMap: true,
      mapPacks: manager,
      mapSettings: const MapSettings(clusterRadiusPx: 0),
      connectivity: connectivity ?? FakeConnectivity(),
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
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
  }

  Future<void> openPacks(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('map-packs-button')));
    await tester.pumpAndSettle();
  }

  Finder key(String k) => find.byKey(Key(k));

  /// Algunas acciones (pausar) esperan la cancelacion de un flujo, que termina
  /// fuera del reloj falso de la prueba: se le da un turno real y se repinta.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  group('pantalla de paquetes', () {
    testWidgets('lista el paquete con su version, tamano y zoom', (
      tester,
    ) async {
      await launch(tester, FakeMapPackManager(available: [pack]));
      await openPacks(tester);
      expect(find.text('Mapas sin conexión'), findsWidgets);
      expect(key('pack-br381'), findsOneWidget);
      expect(find.text('BR-381 Valadares'), findsOneWidget);
      expect(find.text('Versión 3'), findsOneWidget);
      expect(find.text('50 MB'), findsOneWidget);
      expect(find.text('Acercamiento 8 a 16'), findsOneWidget);
      expect(key('pack-download-br381'), findsOneWidget);
      expect(key('pack-installed-br381'), findsNothing);
    });

    testWidgets('bajar muestra el avance y al terminar queda guardado', (
      tester,
    ) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.controllers['br381']!.add(
        PackProgress(receivedBytes: 26214400, totalBytes: pack.sizeBytes),
      );
      await tester.pump();
      expect(find.text('Bajando… 50 %'), findsOneWidget);
      expect(key('pack-progress-br381'), findsOneWidget);
      expect(key('pack-pause-br381'), findsOneWidget);

      await manager.finish(pack);
      await tester.pumpAndSettle();
      expect(key('pack-installed-br381'), findsOneWidget);
      expect(key('pack-download-br381'), findsNothing);
      expect(key('pack-delete-br381'), findsOneWidget);
    });

    testWidgets('comprobando el archivo se indica', (tester) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.controllers['br381']!.add(
        PackProgress(
          receivedBytes: pack.sizeBytes,
          totalBytes: pack.sizeBytes,
          verifying: true,
        ),
      );
      await tester.pump();
      expect(find.text('Comprobando el archivo…'), findsOneWidget);
      // No se puede pausar mientras verifica.
      expect(key('pack-pause-br381'), findsNothing);
    });

    testWidgets('pausar y reanudar', (tester) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.partial['br381'] = 10485760;
      await tester.tap(key('pack-pause-br381'));
      await settle(tester);
      expect(find.text('Pausado · 10 MB bajados'), findsOneWidget);
      expect(find.text('Reanudar'), findsOneWidget);
      expect(key('pack-discard-br381'), findsOneWidget);

      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      expect(manager.downloads, ['br381', 'br381']);
      expect(key('pack-pause-br381'), findsOneWidget);
    });

    testWidgets('descartar lo bajado quita el avance', (tester) async {
      final manager = FakeMapPackManager(available: [pack])
        ..partial['br381'] = 10485760;
      await launch(tester, manager);
      await openPacks(tester);
      expect(find.text('Pausado · 10 MB bajados'), findsOneWidget);
      await tester.tap(key('pack-discard-br381'));
      await tester.pumpAndSettle();
      expect(manager.discarded, ['br381']);
      expect(find.textContaining('Pausado'), findsNothing);
      expect(find.text('Descargar'), findsOneWidget);
    });

    testWidgets('un corte de red avisa y deja reanudar', (tester) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.partial['br381'] = 5242880;
      manager.controllers['br381']!.addError(
        const MapPackException(MapPackError.network),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Se cortó la conexión. Puedes reanudar la descarga.'),
        findsOneWidget,
      );
      expect(find.text('Reanudar'), findsOneWidget);
    });

    testWidgets('un archivo que no coincide se descarta y se avisa', (
      tester,
    ) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.controllers['br381']!.addError(
        const MapPackException(MapPackError.corrupt),
      );
      await tester.pumpAndSettle();
      expect(key('pack-error-br381'), findsOneWidget);
      expect(
        find.textContaining('no coincide con el original'),
        findsOneWidget,
      );
      expect(find.text('Descargar'), findsOneWidget);
    });

    testWidgets('sin espacio se avisa', (tester) async {
      final manager = FakeMapPackManager(available: [pack]);
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      manager.controllers['br381']!.addError(
        const MapPackException(MapPackError.noSpace),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No hay espacio suficiente en el teléfono.'),
        findsOneWidget,
      );
    });

    testWidgets('borrar pide confirmar y libera el paquete', (tester) async {
      final manager = FakeMapPackManager(
        available: [pack],
        installed: [installedFor(pack)],
      );
      await launch(tester, manager);
      await openPacks(tester);
      await tester.tap(key('pack-delete-br381'));
      await tester.pumpAndSettle();
      expect(key('packs-delete-dialog'), findsOneWidget);
      expect(find.textContaining('Se liberan 50 MB'), findsOneWidget);

      // Cancelar no borra.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(manager.removed, isEmpty);

      await tester.tap(key('pack-delete-br381'));
      await tester.pumpAndSettle();
      await tester.tap(key('packs-delete-confirm'));
      await tester.pumpAndSettle();
      expect(manager.removed, ['br381']);
      expect(key('pack-installed-br381'), findsNothing);
      expect(find.text('Descargar'), findsOneWidget);
    });

    testWidgets('una version nueva se avisa y se ofrece actualizar', (
      tester,
    ) async {
      final manager = FakeMapPackManager(
        available: [
          packFor(packBytes(2048), name: 'BR-381 Valadares', version: 4),
        ],
        installed: [installedFor(pack)],
      );
      await launch(tester, manager);
      await openPacks(tester);
      expect(key('pack-update-br381'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(key('pack-installed-br381'), findsOneWidget);
    });

    testWidgets('sin conexion muestra solo lo guardado, con aviso', (
      tester,
    ) async {
      final manager = FakeMapPackManager(installed: [installedFor(pack)])
        ..availableFailure = const MapPackException(MapPackError.network);
      await launch(tester, manager);
      await openPacks(tester);
      expect(key('packs-list-offline'), findsOneWidget);
      expect(key('pack-installed-br381'), findsOneWidget);
      expect(key('pack-download-br381'), findsNothing);
    });
  });

  group('estados', () {
    testWidgets('aun no disponible', (tester) async {
      final manager = FakeMapPackManager()
        ..availableFailure = const MapPackException(MapPackError.notAvailable);
      await launch(tester, manager);
      await openPacks(tester);
      expect(key('packs-state-notAvailable'), findsOneWidget);
      expect(
        find.text('Los mapas sin conexión aún no están disponibles'),
        findsOneWidget,
      );
      expect(key('packs-retry'), findsNothing);
    });

    testWidgets('sin permiso', (tester) async {
      final manager = FakeMapPackManager()
        ..availableFailure = const MapPackException(
          MapPackError.permissionDenied,
        );
      await launch(tester, manager);
      await openPacks(tester);
      expect(key('packs-state-permissionDenied'), findsOneWidget);
      expect(key('packs-retry'), findsNothing);
    });

    testWidgets('error de red con reintento', (tester) async {
      final manager = FakeMapPackManager(available: [pack])
        ..availableFailure = const MapPackException(MapPackError.network);
      await launch(tester, manager);
      await openPacks(tester);
      expect(key('packs-state-network'), findsOneWidget);
      manager.availableFailure = null;
      await tester.tap(key('packs-retry'));
      await tester.pumpAndSettle();
      expect(key('pack-br381'), findsOneWidget);
    });

    testWidgets('sin paquetes en el servidor lo dice', (tester) async {
      await launch(tester, FakeMapPackManager());
      await openPacks(tester);
      expect(key('packs-empty'), findsOneWidget);
    });
  });

  group('el mapa usa el paquete', () {
    testWidgets('sin paquete instalado no hay insignia', (tester) async {
      await launch(tester, FakeMapPackManager(available: [pack]));
      expect(key('map-offline-badge'), findsNothing);
    });

    testWidgets('con paquete instalado muestra la insignia con su nombre', (
      tester,
    ) async {
      final manager = FakeMapPackManager(installed: [installedFor(pack)])
        ..reader = FakeTileReader();
      await launch(tester, manager);
      expect(key('map-offline-badge'), findsOneWidget);
      expect(find.text('Mapa sin conexión · BR-381 Valadares'), findsOneWidget);
    });

    testWidgets('sin red solo se ve el paquete y su atribucion', (
      tester,
    ) async {
      final net = FakeConnectivity();
      final manager = FakeMapPackManager(installed: [installedFor(pack)])
        ..reader = FakeTileReader();
      await launch(tester, manager, connectivity: net);
      net.set(false);
      await tester.pumpAndSettle();
      expect(key('map-offline-badge'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('al volver de la pantalla de paquetes, el mapa lo recoge', (
      tester,
    ) async {
      final manager = FakeMapPackManager(available: [pack])
        ..reader = FakeTileReader();
      await launch(tester, manager);
      expect(key('map-offline-badge'), findsNothing);

      await openPacks(tester);
      await tester.tap(key('pack-download-br381'));
      await tester.pump();
      await manager.finish(pack);
      await tester.pumpAndSettle();

      await back(tester);
      expect(key('map-offline-badge'), findsOneWidget);
    });

    testWidgets('borrar el paquete quita la insignia al volver', (
      tester,
    ) async {
      final manager = FakeMapPackManager(
        available: [pack],
        installed: [installedFor(pack)],
      )..reader = FakeTileReader();
      await launch(tester, manager);
      expect(key('map-offline-badge'), findsOneWidget);

      await openPacks(tester);
      await tester.tap(key('pack-delete-br381'));
      await tester.pumpAndSettle();
      await tester.tap(key('packs-delete-confirm'));
      await tester.pumpAndSettle();
      await back(tester);
      expect(key('map-offline-badge'), findsNothing);
    });
  });
}
