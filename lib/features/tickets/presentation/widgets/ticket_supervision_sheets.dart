import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_supervision.dart';
import '../ticket_labels.dart';

// Las hojas con lo que pide cada accion del Supervisor (DTF M11 v0.3): a quien
// se asigna, con que condicion se cierra, el motivo de regresar o reabrir y el
// motivo de cancelar. Cada una devuelve lo capturado o null si se cierra sin
// guardar; la accion la manda la ficha.

/// Asignar (SIN_VALIDAR) o reasignar con motivo (ABIERTO): empresa y equipo
/// obligatorios, persona de referencia opcional (RB-11-09, RB-11-10).
Future<TicketAssignment?> showAssignSheet(
  BuildContext context, {
  required Ticket ticket,
  required Future<List<TicketAssignableCompany>> Function() load,
}) =>
    _sheet<TicketAssignment>(context, _AssignSheet(ticket: ticket, load: load));

/// Validar y cerrar: observacion opcional (D-11-25) y, si el ticket es de un
/// activo, su condicion (P-11-27; sin activo el servidor no la guarda).
Future<TicketClosing?> showCloseSheet(
  BuildContext context, {
  required bool withAsset,
}) => _sheet<TicketClosing>(context, _CloseSheet(withAsset: withAsset));

/// Regresar a Abierto o reabrir: el motivo es obligatorio.
Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  required String keyPrefix,
}) => _sheet<String>(context, _ReasonSheet(title: title, keyPrefix: keyPrefix));

/// Cancelar: duplicado con el folio del original, improcedente u otro con su
/// detalle (S-TKT-10).
Future<TicketCancellation?> showCancelSheet(BuildContext context) =>
    _sheet<TicketCancellation>(context, const _CancelSheet());

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        // Con el teclado abierto la hoja sube.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(child: SingleChildScrollView(child: child)),
      ),
    );

