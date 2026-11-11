import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/time/concession_zone.dart';
import 'package:sigaco_movil/core/time/concession_zone_source.dart';
import 'package:sigaco_movil/features/accidents/data/repositories/sample_accidents_repository.dart';
import 'package:sigaco_movil/features/accidents/domain/entities/accident.dart';
import 'package:sigaco_movil/features/accidents/presentation/bloc/new_accident_cubit.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Una zona que el servidor todavia no publica: al cambiar [available] la da.
class _LateZone implements ConcessionZoneSource {
  bool available = false;
  int calls = 0;

  @override
  Future<ConcessionZone?> load(String concessionId) async {
    calls++;
    return available ? ConcessionZone.tryParse('America/Sao_Paulo') : null;
  }
}

/// Reglas de la configuracion de la concesion en la captura (DTF Configuracion
/// del Sistema): hora de captura en UTC (RN-12, RN-14, RN-15) y sin
/// configuracion no se crean registros (RN-13).
void main() {
  group('hora de captura (RN-12, RN-14, RN-15)', () {
    test(
      'un ticket nuevo lleva la hora de abrir el formulario en UTC',
      () async {
        final clock = _Clock(DateTime.utc(2026, 10, 19, 15, 0));
        final repo = SampleTicketsRepository(clock: clock.call);
        final cubit = NewTicketCubit(repo, clock: clock.call);
        expect(cubit.capturedAt, DateTime.utc(2026, 10, 19, 15, 0));
        expect(cubit.capturedAt.isUtc, isTrue);

        // La persona tarda 40 minutos en llenar el formulario.
        clock.now = DateTime.utc(2026, 10, 19, 15, 40);
        await cubit.load();
        cubit.setTitle('Bache');
        // La descripcion es obligatoria (DTF M11 v0.3).
        cubit.setDescription('Bache en el carril derecho');
        cubit.setCategory(cubit.state.categories.first);
        await cubit.save();

        final created = (await repo.list()).firstWhere(
          (t) => t.title == 'Bache',
        );
        // El registro queda a la hora de captura, no a la de guardar.
        expect(created.createdAt, DateTime.utc(2026, 10, 19, 15, 0));
      },
    );

    test('el borrador manda tambien la hora del reloj al enviar', () async {
      final clock = _Clock(DateTime.utc(2026, 10, 19, 15, 0));
      final repo = _SpyTickets(clock.call);
      final cubit = NewTicketCubit(repo, clock: clock.call);
      await cubit.load();
      cubit.setTitle('Señal caída');
      cubit.setDescription('Señal vertical en el suelo');
      cubit.setCategory(cubit.state.categories.first);
      clock.now = DateTime.utc(2026, 10, 19, 15, 5);
      await cubit.save();
      expect(repo.drafts.single.capturedAt, DateTime.utc(2026, 10, 19, 15, 0));
      expect(
        repo.drafts.single.deviceClockAt,
        DateTime.utc(2026, 10, 19, 15, 5),
      );
    });

    test('cambiar la zona del telefono no cambia la hora capturada', () {
      // La hora sale de un instante UTC: no se lee ninguna zona.
      final clock = _Clock(DateTime.utc(2026, 1, 1, 0, 0));
      final cubit = NewTicketCubit(
        SampleTicketsRepository(clock: clock.call),
        clock: clock.call,
      );
      expect(cubit.capturedAt.timeZoneOffset, Duration.zero);
    });

    test('un accidente nuevo tambien lleva la hora de captura', () async {
      final clock = _Clock(DateTime.utc(2026, 10, 19, 9, 30));
      final repo = SampleAccidentsRepository(clock: clock.call);
      final cubit = NewAccidentCubit(repo, clock: clock.call);
      clock.now = DateTime.utc(2026, 10, 19, 10, 15);
      cubit.setTitle('Choque');
      cubit.setType(AccidentType.collision);
      await cubit.save();
      final created = (await repo.list()).firstWhere(
        (a) => a.title == 'Choque',
      );
      expect(created.createdAt, DateTime.utc(2026, 10, 19, 9, 30));
    });
  });

  group('sin configuracion no se crean registros (RN-13)', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    Future<void> launch(WidgetTester tester, ConcessionZoneSource zones) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'TICKETS', 'ANTT.ACCIDENTES']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        ticketsRepository: SampleTicketsRepository(),
        sampleTickets: true,
        accidentsRepository: SampleAccidentsRepository(),
        sampleAccidents: true,
        zoneSource: zones,
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

    Future<void> openNewTicket(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Registros'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tickets-new')));
      await tester.pumpAndSettle();
    }

    testWidgets('el formulario de ticket se bloquea sin zona horaria', (
      tester,
    ) async {
      await launch(tester, _LateZone());
      await openNewTicket(tester);
      expect(find.byKey(const Key('configuration-gate')), findsOneWidget);
      expect(find.text('Sin configuración de la concesión'), findsOneWidget);
      expect(find.byKey(const Key('new-ticket-title')), findsNothing);
    });

    testWidgets('sincronizar trae la zona y abre el formulario', (
      tester,
    ) async {
      final zones = _LateZone();
      await launch(tester, zones);
      await openNewTicket(tester);
      expect(find.byKey(const Key('configuration-gate')), findsOneWidget);

      zones.available = true;
      await tester.tap(find.byKey(const Key('configuration-gate-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('configuration-gate')), findsNothing);
      expect(find.byKey(const Key('new-ticket-title')), findsOneWidget);
    });

    testWidgets('sigue bloqueado si el servidor aun no la publica', (
      tester,
    ) async {
      final zones = _LateZone();
      await launch(tester, zones);
      await openNewTicket(tester);
      final before = zones.calls;
      await tester.tap(find.byKey(const Key('configuration-gate-retry')));
      await tester.pumpAndSettle();
      expect(zones.calls, before + 1);
      expect(find.byKey(const Key('configuration-gate')), findsOneWidget);
    });

    testWidgets('el formulario de accidente tambien se bloquea', (
      tester,
    ) async {
      await launch(tester, _LateZone());
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Accidentes'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accidents-new')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('configuration-gate')), findsOneWidget);
      expect(find.byKey(const Key('new-accident-title')), findsNothing);
    });

    testWidgets('con zona publicada el formulario abre directo', (
      tester,
    ) async {
      await launch(tester, FixedZoneSource());
      await openNewTicket(tester);
      expect(find.byKey(const Key('configuration-gate')), findsNothing);
      expect(find.byKey(const Key('new-ticket-title')), findsOneWidget);
    });
  });
}

class _Clock {
  _Clock(this.now);

  DateTime now;

  DateTime call() => now;
}

/// Anota los borradores que recibe y deja que el repositorio real los guarde.
class _SpyTickets extends SampleTicketsRepository {
  _SpyTickets(DateTime Function() clock) : super(clock: clock);

  final drafts = <NewTicket>[];

  @override
  Future<Ticket> create(NewTicket draft) {
    drafts.add(draft);
    return super.create(draft);
  }
}
