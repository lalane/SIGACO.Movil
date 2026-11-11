import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

import '../../support/fake_api.dart';

/// Ejemplos con las carreteras que se le digan; guarda lo que recibe.
class _Roads extends SampleTicketsRepository implements TicketRoadSource {
  _Roads(this._roads);

  final List<TicketRoad> _roads;
  NewTicket? created;

  @override
  Future<List<TicketRoad>> roads() async => _roads;

  @override
  Future<Ticket> create(NewTicket draft) {
    created = draft;
    return super.create(draft);
  }
}

const _br381 = TicketRoad(id: 'r381', code: 'BR-381');
const _br303 = TicketRoad(id: 'r303', code: 'BR-303');

/// Un ticket sin punto ni activo en una concesion con varias carreteras: el
/// servidor no puede deducir la carretera, asi que el formulario la pide (se
/// encontro en la prueba de punta a punta: NOVA tiene BR-381 y BR-303 y el alta
/// desde la lista respondia 400 sin decir por que).
void main() {
  Future<NewTicketCubit> filled(TicketsRepository repo) async {
    final cubit = NewTicketCubit(repo);
    await cubit.load();
    // Las carreteras llegan aparte.
    await Future<void>.delayed(Duration.zero);
    cubit
      ..setTitle('Bache')
      ..setDescription('Bache en el carril derecho')
      ..setCategory(cubit.state.categories.first)
      ..setKm('KM 147+050');
    return cubit;
  }

  test('con varias carreteras pide elegir una y la manda', () async {
    final repo = _Roads(const [_br381, _br303]);
    final cubit = await filled(repo);
    expect(cubit.state.roads, [_br381, _br303]);
    expect(cubit.state.issues, contains(NewTicketIssue.road));

    await cubit.save();
    expect(repo.created, isNull);
    expect(cubit.state.showIssues, isTrue);

    cubit.setRoad('r381');
    expect(cubit.state.issues, isNot(contains(NewTicketIssue.road)));
    await cubit.save();
    expect(repo.created?.roadId, 'r381');
  });

  test('con una sola carretera no pregunta', () async {
    final repo = _Roads(const [_br381]);
    final cubit = await filled(repo);
    expect(cubit.state.roads, isEmpty);
    await cubit.save();
    expect(repo.created?.roadId, isNull);
  });

  test('con punto del mapa no pregunta: la carretera sale del punto', () async {
    final repo = _Roads(const [_br381, _br303]);
    final cubit = NewTicketCubit(
      repo,
      location: const TicketLocation(
        latitude: -18.847,
        longitude: -41.98,
        origin: TicketLocationOrigin.mapPoint,
      ),
    );
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.roads, isEmpty);
  });

  group('contra el servidor', () {
    late FakeApi api;
    late ApiTicketsRepository repo;

    setUp(() {
      api = FakeApi();
      repo = ApiTicketsRepository(api.client(), roadId: () async => null);
    });

    test('las carreteras salen del contexto de la sesion', () async {
      api.on(
        'GET /api/auth/me',
        const FakeReply(200, {
          'context': {
            'roads': [
              {'id': 'r303', 'code': 'BR-303', 'name': 'BR-303'},
              {'id': 'r381', 'code': 'BR-381', 'name': 'BR-381'},
            ],
          },
        }),
      );
      final roads = await repo.roads();
      expect(roads.map((r) => r.code), ['BR-303', 'BR-381']);
    });

    test('la carretera elegida va en el alta', () async {
      final body = await repo.ticketBody(
        const NewTicket(
          title: 'Bache',
          category: 'SGP_1',
          fixedAttention: true,
          roadId: 'r381',
          kmLabel: 'KM 147+050',
        ),
      );
      expect(body['roadId'], 'r381');
      expect(body['kmStart'], 147.05);
    });
  });
}
