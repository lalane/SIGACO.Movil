import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/unavailable_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/follow_up_cubit.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/ticket_detail_cubit.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/tickets_cubit.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);
  late SampleTicketsRepository repo;

  setUp(() => repo = SampleTicketsRepository(clock: () => now));

  TicketsCubit build() => TicketsCubit(repo, clock: () => now);

  group('SampleTicketsRepository', () {
    test('trae los tickets de ejemplo, solo abiertos o atendidos', () async {
      final tickets = await repo.list();
      expect(tickets, hasLength(8));
      expect(tickets.map((t) => t.status).toSet(), {
        TicketStatus.open,
        TicketStatus.attended,
      });
    });

    test('un ticket que no existe da notFound', () async {
      await expectLater(
        repo.get('T-9999'),
        throwsA(
          isA<TicketsException>().having(
            (e) => e.error,
            'error',
            TicketsError.notFound,
          ),
        ),
      );
    });

    test('un seguimiento cambia el estado y queda arriba', () async {
      final updated = await repo.addFollowUp(
        'T-0036',
        NewFollowUp(
          at: now,
          status: TicketStatus.attended,
          description: 'Se rellenó el bache.',
          photoPaths: const ['/tmp/a.jpg'],
        ),
      );
      expect(updated.status, TicketStatus.attended);
      expect(updated.followUps.first.description, 'Se rellenó el bache.');
      expect((await repo.get('T-0036')).status, TicketStatus.attended);
    });

    test('un ticket nuevo entra abierto y primero', () async {
      final created = await repo.create(
        const NewTicket(title: 'Bache nuevo', category: 'Pavimento'),
      );
      expect(created.status, TicketStatus.open);
      expect((await repo.list()).first.id, created.id);
      expect(created.dueAt, isNotNull);
    });

    test('da las categorias del catalogo', () async {
      expect(await repo.categories(), contains('Pavimento'));
    });
  });

  group('TicketsCubit', () {
    test('carga y cuenta por estado', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, TicketsStatus.ready);
      expect(cubit.state.count(TicketFilter.all), 8);
      expect(cubit.state.count(TicketFilter.open), 4);
      expect(cubit.state.count(TicketFilter.attended), 4);
    });

    test('lo mas reciente va primero', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.visible.first.id, 'T-0036');
    });

    test('filtra por estado', () async {
      final cubit = build();
      await cubit.load();
      cubit.setFilter(TicketFilter.open);
      expect(
        cubit.state.visible.every((t) => t.status == TicketStatus.open),
        isTrue,
      );
      expect(cubit.state.visible, hasLength(4));
    });

    test('busca por titulo, numero y cadenamiento', () async {
      final cubit = build();
      await cubit.load();
      cubit.setQuery('barrera');
      expect(cubit.state.visible.map((t) => t.id), {'T-0035', 'T-0040'});
      cubit.setQuery('0036');
      expect(cubit.state.visible.map((t) => t.id), ['T-0036']);
      cubit.setQuery('147+200');
      expect(cubit.state.visible.map((t) => t.id), ['T-0036']);
      cubit.setQuery('   ');
      expect(cubit.state.visible, hasLength(8));
    });

    test('por vencimiento van primero los vencidos', () async {
      final cubit = build();
      await cubit.load();
      cubit.toggleSortByDue();
      final ids = cubit.state.visible.map((t) => t.id).toList();
      expect(ids.take(3), ['T-0038', 'T-0036', 'T-0035']);
      expect(cubit.state.hasActiveFilters, isTrue);
    });

    test('quitar los filtros lo deja como al inicio', () async {
      final cubit = build();
      await cubit.load();
      cubit
        ..setFilter(TicketFilter.open)
        ..setQuery('x')
        ..toggleSortByDue()
        ..clearFilters();
      expect(cubit.state.hasActiveFilters, isFalse);
      expect(cubit.state.visible, hasLength(8));
    });

    test('sin endpoints dice que no esta disponible', () async {
      final cubit = TicketsCubit(const UnavailableTicketsRepository());
      await cubit.load();
      expect(cubit.state.status, TicketsStatus.failure);
      expect(cubit.state.error, TicketsError.notAvailable);
    });

    test('un vencimiento negativo es un ticket vencido', () async {
      final tickets = await repo.list();
      final overdue = tickets.firstWhere((t) => t.id == 'T-0038');
      expect(overdue.timeToDue(now)!.isNegative, isTrue);
    });
  });

  group('TicketDetailCubit', () {
    test('carga la ficha', () async {
      final cubit = TicketDetailCubit(repo, 'T-0035');
      await cubit.load();
      expect(cubit.state.status, TicketDetailStatus.ready);
      expect(cubit.state.ticket!.code, '0035');
    });

    test('un ticket que no existe falla con notFound', () async {
      final cubit = TicketDetailCubit(repo, 'T-9999');
      await cubit.load();
      expect(cubit.state.status, TicketDetailStatus.failure);
      expect(cubit.state.error, TicketsError.notFound);
    });
  });

  group('FollowUpCubit', () {
    FollowUpCubit form() => FollowUpCubit(repo, 'T-0036', clock: () => now);

    test('empieza con la fecha y hora de ahora', () {
      final cubit = form();
      expect(cubit.state.minutes, isNonNegative);
      expect(cubit.state.date.year, greaterThanOrEqualTo(2026));
      expect(cubit.state.status, isNull);
    });

    test('sin estado ni descripcion no guarda y avisa', () async {
      final cubit = form();
      await cubit.save();
      expect(cubit.state.showIssues, isTrue);
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.issues, [
        FollowUpIssue.status,
        FollowUpIssue.description,
      ]);
      expect((await repo.get('T-0036')).followUps, isEmpty);
    });

    test('guarda con estado, descripcion y fotos', () async {
      final cubit = form()
        ..setStatus(TicketStatus.attended)
        ..setDescription('  Listo  ')
        ..setPhoto(0, '/tmp/1.jpg')
        ..setPhoto(2, '/tmp/3.jpg');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      final ticket = await repo.get('T-0036');
      expect(ticket.status, TicketStatus.attended);
      expect(ticket.followUps.first.description, 'Listo');
      expect(ticket.followUps.first.photoPaths, ['/tmp/1.jpg', '/tmp/3.jpg']);
    });

    test('quitar una foto deja el hueco vacio', () {
      final cubit = form()
        ..setPhoto(1, '/tmp/2.jpg')
        ..setPhoto(1, null);
      expect(cubit.state.photos, [null, null, null]);
    });

    test('si falla el guardado lo marca y deja reintentar', () async {
      final cubit = FollowUpCubit(
        const UnavailableTicketsRepository(),
        'T-0036',
        clock: () => now,
      )..setStatus(TicketStatus.open);
      cubit.setDescription('x');
      await cubit.save();
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.saving, isFalse);
    });
  });

  group('NewTicketCubit', () {
    test('carga las categorias', () async {
      final cubit = NewTicketCubit(repo);
      await cubit.load();
      expect(cubit.state.categoriesLoaded, isTrue);
      expect(cubit.state.categories, isNotEmpty);
    });

    test('pide titulo y tipo', () async {
      final cubit = NewTicketCubit(repo);
      await cubit.save();
      expect(cubit.state.issues, [
        NewTicketIssue.title,
        NewTicketIssue.category,
      ]);
      expect(cubit.state.saved, isFalse);
    });

    test('crea el ticket con lo capturado', () async {
      final cubit = NewTicketCubit(repo)
        ..setTitle(' Señal caída ')
        ..setCategory('Señalización')
        ..setKm('KM 150+200')
        ..setDescription('')
        ..setPhoto(0, '/tmp/1.jpg');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      final created = (await repo.list()).first;
      expect(created.title, 'Señal caída');
      expect(created.kmLabel, 'KM 150+200');
      expect(created.description, isNull);
      expect(created.photoPaths, ['/tmp/1.jpg']);
    });
  });
}
