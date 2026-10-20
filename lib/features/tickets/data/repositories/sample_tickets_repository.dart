import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Tickets de ejemplo sobre la BR-381, para ver el modulo mientras el backend
/// no publica los suyos. Viven en memoria: crear un ticket o un seguimiento los
/// cambia hasta que se cierra la app. No son tickets reales.
class SampleTicketsRepository implements TicketsRepository {
  SampleTicketsRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) : _clock = clock ?? DateTime.now {
    _tickets = _seed(_clock().toUtc());
  }

  final DateTime Function() _clock;

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  late List<Ticket> _tickets;
  var _next = 100;

  static const _concession = 'NOVA 361';

  static const categoryNames = [
    'Defensa dañada',
    'Señalización',
    'Pavimento',
    'Iluminación',
    'Limpieza',
  ];

  static List<Ticket> _seed(DateTime now) {
    Ticket t(
      String code,
      String title,
      TicketStatus status, {
      required Duration age,
      Duration? due,
      String? category,
      String? km,
      String? description,
      String author = 'Ana Herrera',
      List<TicketFollowUp> followUps = const [],
    }) => Ticket(
      id: 'T-$code',
      code: code,
      title: title,
      status: status,
      createdAt: now.subtract(age),
      dueAt: due == null ? null : now.add(due),
      description: description,
      category: category,
      authorName: author,
      authorProfile: 'Supervisor',
      company: 'TEKIA',
      concessionName: _concession,
      kmLabel: km,
      latitude: -18.8461,
      longitude: -41.9807,
      carriageway: 'B',
      followUps: followUps,
    );
    return [
      t(
        '0035',
        'Barrera de contención dañada km 513+615 – tramo sur',
        TicketStatus.attended,
        age: const Duration(days: 2),
        due: const Duration(hours: 12),
        category: 'Defensa dañada',
        km: 'KM 513+615',
        description:
            'Choque contra la defensa metálica. Hay un tramo de 6 metros deformado.',
        followUps: [
          TicketFollowUp(
            id: 'F-1',
            at: now.subtract(const Duration(hours: 20)),
            status: TicketStatus.attended,
            description: 'Cuadrilla en sitio, se balizó el carril derecho.',
          ),
        ],
      ),
      t(
        '0036',
        'Pozo en el carril derecho km 147+200',
        TicketStatus.open,
        age: const Duration(days: 1),
        due: const Duration(hours: 3),
        category: 'Pavimento',
        km: 'KM 147+200',
        description: 'Bache de unos 40 cm que ya dañó dos neumáticos.',
      ),
      t(
        '0037',
        'Señal vertical caída km 148+000',
        TicketStatus.open,
        age: const Duration(hours: 30),
        due: const Duration(days: 3),
        category: 'Señalización',
        km: 'KM 148+000',
        author: 'Luis Prado',
      ),
      t(
        '0038',
        'Luminarias apagadas en el túnel norte',
        TicketStatus.open,
        age: const Duration(days: 4),
        due: const Duration(hours: -6),
        category: 'Iluminación',
        km: 'KM 150+300',
        author: 'Luis Prado',
      ),
      t(
        '0039',
        'Limpieza de cunetas km 152+500',
        TicketStatus.attended,
        age: const Duration(days: 3),
        due: const Duration(days: 2),
        category: 'Limpieza',
        km: 'KM 152+500',
      ),
      t(
        '0040',
        'Barrera New Jersey con grieta km 154+100',
        TicketStatus.attended,
        age: const Duration(days: 9),
        due: const Duration(days: 5),
        category: 'Defensa dañada',
        km: 'KM 154+100',
        followUps: [
          TicketFollowUp(
            id: 'F-2',
            at: now.subtract(const Duration(days: 5)),
            status: TicketStatus.attended,
            description: 'Se sustituyó el módulo y se verificó el anclaje.',
          ),
        ],
      ),
      t(
        '0041',
        'Pintura de balizamiento borrada km 149+800',
        TicketStatus.open,
        age: const Duration(days: 12),
        due: const Duration(days: 1),
        category: 'Señalización',
        km: 'KM 149+800',
        author: 'Luis Prado',
      ),
      t(
        '0042',
        'Hundimiento en el acotamiento km 151+000',
        TicketStatus.attended,
        age: const Duration(days: 6),
        due: const Duration(days: 1),
        category: 'Pavimento',
        km: 'KM 151+000',
      ),
    ];
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<Ticket>> list() async {
    await _wait();
    return List.unmodifiable(_tickets);
  }

  @override
  Future<Ticket> get(String id) async {
    await _wait();
    return _tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw const TicketsException(TicketsError.notFound),
    );
  }

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) async {
    await _wait();
    final i = _tickets.indexWhere((t) => t.id == ticketId);
    if (i < 0) throw const TicketsException(TicketsError.notFound);
    final current = _tickets[i];
    final updated = current.copyWith(
      status: followUp.status,
      followUps: [
        TicketFollowUp(
          id: 'F-${_next++}',
          at: followUp.at,
          status: followUp.status,
          description: followUp.description,
          photoPaths: followUp.photoPaths,
        ),
        ...current.followUps,
      ],
    );
    _tickets = [..._tickets]..[i] = updated;
    return updated;
  }

  @override
  Future<Ticket> create(NewTicket draft) async {
    await _wait();
    final n = _next++;
    final now = draft.capturedAt ?? _clock().toUtc();
    final created = Ticket(
      id: 'T-$n',
      code: n.toString().padLeft(4, '0'),
      title: draft.title,
      status: TicketStatus.open,
      createdAt: now,
      dueAt: now.add(const Duration(days: 3)),
      description: draft.description,
      category: draft.category,
      authorName: 'Usuario de ejemplo',
      authorProfile: 'Supervisor',
      company: 'TEKIA',
      concessionName: _concession,
      kmLabel: draft.kmLabel ?? draft.location?.kmLabel,
      latitude: draft.location?.latitude,
      longitude: draft.location?.longitude,
      photoPaths: draft.photoPaths,
    );
    _tickets = [created, ..._tickets];
    return created;
  }

  @override
  Future<List<String>> categories() async {
    await _wait();
    return categoryNames;
  }
}
