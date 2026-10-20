import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/ui/device_navigation.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/sample_accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/domain/entities/accident.dart';
import 'package:sigaco_movil/features/accidents/presentation/bloc/new_accident_cubit.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';
import 'package:sigaco_movil/features/map/data/cache/map_pins_cache.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_settings.dart';
import 'package:sigaco_movil/features/map/domain/entities/user_location.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

/// Registrar desde el mapa (DTF M10, HU-MOB-10-03/04/06/07): abrir la ficha,
/// levantar un ticket con ubicacion, precision y origen, navegar, y el filtro
/// por estado del equipo.
void main() {
  group('ubicacion del ticket', () {
    const gps = TicketLocation(
      latitude: -18.85,
      longitude: -41.98,
      origin: TicketLocationOrigin.gps,
      accuracyMeters: 10,
    );

    test('una lectura buena del GPS no se advierte', () {
      expect(gps.issue(30), isNull);
    });

    test('una lectura peor que el umbral avisa de la precision', () {
      const poor = TicketLocation(
        latitude: 1,
        longitude: 1,
        origin: TicketLocationOrigin.gps,
        accuracyMeters: 45,
      );
      expect(poor.issue(30), TicketLocationIssue.lowAccuracy);
      // Justo en el umbral todavia sirve.
      expect(
        const TicketLocation(
          latitude: 1,
          longitude: 1,
          origin: TicketLocationOrigin.gps,
          accuracyMeters: 30,
        ).issue(30),
        isNull,
      );
    });

    test('la ultima posicion conocida siempre se advierte', () {
      const old = TicketLocation(
        latitude: 1,
        longitude: 1,
        origin: TicketLocationOrigin.lastKnown,
        accuracyMeters: 5,
      );
      expect(old.issue(30), TicketLocationIssue.lastKnown);
    });

    test('un punto elegido o un activo no tienen precision que juzgar', () {
      for (final o in [
        TicketLocationOrigin.mapPoint,
        TicketLocationOrigin.asset,
      ]) {
        expect(
          TicketLocation(latitude: 1, longitude: 1, origin: o).issue(30),
          isNull,
        );
      }
    });
  });

  group('ticket nuevo con ubicacion y clave de cliente', () {
    test('lleva un identificador unico por formulario', () {
      final a = NewTicketCubit(SampleTicketsRepository());
      final b = NewTicketCubit(SampleTicketsRepository());
      expect(a.clientId, isNot(b.clientId));
      expect(a.clientId, hasLength(36));
    });

    test('el identificador no cambia al guardar ni al reintentar', () async {
      final repo = _SpyTickets();
      final cubit = NewTicketCubit(repo, clientIdGenerator: () => 'fijo-1');
      await cubit.load();
      cubit.setTitle('Bache');
      cubit.setCategory(cubit.state.categories.first);
      await cubit.save();
      expect(repo.drafts.single.clientId, 'fijo-1');
      expect(cubit.clientId, 'fijo-1');
    });

    test('el cadenamiento del activo se rellena solo', () {
      final cubit = NewTicketCubit(
        SampleTicketsRepository(),
        location: const TicketLocation(
          latitude: 1,
          longitude: 2,
          origin: TicketLocationOrigin.asset,
          assetId: 'A-004',
          kmLabel: 'KM 150+200',
        ),
      );
      expect(cubit.state.kmLabel, 'KM 150+200');
    });

    test('el borrador manda la ubicacion y la ficha la conserva', () async {
      final repo = _SpyTickets();
      const location = TicketLocation(
        latitude: -18.87,
        longitude: -41.99,
        origin: TicketLocationOrigin.gps,
        accuracyMeters: 12,
        assetId: 'A-004',
        kmLabel: 'KM 150+200',
      );
      final cubit = NewTicketCubit(repo, location: location);
      await cubit.load();
      cubit.setTitle('Drenaje tapado');
      cubit.setCategory(cubit.state.categories.first);
      await cubit.save();
      expect(repo.drafts.single.location, location);

      final created = (await repo.list()).first;
      expect(created.latitude, -18.87);
      expect(created.longitude, -41.99);
      expect(created.kmLabel, 'KM 150+200');
    });

    test('un ticket sin ubicacion sigue como antes', () async {
      final repo = _SpyTickets();
      final cubit = NewTicketCubit(repo);
      await cubit.load();
      cubit.setTitle('Señal caída');
      cubit.setCategory(cubit.state.categories.first);
      await cubit.save();
      expect(repo.drafts.single.location, isNull);
      expect((await repo.list()).first.latitude, isNull);
    });

    test('un accidente nuevo tambien lleva su identificador', () async {
      final repo = SampleAccidentsRepository();
      final cubit = NewAccidentCubit(repo, clientIdGenerator: () => 'acc-1');
      expect(cubit.clientId, 'acc-1');
      expect(NewAccidentCubit(repo).clientId, hasLength(36));
      expect(
        NewAccidentCubit(repo).clientId,
        isNot(NewAccidentCubit(repo).clientId),
      );
      cubit.setTitle('Choque');
      cubit.setType(AccidentType.collision);
      cubit.setSeverity(AccidentSeverity.low);
      await cubit.save();
      expect(cubit.state.saved, isTrue);
    });
  });

  group('estado del equipo en el mapa', () {
    late MapCubit cubit;
    setUp(() async {
      cubit = MapCubit(
        repository: SampleMapRepository(),
        locationSource: FakeLocationSource(),
      );
      await cubit.load();
      await cubit.selectLayer(MapLayer.inventory);
    });
    tearDown(() => cubit.close());

    test('solo los equipos tienen filtro de estado', () async {
      expect(cubit.state.hasOperatingStates, isTrue);
      await cubit.selectLayer(MapLayer.tickets);
      expect(cubit.state.hasOperatingStates, isFalse);
    });

    test('filtra por cada estado operativo', () {
      ids() => cubit.state.visiblePins.map((p) => p.id).toSet();
      cubit.setOperatingFilter(OperatingState.inMaintenance);
      expect(ids(), {'A-004', 'A-008'});
      cubit.setOperatingFilter(OperatingState.outOfService);
      expect(ids(), {'A-005'});
      cubit.setOperatingFilter(OperatingState.inOperation);
      expect(ids(), hasLength(9));
      cubit.setOperatingFilter(null);
      expect(ids(), hasLength(12));
    });

    test('cuenta como filtro activo, se combina y se quita', () {
      cubit.setOperatingFilter(OperatingState.inMaintenance);
      expect(cubit.state.activeFilterCount, 1);
      cubit.toggleCategory('Drenaje');
      expect(cubit.state.activeFilterCount, 2);
      expect(cubit.state.visiblePins.map((p) => p.id), ['A-004']);
      cubit.clearFilters();
      expect(cubit.state.operatingFilter, isNull);
      expect(cubit.state.activeFilterCount, 0);
    });

    test('el estado se guarda con los pines sin conexion', () async {
      final dir = await Directory.systemTemp.createTemp('map_operating');
      addTearDown(() => dir.delete(recursive: true));
      final cache = FileMapPinsCache(root: () async => dir);
      await cache.bind(const OfflineScope(userId: 'ana', concessionId: 'c1'));
      await cache.save(MapLayer.inventory, cubit.state.layerPins);
      final saved = (await cache.read(MapLayer.inventory))!;
      expect(saved, cubit.state.layerPins);
      expect(
        saved.singleWhere((p) => p.id == 'A-005').operatingState,
        OperatingState.outOfService,
      );
    });
  });

  group('punto elegido', () {
    late MapCubit cubit;
    setUp(() async {
      cubit = MapCubit(
        repository: SampleMapRepository(),
        locationSource: FakeLocationSource(),
      );
      await cubit.load();
    });
    tearDown(() => cubit.close());

    test('elegirlo suelta lo seleccionado', () {
      cubit.selectPin('T-1041');
      cubit.pickPoint(const GeoPoint(-18.9, -42.0));
      expect(cubit.state.pickedPoint, const GeoPoint(-18.9, -42.0));
      expect(cubit.state.selectedId, isNull);
    });

    test('elegir un pin o cambiar de pestana lo quita', () async {
      cubit.pickPoint(const GeoPoint(-18.9, -42.0));
      cubit.selectPin('T-1041');
      expect(cubit.state.pickedPoint, isNull);
      cubit.pickPoint(const GeoPoint(-18.9, -42.0));
      await cubit.selectLayer(MapLayer.inventory);
      expect(cubit.state.pickedPoint, isNull);
    });

    test('se puede quitar a mano', () {
      cubit.pickPoint(const GeoPoint(1, 1));
      cubit.clearPickedPoint();
      expect(cubit.state.pickedPoint, isNull);
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

    late SampleTicketsRepository tickets;
    late List<Uri> navigated;
    late Future<bool> Function(Uri) originalOpener;

    setUp(() {
      navigated = [];
      originalOpener = DeviceNavigation.opener;
      DeviceNavigation.opener = (uri) async {
        navigated.add(uri);
        return true;
      };
    });
    tearDown(() => DeviceNavigation.opener = originalOpener);

    UserLocation here({
      double accuracy = 10,
      Duration age = Duration.zero,
      LocationOrigin origin = LocationOrigin.gps,
    }) => UserLocation(
      position: const GeoPoint(-18.872509, -41.992129),
      accuracyMeters: accuracy,
      capturedAt: DateTime.now().toUtc().subtract(age),
      origin: origin,
    );

    Future<void> launch(
      WidgetTester tester, {
      List<String> modules = const ['PANEL', 'INVENTARIO', 'TICKETS'],
      UserLocation? location,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      SharedPreferences.setMockInitialValues({});
      tickets = SampleTicketsRepository();
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(menu: menuWith(modules)),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        mapRepository: SampleMapRepository(),
        roadSegmentsRepository: FakeRoadSegmentsRepository(),
        locationSource: FakeLocationSource(location: location ?? here()),
        sampleMap: true,
        ticketsRepository: tickets,
        sampleTickets: true,
        inventoryRepository: SampleInventoryRepository(),
        zoneSource: FixedZoneSource(),
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
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
    }

    Future<void> openInventoryPin(WidgetTester tester, String id) async {
      await tester.tap(find.byKey(const Key('map-tab-inventory')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('map-pin-$id')));
      await tester.pumpAndSettle();
    }

    Future<void> fillAndSave(WidgetTester tester, String title) async {
      await tester.enterText(find.byKey(const Key('new-ticket-title')), title);
      await tester.tap(find.byKey(const Key('new-ticket-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpieza').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('la ficha del equipo muestra su estado operativo', (
      tester,
    ) async {
      await launch(tester);
      await openInventoryPin(tester, 'A-005');
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('map-detail-operating')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Fuera de servicio',
      );
    });

    testWidgets('el filtro por estado deja solo los equipos que cumplen', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('map-tab-inventory')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('map-filter-operating-inMaintenance')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-filter-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-pin-A-004')), findsOneWidget);
      expect(find.byKey(const Key('map-pin-A-008')), findsOneWidget);
      expect(find.byKey(const Key('map-pin-A-001')), findsNothing);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('el filtro de equipos no aparece en las demas pestañas', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('map-filter-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('map-filter-operating-inMaintenance')),
        findsNothing,
      );
    });

    testWidgets('abrir la ficha del activo lleva a su vista de inventario', (
      tester,
    ) async {
      await launch(tester);
      await openInventoryPin(tester, 'A-012');
      await tester.tap(find.byKey(const Key('map-detail-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-detail')), findsOneWidget);
      expect(find.text('Alcantarilla AL-07'), findsWidgets);
    });

    testWidgets('navegar entrega el punto del elemento al telefono', (
      tester,
    ) async {
      await launch(tester);
      await openInventoryPin(tester, 'A-012');
      await tester.tap(find.byKey(const Key('map-detail-navigate')));
      await tester.pumpAndSettle();
      expect(navigated, hasLength(1));
      expect(navigated.single.scheme, 'geo');
      expect(
        Uri.decodeComponent(navigated.single.toString()),
        contains('AL-07'),
      );
    });

    testWidgets('si no hay app de navegacion lo avisa', (tester) async {
      await launch(tester);
      DeviceNavigation.opener = (uri) async => false;
      await openInventoryPin(tester, 'A-012');
      await tester.tap(find.byKey(const Key('map-detail-navigate')));
      await tester.pump();
      expect(find.byKey(const Key('map-navigate-failed')), findsOneWidget);
    });

    testWidgets('crear un registro desde un activo conserva activo y lugar', (
      tester,
    ) async {
      await launch(tester);
      await openInventoryPin(tester, 'A-012');
      await tester.tap(find.byKey(const Key('map-detail-create')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ticket-location')), findsOneWidget);
      expect(find.text('Ubicación del activo'), findsOneWidget);
      expect(find.text('Activo A-012'), findsOneWidget);
      // El cadenamiento del activo ya viene escrito.
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('new-ticket-km')))
            .initialValue,
        'KM 163+200',
      );

      await fillAndSave(tester, 'Drenaje obstruido');
      expect(find.text('Registro creado.'), findsOneWidget);
      final created = (await tickets.list()).first;
      expect(created.title, 'Drenaje obstruido');
      expect(created.latitude, closeTo(-18.946381, 1e-5));
      expect(created.kmLabel, 'KM 163+200');
    });

    testWidgets('sin el modulo de registros no se ofrece crearlos', (
      tester,
    ) async {
      await launch(tester, modules: const ['PANEL', 'INVENTARIO']);
      await openInventoryPin(tester, 'A-012');
      expect(find.byKey(const Key('map-detail-create')), findsNothing);
      // Navegar y abrir la ficha siguen disponibles.
      expect(find.byKey(const Key('map-detail-navigate')), findsOneWidget);
      expect(find.byKey(const Key('map-detail-open')), findsOneWidget);
      expect(find.byKey(const Key('map-record-here')), findsNothing);
    });

    testWidgets('mantener presionado elige un punto con sus coordenadas', (
      tester,
    ) async {
      await launch(tester);
      await tester.longPressAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-picked')), findsOneWidget);
      expect(find.byKey(const Key('map-picked-marker')), findsOneWidget);
      expect(find.byKey(const Key('map-picked-coords')), findsOneWidget);

      await tester.tap(find.byKey(const Key('map-picked-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-picked')), findsNothing);
    });

    testWidgets('un punto elegido sirve para navegar y para registrar', (
      tester,
    ) async {
      await launch(tester);
      await tester.longPressAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-picked-navigate')));
      await tester.pumpAndSettle();
      expect(navigated, hasLength(1));

      await tester.tap(find.byKey(const Key('map-picked-create')));
      await tester.pumpAndSettle();
      expect(find.text('Punto elegido en el mapa'), findsOneWidget);
      // Un punto elegido no tiene precision que advertir: guarda directo.
      await fillAndSave(tester, 'Daño en el talud');
      expect(find.text('Registro creado.'), findsOneWidget);
      expect(find.byKey(const Key('ticket-location-warning')), findsNothing);
    });

    testWidgets('"Registrar aquí" usa mi ubicacion si ya la tengo', (
      tester,
    ) async {
      await launch(tester);
      expect(find.byKey(const Key('map-record-here')), findsNothing);
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-record-here')));
      await tester.pumpAndSettle();

      expect(find.text('Lectura del GPS'), findsOneWidget);
      expect(find.text('Precisión ±10 m'), findsOneWidget);
      // Buena precision: se guarda sin preguntar.
      await fillAndSave(tester, 'Bache en el carril');
      expect(find.byKey(const Key('ticket-location-warning')), findsNothing);
      expect(find.text('Registro creado.'), findsOneWidget);
      expect((await tickets.list()).first.latitude, closeTo(-18.872509, 1e-5));
    });

    testWidgets('con poca precision avisa y deja elegir', (tester) async {
      await launch(tester, location: here(accuracy: 55));
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-record-here')));
      await tester.pumpAndSettle();
      final before = (await tickets.list()).length;

      await fillAndSave(tester, 'Señal torcida');
      expect(find.byKey(const Key('ticket-location-warning')), findsOneWidget);
      expect(
        find.textContaining('±55 m y el mínimo es de 30 m'),
        findsOneWidget,
      );

      // Cancelar no guarda nada.
      await tester.tap(find.byKey(const Key('ticket-location-cancel')));
      await tester.pumpAndSettle();
      expect((await tickets.list()).length, before);

      // Guardar de todos modos si.
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-location-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Registro creado.'), findsOneWidget);
      expect((await tickets.list()).length, before + 1);
    });

    testWidgets('una lectura vieja se marca como ultima posicion conocida', (
      tester,
    ) async {
      await launch(tester, location: here(age: const Duration(minutes: 10)));
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-record-here')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Última posición conocida'), findsOneWidget);
      await fillAndSave(tester, 'Poste inclinado');
      expect(find.byKey(const Key('ticket-location-warning')), findsOneWidget);
      expect(
        find.textContaining('última posición conocida, no una lectura actual'),
        findsOneWidget,
      );
    });

    testWidgets('con los campos por corregir no pregunta por la ubicacion', (
      tester,
    ) async {
      await launch(tester, location: here(accuracy: 80));
      await tester.tap(find.byKey(const Key('map-locate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-record-here')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-location-warning')), findsNothing);
      expect(find.text('Escribe un título.'), findsOneWidget);
    });
  });
}

/// Anota los borradores que recibe y los guarda en el repositorio de ejemplo.
class _SpyTickets extends SampleTicketsRepository implements TicketsRepository {
  final drafts = <NewTicket>[];

  @override
  Future<Ticket> create(NewTicket draft) {
    drafts.add(draft);
    return super.create(draft);
  }
}
