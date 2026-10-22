import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/app/shell/alert_routes.dart';
import 'package:sigaco_movil/features/alerts/data/repositories/sample_alerts_repository.dart';
import 'package:sigaco_movil/features/alerts/data/repositories/unavailable_alerts_repository.dart';
import 'package:sigaco_movil/features/alerts/domain/entities/app_alert.dart';
import 'package:sigaco_movil/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:sigaco_movil/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Una lista de alertas controlable: lo que responde y lo que falla.
class _Repo implements AlertsRepository {
  _Repo(this.alerts);

  List<AppAlert> alerts;
  AlertsError? failure;
  AlertsError? writeFailure;
  final marked = <String>[];
  int lists = 0;
  Completer<void>? gate;

  @override
  Future<List<AppAlert>> list() async {
    lists++;
    if (gate != null) await gate!.future;
    if (failure != null) throw AlertsException(failure!);
    return alerts;
  }

  @override
  Future<void> markRead(String id) async {
    if (writeFailure != null) throw AlertsException(writeFailure!);
    marked.add(id);
  }

  @override
  Future<void> markAllRead() async {
    if (writeFailure != null) throw AlertsException(writeFailure!);
    marked.add('*');
  }
}

AppAlert _alert(
  String id, {
  bool read = false,
  DateTime? at,
  String? type,
  String? entity,
}) => AppAlert(
  id: id,
  title: 'Alerta $id',
  createdAt: at ?? DateTime.utc(2026, 10, 21, 12),
  read: read,
  entityType: type,
  entityId: entity,
);

