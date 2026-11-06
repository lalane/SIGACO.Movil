import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

/// Ejemplos que ubican el punto con la respuesta dada y guardan lo recibido.
class _PlacedRepo extends SampleTicketsRepository
    implements TicketPlacementSource {
  _PlacedRepo(this.placement);

  final TicketPlacement placement;
  NewTicket? created;
  int asked = 0;

  @override
  Future<TicketPlacement> place(double longitude, double latitude) async {
    asked++;
    return placement;
  }

  @override
  Future<Ticket> create(NewTicket draft) {
    created = draft;
    return super.create(draft);
  }
}

const _point = TicketLocation(
  latitude: -19.53,
  longitude: -42.61,
  origin: TicketLocationOrigin.mapPoint,
);

const _onRoad = TicketPlacement(
  status: TicketPlacementStatus.onRoad,
  km: 146.9,
  direction: 'CRECIENTE',
  segmentCode: '381BMG0100',
  distanceMeters: 12,
);

Future<NewTicketCubit> _ready(_PlacedRepo repo, {TicketLocation? at}) async {
  final cubit = NewTicketCubit(repo, location: at ?? _point);
  await cubit.load();
  // La ubicacion corre aparte de la carga del catalogo.
  await Future<void>.delayed(Duration.zero);
  cubit
    ..setTitle('Bache')
    ..setCategory(cubit.state.categories.first);
  return cubit;
}

/// El punto del ticket tiene que caer sobre la carretera (decision del
/// 06/11/2026): sobre ella llena km y sentido; lejos, no se guarda.
void main() {
  test('sobre la carretera llena el km y manda el sentido', () async {
    final repo = _PlacedRepo(_onRoad);
    final cubit = await _ready(repo);
    expect(cubit.state.kmLabel, 'KM 146+900');
    expect(cubit.state.issues, isEmpty);

    await cubit.save();
    expect(repo.created!.direction, 'CRECIENTE');
    expect(repo.created!.kmLabel, 'KM 146+900');
  });

  test('con los dos sentidos en el mismo trazo no manda sentido', () async {
    final repo = _PlacedRepo(
      const TicketPlacement(
        status: TicketPlacementStatus.onRoad,
        km: 146.9,
        direction: 'CRECIENTE',
        directionAmbiguous: true,
      ),
    );
    final cubit = await _ready(repo);
    await cubit.save();
    expect(repo.created!.direction, isNull);
  });

  test('lejos de la carretera no se guarda', () async {
    final repo = _PlacedRepo(const TicketPlacement.offRoad());
    final cubit = await _ready(repo);
    expect(cubit.state.issues, contains(NewTicketIssue.offRoad));

    await cubit.save();
    expect(repo.created, isNull);
    expect(cubit.state.showIssues, isTrue);
  });

  test('sin red no se puede saber y el servidor lo revisa', () async {
    final repo = _PlacedRepo(const TicketPlacement.unknown());
    final cubit = await _ready(repo);
    expect(cubit.state.issues, isEmpty);
    await cubit.save();
    expect(repo.created, isNotNull);
    expect(repo.created!.direction, isNull);
  });

  test('un ticket desde un activo no se ubica', () async {
    final repo = _PlacedRepo(const TicketPlacement.offRoad());
    final cubit = await _ready(
      repo,
      at: const TicketLocation(
        latitude: -19.53,
        longitude: -42.61,
        origin: TicketLocationOrigin.asset,
        assetId: 'A-1',
      ),
    );
    expect(repo.asked, 0);
    expect(cubit.state.issues, isEmpty);
  });
}
