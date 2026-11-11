import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_supervision.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Tickets de ejemplo sobre la BR-381, para ver el modulo mientras el backend
/// no publica los suyos. Viven en memoria: crear un ticket o un seguimiento los
/// cambia hasta que se cierra la app. No son tickets reales. Quien los ve hace
/// de Supervisor: puede asignar, cerrar y regresar (como en la app, cancelar y
/// reabrir quedan para la web).
class SampleTicketsRepository implements TicketsRepository, TicketSupervision {
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

  /// La empresa y los equipos de ejemplo a los que se asigna.
  static const _company = TicketAssignableCompany(
    id: 'E-1',
    name: 'Conserva Vial',
    isExternal: true,
    teams: [
      TicketAssignableTeam(
        id: 'EQ-1',
        name: 'Cuadrilla Norte',
        members: [
          TicketTeamMember(userId: 'U-1', fullName: 'Marta Ruiz'),
          TicketTeamMember(userId: 'U-2', fullName: 'Pedro Gil'),
        ],
      ),
      TicketAssignableTeam(
        id: 'EQ-2',
        name: 'Cuadrilla Sur',
        members: [TicketTeamMember(userId: 'U-3', fullName: 'Rosa Lima')],
      ),
    ],
  );

  static const _companies = [
    _company,
    TicketAssignableCompany(
      id: 'E-2',
      name: 'NOVA Operación',
      teams: [
        TicketAssignableTeam(
          id: 'EQ-3',
          name: 'Señalización',
          members: [TicketTeamMember(userId: 'U-4', fullName: 'Luis Prado')],
        ),
      ],
    ),
  ];

