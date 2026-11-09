import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_bounds.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_settings.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/map_tile_source.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

/// El inventario como el servidor: por zona, anotando cada rectangulo.
class _AreaRepo extends FakeMapRepository implements AreaPinsSource {
  _AreaRepo({super.data, required this.assets});

  final List<MapPin> assets;
  final areas = <GeoBounds>[];

  @override
  bool loadsByArea(MapLayer layer) => layer == MapLayer.inventory;

  @override
  Future<AreaPins> pinsIn(
    MapLayer layer,
    GeoBounds area, {
    MapQueryCancel? cancel,
  }) async {
    areas.add(area);
    return AreaPins([
      for (final p in assets)
        if (area.contains(p.position)) p,
    ]);
  }
}

MapPin _pin(String id, double lat, double lon, MapLayer layer) => MapPin(
  id: id,
  layer: layer,
  title: 'Pin $id',
  category: layer == MapLayer.inventory ? 'Defensa' : 'Daño',
  position: GeoPoint(lat, lon),
);

/// El mapa de la app con el inventario por zona (`flutter_map`, como en las
/// demas pruebas de la pantalla): aviso para acercarse, pines al acercar y
/// «Ver en mapa» desde la ficha de un activo.
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

  // Dos tickets a unos 150 km: el mapa se encuadra lejos.
  final tickets = [
    _pin('t-norte', -18.85, -41.98, MapLayer.tickets),
    _pin('t-sur', -19.85, -42.98, MapLayer.tickets),
  ];
  final assets = [
    _pin('act-1', -18.851, -41.981, MapLayer.inventory),
    _pin('act-2', -18.852, -41.982, MapLayer.inventory),
  ];

  late _AreaRepo repo;

  Future<void> launch(WidgetTester tester) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    repo = _AreaRepo(data: {MapLayer.tickets: tickets}, assets: assets);
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(
        menu: const NavigationMenu(
          modules: [
            NavigationItem(code: 'PANEL', name: 'Panel'),
            NavigationItem(code: 'INVENTARIO', name: 'Catálogo'),
          ],
          permissions: [PermissionKeys.inventoryView],
        ),
      ),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      mapRepository: repo,
      roadSegmentsRepository: FakeRoadSegmentsRepository(),
      // Sin ubicacion: el mapa no se va a la persona y queda encuadrado lejos.
      locationSource: FakeLocationSource(failure: LocationFailure.unavailable),
      sampleMap: false,
      mapTileSource: const NoTileSource(),
      mapSettings: const MapSettings(clusterRadiusPx: 0),
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

  /// Deja pasar la espera corta del mapa antes de pedir la zona.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  testWidgets('lejos pide acercarse; al acercar llegan los activos de la zona', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-pin-t-norte')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-tab-inventory')));
    await settle(tester);

    expect(find.byKey(const Key('map-area-zoom')), findsOneWidget);
    expect(find.text('Acerca el mapa para ver los activos.'), findsOneWidget);
    expect(repo.areas, isEmpty);
    expect(repo.requestsFor(MapLayer.inventory), 0);

    // «Acercar» acerca sin mover el centro (entre los dos tickets, sin
    // activos): se pide esa zona y no hay nada.
    final cubit = tester
        .element(find.byKey(const Key('map-nearby-button')))
        .read<MapCubit>();
    final center = cubit.viewportCenter!;
    await tester.tap(find.byKey(const Key('map-notice-action')));
    await settle(tester);
    expect(find.byKey(const Key('map-area-zoom')), findsNothing);
    expect(repo.areas, hasLength(1));
    expect(repo.areas.single.contains(center), isTrue);
    expect(find.text('No hay activos en esta zona.'), findsOneWidget);

    // Desde un ticket del norte, ya cerca, la pestana del inventario se queda
    // donde esta la camara y trae los activos de ahi.
    await tester.tap(find.byKey(const Key('map-tab-tickets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-results-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-result-t-norte')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-detail-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-tab-inventory')));
    await settle(tester);

    expect(find.byKey(const Key('map-pin-act-1')), findsOneWidget);
    expect(find.byKey(const Key('map-pin-act-2')), findsOneWidget);
    expect(find.byKey(const Key('map-area-zoom')), findsNothing);
    expect(repo.areas.last.contains(const GeoPoint(-18.851, -41.981)), isTrue);
    expect(repo.requestsFor(MapLayer.inventory), 0);
  });

  testWidgets('«Ver en mapa» centra el activo y abre su ficha', (
    tester,
  ) async {
    await launch(tester);
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).push(
      Uri(
        path: '/map',
        queryParameters: {
          'layer': 'inventory',
          'pin': 'act-1',
          'lat': '-18.851',
          'lon': '-41.981',
        },
      ).toString(),
    );
    await settle(tester);

    expect(find.byKey(const Key('map-detail')), findsOneWidget);
    expect(find.text('Pin act-1'), findsWidgets);
    expect(find.byKey(const Key('map-pin-act-2')), findsOneWidget);
    expect(find.byKey(const Key('map-area-zoom')), findsNothing);
    // Se pidio la zona alrededor del activo, no el inventario entero.
    expect(repo.areas.last.contains(const GeoPoint(-18.851, -41.981)), isTrue);
    expect(repo.requestsFor(MapLayer.inventory), 0);
  });
}
