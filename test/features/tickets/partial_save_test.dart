import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/follow_up_cubit.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

import '../../support/fake_api.dart';

const _config = {
  'operationalCatalogs': {
    'ticketTypes': [
      {'code': 'GENERAL', 'labelEs': 'General', 'sortOrder': 1, 'active': true},
    ],
  },
};

Map<String, Object?> _dto(String id) => {
  'id': id,
  'folio': 'TK-2026-0001',
  'ticketTypeLabel': 'General',
  'status': 'NUEVO',
  'description': 'test',
  'detectedAt': '2026-10-28T15:00:00Z',
  'rowVersion': 1,
};

class _Repo extends Fake implements TicketsRepository {
  _Repo({this.partial});

  final String? partial;
  var created = 0;

  @override
  Future<List<String>> categories() async => ['General'];

  @override
  Future<Ticket> create(NewTicket draft) async {
    created++;
    final reason = partial;
    if (reason != null) throw TicketPartiallySavedException(reason);
    return Ticket(
      id: 't1',
      code: 'TK-1',
      title: draft.title,
      status: TicketStatus.open,
      createdAt: DateTime.utc(2026, 10, 28),
    );
  }

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) async {
    final reason = partial;
    if (reason != null) throw TicketPartiallySavedException(reason);
    return Ticket(
      id: ticketId,
      code: 'TK-1',
      title: '',
      status: TicketStatus.open,
      createdAt: DateTime.utc(2026, 10, 28),
    );
  }
}

/// Crear un registro con fotos: si el servidor lo guarda pero rechaza las fotos,
/// la persona debe saberlo y no creer que todo fallo (APP-MOB-01, tickets).
void main() {
  late Directory dir;
  late File photo;
  late FakeApi api;
  late ApiTicketsRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ps_');
    photo = File('${dir.path}/f.jpg')..writeAsBytesSync([1, 2, 3]);
    api = FakeApi()
      ..on('GET /api/app-configuration', const FakeReply(200, _config))
      ..on('POST /api/tickets', FakeReply(201, _dto('t1')));
    repo = ApiTicketsRepository(api.client(), roadId: () async => 'road-1');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    });
  });

  NewTicket draft() => NewTicket(
    title: 'test',
    category: 'General',
    photoPaths: [photo.path],
    capturedAt: DateTime.utc(2026, 10, 28, 15),
    clientId: 'c0a80101-0000-4000-8000-000000000001',
  );

  group('con el servidor', () {
    test(
      'el ticket se crea una vez y las fotos rechazadas se explican',
      () async {
        await repo.categories();
        api.on(
          'POST /api/tickets/t1/attachments',
          const FakeReply(409, {
            'code': 'STORAGE_NOT_CONFIGURED',
            'title':
                'El ambiente no tiene almacenamiento de archivos configurado.',
          }),
        );

        await expectLater(
          repo.create(draft()),
          throwsA(
            isA<TicketPartiallySavedException>().having(
              (e) => e.reason,
              'reason',
              allOf(
                contains('almacenamiento'),
                contains('STORAGE_NOT_CONFIGURED'),
              ),
            ),
          ),
        );
        expect(api.to('POST /api/tickets'), hasLength(1));
      },
    );

    test('toma el motivo por campo si el servidor lo da', () async {
      await repo.categories();
      api.on(
        'POST /api/tickets/t1/attachments',
        const FakeReply(400, {
          'code': 'VALIDATION_FAILED',
          'errors': {
            'file': ['Una FOTO debe ser una imagen.'],
          },
        }),
      );
      await expectLater(
        repo.create(draft()),
        throwsA(
          isA<TicketPartiallySavedException>().having(
            (e) => e.reason,
            'reason',
            'Una FOTO debe ser una imagen. (VALIDATION_FAILED)',
          ),
        ),
      );
    });

    test('sin motivo ni codigo, al menos el estado', () async {
      await repo.categories();
      api.on('POST /api/tickets/t1/attachments', const FakeReply(500, {}));
      await expectLater(
        repo.create(draft()),
        throwsA(
          isA<TicketPartiallySavedException>().having(
            (e) => e.reason,
            'reason',
            '500',
          ),
        ),
      );
    });

    test(
      'un corte justo al subir las fotos sigue siendo fallo de red',
      () async {
        await repo.categories();
        // El ticket se crea y la conexion cae en las fotos: se encola entero.
        api.failingRoutes.add('POST /api/tickets/t1/attachments');
        await expectLater(
          repo.create(draft()),
          throwsA(
            isA<TicketsException>().having(
              (e) => e.error,
              'error',
              TicketsError.network,
            ),
          ),
        );
      },
    );

    test('las fotos de un seguimiento tambien se explican', () async {
      api
        ..on(
          'POST /api/tickets/t1/follow-ups',
          const FakeReply(201, {'id': 'f1'}),
        )
        ..on(
          'POST /api/tickets/t1/attachments',
          const FakeReply(409, {'code': 'STORAGE_NOT_CONFIGURED'}),
        );
      await expectLater(
        repo.addFollowUp(
          't1',
          NewFollowUp(
            at: DateTime.utc(2026, 10, 28, 16),
            status: TicketStatus.attended,
            description: 'ok',
            photoPaths: [photo.path],
          ),
        ),
        throwsA(isA<TicketPartiallySavedException>()),
      );
      expect(api.to('POST /api/tickets/t1/follow-ups'), hasLength(1));
    });
  });

  group('formularios', () {
    test('el registro guardado con un aviso cuenta como guardado', () async {
      final cubit =
          NewTicketCubit(_Repo(partial: 'Una FOTO debe ser una imagen.'))
            ..setTitle('test')
            ..setDescription('detalle')
            ..setCategory('General');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.failed, isFalse);
      expect(cubit.state.warning, 'Una FOTO debe ser una imagen.');
    });

    test('sin aviso no hay advertencia', () async {
      final cubit = NewTicketCubit(_Repo())
        ..setTitle('test')
        ..setDescription('detalle')
        ..setCategory('General');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.warning, isNull);
    });

    test('el seguimiento tambien guarda con aviso', () async {
      final cubit = FollowUpCubit(_Repo(partial: 'sin almacenamiento'), 't1')
        ..setStatus(TicketStatus.attended)
        ..setDescription('ok');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.warning, 'sin almacenamiento');
    });
  });
}