/// El centro de alertas (M05): lista, sin leer y enlace al registro. Es lo que
/// TEKIA acepto el 20/10/2026 en lugar de la notificacion del sistema.
void main() {
  final now = DateTime.utc(2026, 10, 21, 18);

  group('dominio', () {
    test('marcar como leida no cambia lo demas', () {
      final a = _alert('1', type: 'TICKET', entity: 'T-1');
      final b = a.copyWith(read: true);

      expect(b.read, isTrue);
      expect(b.id, a.id);
      expect(b.entityId, 'T-1');
      expect(b.createdAt, a.createdAt);
    });

    test(
      'las de ejemplo apuntan a registros de los otros datos de ejemplo',
      () async {
        final alerts = await SampleAlertsRepository(now: now).list();

        expect(alerts, hasLength(6));
        expect(alerts.where((a) => !a.read), hasLength(3));
        expect(alerts.map((a) => a.entityType).whereType<String>().toSet(), {
          'TICKET',
          'ACCIDENT',
          'INSPECTION',
          'WORK',
        });
      },
    );

    test('las de ejemplo se marcan como leidas y se recuerda', () async {
      final repo = SampleAlertsRepository(now: now);
      await repo.markRead('AL-1');
      expect(
        (await repo.list()).singleWhere((a) => a.id == 'AL-1').read,
        isTrue,
      );

      await repo.markAllRead();
      expect((await repo.list()).every((a) => a.read), isTrue);
    });

    test('sin endpoints, dice que no estan disponibles', () async {
      const repo = UnavailableAlertsRepository();

      await expectLater(
        repo.list(),
        throwsA(
          isA<AlertsException>().having(
            (e) => e.error,
            'error',
            AlertsError.notAvailable,
          ),
        ),
      );
    });
  });

  group('cubit', () {
    late _Repo repo;
    late AlertsCubit cubit;

    setUp(() {
      repo = _Repo([
        _alert('viejo', at: DateTime.utc(2026, 10, 19), read: true),
        _alert('nuevo', at: DateTime.utc(2026, 10, 21)),
        _alert('medio', at: DateTime.utc(2026, 10, 20)),
      ]);
      cubit = AlertsCubit(repo);
    });
    tearDown(() => cubit.close());

    test('antes de cargar no hay nada ni contador', () {
      expect(cubit.state.status, AlertsStatus.idle);
      expect(cubit.state.unread, 0);
    });

    test(
      'carga, cuenta lo no leido y ordena lo mas reciente primero',
      () async {
        await cubit.load();

        expect(cubit.state.status, AlertsStatus.ready);
        expect(cubit.state.unread, 2);
        expect(cubit.state.visible.map((a) => a.id), [
          'nuevo',
          'medio',
          'viejo',
        ]);
      },
    );

    test('solo las no leidas', () async {
      await cubit.load();
      cubit.setOnlyUnread(true);

      expect(cubit.state.visible.map((a) => a.id), ['nuevo', 'medio']);
    });

    test('marcar una se ve al instante y se guarda', () async {
      await cubit.load();

      final done = cubit.markRead('nuevo');
      expect(
        cubit.state.unread,
        1,
        reason: 'antes de que responda el servidor',
      );
      await done;

      expect(repo.marked, ['nuevo']);
    });

    test('marcar una ya leida no vuelve a llamar al servidor', () async {
      await cubit.load();
      await cubit.markRead('viejo');
      await cubit.markRead('no-existe');

      expect(repo.marked, isEmpty);
    });

    test('si el servidor no la acepta, vuelve a como estaba', () async {
      await cubit.load();
      repo.writeFailure = AlertsError.network;

      await cubit.markRead('nuevo');

      expect(cubit.state.byId('nuevo')!.read, isFalse);
      expect(cubit.state.unread, 2);
    });

    test('marcar todas', () async {
      await cubit.load();
      await cubit.markAllRead();

      expect(cubit.state.unread, 0);
      expect(repo.marked, ['*']);
    });

    test('marcar todas sin nada pendiente no llama al servidor', () async {
      repo.alerts = [_alert('a', read: true)];
      await cubit.load();
      await cubit.markAllRead();

      expect(repo.marked, isEmpty);
    });

    test('sin endpoints queda como no disponible', () async {
      repo.failure = AlertsError.notAvailable;
      await cubit.load();

      expect(cubit.state.status, AlertsStatus.failure);
      expect(cubit.state.error, AlertsError.notAvailable);
      expect(cubit.state.unread, 0);
    });

    test('un fallo al actualizar no quita lo que ya se veia', () async {
      await cubit.load();
      repo.failure = AlertsError.network;

      await cubit.refresh();

      expect(cubit.state.status, AlertsStatus.ready);
      expect(cubit.state.alerts, hasLength(3));
    });

    test('un fallo al cargar por primera vez se informa', () async {
      repo.failure = AlertsError.network;
      await cubit.load();

      expect(cubit.state.status, AlertsStatus.failure);
      expect(cubit.state.error, AlertsError.network);
    });

    test('dos consultas a la vez se reducen a una', () async {
      repo.gate = Completer<void>();
      final a = cubit.refresh();
      final b = cubit.refresh();
      repo.gate!.complete();
      await Future.wait([a, b]);

      expect(repo.lists, 1);
    });

    test('al cerrar sesion se vacia', () async {
      await cubit.load();
      cubit.clear();

      expect(cubit.state, const AlertsState());
    });
  });

  group('a donde lleva una alerta', () {
    final all = menuWith([
      'TICKETS',
      'ANTT',
      'ANTT.ACCIDENTES',
      'INSPECCIONES',
      'OBRAS',
      'INVENTARIO',
      'MANTENIMIENTO',
    ]);

    String? route(String? type, String? id, {NavigationMenu? menu}) =>
        alertRoute(_alert('x', type: type, entity: id), menu ?? all);

    test('cada tipo va a su pantalla', () {
      expect(route('TICKET', 'T-0038'), '/tickets/T-0038');
      expect(route('ACCIDENT', 'A-0036'), '/accidents/A-0036');
      expect(route('INSPECTION', 'I-501'), '/inspections/I-501');
      expect(route('WORK', 'O-031'), '/works/O-031');
      expect(route('ASSET', 'A-004'), '/inventory/A-004');
      expect(route('MAINTENANCE', 'M-1'), '/maintenance');
    });

    test('el tipo se acepta en minusculas', () {
      expect(route('ticket', 'T-1'), '/tickets/T-1');
    });

    test('sin el modulo en el menu no lleva a ninguna parte', () {
      expect(route('TICKET', 'T-1', menu: menuWith(['OBRAS'])), isNull);
      expect(route('WORK', 'O-1', menu: menuWith(['TICKETS'])), isNull);
    });

    test('una alerta solo informativa no apunta a nada', () {
      expect(route(null, null), isNull);
      expect(route('TICKET', null), isNull);
      expect(route(null, 'T-1'), isNull);
    });

    test('un tipo desconocido no se adivina', () {
      expect(route('SATELITE', 'S-1'), isNull);
    });

    test('un identificador raro del servidor nunca se vuelve una ruta', () {
      for (final id in [
        '../admin',
        'a/b',
        'x?y=1',
        '',
        ' ',
        'a b',
        '/tickets',
        'x#y',
      ]) {
        expect(route('TICKET', id), isNull, reason: id);
      }
      expect(route('TICKET', 'a' * 65), isNull);
    });
  });

  group('en la app', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    late SampleAlertsRepository alerts;

    Future<void> launch(
      WidgetTester tester, {
      AlertsRepository? repository,
      bool sample = true,
      List<String> modules = const ['PANEL', 'TICKETS', 'ALERTAS_OPERATIVAS'],
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      alerts = SampleAlertsRepository(now: DateTime.now());
      final tickets = SampleTicketsRepository();
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(menu: menuWith(modules)),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        alertsRepository: repository ?? alerts,
        sampleAlerts: sample,
        ticketsRepository: tickets,
        sampleTickets: true,
        zoneSource: FixedZoneSource(),
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

    /// Las alertas se abren con la campana de la cabecera.
    Future<void> openAlerts(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('home-alerts-bell')));
      await tester.pumpAndSettle();
    }

    testWidgets('la campana muestra cuantas hay sin leer', (tester) async {
      await launch(tester);

      final bell = tester.widget<Badge>(find.byKey(const Key('bell-badge')));
      expect(bell.isLabelVisible, isTrue);
      expect(
        find.descendant(
          of: find.byKey(const Key('bell-badge')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('nav-badge-Alertas')), findsOneWidget);
      // Ya no es una tarjeta de la rejilla.
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Alertas'),
        ),
        findsNothing,
      );
    });

    testWidgets('la campana se ve aunque el menu no traiga alertas', (
      tester,
    ) async {
      await launch(tester, modules: const ['PANEL', 'TICKETS']);

      expect(find.byKey(const Key('home-alerts-bell')), findsOneWidget);
      await openAlerts(tester);
      expect(find.byKey(const Key('alerts-list')), findsOneWidget);
    });

    testWidgets('la lista muestra todas, con las no leidas marcadas', (
      tester,
    ) async {
      await launch(tester);
      await openAlerts(tester);

      expect(find.byKey(const Key('alerts-sample-banner')), findsOneWidget);
      expect(find.byKey(const Key('alert-AL-1')), findsOneWidget);
      expect(find.byKey(const Key('alert-unread-AL-1')), findsOneWidget);
      expect(find.byKey(const Key('alert-unread-AL-4')), findsNothing);
      // Lo mas reciente primero.
      expect(
        tester.getTopLeft(find.byKey(const Key('alert-AL-1'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('alert-AL-2'))).dy),
      );
    });

    testWidgets('el filtro deja solo las no leidas', (tester) async {
      await launch(tester);
      await openAlerts(tester);

      await tester.tap(find.byKey(const Key('alerts-filter-unread')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('alert-AL-1')), findsOneWidget);
      expect(find.byKey(const Key('alert-AL-4')), findsNothing);
    });

    testWidgets('tocar una con registro la marca y abre el ticket en la app', (
      tester,
    ) async {
      await launch(tester);
      await openAlerts(tester);

      await tester.tap(find.byKey(const Key('alert-AL-1')));
      await tester.pumpAndSettle();

      // Esta en el detalle del ticket 0038, dentro de la app.
      expect(
        find.text('Luminarias apagadas en el túnel norte'),
        findsOneWidget,
      );
      expect(
        (await alerts.list()).singleWhere((a) => a.id == 'AL-1').read,
        isTrue,
      );
    });

    testWidgets('una solo informativa se marca y se queda en la lista', (
      tester,
    ) async {
      await launch(tester);
      await openAlerts(tester);

      await tester.tap(find.byKey(const Key('alert-AL-6')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('alerts-list')), findsOneWidget);
    });

    testWidgets('marcar todas deja el contador en cero', (tester) async {
      await launch(tester);
      await openAlerts(tester);

      await tester.tap(find.byKey(const Key('alerts-mark-all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('alert-unread-AL-1')), findsNothing);
      final button = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const Key('alerts-mark-all')),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull, reason: 'ya no hay nada pendiente');
    });

    testWidgets('sin endpoints, la pantalla lo dice', (tester) async {
      await launch(
        tester,
        repository: const UnavailableAlertsRepository(),
        sample: false,
      );
      await openAlerts(tester);

      expect(
        find.byKey(const Key('alerts-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.text('Alertas aún no disponibles'), findsOneWidget);
      expect(find.byKey(const Key('alerts-sample-banner')), findsNothing);
    });

    testWidgets('un error de red se puede reintentar', (tester) async {
      final repo = _Repo([_alert('1')])..failure = AlertsError.network;
      await launch(tester, repository: repo);
      await openAlerts(tester);

      expect(find.byKey(const Key('alerts-state-network')), findsOneWidget);

      repo.failure = null;
      await tester.tap(find.byKey(const Key('alerts-retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('alert-1')), findsOneWidget);
    });

    testWidgets('sin alertas dice que no hay', (tester) async {
      await launch(tester, repository: _Repo(const []));
      await openAlerts(tester);

      expect(find.text('No tienes alertas.'), findsOneWidget);
    });

    testWidgets('la notificacion abre el registro de su alerta', (
      tester,
    ) async {
      await launch(tester);
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/alerts/AL-1');
      await tester.pumpAndSettle();

      expect(
        find.text('Luminarias apagadas en el túnel norte'),
        findsOneWidget,
      );
      expect(
        (await alerts.list()).singleWhere((a) => a.id == 'AL-1').read,
        isTrue,
      );
    });

    testWidgets(
      'una notificacion de una alerta que no existe deja en la lista',
      (tester) async {
        await launch(tester);
        final context = tester.element(find.byType(Scaffold).first);
        GoRouter.of(context).go('/alerts/NO-EXISTE');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('alerts-list')), findsOneWidget);
      },
    );
  });
}
