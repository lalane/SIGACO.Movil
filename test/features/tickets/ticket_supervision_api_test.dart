import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket_supervision.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';

import '../../support/fake_api.dart';

/// Las acciones del Supervisor contra el servidor (DTF M11 v0.3): lo que la app
/// lee del ticket (estado, acciones, version, asignacion) y lo que manda en
/// cada paso.
Map<String, Object?> _dto(
  String status, {
  List<String> actions = const [],
  int rowVersion = 4,
  Map<String, Object?> extra = const {},
}) => {
  'id': '1',
  'folio': 'TK-2026-000001',
  'ticketTypeLabel': 'Bache',
  'status': status,
  'description': 'Bache en carril derecho',
  'detectedAt': '2026-11-09T15:00:00Z',
  'actions': actions,
  'rowVersion': rowVersion,
  ...extra,
};

const _teams = [
  {
    'id': 'c1',
    'name': 'Conserva Vial',
    'isExternal': true,
    'teams': [
      {
        'id': 't1',
        'name': 'Cuadrilla Norte',
        'activeMembers': 2,
        'members': [
          {
            'userId': 'u1',
            'fullName': 'Marta Ruiz',
            'profileCode': 'OPERACIONAL',
          },
          {'userId': 'u2', 'fullName': 'Pedro Gil', 'profileCode': null},
        ],
      },
    ],
  },
  {'id': 'c2', 'name': 'Sin equipos', 'isExternal': false, 'teams': []},
];