  /// Lo que un Supervisor puede hacer desde la app en cada estado (lo mismo que
  /// ofrece el servidor; cancelar y reabrir son de la web).
  static Set<TicketAction> actionsFor(TicketStage stage) => switch (stage) {
    TicketStage.unvalidated => {
      TicketAction.edit,
      TicketAction.assign,
      TicketAction.followUp,
    },
    TicketStage.open => {
      TicketAction.edit,
      TicketAction.reassign,
      TicketAction.followUp,
      TicketAction.attend,
    },
    TicketStage.attended => {
      TicketAction.edit,
      TicketAction.followUp,
      TicketAction.close,
      TicketAction.returnToOpen,
    },
    TicketStage.closed || TicketStage.cancelled => const {},
  };

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
      TicketStage? stage,
      String? asset,
    }) {
      final s =
          stage ??
          (status == TicketStatus.open
              ? TicketStage.open
              : TicketStage.attended);
      final assigned = s != TicketStage.unvalidated;
      return Ticket(
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
        stage: s,
        actions: actionsFor(s),
        rowVersion: 1,
        assignedCompanyId: assigned ? _company.id : null,
        assignedCompanyName: assigned ? _company.name : null,
        assignedTeamId: assigned ? _company.teams.first.id : null,
        assignedTeamName: assigned ? _company.teams.first.name : null,
        assetId: asset,
      );
    }

    return [
      t(
        '0035',
        'Barrera de contención dañada km 513+615 – tramo sur',
        TicketStatus.attended,
        age: const Duration(days: 2),
        due: const Duration(hours: 12),
        category: 'Defensa dañada',
        km: 'KM 513+615',
        asset: 'DEFENSA-000513',
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
        stage: TicketStage.unvalidated,
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
        stage: TicketStage.unvalidated,
      ),
      t(
        '0042',
        'Hundimiento en el acotamiento km 151+000',
        TicketStatus.attended,
        age: const Duration(days: 6),
        due: const Duration(days: 1),
        category: 'Pavimento',
        km: 'KM 151+000',
        stage: TicketStage.closed,
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
    final stage = followUp.status == TicketStatus.attended
        ? TicketStage.attended
        : (current.stage.pending ? current.stage : TicketStage.open);
    final updated = current.copyWith(
      status: followUp.status,
      stage: stage,
      actions: actionsFor(stage),
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
      // Nace sin validar: lo asigna el Supervisor (D-11-03).
      stage: TicketStage.unvalidated,
      actions: actionsFor(TicketStage.unvalidated),
      rowVersion: 1,
    );
    _tickets = [created, ..._tickets];
    return created;
  }

  @override
  Future<List<TicketAssignableCompany>> assignableTeams() async {
    await _wait();
    return _companies;
  }

  /// Cambia el ticket si [action] se ofrece en su estado; si no, lo rechaza
  /// como el servidor.
  Future<Ticket> _step(
    Ticket ticket,
    TicketAction action,
    Ticket Function(Ticket current) change, {
    required TicketStatus status,
    required String note,
  }) async {
    await _wait();
    final i = _tickets.indexWhere((t) => t.id == ticket.id);
    if (i < 0) throw const TicketsException(TicketsError.notFound);
    final current = _tickets[i];
    if (!actionsFor(current.stage).contains(action)) {
      throw const TicketActionRejected('TRANSITION_NOT_ALLOWED');
    }
    final changed = change(current);
    final updated = changed.copyWith(
      status: status,
      actions: actionsFor(changed.stage),
      rowVersion: (current.rowVersion ?? 0) + 1,
      followUps: [
        TicketFollowUp(
          id: 'F-${_next++}',
          at: _clock().toUtc(),
          status: status,
          description: note,
        ),
        ...current.followUps,
      ],
    );
    _tickets = [..._tickets]..[i] = updated;
    return updated;
  }

  @override
  Future<Ticket> assign(Ticket ticket, TicketAssignment assignment) async {
    final company = _companies.firstWhere(
      (c) => c.id == assignment.companyId,
      orElse: () => throw const TicketActionRejected('COMPANY_NOT_FOUND'),
    );
    final team = company.teams.firstWhere(
      (t) => t.id == assignment.teamId,
      orElse: () => throw const TicketActionRejected('TEAM_NOT_FOUND'),
    );
    final reassign = ticket.stage == TicketStage.open;
    if (reassign && (assignment.reason?.trim() ?? '').isEmpty) {
      throw const TicketActionRejected('REASON_REQUIRED');
    }
    return _step(
      ticket,
      reassign ? TicketAction.reassign : TicketAction.assign,
      (t) => t.copyWith(
        stage: TicketStage.open,
        assignedCompanyId: company.id,
        assignedCompanyName: company.name,
        assignedTeamId: team.id,
        assignedTeamName: team.name,
      ),
      status: TicketStatus.open,
      note: '${company.name} · ${team.name}',
    );
  }

  @override
  Future<Ticket> close(Ticket ticket, TicketClosing closing) => _step(
    ticket,
    TicketAction.close,
    (t) => t.copyWith(
      stage: TicketStage.closed,
      closingAssetCondition: closing.condition.code,
    ),
    status: TicketStatus.attended,
    note: closing.notes?.trim().isNotEmpty == true
        ? closing.notes!.trim()
        : closing.condition.code,
  );

  @override
  Future<Ticket> returnToOpen(Ticket ticket, String reason) => _step(
    ticket,
    TicketAction.returnToOpen,
    (t) => t.copyWith(stage: TicketStage.open),
    status: TicketStatus.open,
    note: reason.trim(),
  );

  @override
  Future<Ticket> reopen(Ticket ticket, String reason) => _step(
    ticket,
    TicketAction.reopen,
    (t) => t.copyWith(stage: TicketStage.open),
    status: TicketStatus.open,
    note: reason.trim(),
  );

  @override
  Future<Ticket> cancel(Ticket ticket, TicketCancellation cancellation) =>
      _step(
        ticket,
        TicketAction.cancel,
        (t) => t.copyWith(
          stage: TicketStage.cancelled,
          cancelReason: cancellation.reason.code,
          duplicateOfFolio: cancellation.duplicateOfFolio,
        ),
        status: TicketStatus.attended,
        note: cancellation.notes ?? cancellation.reason.code,
      );

  @override
  Future<List<String>> categories() async {
    await _wait();
    return categoryNames;
  }
}
