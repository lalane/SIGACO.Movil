import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_settings.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/repositories/road_segments_repository.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/map_tile_source.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

NavigationMenu _menu({bool module = true, bool permission = true}) =>
    NavigationMenu(
      modules: [
        const NavigationItem(code: 'PANEL', name: 'Panel'),
        if (module)
          const NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
      ],
      permissions: [if (permission) PermissionKeys.inventoryView],
    );

/// El mapa de punta a punta con pines de ejemplo: la tarjeta del menu, las
/// cuatro pestanas, los filtros, la ficha, ubicarme y los activos cercanos.
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

  // El tramo de ejemplo: el usuario esta junto al activo A-004 (km 150.2).
  final onSite = () {
    final road = SampleRoadSegmentsRepository.pointAt(
      150.2,
      TravelDirection.increasing,
    );
    return GeoPoint(road.latitude + 0.0004, road.longitude - 0.0002);
  }();

  Future<FakeLocationSource> launch(
    WidgetTester tester, {
    NavigationMenu? menu,
    MapRepository? repo,
    RoadSegmentsRepository? segments,
    FakeLocationSource? location,
    bool sample = true,
    MapTileSource tiles = const NoTileSource(),
    MapSettings settings = const MapSettings(clusterRadiusPx: 0),
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final source =
        location ??
        FakeLocationSource(location: fakeLocation(position: onSite));
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(menu: menu ?? _menu()),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      mapRepository: repo ?? SampleMapRepository(),
      roadSegmentsRepository: segments ?? FakeRoadSegmentsRepository(),
      locationSource: source,
      sampleMap: sample,
      mapTileSource: tiles,
      mapSettings: settings,
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
    return source;
  }

  Future<void> openMap(WidgetTester tester) async {
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
  }

  BuildContext context(WidgetTester tester) =>
      tester.element(find.byKey(const Key('map-nearby-button')));

  Finder pin(String id) => find.byKey(Key('map-pin-$id'));
  Finder tab(String name) => find.byKey(Key('map-tab-$name'));

  Future<void> pickTab(WidgetTester tester, String name) async {
    await tester.tap(tab(name));
    await tester.pumpAndSettle();
  }

  group('tarjeta del menu', () {
    testWidgets('aparece con el modulo de inventario y su permiso', (
      tester,
    ) async {
      await launch(tester);
      expect(find.text('Mapa'), findsOneWidget);
    });

    testWidgets('no aparece sin el permiso de ver inventario', (tester) async {
      await launch(tester, menu: _menu(permission: false));
      expect(find.text('Mapa'), findsNothing);
    });

    testWidgets('no aparece si el menu no trae inventario', (tester) async {
      await launch(tester, menu: _menu(module: false));
      expect(find.text('Mapa'), findsNothing);
    });
  });

  group('tramos', () {
    final segments = [
      fakeSegment('TR01-up'),
      fakeSegment(
        'TR01-down',
        direction: TravelDirection.decreasing,
        points: const [
          GeoPoint(-18.8505, -41.9805),
          GeoPoint(-18.8605, -41.9905),
          GeoPoint(-18.8705, -41.9905),
        ],
      ),
    ];

    Finder lines() => find.byType(PolylineLayer<String>);

    testWidgets('sin tramos publicados el mapa se ve solo con pines', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      expect(lines(), findsNothing);
      expect(pin('T-1041'), findsOneWidget);
    });

    testWidgets('dibuja los tramos debajo de los pines', (tester) async {
      await launch(
        tester,
        segments: FakeRoadSegmentsRepository(data: segments),
      );
      await openMap(tester);
      expect(lines(), findsOneWidget);
      expect(pin('T-1041'), findsOneWidget);
    });

    testWidgets('elegir un tramo abre su ficha y cerrarla la quita', (
      tester,
    ) async {
      await launch(
        tester,
        segments: FakeRoadSegmentsRepository(data: segments),
      );
      await openMap(tester);
      context(tester).read<MapCubit>().selectSegment('TR01-down');
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('map-segment-detail'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Tramo TR01')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Sentido decreciente')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('KM 10+000 a KM 12+000')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('map-segment-close')));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
    });

    testWidgets('tocar la linea elige el tramo y tocar el mapa lo suelta', (
      tester,
    ) async {
      // Sin pines el mapa se encuadra en la carretera: la linea queda a la vista.
      await launch(
        tester,
        repo: FakeMapRepository(),
        segments: FakeRoadSegmentsRepository(data: [segments.first]),
      );
      await openMap(tester);
      // Un punto sobre la linea, en pantalla.
      final camera = MapCamera.of(tester.element(lines()));
      final origin = tester.getTopLeft(find.byType(FlutterMap));
      const on = GeoPoint(-18.855, -41.985);
      final spot =
          origin +
          camera.latLngToScreenOffset(LatLng(on.latitude, on.longitude));
      await tester.tapAt(spot);
      // El mapa espera un momento por si el toque es el primero de un doble
      // toque (acercar) antes de avisar.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-segment-detail')), findsOneWidget);
      // Tocar un lugar vacio lo suelta.
      await tester.tapAt(origin + const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-segment-detail')), findsNothing);
    });

    testWidgets('la ficha de un pin dice a que tramo pertenece', (
      tester,
    ) async {
      await launch(tester, segments: SampleRoadSegmentsRepository());
      await openMap(tester);
      await tester.tap(pin('T-1041'));
      await tester.pumpAndSettle();
      final chip = find.byKey(const Key('map-detail-segment'));
      expect(chip, findsOneWidget);
      expect(
        find.descendant(
          of: chip,
          matching: find.text('Tramo 381BMG0160 · Sentido creciente'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('al elegir un pin se resalta la linea de su tramo', (
      tester,
    ) async {
      await launch(tester, segments: SampleRoadSegmentsRepository());
      await openMap(tester);
      double width(String id) => tester
          .widget<PolylineLayer<String>>(lines())
          .polylines
          .singleWhere((l) => l.hitValue == id)
          .strokeWidth;
      expect(width('381BMG0160-increasing'), 5);

      // T-1041 esta en el km 147+200, sentido creciente: tramo 381BMG0160.
      await tester.tap(pin('T-1041'));
      await tester.pumpAndSettle();

      expect(width('381BMG0160-increasing'), greaterThan(5));
      // Ni el otro sentido ni el otro tramo se resaltan.
      expect(width('381BMG0160-decreasing'), 5);
      expect(width('381BMG0170-increasing'), 5);
    });

    testWidgets('la ficha del tramo cuenta los elementos que contiene', (
      tester,
    ) async {
      await launch(tester, segments: SampleRoadSegmentsRepository());
      await openMap(tester);
      context(tester).read<MapCubit>().selectSegment('381BMG0160-increasing');
      await tester.pumpAndSettle();
      // De los tickets abiertos, T-1041 (km 147+200) y T-1043 (km 151+000)
      // estan en ese tramo y sentido; T-1042 esta en el otro tramo.
      final count = find.byKey(const Key('map-segment-count'));
      expect(count, findsOneWidget);
      expect(
        find.descendant(of: count, matching: find.textContaining('2 en este')),
        findsOneWidget,
      );
    });

    testWidgets('elegir un pin cierra la ficha del tramo', (tester) async {
      await launch(
        tester,
        segments: FakeRoadSegmentsRepository(data: segments),
      );
      await openMap(tester);
      context(tester).read<MapCubit>().selectSegment('TR01-up');
      await tester.pumpAndSettle();
      await tester.tap(pin('T-1041'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-segment-detail')), findsNothing);
      expect(find.byKey(const Key('map-detail')), findsOneWidget);
    });
  });

  group('pestanas y pines', () {
    testWidgets('abre en Tickets con sus pines y el aviso de ejemplo', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      expect(find.byKey(const Key('map-sample-banner')), findsOneWidget);
      expect(pin('T-1041'), findsOneWidget);
      expect(pin('T-1042'), findsOneWidget);
      expect(pin('A-001'), findsNothing);
      // Sin proveedor de teselas se avisa que no hay mapa base.
      expect(find.byKey(const Key('map-no-tiles')), findsOneWidget);
    });

    testWidgets('el mapa no muestra tickets cerrados', (tester) async {
      await launch(tester);
      await openMap(tester);
      expect(pin('T-1043'), findsOneWidget);
      expect(pin('T-1044'), findsNothing);
    });

    testWidgets('sin conexion avisa que los pines son del telefono', (
      tester,
    ) async {
      final saved = PinListing([
        fakePin('t1', layer: MapLayer.tickets, status: PinStatus.critical),
      ], cachedAt: DateTime.utc(2026, 10, 16, 15, 30));
      await launch(
        tester,
        sample: false,
        repo: FakeMapRepository(data: {MapLayer.tickets: saved}),
      );
      await openMap(tester);
      expect(find.byKey(const Key('map-saved-banner')), findsOneWidget);
      expect(find.textContaining('guardados en el teléfono'), findsOneWidget);
      expect(pin('t1'), findsOneWidget);
    });

    testWidgets('con conexion no hay aviso de guardado', (tester) async {
      await launch(tester);
      await openMap(tester);
      expect(find.byKey(const Key('map-saved-banner')), findsNothing);
    });

    testWidgets('cambiar de pestana cambia los pines', (tester) async {
      await launch(tester);
      await openMap(tester);
      await pickTab(tester, 'inventory');
      expect(pin('A-001'), findsOneWidget);
      expect(pin('T-1041'), findsNothing);
      await pickTab(tester, 'maintenance');
      expect(pin('M-210'), findsOneWidget);
      await pickTab(tester, 'works');
      expect(pin('O-031'), findsOneWidget);
    });

    testWidgets('tocar un pin abre su ficha con referencia y estado', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(pin('T-1041'));
      await tester.pumpAndSettle();
      final detail = find.byKey(const Key('map-detail'));
      expect(detail, findsOneWidget);
      expect(
        find.descendant(of: detail, matching: find.text('Defensa dañada')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.text('Crítico')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.textContaining('KM 147+200'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la ficha se cierra con la X', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(pin('T-1041'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-detail-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-detail')), findsNothing);
    });
  });

  group('filtros', () {
    testWidgets('filtrar por categoria deja solo esos pines', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-filter-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-filters-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('map-filter-category-Daño')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-done')));
      await tester.pumpAndSettle();
      expect(pin('T-1041'), findsOneWidget);
      expect(pin('T-1042'), findsNothing);
      // El boton de filtros cuenta los activos en su insignia.
      expect(
        find.descendant(
          of: find.byKey(const Key('map-filter-button')),
          matching: find.byType(Badge),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Filtros (1)'), findsOneWidget);
    });

    testWidgets('filtrar por estado y quitar los filtros', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-status-critical')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-done')));
      await tester.pumpAndSettle();
      expect(pin('T-1042'), findsOneWidget);
      expect(find.byTooltip('Filtros'), findsOneWidget);
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('sin coincidencias se avisa', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-category-Daño')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-status-attention')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-empty')), findsOneWidget);
      expect(
        find.text('Ningún elemento coincide con los filtros.'),
        findsOneWidget,
      );
    });
  });

  group('ubicarme y cercanos', () {
    testWidgets('ubicarme muestra tu posicion y la precision', (tester) async {
      final source = await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(source.calls, 1);
      expect(find.byKey(const Key('map-user-marker')), findsOneWidget);
      expect(find.byKey(const Key('map-accuracy-ok')), findsOneWidget);
      expect(find.text('Precisión ±10 m'), findsOneWidget);
    });

    testWidgets('una precision peor que 30 m se marca como baja', (
      tester,
    ) async {
      final low = FakeLocationSource(
        location: fakeLocation(position: onSite, accuracy: 80),
      );
      await launch(tester, location: low);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-accuracy-low')), findsOneWidget);
    });

    testWidgets('una ubicacion simulada se rechaza para guardar datos', (
      tester,
    ) async {
      final fake = FakeLocationSource(
        location: fakeLocation(position: onSite, origin: LocationOrigin.mocked),
      );
      await launch(tester, location: fake);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-accuracy-low')), findsOneWidget);
    });

    testWidgets('los cercanos salen ordenados con su distancia', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-nearby-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-nearby-sheet')), findsOneWidget);
      // A-004 y A-005 estan a pocos metros; A-001 (km 147) queda fuera de 1 km.
      expect(find.byKey(const Key('map-nearby-A-004')), findsOneWidget);
      expect(find.byKey(const Key('map-nearby-A-005')), findsOneWidget);
      expect(find.byKey(const Key('map-nearby-A-001')), findsNothing);
      final first = tester
          .getTopLeft(find.byKey(const Key('map-nearby-A-004')))
          .dy;
      final second = tester
          .getTopLeft(find.byKey(const Key('map-nearby-A-005')))
          .dy;
      expect(first, lessThan(second));
    });

    testWidgets('ampliar el radio suma activos', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-nearby-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-radius-5000')));
      await tester.pumpAndSettle();
      // El mas lejano queda al final de la lista: hay que bajar hasta el.
      await tester.scrollUntilVisible(
        find.byKey(const Key('map-nearby-A-001')),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('map-nearby-sheet')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const Key('map-nearby-A-001')), findsOneWidget);
    });

    testWidgets('un radio corto deja solo los activos mas cercanos', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-nearby-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-radius-250')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-nearby-A-004')), findsOneWidget);
      expect(find.byKey(const Key('map-nearby-A-005')), findsOneWidget);
    });

    testWidgets('sin ubicacion pide tocar Ubicarme', (tester) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-nearby-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-nearby-message')), findsOneWidget);
      expect(find.textContaining('Ubicarme'), findsWidgets);
    });

    testWidgets('elegir un cercano abre Inventario con su ficha y distancia', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-nearby-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-nearby-A-004')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-detail')), findsOneWidget);
      expect(find.byKey(const Key('map-detail-distance')), findsOneWidget);
      expect(pin('A-004'), findsOneWidget);
    });

    testWidgets('con el GPS apagado avisa y ofrece abrir ajustes', (
      tester,
    ) async {
      final off = FakeLocationSource(failure: LocationFailure.serviceDisabled);
      await launch(tester, location: off);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(
        find.text('El GPS está apagado. Enciéndelo para ubicarte.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Abrir ajustes'));
      await tester.pumpAndSettle();
      expect(off.openedSettings, [LocationFailure.serviceDisabled]);
      expect(find.byKey(const Key('map-user-marker')), findsNothing);
    });

    testWidgets('con el permiso denegado explica sin ofrecer ajustes', (
      tester,
    ) async {
      final denied = FakeLocationSource(
        failure: LocationFailure.permissionDenied,
      );
      await launch(tester, location: denied);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(find.textContaining('permiso de ubicación'), findsOneWidget);
      expect(find.text('Abrir ajustes'), findsNothing);
    });

    testWidgets('con el permiso bloqueado ofrece abrir ajustes', (
      tester,
    ) async {
      final blocked = FakeLocationSource(
        failure: LocationFailure.permissionDeniedForever,
      );
      await launch(tester, location: blocked);
      await openMap(tester);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      expect(find.text('Abrir ajustes'), findsOneWidget);
    });
  });

  group('estados', () {
    testWidgets('sin endpoints del servidor dice que no esta disponible', (
      tester,
    ) async {
      await launch(
        tester,
        repo: FakeMapRepository(failure: MapError.notAvailable),
        sample: false,
      );
      await openMap(tester);
      expect(find.byKey(const Key('map-state-notAvailable')), findsOneWidget);
      expect(find.byKey(const Key('map-sample-banner')), findsNothing);
    });

    testWidgets('un error de red ofrece reintentar y se recupera', (
      tester,
    ) async {
      final repo = FakeMapRepository(
        data: {
          MapLayer.tickets: [
            fakePin(
              't9',
              layer: MapLayer.tickets,
              position: const GeoPoint(-18.85, -41.98),
            ),
          ],
        },
        failure: MapError.network,
      );
      await launch(tester, repo: repo);
      await openMap(tester);
      expect(find.byKey(const Key('map-state-network')), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.byKey(const Key('map-retry')));
      await tester.pumpAndSettle();
      expect(pin('t9'), findsOneWidget);
    });

    testWidgets('sin permiso en una pestana no ofrece reintentar', (
      tester,
    ) async {
      final repo = FakeMapRepository(
        data: {
          MapLayer.tickets: [fakePin('t9', layer: MapLayer.tickets)],
        },
      )..failureByLayer[MapLayer.works] = MapError.permissionDenied;
      await launch(tester, repo: repo);
      await openMap(tester);
      await pickTab(tester, 'works');
      expect(
        find.byKey(const Key('map-state-permissionDenied')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('map-retry')), findsNothing);
      // Las demas pestanas siguen funcionando.
      await pickTab(tester, 'tickets');
      expect(pin('t9'), findsOneWidget);
    });

    testWidgets('una pestana sin elementos lo avisa', (tester) async {
      await launch(tester, repo: FakeMapRepository(data: {}));
      await openMap(tester);
      expect(find.byKey(const Key('map-empty')), findsOneWidget);
    });
  });

  testWidgets('con proveedor de teselas muestra su atribucion', (tester) async {
    await launch(tester, tiles: const _FakeTiles());
    await openMap(tester);
    expect(find.byKey(const Key('map-attribution')), findsOneWidget);
    expect(find.text('© Proveedor de prueba'), findsOneWidget);
    expect(find.byKey(const Key('map-no-tiles')), findsNothing);
  });

  group('agrupacion de pines', () {
    int pinCount(WidgetTester tester) => find
        .byWidgetPredicate(
          (w) => w.key is Key && w.key.toString().contains("[<'map-pin-"),
        )
        .evaluate()
        .length;
    Finder clusters() => find.byWidgetPredicate(
      (w) => w.key.toString().contains("[<'map-cluster-"),
    );

    testWidgets('con muchos pines juntos aparecen grupos con su cuenta', (
      tester,
    ) async {
      await launch(tester, settings: const MapSettings());
      await openMap(tester);
      await pickTab(tester, 'inventory');
      expect(clusters(), findsWidgets);
      // Hay 8 activos: agrupados, se ven menos pines sueltos.
      expect(pinCount(tester), lessThan(8));
    });

    testWidgets('tocar un grupo acerca el mapa y lo deshace', (tester) async {
      await launch(tester, settings: const MapSettings());
      await openMap(tester);
      await pickTab(tester, 'inventory');
      final before = clusters().evaluate().length;
      await tester.tap(clusters().first);
      await tester.pumpAndSettle();
      // Tras acercar, hay mas pines sueltos o menos grupos.
      expect(
        pinCount(tester) > 0 || clusters().evaluate().length < before,
        isTrue,
      );
    });

    testWidgets('con la agrupacion apagada se ven todos los pines', (
      tester,
    ) async {
      await launch(tester);
      await openMap(tester);
      await pickTab(tester, 'inventory');
      expect(clusters(), findsNothing);
      expect(pinCount(tester), 12);
    });
  });

  testWidgets('el mapa se ve bien en un telefono pequeno y con texto grande', (
    tester,
  ) async {
    await tester.runAsync(loadAppFonts);
    await launch(tester);
    useSurface(tester, TestSurface.smallPhone, textScale: 1.5);
    await tester.pumpAndSettle();
    await openMap(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('map-locate')), findsOneWidget);
  });
}

/// Un proveedor de teselas que no sale a la red.
class _FakeTiles extends MapTileSource {
  const _FakeTiles();

  @override
  Widget? buildLayer() => const SizedBox.shrink();

  @override
  String? get attribution => '© Proveedor de prueba';

  @override
  String? get attributionUrl => null;

  @override
  double get maxZoom => 18;
}
