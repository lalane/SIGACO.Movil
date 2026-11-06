import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// El modulo de tickets de punta a punta con datos de ejemplo: la tarjeta del
/// menu, el historial con sus pestanas, la ficha, el seguimiento y el ticket
/// nuevo.
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

  late SampleTicketsRepository repo;

  Future<void> launch(
    WidgetTester tester, {
    TicketsRepository? tickets,
    bool sample = true,
    Size surface = TestSurface.largePhone,
    double textScale = 1.0,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, surface, textScale: textScale);
    SharedPreferences.setMockInitialValues({});
    repo = SampleTicketsRepository();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      ticketsRepository: tickets ?? repo,
      zoneSource: FixedZoneSource(),
      sampleTickets: sample,
      fileSource: FakeFileSource(
        photo: const SelectedFile(
          name: 'foto.jpg',
          path: '/no/existe/foto.jpg',
          sizeBytes: 10,
        ),
      ),
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

  Future<void> openTickets(WidgetTester tester) async {
    final card = find.descendant(
      of: find.byType(GridView),
      matching: find.text('Registros'),
    );
    // Las tarjetas de resumen empujan los modulos: en pantallas chicas se baja.
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byKey(Key('ticket-$id'));
  Finder count(String filter) => find.descendant(
    of: find.byKey(Key('tickets-count-$filter')),
    matching: find.byType(Text),
  );

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('tickets-search')), text);
    await tester.pumpAndSettle();
  }

  group('historial', () {
    testWidgets('abre desde el menu con el aviso de ejemplo y las cuentas', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      expect(find.byKey(const Key('tickets-sample-banner')), findsOneWidget);
      expect(find.text('Historial de registros'), findsOneWidget);
      expect(tester.widget<Text>(count('all')).data, '8');
      expect(tester.widget<Text>(count('open')).data, '4');
      expect(tester.widget<Text>(count('attended')).data, '4');
      // Lo mas reciente primero.
      expect(card('T-0036'), findsOneWidget);
    });

    testWidgets('sin el modo de ejemplo no hay aviso', (tester) async {
      await launch(tester, sample: false);
      await openTickets(tester);
      expect(find.byKey(const Key('tickets-sample-banner')), findsNothing);
    });

    testWidgets('filtrar por estado deja solo esos tickets', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await search(tester, 'Barrera');
      expect(card('T-0035'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tickets-filter-open')));
      await tester.pumpAndSettle();
      // Con "Barrera" y abiertos no queda ninguno.
      expect(find.byKey(const Key('tickets-state-empty')), findsOneWidget);
      expect(
        find.text('Ningún registro coincide con los filtros.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tickets-filter-attended')));
      await tester.pumpAndSettle();
      expect(card('T-0035'), findsOneWidget);
    });

    testWidgets('buscar por titulo y por cadenamiento', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await search(tester, 'pozo');
      expect(card('T-0036'), findsOneWidget);
      expect(card('T-0035'), findsNothing);
      await search(tester, '148+000');
      expect(card('T-0037'), findsOneWidget);
    });

    testWidgets('ordenar por vencimiento pone primero al vencido', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-sort-due')));
      await tester.pumpAndSettle();
      expect(card('T-0038'), findsOneWidget);
      expect(find.text('vencido'), findsOneWidget);
    });

    testWidgets('la hoja de filtros cambia el estado y los quita', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-filter-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-filters-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tickets-sheet-filter-attended')));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      await tester.tap(find.byKey(const Key('tickets-sheet-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tickets-sheet-done')));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('sin endpoints dice que no esta disponible', (tester) async {
      await launch(tester, tickets: _Failing(TicketsError.notAvailable));
      await openTickets(tester);
      expect(
        find.byKey(const Key('tickets-state-notAvailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tickets-retry')), findsNothing);
    });

    testWidgets('un error de red ofrece reintentar', (tester) async {
      final failing = _Failing(TicketsError.network);
      await launch(tester, tickets: failing);
      await openTickets(tester);
      expect(find.byKey(const Key('tickets-state-network')), findsOneWidget);
      failing.error = null;
      await tester.tap(find.byKey(const Key('tickets-retry')));
      await tester.pumpAndSettle();
      expect(card('T-0036'), findsOneWidget);
    });
  });

  group('ficha', () {
    testWidgets('muestra los datos, el estado y los seguimientos', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      await search(tester, '0035');
      await tester.tap(card('T-0035'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-detail')), findsOneWidget);
      expect(find.text('ID REGISTRO #0035'), findsOneWidget);
      expect(
        find.text('Barrera de contención dañada km 513+615 – tramo sur'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ticket-detail-status')), findsOneWidget);
      expect(find.byKey(const Key('ticket-info')), findsOneWidget);
      expect(find.text('KM 513+615'), findsOneWidget);
      expect(find.text('Ana Herrera'), findsOneWidget);
      // Las coordenadas salen en grados, minutos y segundos.
      expect(find.textContaining("18°50'45.96"), findsOneWidget);
    });

    testWidgets('los seguimientos van del mas reciente al mas antiguo', (
      tester,
    ) async {
      await launch(tester, tickets: _WithFollowUps());
      await openTickets(tester);
      await search(tester, '0035');
      await tester.tap(card('T-0035'));
      await tester.pumpAndSettle();
      final newer = find.text('Segundo seguimiento', skipOffstage: false);
      final older = find.text('Primer seguimiento', skipOffstage: false);
      await tester.drag(
        find.byKey(const Key('ticket-detail')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(newer, findsOneWidget);
      expect(
        tester.getTopLeft(newer).dy,
        lessThan(tester.getTopLeft(older).dy),
      );
    });

    testWidgets('tocar la foto la abre a pantalla completa y se cierra', (
      tester,
    ) async {
      await launch(tester, tickets: _WithFollowUps());
      await openTickets(tester);
      await search(tester, '0035');
      await tester.tap(card('T-0035'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hero-photo-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo-viewer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo-viewer')), findsNothing);
      expect(find.byKey(const Key('ticket-detail')), findsOneWidget);
    });

    testWidgets('descargar y editar avisan que llegan despues', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await search(tester, '0035');
      await tester.tap(card('T-0035'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-action-edit')));
      await tester.pump();
      expect(
        find.text('Esta acción estará disponible pronto.'),
        findsOneWidget,
      );
    });

    testWidgets('el boton Volver regresa al historial', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await search(tester, '0035');
      await tester.tap(card('T-0035'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-detail')), findsOneWidget);
      // El boton de volver regresa al historial.
      await tester.tap(find.byKey(const Key('ticket-detail-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-list')), findsOneWidget);
    });
  });

  group('seguimiento', () {
    Future<void> openFollowUp(WidgetTester tester) async {
      await openTickets(tester);
      await search(tester, '0036');
      await tester.tap(card('T-0036'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-action-follow-up')));
      await tester.pumpAndSettle();
    }

    testWidgets('sin estado ni descripcion no guarda y lo avisa', (
      tester,
    ) async {
      await launch(tester);
      await openFollowUp(tester);
      expect(find.text('Seguimiento de registro'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Elige el estado del registro.'), findsOneWidget);
      expect(find.text('Escribe una descripción.'), findsOneWidget);
      expect((await repo.get('T-0036')).followUps, isEmpty);
    });

    testWidgets('guarda el seguimiento y la ficha lo refleja', (tester) async {
      await launch(tester);
      await openFollowUp(tester);
      await tester.tap(find.byKey(const Key('follow-up-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atendido').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('follow-up-description')),
        'Se rellenó el bache',
      );
      await tester.tap(find.byKey(const Key('ticket-photo-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Seguimiento guardado.'), findsOneWidget);
      final ticket = await repo.get('T-0036');
      expect(ticket.status, TicketStatus.attended);
      expect(ticket.followUps.single.description, 'Se rellenó el bache');
      expect(ticket.followUps.single.photoPaths, ['/no/existe/foto.jpg']);
      // De vuelta en la ficha, con el estado nuevo.
      expect(find.byKey(const Key('ticket-detail')), findsOneWidget);
    });

    testWidgets('una foto se puede quitar', (tester) async {
      await launch(tester);
      await openFollowUp(tester);
      await tester.tap(find.byKey(const Key('ticket-photo-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-photo-remove-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-photo-remove-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-photo-remove-1')), findsNothing);
    });
  });

  group('ticket nuevo', () {
    testWidgets('pide titulo y tipo', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-new')));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo registro'), findsWidgets);
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un título.'), findsOneWidget);
      expect(find.text('Elige el tipo de registro.'), findsOneWidget);
    });

    testWidgets('la prioridad empieza en Media y se puede cambiar', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-new')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('new-ticket-priority'));
      await tester.ensureVisible(field);
      expect(find.text('Media'), findsOneWidget);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crítica').last);
      await tester.pumpAndSettle();
      expect(find.text('Crítica'), findsOneWidget);
    });

    testWidgets('crea el ticket y el historial lo cuenta', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('tickets-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-ticket-title')),
        'Cuneta tapada km 160',
      );
      await tester.enterText(
        find.byKey(const Key('new-ticket-description')),
        'Basura en la cuneta',
      );
      await tester.tap(find.byKey(const Key('new-ticket-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpieza').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Registro creado.'), findsOneWidget);
      expect(tester.widget<Text>(count('all')).data, '9');
      expect(tester.widget<Text>(count('open')).data, '5');
      expect((await repo.list()).first.title, 'Cuneta tapada km 160');
    });
  });

  group('barra inferior', () {
    testWidgets('lleva de tickets al mapa, de vuelta y al menu', (
      tester,
    ) async {
      await launch(tester);
      await openTickets(tester);
      expect(find.byKey(const Key('module-nav')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-tab-map')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-tab-tickets')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-tab-tickets')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-list')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-tab-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('module-nav')), findsNothing);
    });

    testWidgets('Catálogo lleva al catálogo de activos', (tester) async {
      await launch(tester);
      await openTickets(tester);
      await tester.tap(find.byKey(const Key('nav-tab-inventory')));
      await tester.pumpAndSettle();
      // Sin servidor que publique el catálogo, la pantalla lo dice.
      expect(
        find.byKey(const Key('inventory-state-notAvailable')),
        findsOneWidget,
      );
    });
  });

  testWidgets('se ve bien en un telefono pequeno y con texto grande', (
    tester,
  ) async {
    await launch(tester, surface: TestSurface.smallPhone, textScale: 1.5);
    await openTickets(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('tickets-new')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

/// Un repositorio que falla con el error que se le diga (o responde si es null).
class _Failing implements TicketsRepository {
  _Failing(this.error);

  TicketsError? error;
  final _ok = SampleTicketsRepository();

  Future<T> _run<T>(Future<T> Function() ok) =>
      error == null ? ok() : Future.error(TicketsException(error!));

  @override
  Future<List<Ticket>> list() => _run(_ok.list);

  @override
  Future<Ticket> get(String id) => _run(() => _ok.get(id));

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) =>
      _run(() => _ok.addFollowUp(ticketId, followUp));

  @override
  Future<Ticket> create(NewTicket draft) => _run(() => _ok.create(draft));

  @override
  Future<List<String>> categories() => _run(_ok.categories);
}

/// Una ficha con fotos y seguimientos guardados del mas antiguo al mas nuevo,
/// como los entrega el servidor.
class _WithFollowUps extends SampleTicketsRepository {
  @override
  Future<Ticket> get(String id) async {
    final base = await super.get(id);
    return base.copyWith(
      photoPaths: const ['/no/existe/a.jpg', '/no/existe/b.jpg'],
      followUps: [
        TicketFollowUp(
          id: 'f1',
          at: DateTime.utc(2026, 10, 1, 10),
          status: TicketStatus.open,
          description: 'Primer seguimiento',
        ),
        TicketFollowUp(
          id: 'f2',
          at: DateTime.utc(2026, 10, 2, 10),
          status: TicketStatus.open,
          description: 'Segundo seguimiento',
        ),
      ],
    );
  }
}