void main() {
  late FakeApi api;
  late ApiTicketsRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiTicketsRepository(api.client(), roadId: () async => 'road-1');
  });

  /// El servidor despues del paso: la ficha ya con el estado nuevo.
  void after(String status, {List<String> actions = const []}) {
    api.on(
      'GET /api/tickets/1',
      FakeReply(200, _dto(status, actions: actions, rowVersion: 5)),
    );
    api.on('GET /api/tickets/1/follow-ups', const FakeReply(200, <Object>[]));
    api.on('GET /api/tickets/1/attachments', const FakeReply(200, <Object>[]));
  }

  Map<String, Object?> sent(String route) =>
      (api.to(route).single.data as Map).cast<String, Object?>();

  group('traduccion', () {
    test('lee el estado del DTF, las acciones, la version y la asignacion', () {
      final t = ApiTicketsRepository.ticketFromDto(
        _dto(
          'ABIERTO',
          actions: ['REASIGNAR', 'SEGUIMIENTO', 'ATENDER', 'ALGO_NUEVO'],
          extra: {
            'assignedCompanyId': 'c1',
            'assignedCompanyName': 'Conserva Vial',
            'assignedTeamId': 't1',
            'assignedTeamName': 'Cuadrilla Norte',
            'responsibleName': 'Marta Ruiz',
            'createdByName': 'Raul Test',
            'carriageway': 'B',
            'lane': 'PISTA',
          },
        ),
      );
      expect(t.stage, TicketStage.open);
      expect(t.status, TicketStatus.open);
      // Un codigo que la app no conoce se ignora.
      expect(t.actions, {
        TicketAction.reassign,
        TicketAction.followUp,
        TicketAction.attend,
      });
      expect(t.rowVersion, 4);
      expect(t.assignedCompanyName, 'Conserva Vial');
      expect(t.assignedTeamName, 'Cuadrilla Norte');
      expect(t.responsibleName, 'Marta Ruiz');
      expect(t.authorName, 'Raul Test');
      // El cuerpo de la via manda sobre el carril del BBP.
      expect(t.carriageway, 'B');
    });

    test('los cinco estados y los del BBP como su equivalente', () {
      final expected = {
        'SIN_VALIDAR': TicketStage.unvalidated,
        'NUEVO': TicketStage.unvalidated,
        'ABIERTO': TicketStage.open,
        'EN_PROCESO': TicketStage.open,
        'REABIERTO': TicketStage.open,
        'ATENDIDO': TicketStage.attended,
        'RESUELTO': TicketStage.attended,
        'CERRADO': TicketStage.closed,
        'CANCELADO': TicketStage.cancelled,
      };
      expected.forEach((code, stage) {
        expect(
          ApiTicketsRepository.ticketFromDto(_dto(code)).stage,
          stage,
          reason: code,
        );
      });
    });

    test('sin acciones del servidor no se inventan', () {
      final dto = _dto('ABIERTO')..remove('actions');
      final t = ApiTicketsRepository.ticketFromDto(dto);
      expect(t.actions, isNull);
      expect(t.offers(TicketAction.close), isFalse);
      // Un servidor anterior: el seguimiento sigue a la mano.
      expect(t.offersFollowUp, isTrue);
    });

    test('un cancelado trae su motivo y el original', () {
      final t = ApiTicketsRepository.ticketFromDto(
        _dto(
          'CANCELADO',
          extra: {
            'cancelReason': 'DUPLICADO',
            'duplicateOfFolio': 'TK-2026-000007',
          },
        ),
      );
      expect(t.stage, TicketStage.cancelled);
      expect(t.cancelReason, 'DUPLICADO');
      expect(t.duplicateOfFolio, 'TK-2026-000007');
      expect(t.offersFollowUp, isFalse);
    });
  });

  group('equipos asignables', () {
    test('trae empresas, equipos e integrantes', () async {
      api.on('GET /api/tickets/assignable-teams', const FakeReply(200, _teams));
      final companies = await repo.assignableTeams();
      expect(companies.map((c) => c.name), ['Conserva Vial', 'Sin equipos']);
      final team = companies.first.teams.single;
      expect(team.name, 'Cuadrilla Norte');
      expect(team.members.map((m) => m.fullName), ['Marta Ruiz', 'Pedro Gil']);
      expect(companies.first.isExternal, isTrue);
    });

    test('sin permiso de asignar lo dice', () async {
      api.on('GET /api/tickets/assignable-teams', const FakeReply(403));
      await expectLater(
        repo.assignableTeams(),
        throwsA(
          isA<TicketsException>().having(
            (e) => e.error,
            'error',
            TicketsError.permissionDenied,
          ),
        ),
      );
    });
  });

  group('acciones', () {
    final unvalidated = ApiTicketsRepository.ticketFromDto(
      _dto('SIN_VALIDAR', actions: ['ASIGNAR']),
    );
    final attended = ApiTicketsRepository.ticketFromDto(
      _dto('ATENDIDO', actions: ['CERRAR', 'REGRESAR']),
    );

    test('asignar manda empresa, equipo, persona y version', () async {
      api.on(
        'POST /api/tickets/1/assign',
        FakeReply(200, _dto('ABIERTO', rowVersion: 5)),
      );
      after('ABIERTO', actions: ['REASIGNAR']);
      final t = await repo.assign(
        unvalidated,
        const TicketAssignment(
          companyId: 'c1',
          teamId: 't1',
          responsibleUserId: 'u1',
        ),
      );
      expect(sent('POST /api/tickets/1/assign'), {
        'companyId': 'c1',
        'teamId': 't1',
        'responsibleUserId': 'u1',
        'rowVersion': 4,
      });
      // Devuelve la ficha como quedo.
      expect(t.stage, TicketStage.open);
      expect(t.rowVersion, 5);
    });

    test('reasignar lleva el motivo', () async {
      api.on('POST /api/tickets/1/assign', FakeReply(200, _dto('ABIERTO')));
      after('ABIERTO');
      await repo.assign(
        unvalidated,
        const TicketAssignment(companyId: 'c1', teamId: 't1', reason: ' Otra '),
      );
      expect(sent('POST /api/tickets/1/assign')['reason'], 'Otra');
    });

    test('cerrar manda la observacion y la condicion del activo', () async {
      api.on('POST /api/tickets/1/close', FakeReply(200, _dto('CERRADO')));
      after('CERRADO');
      final t = await repo.close(
        attended,
        const TicketClosing(
          notes: 'Revisado en sitio',
          condition: TicketAssetCondition.fair,
        ),
      );
      expect(sent('POST /api/tickets/1/close'), {
        'notes': 'Revisado en sitio',
        'assetCondition': 'REGULAR',
        'rowVersion': 4,
      });
      expect(t.stage, TicketStage.closed);
    });

    test('cerrar sin observacion deja la condicion sin cambio', () async {
      api.on('POST /api/tickets/1/close', FakeReply(200, _dto('CERRADO')));
      after('CERRADO');
      await repo.close(attended, const TicketClosing(notes: '  '));
      expect(sent('POST /api/tickets/1/close'), {
        'assetCondition': 'SIN_CAMBIO',
        'rowVersion': 4,
      });
    });

    test('regresar y reabrir mandan el motivo', () async {
      api.on('POST /api/tickets/1/return', FakeReply(200, _dto('ABIERTO')));
      api.on('POST /api/tickets/1/reopen', FakeReply(200, _dto('ABIERTO')));
      after('ABIERTO');
      await repo.returnToOpen(attended, 'Faltan fotos');
      await repo.reopen(attended, 'Volvio a fallar');
      expect(sent('POST /api/tickets/1/return'), {
        'reason': 'Faltan fotos',
        'rowVersion': 4,
      });
      expect(sent('POST /api/tickets/1/reopen'), {
        'reason': 'Volvio a fallar',
        'rowVersion': 4,
      });
    });

    test('cancelar como duplicado manda el folio del original', () async {
      api.on('POST /api/tickets/1/cancel', FakeReply(200, _dto('CANCELADO')));
      after('CANCELADO');
      await repo.cancel(
        unvalidated,
        const TicketCancellation(
          reason: TicketCancelReason.duplicate,
          duplicateOfFolio: 'TK-2026-000007',
        ),
      );
      expect(sent('POST /api/tickets/1/cancel'), {
        'reason': 'DUPLICADO',
        'duplicateOfFolio': 'TK-2026-000007',
        'rowVersion': 4,
      });
    });

    test('lo que el servidor rechaza llega con su motivo', () async {
      api.on(
        'POST /api/tickets/1/cancel',
        const FakeReply(400, {
          'code': 'DUPLICATE_NOT_FOUND',
          'title': 'No existe un ticket con ese folio en la concesión.',
        }),
      );
      await expectLater(
        repo.cancel(
          unvalidated,
          const TicketCancellation(
            reason: TicketCancelReason.duplicate,
            duplicateOfFolio: 'TK-1',
          ),
        ),
        throwsA(
          isA<TicketActionRejected>().having(
            (e) => e.reason,
            'reason',
            'No existe un ticket con ese folio en la concesión. '
                '(DUPLICATE_NOT_FOUND)',
          ),
        ),
      );
    });

    test('otra persona ya lo cambio: 409 es un rechazo', () async {
      api.on(
        'POST /api/tickets/1/close',
        const FakeReply(409, {'code': 'CONCURRENCY_CONFLICT'}),
      );
      await expectLater(
        repo.close(attended, const TicketClosing()),
        throwsA(isA<TicketActionRejected>()),
      );
    });

    test('sin red o sin permiso es un fallo, no un rechazo', () async {
      api.on('POST /api/tickets/1/close', const FakeReply(403));
      await expectLater(
        repo.close(attended, const TicketClosing()),
        throwsA(
          isA<TicketsException>().having(
            (e) => e.error,
            'error',
            TicketsError.permissionDenied,
          ),
        ),
      );
      api.offline = true;
      await expectLater(
        repo.returnToOpen(attended, 'x'),
        throwsA(
          isA<TicketsException>().having(
            (e) => e.error,
            'error',
            TicketsError.network,
          ),
        ),
      );
    });

    test('si la ficha no se puede volver a pedir, usa la respuesta', () async {
      api.on(
        'POST /api/tickets/1/close',
        FakeReply(200, _dto('CERRADO', rowVersion: 6)),
      );
      api.on('GET /api/tickets/1', const FakeReply(500));
      final t = await repo.close(attended, const TicketClosing());
      expect(t.stage, TicketStage.closed);
      expect(t.rowVersion, 6);
    });
  });
}
