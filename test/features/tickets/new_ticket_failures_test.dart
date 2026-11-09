import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/tickets/data/repositories/sample_tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';
import 'package:sigaco_movil/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:sigaco_movil/features/tickets/presentation/bloc/new_ticket_cubit.dart';

/// Ejemplos con catalogo de fallas: guarda lo que recibe.
class _MatrixRepo extends SampleTicketsRepository
    implements TicketFailureSource {
  NewTicket? created;

  @override
  Future<List<TicketFailure>> failures() async => const [
    TicketFailure(
      code: 'SGP_1',
      label: 'Buraco',
      subsystemCode: 'SGP',
      group: 'Buracos',
      attentionHours: 720,
      attentionLabel: '30 dias',
    ),
    TicketFailure(
      code: 'SGP_2',
      label: 'Derramamento perigoso',
      subsystemCode: 'SGP',
      group: 'Risco imediato',
      attentionHours: 24,
      attentionLabel: 'Imediato',
    ),
    TicketFailure(
      code: 'SGS_1',
      label: 'Tacha ausente',
      subsystemCode: 'SGS',
      group: 'Sinalização horizontal',
      attentionHours: 720,
      attentionLabel: '30 dias',
    ),
  ];

  @override
  Future<Ticket> create(NewTicket draft) {
    created = draft;
    return super.create(draft);
  }
}

/// El alta por la Matriz de falhas: indicador, subclasificacion y falla, con el
/// plazo fijo (reunion con TEKIA del 05/11/2026).
void main() {
  test('solo ofrece las fallas de los indicadores asignados', () async {
    final cubit = NewTicketCubit(
      _MatrixRepo(),
      allowedIndicators: () async => {'SGP'},
    );
    await cubit.load();
    expect(cubit.state.usesMatrix, isTrue);
    expect(cubit.state.indicators, ['SGP']);
  });

  test('sin saber los indicadores ofrece todos', () async {
    final cubit = NewTicketCubit(_MatrixRepo());
    await cubit.load();
    expect(cubit.state.indicators, ['SGP', 'SGS']);
  });

  test(
    'la cascada se reinicia al cambiar arriba y la falla da el plazo',
    () async {
      final repo = _MatrixRepo();
      final cubit = NewTicketCubit(repo);
      await cubit.load();

      cubit.setIndicator('SGP');
      expect(cubit.state.groups, ['Buracos', 'Risco imediato']);
      cubit.setGroup('Risco imediato');
      expect(cubit.state.groupFailures.map((f) => f.code), ['SGP_2']);
      cubit.setCategory('SGP_2');
      expect(cubit.state.failure!.immediate, isTrue);

      cubit.setGroup('Buracos');
      expect(cubit.state.category, isNull, reason: 'otra subclasificacion');
      cubit.setCategory('SGP_1');
      expect(cubit.state.failure!.days, 30);
      cubit.setIndicator('SGS');
      expect((cubit.state.group, cubit.state.category), (null, null));

      cubit
        ..setIndicator('SGP')
        ..setGroup('Buracos')
        ..setCategory('SGP_1')
        ..setTitle('Buraco grande')
        ..setDescription('En el carril derecho');
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(repo.created!.category, 'SGP_1');
      expect(repo.created!.fixedAttention, isTrue);
    },
  );

  test('sin catalogo de fallas queda la lista plana', () async {
    final cubit = NewTicketCubit(SampleTicketsRepository());
    await cubit.load();
    expect(cubit.state.usesMatrix, isFalse);
    expect(cubit.state.categories, isNotEmpty);
  });

  group('desde la ficha de un activo', () {
    const asset = TicketAssetRef(
      id: 'a-1',
      code: 'TACHA-000001',
      kmLabel: 'KM 150+200',
      kmEndLabel: 'KM 151+000',
      subsystemCode: 'sgs',
    );

    test('precarga su km, propone su indicador y manda el activo', () async {
      final repo = _MatrixRepo();
      final cubit = NewTicketCubit(repo, asset: asset);
      expect(cubit.state.kmLabel, 'KM 150+200');
      expect(cubit.state.kmEndLabel, 'KM 151+000');
      await cubit.load();
      expect(cubit.state.indicator, 'SGS');

      cubit
        ..setGroup('Sinalização horizontal')
        ..setCategory('SGS_1')
        ..setTitle('Tacha suelta')
        ..setDescription('Sobre el carril izquierdo');
      // Sin punto no hay nada que ubicar ni que avisar del GPS.
      expect(cubit.location?.issue(30), isNull);
      expect(cubit.state.issues, isEmpty);
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(repo.created!.assetId, 'a-1');
      expect(repo.created!.location, isNull);
      expect(repo.created!.kmEndLabel, 'KM 151+000');
    });

    test('un indicador que la persona no tiene no se propone', () async {
      final cubit = NewTicketCubit(
        _MatrixRepo(),
        asset: asset,
        allowedIndicators: () async => {'SGP'},
      );
      await cubit.load();
      expect(cubit.state.indicator, isNull);
    });
  });
}
