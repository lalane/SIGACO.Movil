import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/api_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/in_memory_inventory.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/sample_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_detail_cubit.dart';
import 'package:sigaco_movil/features/inventory/presentation/inventory_labels.dart';
import 'package:sigaco_movil/core/theme/status_colors.dart';
import 'package:sigaco_movil/l10n/app_localizations_es.dart';
import 'package:sigaco_movil/l10n/app_localizations_pt.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';

import '../../support/fake_api.dart';
import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

/// Un activo con tickets (uno abierto), sin inspecciones y sin permiso de ver
/// mantenimientos, como lo da la ficha del servidor.
const _asset = InventoryAsset(
  id: 'a-1',
  code: 'DEFENSA-000001',
  name: 'DEFENSA-000001',
  category: 'Defensa metálica',
  subsystemCode: 'SGS',
  condition: AssetCondition.good,
  lifecycle: AssetLifecycle.active,
  inMaintenance: true,
  openTicketCount: 1,
  kmLabel: 'KM 150+200',
  history: AssetHistoryCounts(
    tickets: AssetHistoryCount(open: 1, total: 6),
    inspections: AssetHistoryCount(open: 0, total: 0),
  ),
);

/// El inventario de prueba con la historia del activo.
class _Inventory with InMemoryInventory implements AssetHistorySource {
  _Inventory({this.failing = const {}});

  /// Los tipos cuya lista no baja.
  final Set<AssetHistoryKind> failing;
  final asked = <AssetHistoryKind>[];

  @override
  Future<List<InventoryAsset>> allAssets() async => const [_asset];

  @override
  Future<InventoryAsset> get(String id) async => _asset;

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;

  @override
  Future<AssetHistoryPage> history(
    String assetId,
    AssetHistoryKind kind, {
    int limit = 5,
  }) async {
    asked.add(kind);
    if (failing.contains(kind)) {
      throw const InventoryException(InventoryError.network);
    }
    return AssetHistoryPage(
      total: 6,
      items: [
        for (var i = 0; i < limit; i++)
          AssetHistoryEntry(
            id: 't-$i',
            kind: kind,
            folio: 'TK-2026-00000$i',
            status: i == 0 ? 'EN_PROCESO' : 'CERRADO',
            title: 'Defensa golpeada',
            date: DateTime.utc(2026, 11, 8 - i, 12),
            responsible: 'Ana Pérez',
            overdue: i == 0,
          ),
      ],
    );
  }
}

