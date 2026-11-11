import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket_supervision.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/ticket_detail_cubit.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Las acciones del Supervisor en la ficha (DTF M11 v0.3, HU-11-24): solo las
/// que ofrece el servidor, cada una con lo que pide, y el ticket como queda.
void main() {
  final now = DateTime.utc(2026, 11, 10, 12);

  group('datos de ejemplo', () {
    late SampleTicketsRepository repo;

    setUp(() => repo = SampleTicketsRepository(clock: () => now));

    test('asignar deja el ticket ABIERTO con su empresa y equipo', () async {
      final t = await repo.get('T-0037');
      expect(t.stage, TicketStage.unvalidated);
      final updated = await repo.assign(
        t,
        const TicketAssignment(companyId: 'E-1', teamId: 'EQ-2'),
      );
      expect(updated.stage, TicketStage.open);
      expect(updated.assignedTeamName, 'Cuadrilla Sur');
      expect(updated.offers(TicketAction.reassign), isTrue);
      expect(updated.offers(TicketAction.assign), isFalse);
    });

    test('reasignar sin motivo se rechaza', () async {
      final t = await repo.get('T-0036');
      await expectLater(
        repo.assign(
          t,
          const TicketAssignment(companyId: 'E-1', teamId: 'EQ-1'),
        ),
        throwsA(isA<TicketActionRejected>()),
      );
    });

    test('cerrar y regresar solo desde ATENDIDO', () async {
      final attended = await repo.get('T-0035');
      final closed = await repo.close(
        attended,
        const TicketClosing(condition: TicketAssetCondition.good),
      );
      expect(closed.stage, TicketStage.closed);
      expect(closed.closingAssetCondition, 'BUENO');
      // Cerrado ya no ofrece nada en la app (reabrir es de la web).
      expect(closed.actions, isEmpty);
      await expectLater(
        repo.returnToOpen(closed, 'x'),
        throwsA(isA<TicketActionRejected>()),
      );
      final back = await repo.returnToOpen(await repo.get('T-0039'), 'Fotos');
      expect(back.stage, TicketStage.open);
    });

    test('cancelar no se ofrece en la app y se rechaza', () async {
      final t = await repo.get('T-0037');
      expect(t.offers(TicketAction.cancel), isFalse);
      await expectLater(
        repo.cancel(
          t,
          const TicketCancellation(reason: TicketCancelReason.improper),
        ),
        throwsA(isA<TicketActionRejected>()),
      );
    });
  });

  group('cubit de la ficha', () {
    test('una accion que sale deja el ticket nuevo y lo dice', () async {
      final repo = SampleTicketsRepository(clock: () => now);
      final cubit = TicketDetailCubit(repo, 'T-0037');
      await cubit.load();
      expect(cubit.canSupervise, isTrue);
      final ok = await cubit.assign(
        const TicketAssignment(companyId: 'E-1', teamId: 'EQ-1'),
      );
      expect(ok, isTrue);
      expect(cubit.state.ticket!.stage, TicketStage.open);
      expect(cubit.state.lastAction, TicketAction.assign);
      expect(cubit.state.outcome, TicketActionOutcome.done);
      expect(cubit.state.acting, isFalse);
    });

    test('un rechazo deja el ticket como estaba y guarda el motivo', () async {
      final repo = SampleTicketsRepository(clock: () => now);
      final cubit = TicketDetailCubit(repo, 'T-0036');
      await cubit.load();
      final ok = await cubit.assign(
        const TicketAssignment(companyId: 'E-1', teamId: 'EQ-2'),
      );
      expect(ok, isFalse);
      expect(cubit.state.lastAction, TicketAction.reassign);
      expect(cubit.state.outcome, TicketActionOutcome.rejected);
      expect(cubit.state.rejection, 'REASON_REQUIRED');
      expect(cubit.state.ticket!.stage, TicketStage.open);
    });

    test('sin red lo dice como fallo', () async {
      final repo = _Supervised(error: TicketsError.network);
      final cubit = TicketDetailCubit(repo, 'T-0035');
      await cubit.load();
      expect(await cubit.closeTicket(const TicketClosing()), isFalse);
      expect(cubit.state.outcome, TicketActionOutcome.failed);
      expect(cubit.state.actionError, TicketsError.network);
    });
  });

  group('en la ficha', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ),
    );

    Future<void> openTicket(
      WidgetTester tester,
      String id, {
      TicketsRepository? tickets,
    }) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        ticketsRepository: tickets ?? SampleTicketsRepository(),
        zoneSource: FixedZoneSource(),
        sampleTickets: true,
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
      final menu = find.descendant(
        of: find.byType(GridView),
        matching: find.text('Registros'),
      );
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tickets-search')),
        id.substring(2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('ticket-$id')));
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, Key field, String option) async {
      await tester.tap(find.byKey(field));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    Finder status(String text) => find.descendant(
      of: find.byKey(const Key('ticket-detail-status')),
      matching: find.text(text),
    );

    testWidgets('sin validar: asignar a empresa y equipo', (tester) async {
      await openTicket(tester, 'T-0037');
      expect(status('Sin validar'), findsOneWidget);
      // Solo lo que ofrece el servidor: asignar, no cerrar ni cancelar.
      expect(find.byKey(const Key('ticket-action-assign')), findsOneWidget);
      expect(find.byKey(const Key('ticket-action-close')), findsNothing);
      expect(find.byKey(const Key('ticket-action-cancel')), findsNothing);

      await tester.tap(find.byKey(const Key('ticket-action-assign')));
      await tester.pumpAndSettle();
      // Sin empresa ni equipo no guarda.
      await tester.tap(find.byKey(const Key('ticket-assign-save')));
      await tester.pumpAndSettle();
      expect(find.text('Elige la empresa y el equipo.'), findsOneWidget);

      await pick(tester, const Key('ticket-assign-company'), 'Conserva Vial');
      await pick(tester, const Key('ticket-assign-team-E-1'), 'Cuadrilla Sur');
      await pick(tester, const Key('ticket-assign-person-EQ-2'), 'Rosa Lima');
      await tester.tap(find.byKey(const Key('ticket-assign-save')));
      await tester.pumpAndSettle();

      expect(find.text('Registro asignado.'), findsOneWidget);
      expect(status('Abierto'), findsOneWidget);
      expect(find.text('Cuadrilla Sur'), findsOneWidget);
      expect(find.byKey(const Key('ticket-action-reassign')), findsOneWidget);
      expect(find.byKey(const Key('ticket-action-assign')), findsNothing);
    });

    testWidgets('abierto: reasignar pide el motivo', (tester) async {
      await openTicket(tester, 'T-0036');
      await tester.tap(find.byKey(const Key('ticket-action-reassign')));
      await tester.pumpAndSettle();
      await pick(tester, const Key('ticket-assign-team-E-1'), 'Cuadrilla Sur');
      await tester.tap(find.byKey(const Key('ticket-assign-save')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el motivo.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ticket-assign-reason')),
        'La cuadrilla norte esta en otro frente',
      );
      await tester.tap(find.byKey(const Key('ticket-assign-save')));
      await tester.pumpAndSettle();
      expect(find.text('Registro reasignado.'), findsOneWidget);
      expect(find.text('Cuadrilla Sur'), findsOneWidget);
    });

    testWidgets('atendido: validar y cerrar con la condicion del activo', (
      tester,
    ) async {
      await openTicket(tester, 'T-0035');
      expect(status('Atendido'), findsOneWidget);
      expect(
        find.byKey(const Key('ticket-action-returnToOpen')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('ticket-action-close')));
      await tester.pumpAndSettle();
      await pick(tester, const Key('ticket-close-condition'), 'Regular');
      await tester.enterText(
        find.byKey(const Key('ticket-close-notes')),
        'Defensa sustituida',
      );
      await tester.tap(find.byKey(const Key('ticket-close-save')));
      await tester.pumpAndSettle();
      expect(find.text('Registro validado y cerrado.'), findsOneWidget);
      expect(status('Cerrado'), findsOneWidget);
      expect(
        find.text('Condición del activo al cerrar: Regular'),
        findsOneWidget,
      );
      // Cerrado: ni acciones del Supervisor ni seguimiento.
      expect(find.byKey(const Key('ticket-supervision')), findsNothing);
      expect(find.byKey(const Key('ticket-action-follow-up')), findsNothing);
    });

    testWidgets('sin activo, cerrar no pide la condicion', (tester) async {
      await openTicket(tester, 'T-0039');
      await tester.tap(find.byKey(const Key('ticket-action-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-close-condition')), findsNothing);
      expect(find.byKey(const Key('ticket-close-notes')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-close-save')));
      await tester.pumpAndSettle();
      expect(status('Cerrado'), findsOneWidget);
    });

    testWidgets('atendido: regresar a Abierto pide el motivo', (tester) async {
      await openTicket(tester, 'T-0039');
      await tester.tap(find.byKey(const Key('ticket-action-returnToOpen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-return-save')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el motivo.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ticket-return-reason')),
        'Faltan las fotos del final',
      );
      await tester.tap(find.byKey(const Key('ticket-return-save')));
      await tester.pumpAndSettle();
      expect(find.text('Registro regresado a Abierto.'), findsOneWidget);
      expect(status('Abierto'), findsOneWidget);
    });

    testWidgets('cancelar como duplicado pide el folio del original', (
      tester,
    ) async {
      final repo = _Supervised(offer: {TicketAction.cancel});
      await openTicket(tester, 'T-0037', tickets: repo);
      await tester.tap(find.byKey(const Key('ticket-action-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-cancel-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe el folio del registro original.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('ticket-cancel-folio')),
        'tk-2026-000036',
      );
      await tester.tap(find.byKey(const Key('ticket-cancel-save')));
      await tester.pumpAndSettle();
      expect(repo.cancelled?.reason, TicketCancelReason.duplicate);
      expect(repo.cancelled?.duplicateOfFolio, 'TK-2026-000036');
      expect(find.text('Registro cancelado.'), findsOneWidget);
      expect(status('Cancelado'), findsOneWidget);
      expect(find.text('Duplicado de TK-2026-000036'), findsOneWidget);
    });

    testWidgets('cancelar como otro pide el detalle', (tester) async {
      final repo = _Supervised(offer: {TicketAction.cancel});
      await openTicket(tester, 'T-0037', tickets: repo);
      await tester.tap(find.byKey(const Key('ticket-action-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ticket-cancel-reason-other')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-cancel-folio')), findsNothing);
      await tester.tap(find.byKey(const Key('ticket-cancel-save')));
      await tester.pumpAndSettle();
      expect(find.text('Con «Otro», explica el motivo.'), findsOneWidget);
    });

    testWidgets('reabrir un cerrado, si el servidor lo ofrece', (tester) async {
      final repo = _Supervised(offer: {TicketAction.reopen});
      await openTicket(tester, 'T-0042', tickets: repo);
      expect(status('Cerrado'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ticket-action-reopen')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ticket-reopen-reason')),
        'El hundimiento volvio',
      );
      await tester.tap(find.byKey(const Key('ticket-reopen-save')));
      await tester.pumpAndSettle();
      expect(find.text('Registro reabierto.'), findsOneWidget);
      expect(status('Abierto'), findsOneWidget);
    });

    testWidgets('lo que el servidor rechaza se avisa con su motivo', (
      tester,
    ) async {
      final repo = _Supervised(
        offer: {TicketAction.cancel},
        rejection: 'No existe ese folio (DUPLICATE_NOT_FOUND)',
      );
      await openTicket(tester, 'T-0037', tickets: repo);
      await tester.tap(find.byKey(const Key('ticket-action-cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ticket-cancel-folio')),
        'TK-1',
      );
      await tester.tap(find.byKey(const Key('ticket-cancel-save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No se aplicó el cambio: No existe ese folio (DUPLICATE_NOT_FOUND)',
        ),
        findsOneWidget,
      );
      expect(status('Sin validar'), findsOneWidget);
    });
  });
}

/// Los tickets de ejemplo con acciones de mas (las que en la app solo ofrece
/// el servidor si cambia la regla), un rechazo fijo o un fallo de red.
class _Supervised extends SampleTicketsRepository {
  _Supervised({this.offer = const {}, this.rejection, this.error});

  final Set<TicketAction> offer;
  final String? rejection;
  final TicketsError? error;
  TicketCancellation? cancelled;

  Ticket _more(Ticket t) => t.copyWith(actions: {...?t.actions, ...offer});

  @override
  Future<Ticket> get(String id) async => _more(await super.get(id));

  Future<Ticket> _check(Ticket t, Ticket Function() result) async {
    if (error != null) throw TicketsException(error!);
    if (rejection != null) throw TicketActionRejected(rejection!);
    return result();
  }

  @override
  Future<Ticket> close(Ticket ticket, TicketClosing closing) => _check(
    ticket,
    () => ticket.copyWith(stage: TicketStage.closed, actions: const {}),
  );

  @override
  Future<Ticket> cancel(Ticket ticket, TicketCancellation cancellation) {
    cancelled = cancellation;
    return _check(
      ticket,
      () => ticket.copyWith(
        stage: TicketStage.cancelled,
        actions: const {},
        cancelReason: cancellation.reason.code,
        duplicateOfFolio: cancellation.duplicateOfFolio,
      ),
    );
  }

  @override
  Future<Ticket> reopen(Ticket ticket, String reason) => _check(
    ticket,
    () => ticket.copyWith(
      stage: TicketStage.open,
      actions: SampleTicketsRepository.actionsFor(TicketStage.open),
    ),
  );
}