/// El cuerpo comun de las hojas: titulo, campos y los botones de abajo.
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.fields,
    required this.saveKey,
    required this.onSave,
  });

  final String title;
  final List<Widget> fields;
  final Key saveKey;

  /// Null mientras falta algo: el boton espera.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: const Color(0xFF1E293B)),
          ),
          SizedBox(height: r.s(16)),
          ...fields,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              SizedBox(width: r.s(8)),
              FilledButton(
                key: saveKey,
                onPressed: onSave,
                child: Text(l10n.ticketActionSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.ticket, required this.load});

  final Ticket ticket;
  final Future<List<TicketAssignableCompany>> Function() load;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  late Future<List<TicketAssignableCompany>> _companies;
  final _reason = TextEditingController();
  String? _companyId;
  String? _teamId;
  String? _personId;
  bool _showIssues = false;

  bool get _reassign => widget.ticket.stage == TicketStage.open;

  @override
  void initState() {
    super.initState();
    _companies = widget.load().then((list) {
      _preselect(list);
      return list;
    });
  }

  /// Al reasignar parte de la asignacion actual; con una sola opcion, ya va
  /// elegida.
  void _preselect(List<TicketAssignableCompany> list) {
    final current = list
        .where((c) => c.id == widget.ticket.assignedCompanyId)
        .firstOrNull;
    final company = current ?? (list.length == 1 ? list.single : null);
    if (company == null) return;
    _companyId = company.id;
    final team = company.teams
        .where((t) => t.id == widget.ticket.assignedTeamId)
        .firstOrNull;
    _teamId =
        team?.id ??
        (company.teams.length == 1 ? company.teams.single.id : null);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _retry() => setState(
    () => _companies = widget.load().then((list) {
      _preselect(list);
      return list;
    }),
  );

  void _save() {
    final company = _companyId;
    final team = _teamId;
    final reason = _reason.text.trim();
    if (company == null || team == null || (_reassign && reason.isEmpty)) {
      setState(() => _showIssues = true);
      return;
    }
    Navigator.of(context).pop(
      TicketAssignment(
        companyId: company,
        teamId: team,
        responsibleUserId: _personId,
        reason: _reassign ? reason : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<TicketAssignableCompany>>(
      future: _companies,
      builder: (context, snapshot) {
        final title = _reassign
            ? l10n.ticketReassignTitle
            : l10n.ticketAssignTitle;
        if (snapshot.connectionState != ConnectionState.done) {
          return _SheetBody(
            title: title,
            saveKey: const Key('ticket-assign-save'),
            onSave: null,
            fields: const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  key: Key('ticket-assign-loading'),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }
        final companies = snapshot.data ?? const <TicketAssignableCompany>[];
        if (snapshot.hasError || companies.isEmpty) {
          return _SheetBody(
            title: title,
            saveKey: const Key('ticket-assign-save'),
            onSave: null,
            fields: [
              Text(
                snapshot.hasError
                    ? l10n.ticketAssignLoadFailed
                    : l10n.ticketAssignNoTeams,
                key: const Key('ticket-assign-empty'),
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              if (snapshot.hasError)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('ticket-assign-retry'),
                    onPressed: _retry,
                    child: Text(l10n.ticketsRetry),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        }
        final company = companies.where((c) => c.id == _companyId).firstOrNull;
        final team = company?.teams.where((t) => t.id == _teamId).firstOrNull;
        final missing = _showIssues && (company == null || team == null);
        final reasonMissing =
            _showIssues && _reassign && _reason.text.trim().isEmpty;
        return _SheetBody(
          title: title,
          saveKey: const Key('ticket-assign-save'),
          onSave: _save,
          fields: [
            ModuleField(
              label: l10n.ticketAssignCompany,
              error: missing && company == null
                  ? l10n.ticketAssignMissing
                  : null,
              child: DropdownButtonFormField<String>(
                key: const Key('ticket-assign-company'),
                initialValue: company?.id,
                isExpanded: true,
                style: moduleInkStyle,
                dropdownColor: Colors.white,
                hint: Text(l10n.ticketAssignSelect, style: moduleHintStyle),
                decoration: moduleInput(
                  context,
                  error: missing && company == null,
                ),
                items: [
                  for (final c in companies)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (id) => setState(() {
                  _companyId = id;
                  final teams = companies.firstWhere((c) => c.id == id).teams;
                  _teamId = teams.length == 1 ? teams.single.id : null;
                  _personId = null;
                }),
              ),
            ),
            if (company != null)
              ModuleField(
                label: l10n.ticketAssignTeam,
                error: missing && team == null
                    ? l10n.ticketAssignMissing
                    : null,
                child: DropdownButtonFormField<String>(
                  // Otra empresa, otra lista: el campo empieza de nuevo.
                  key: Key('ticket-assign-team-${company.id}'),
                  initialValue: team?.id,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  hint: Text(l10n.ticketAssignSelect, style: moduleHintStyle),
                  decoration: moduleInput(
                    context,
                    error: missing && team == null,
                  ),
                  items: [
                    for (final t in company.teams)
                      DropdownMenuItem(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (id) => setState(() {
                    _teamId = id;
                    _personId = null;
                  }),
                ),
              ),
            if (team != null && team.members.isNotEmpty)
              ModuleField(
                label: l10n.ticketAssignPerson,
                child: DropdownButtonFormField<String?>(
                  key: Key('ticket-assign-person-${team.id}'),
                  initialValue: _personId,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  decoration: moduleInput(context),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.ticketAssignNoPerson),
                    ),
                    for (final m in team.members)
                      DropdownMenuItem<String?>(
                        value: m.userId,
                        child: Text(m.fullName),
                      ),
                  ],
                  onChanged: (id) => setState(() => _personId = id),
                ),
              ),
            if (_reassign)
              ModuleField(
                label: l10n.ticketReasonLabel,
                error: reasonMissing ? l10n.ticketReasonRequired : null,
                child: TextField(
                  key: const Key('ticket-assign-reason'),
                  controller: _reason,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  style: moduleInkStyle,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: moduleInput(
                    context,
                    hint: l10n.ticketReasonHint,
                    error: reasonMissing,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CloseSheet extends StatefulWidget {
  const _CloseSheet({required this.withAsset});

  final bool withAsset;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  final _notes = TextEditingController();
  var _condition = TicketAssetCondition.unchanged;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.ticketCloseTitle,
      saveKey: const Key('ticket-close-save'),
      onSave: () => Navigator.of(
        context,
      ).pop(TicketClosing(notes: _notes.text.trim(), condition: _condition)),
      fields: [
        if (widget.withAsset)
          ModuleField(
            label: l10n.ticketCloseCondition,
            child: DropdownButtonFormField<TicketAssetCondition>(
              key: const Key('ticket-close-condition'),
              initialValue: _condition,
              isExpanded: true,
              style: moduleInkStyle,
              dropdownColor: Colors.white,
              decoration: moduleInput(context),
              items: [
                for (final c in TicketAssetCondition.values)
                  DropdownMenuItem(
                    value: c,
                    child: Text(assetConditionLabel(l10n, c)),
                  ),
              ],
              onChanged: (c) {
                if (c != null) setState(() => _condition = c);
              },
            ),
          ),
        ModuleField(
          label: l10n.ticketCloseNotes,
          child: TextField(
            key: const Key('ticket-close-notes'),
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            style: moduleInkStyle,
            textCapitalization: TextCapitalization.sentences,
            decoration: moduleInput(context),
          ),
        ),
      ],
    );
  }
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.title, required this.keyPrefix});

  final String title;
  final String keyPrefix;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();
  bool _showIssues = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final missing = _showIssues && _reason.text.trim().isEmpty;
    return _SheetBody(
      title: widget.title,
      saveKey: Key('${widget.keyPrefix}-save'),
      onSave: _save,
      fields: [
        ModuleField(
          label: l10n.ticketReasonLabel,
          error: missing ? l10n.ticketReasonRequired : null,
          child: TextField(
            key: Key('${widget.keyPrefix}-reason'),
            controller: _reason,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            style: moduleInkStyle,
            textCapitalization: TextCapitalization.sentences,
            decoration: moduleInput(
              context,
              hint: l10n.ticketReasonHint,
              error: missing,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final _folio = TextEditingController();
  final _notes = TextEditingController();
  var _reason = TicketCancelReason.duplicate;
  bool _showIssues = false;

  @override
  void dispose() {
    _folio.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _folioMissing =>
      _reason == TicketCancelReason.duplicate && _folio.text.trim().isEmpty;

  bool get _notesMissing =>
      _reason == TicketCancelReason.other && _notes.text.trim().isEmpty;

  void _save() {
    if (_folioMissing || _notesMissing) {
      setState(() => _showIssues = true);
      return;
    }
    final folio = _folio.text.trim().toUpperCase();
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      TicketCancellation(
        reason: _reason,
        duplicateOfFolio: _reason == TicketCancelReason.duplicate
            ? folio
            : null,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.ticketCancelTitle,
      saveKey: const Key('ticket-cancel-save'),
      onSave: _save,
      fields: [
        ModuleField(
          label: l10n.ticketCancelReason,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in TicketCancelReason.values)
                ChoiceChip(
                  key: Key('ticket-cancel-reason-${r.name}'),
                  label: Text(cancelReasonLabel(l10n, r)),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ],
          ),
        ),
        if (_reason == TicketCancelReason.duplicate)
          ModuleField(
            label: l10n.ticketCancelFolio,
            error: _showIssues && _folioMissing
                ? l10n.ticketCancelFolioRequired
                : null,
            child: TextField(
              key: const Key('ticket-cancel-folio'),
              controller: _folio,
              style: moduleInkStyle,
              textCapitalization: TextCapitalization.characters,
              decoration: moduleInput(
                context,
                hint: 'TK-2026-000123',
                error: _showIssues && _folioMissing,
              ),
            ),
          ),
        ModuleField(
          label: l10n.ticketCancelNotes,
          error: _showIssues && _notesMissing
              ? l10n.ticketCancelNotesRequired
              : null,
          child: TextField(
            key: const Key('ticket-cancel-notes'),
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            style: moduleInkStyle,
            textCapitalization: TextCapitalization.sentences,
            decoration: moduleInput(
              context,
              error: _showIssues && _notesMissing,
            ),
          ),
        ),
      ],
    );
  }
}