void main() {
  group('ficha del servidor', () {
    test('los conteos de operationalHistory, sin los modulos que no ve', () {
      final a = ApiInventoryRepository.fromDetailResponse({
        'asset': {'id': 'a-1', 'code': 'X', 'status': 'ACTIVO'},
        'operationalHistory': {
          'tickets': {'open': 1, 'total': 3},
          'inspections': {'open': 0, 'total': 2},
          'maintenances': null,
        },
      });
      expect(
        a.history,
        const AssetHistoryCounts(
          tickets: AssetHistoryCount(open: 1, total: 3),
          inspections: AssetHistoryCount(open: 0, total: 2),
        ),
      );
      expect(a.history!.visible, [
        AssetHistoryKind.tickets,
        AssetHistoryKind.inspections,
      ]);
    });

    test('un servidor sin operationalHistory no da historia', () {
      final a = ApiInventoryRepository.fromDetailResponse({
        'asset': {'id': 'a-1', 'code': 'X'},
      });
      expect(a.history, isNull);
    });

    test('cada modulo se resume con su folio, estado y fecha clave', () {
      final ticket =
          ApiInventoryRepository.historyEntry(AssetHistoryKind.tickets, {
            'id': 't-1',
            'folio': 'TK-2026-000001',
            'ticketTypeLabel': 'Defensa dañada',
            'status': 'EN_PROCESO',
            'detectedAt': '2026-11-08T12:30:00Z',
            'isOverdue': true,
            'responsibleName': 'Ana',
            'subsystemCode': 'SGS',
          })!;
      expect(ticket.folio, 'TK-2026-000001');
      expect(ticket.title, 'Defensa dañada');
      expect(ticket.date, DateTime.utc(2026, 11, 8, 12, 30));
      expect((ticket.overdue, ticket.dateOnly), (true, false));
      expect(ticket.responsible, 'Ana');

      final inspection =
          ApiInventoryRepository.historyEntry(AssetHistoryKind.inspections, {
            'id': 'i-1',
            'folio': 'IN-2026-000001',
            'inspectionTypeCode': 'RUTINA',
            'inspectionTypeLabel': null,
            'status': 'ASIGNADA',
            'scheduledOn': '2026-11-20',
            'executedAt': null,
            'inspectorName': 'Luis',
          })!;
      // Sin nombre del tipo, su codigo; sin ejecucion, el dia programado.
      expect(inspection.title, 'RUTINA');
      expect(inspection.date, DateTime.utc(2026, 11, 20));
      expect(inspection.dateOnly, isTrue);
      expect(inspection.responsible, 'Luis');

      final maintenance =
          ApiInventoryRepository.historyEntry(AssetHistoryKind.maintenances, {
            'id': 'm-1',
            'folio': 'MP-2026-000001',
            'activity': 'Limpieza',
            'status': 'COMPLETADO',
            'plannedStart': '2026-10-01',
            'actualEnd': '2026-10-05',
            'isOverdue': false,
            'responsibleName': null,
            'subsystemCode': 'SGS',
          })!;
      expect(maintenance.title, 'Limpieza');
      expect(maintenance.date, DateTime.utc(2026, 10, 5));
      expect(maintenance.subsystemCode, 'SGS');

      expect(
        ApiInventoryRepository.historyEntry(AssetHistoryKind.tickets, {}),
        isNull,
      );
    });
  });

  group('repositorio', () {
    late FakeApi api;
    late ApiInventoryRepository repo;

    setUp(() {
      api = FakeApi();
      repo = ApiInventoryRepository(api.client());
    });

    test('pide la lista de cada modulo filtrada por el activo', () async {
      api.on(
        'GET /api/tickets',
        const FakeReply(200, {
          'items': [
            {'id': 't-1', 'folio': 'TK-1', 'status': 'CERRADO'},
          ],
          'total': 7,
          'page': 1,
          'pageSize': 5,
        }),
      );
      api.on(
        'GET /api/inspections',
        const FakeReply(200, {'items': [], 'total': 0}),
      );
      api.on(
        'GET /api/preventive-maintenance',
        const FakeReply(200, {'items': [], 'total': 0}),
      );

      final tickets = await repo.history('a-1', AssetHistoryKind.tickets);
      expect(tickets.total, 7);
      expect(tickets.items.single.folio, 'TK-1');
      await repo.history('a-1', AssetHistoryKind.inspections, limit: 3);
      await repo.history('a-1', AssetHistoryKind.maintenances);

      final t = api.to('GET /api/tickets').single.queryParameters;
      expect(t['assetId'], 'a-1');
      expect(t['pageSize'], 5);
      // Los tickets cerrados tambien son historia.
      expect(t['includeClosed'], true);
      expect(
        api.to('GET /api/inspections').single.queryParameters['pageSize'],
        3,
      );
      expect(
        api
            .to('GET /api/preventive-maintenance')
            .single
            .queryParameters['sort'],
        'recent',
      );
    });

    test('sin permiso del modulo lo dice', () async {
      api.on('GET /api/tickets', const FakeReply(403));
      await expectLater(
        repo.history('a-1', AssetHistoryKind.tickets),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.error,
            'error',
            InventoryError.permissionDenied,
          ),
        ),
      );
    });
  });

  group('cubit de la ficha', () {
    test('pide solo lo que tiene registros y lo que la persona ve', () async {
      final repo = _Inventory();
      final cubit = InventoryDetailCubit(repo, 'a-1');
      await cubit.load();

      final history = cubit.state.history;
      expect(history.keys, [
        AssetHistoryKind.tickets,
        AssetHistoryKind.inspections,
      ]);
      // Sin inspecciones no se pregunta; sin permiso de mantenimientos, nada.
      expect(repo.asked, [AssetHistoryKind.tickets]);
      final tickets = history[AssetHistoryKind.tickets]!;
      expect(tickets.status, AssetHistoryStatus.ready);
      expect(tickets.items, hasLength(InventoryDetailCubit.historyLimit));
      expect(tickets.count, const AssetHistoryCount(open: 1, total: 6));
      expect(
        history[AssetHistoryKind.inspections]!.status,
        AssetHistoryStatus.ready,
      );
    });

    test('una lista que no baja deja su conteo y un aviso', () async {
      final cubit = InventoryDetailCubit(
        _Inventory(failing: {AssetHistoryKind.tickets}),
        'a-1',
      );
      await cubit.load();
      final tickets = cubit.state.history[AssetHistoryKind.tickets]!;
      expect(tickets.status, AssetHistoryStatus.failure);
      expect(tickets.count.total, 6);
      // La ficha sigue en pie.
      expect(cubit.state.status, InventoryDetailStatus.ready);
    });

    test('sin conteos (servidor anterior) no hay historia', () async {
      final cubit = InventoryDetailCubit(_NoHistory(), 'a-1');
      await cubit.load();
      expect(cubit.state.history, isEmpty);
    });
  });

  test('los ejemplos cuadran con sus conteos', () async {
    final repo = SampleInventoryRepository();
    final asset = await repo.get('A-004');
    expect(asset.inMaintenance, isTrue);
    final count = asset.history!.tickets!;
    final page = await repo.history('A-004', AssetHistoryKind.tickets);
    expect(page.total, count.total);
    expect(
      page.items.where((e) => e.status == 'EN_PROCESO'),
      hasLength(count.open),
    );
  });

  group('pantalla', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    Future<void> launch(WidgetTester tester) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(
            ['PANEL', 'INVENTARIO', 'TICKETS'],
            permissions: [PermissionKeys.inventoryView],
          ),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        inventoryRepository: _Inventory(),
        ticketsRepository: SampleTicketsRepository(),
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
      await tester.tap(find.byKey(const Key('inventory-a-1')));
      await tester.pumpAndSettle();
    }

    testWidgets('la ficha muestra la historia operativa con sus conteos', (
      tester,
    ) async {
      await launch(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('inventory-history-inspections')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('inventory-detail')),
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.text('Historia operativa'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-history-maintenances')),
        findsNothing,
        reason: 'sin permiso de ver mantenimientos',
      );
      expect(find.text('1 sin cerrar · 6 en total'), findsOneWidget);
      expect(find.text('TK-2026-000000'), findsOneWidget);
      expect(find.text('En proceso'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-history-entry-t-0-overdue')),
        findsOneWidget,
      );
      expect(find.text('Últimos 5 de 6.'), findsOneWidget);
      expect(find.text('Este activo no tiene inspecciones.'), findsOneWidget);
    });

    testWidgets('crear ticket abre el alta con el activo elegido', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.byKey(const Key('inventory-action-ticket')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ticket-asset')), findsOneWidget);
      expect(find.text('Activo DEFENSA-000001'), findsOneWidget);
      expect(find.byKey(const Key('ticket-location')), findsNothing);
      final km = tester.widget<TextFormField>(
        find.byKey(const Key('new-ticket-km')),
      );
      expect(km.initialValue, 'KM 150+200');
    });
  });

  group('estados de ticket del DTF M11 v0.3 en la historia', () {
    test('SIN_VALIDAR, ABIERTO y ATENDIDO tienen su etiqueta en cada idioma', () {
      const kind = AssetHistoryKind.tickets;
      final es = AppLocalizationsEs();
      final pt = AppLocalizationsPt();
      expect(historyStatusLabel(es, kind, 'SIN_VALIDAR'), 'Sin validar');
      expect(historyStatusLabel(es, kind, 'ABIERTO'), 'Abierto');
      expect(historyStatusLabel(es, kind, 'ATENDIDO'), 'Atendido');
      expect(historyStatusLabel(pt, kind, 'SIN_VALIDAR'), 'Não validado');
      expect(historyStatusLabel(pt, kind, 'ABIERTO'), 'Aberto');
    });

    test('lo que falta atender es abierto y ATENDIDO espera la validacion', () {
      expect(historyStatusColor('SIN_VALIDAR'), StatusColors.open);
      expect(historyStatusColor('ABIERTO'), StatusColors.open);
      expect(historyStatusColor('ATENDIDO'), StatusColors.attended);
      expect(historyStatusColor('CERRADO'), StatusColors.closed);
    });
  });
}

/// Un servidor anterior al contrato: la ficha sin `operationalHistory`.
class _NoHistory extends _Inventory {
  @override
  Future<InventoryAsset> get(String id) async => const InventoryAsset(
    id: 'a-1',
    name: 'x',
    category: 'x',
    condition: AssetCondition.unknown,
  );
}
