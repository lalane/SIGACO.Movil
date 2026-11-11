import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/files/file_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/inspection_capture.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../bloc/inspection_capture_cubit.dart';

/// Captura en campo con la plantilla de la inspeccion (APP-MOB-08): secciones
/// con sus campos, datos del activo sin edicion, el valor anterior como
/// referencia, fotos con posicion por campo, hallazgos con falla de la Matriz
/// y «Finalizar» que dice antes que falta. Sin red todo queda en la cola.
class InspectionCapturePage extends StatelessWidget {
  const InspectionCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<InspectionCaptureCubit, InspectionCaptureState>(
      listenWhen: (a, b) =>
          a.notice != b.notice ||
          a.error != b.error ||
          a.askJustification != b.askJustification,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        final text = switch (state.notice) {
          CaptureNotice.saved => l.captSaved,
          CaptureNotice.savedOffline => l.captSavedOffline,
          CaptureNotice.finalized => l.captFinalized,
          CaptureNotice.finalizedOffline => l.captFinalizedOffline,
          CaptureNotice.photoAdded ||
          CaptureNotice.findingAdded ||
          CaptureNotice.accepted ||
          CaptureNotice.started => l.captDone,
          CaptureNotice.rejected => l.captRejected,
          null => null,
        };
        if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
        if (state.status == CaptureStatus.ready &&
            state.error != null &&
            state.error != InspectionsError.incomplete) {
          messenger.showSnackBar(
            SnackBar(content: Text(_errorText(l, state.error!))),
          );
        }
        if (state.error == InspectionsError.incomplete &&
            state.askJustification == null) {
          messenger.showSnackBar(
            SnackBar(content: Text(l.captMissing(state.issues.length))),
          );
        }
        final ask = state.askJustification;
        if (ask != null) {
          _askText(context, l.captJustifyTitle, ask).then((reason) {
            if (!context.mounted) return;
            final cubit = context.read<InspectionCaptureCubit>();
            if (reason == null) {
              cubit.dismissJustification();
            } else {
              cubit.finalize(justification: reason);
            }
          });
        }
      },
      builder: (context, state) {
        final view = state.view;
        if (state.status == CaptureStatus.loading && view == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (view == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.error == InspectionsError.network
                          ? l.captOffline
                          : _errorText(
                              l,
                              state.error ?? InspectionsError.server,
                            ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<InspectionCaptureCubit>().load(),
                      child: Text(l.captRetry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final cubit = context.read<InspectionCaptureCubit>();
        final editable = view.editable;
        final language = Localizations.localeOf(context).languageCode;
        return Scaffold(
          appBar: AppBar(
            title: Text(view.folio),
            bottom: state.busy
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                _Header(view: view, state: state),
                if (view.pendingSync)
                  _Banner(
                    icon: Icons.cloud_upload_outlined,
                    text: l.captPendingSync,
                  ),
                if (view.correctionReason != null &&
                    view.serverStatus == 'EN_PROCESO')
                  _Banner(
                    icon: Icons.undo,
                    text: l.captCorrection(view.correctionReason!),
                  ),
                if (view.actions.accept ||
                    view.actions.reject ||
                    view.actions.start)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (view.actions.accept)
                          OutlinedButton.icon(
                            onPressed: state.busy ? null : cubit.accept,
                            icon: const Icon(Icons.check),
                            label: Text(l.captAccept),
                          ),
                        if (view.actions.reject)
                          OutlinedButton.icon(
                            onPressed: state.busy
                                ? null
                                : () async {
                                    final reason = await _askText(
                                      context,
                                      l.captReject,
                                      l.captRejectReason,
                                    );
                                    if (reason != null) cubit.reject(reason);
                                  },
                            icon: const Icon(Icons.close),
                            label: Text(l.captReject),
                          ),
                        if (view.actions.start)
                          FilledButton.icon(
                            onPressed: state.busy ? null : cubit.start,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l.captStart),
                          ),
                      ],
                    ),
                  ),
                if (editable && state.issues.isNotEmpty)
                  _Missing(issues: state.issues),
                for (final section in view.template.activeSections)
                  _SectionCard(
                    section: section,
                    state: state,
                    editable: editable,
                    language: language,
                  ),
                _Findings(view: view, state: state, editable: editable),
              ],
            ),
          ),
          bottomNavigationBar: editable
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.busy ? null : cubit.save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(l.captSave),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: state.busy || !view.actions.finalize
                                ? null
                                : () => cubit.finalize(),
                            icon: const Icon(Icons.send),
                            label: Text(l.captFinalize),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  static String _errorText(AppLocalizations l, InspectionsError e) =>
      switch (e) {
        InspectionsError.network => l.captOffline,
        InspectionsError.permissionDenied => l.captPermission,
        InspectionsError.notEditable => l.captNotEditable,
        InspectionsError.incomplete => l.captMissing(0),
        _ => l.captError,
      };
}

Future<String?> _askText(BuildContext context, String title, String hint) {
  final controller = TextEditingController();
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.captCancel),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: Text(l.captConfirm),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.view, required this.state});

  final InspectionCaptureView view;
  final InspectionCaptureState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(view.typeLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              [view.assetCode ?? l.captRoadSection, ?view.kmLabel].join(' · '),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(_status(l, view.serverStatus)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    '${l.captCondition}: ${view.computedCondition ?? l.captUnrated}${view.computedNative != null ? ' (${view.computedNative})' : ''}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (view.templateVersion != null)
                  Chip(
                    label: Text(l.captTemplateVersion(view.templateVersion!)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _status(AppLocalizations l, String code) => switch (code) {
    'PENDIENTE' => l.captStatusPending,
    'ASIGNADA' => l.captStatusAssigned,
    'EN_PROCESO' => l.captStatusInProgress,
    'ATENDIDA' => l.captStatusAttended,
    'EN_REVISION' => l.captStatusInReview,
    'CERRADA' => l.captStatusClosed,
    'CANCELADA' => l.captStatusCancelled,
    _ => code,
  };
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

class _Missing extends StatelessWidget {
  const _Missing({required this.issues});

  final List<CaptureIssue> issues;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.checklist),
        title: Text(l.captMissing(issues.length)),
        children: [
          for (final i in issues.take(30))
            ListTile(
              dense: true,
              title: Text(i.message),
              subtitle: Text(i.path.replaceFirst('answers.', '')),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.state,
    required this.editable,
    required this.language,
  });

  final TemplateSection section;
  final InspectionCaptureState state;
  final bool editable;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cubit = context.read<InspectionCaptureCubit>();
    final rows = TemplateEvaluator.rowsOf(section, state.answers);
    final shown = section.repeatable
        ? rows
        : [rows.isEmpty ? null : rows.first];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.labelFor(language),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (section.repeatable &&
                    editable &&
                    (section.maxItems == null ||
                        rows.length < section.maxItems!))
                  TextButton.icon(
                    onPressed: () => cubit.addRow(section.key),
                    icon: const Icon(Icons.add),
                    label: Text(l.captAddRow),
                  ),
              ],
            ),
            for (var i = 0; i < shown.length; i++) ...[
              if (section.repeatable)
                Row(
                  children: [
                    Text('#${i + 1}'),
                    const Spacer(),
                    if (editable)
                      TextButton(
                        onPressed: () => cubit.removeRow(section.key, i),
                        child: Text(l.captRemoveRow),
                      ),
                  ],
                ),
              for (final field in section.activeFields)
                _FieldInput(
                  key: ValueKey('${section.key}|$i|${field.key}'),
                  section: section,
                  field: field,
                  row: section.repeatable ? i : null,
                  value: shown[i]?[field.key],
                  previous: section.repeatable
                      ? null
                      : (section.key.isEmpty
                            ? state.view!.previousAnswers
                            : state.view!.previousAnswers[section.key]
                                  as Map?)?[field.key],
                  editable: editable && !field.readOnly,
                  issue: state.issues
                      .where((x) => x.path == _issuePath(section, i, field))
                      .firstOrNull
                      ?.message,
                  language: language,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La ruta con que el servidor y el telefono nombran lo que falta en un campo.
String _issuePath(TemplateSection section, int row, TemplateField field) =>
    section.repeatable
    ? 'answers.${section.key}[$row].${field.key}'
    : section.key.isEmpty
    ? 'answers.${field.key}'
    : 'answers.${section.key}.${field.key}';

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    super.key,
    required this.section,
    required this.field,
    required this.row,
    required this.value,
    required this.previous,
    required this.editable,
    required this.issue,
    required this.language,
  });

  final TemplateSection section;
  final TemplateField field;
  final int? row;
  final Object? value;
  final Object? previous;
  final bool editable;
  final String? issue;
  final String language;

  String _text(Object? v) => v == null
      ? '—'
      : v is bool
      ? (v ? 'Sí' : 'No')
      : v is List
      ? v.map((e) => _option(e)).join(', ')
      : _option(v);

  String _option(Object? v) =>
      field.options
          .where((o) => o.value == v)
          .firstOrNull
          ?.labelFor(language) ??
      '$v';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cubit = context.read<InspectionCaptureCubit>();
    void set(Object? v) => cubit.setValue(section.key, field.key, v, row: row);
    final required = field.required || field.requiredIfField != null;
    final label =
        '${field.labelFor(language)}${field.unit != null ? ' (${field.unit})' : ''}${required ? ' *' : ''}';
    final helper = [
      if (field.source == 'ACTIVO') l.captFromAsset,
      if (previous != null && previous != '') l.captPrevious(_text(previous)),
      ?field.help,
    ].join(' · ');

    if (field.type == TemplateFieldType.evidence) {
      final path = fieldPath(section.key, field.key);
      final photos = context.select(
        (InspectionCaptureCubit c) =>
            c.state.view?.evidences.where((e) => e.fieldKey == path).toList() ??
            const <CaptureEvidence>[],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final p in photos)
                  Chip(
                    avatar: Icon(
                      p.pending
                          ? Icons.cloud_upload_outlined
                          : p.latitude != null
                          ? Icons.place_outlined
                          : Icons.photo_outlined,
                      size: 18,
                    ),
                    label: Text(
                      p.pending ? l.captPhotoPending : p.fileName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (photos.isEmpty) Text(l.captNoPhotos),
                if (editable)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final shot = await context.read<FileSource>().takePhoto();
                      if (shot != null) {
                        cubit.addPhoto(shot.path, fieldKey: path);
                      }
                    },
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.captAddPhoto),
                  ),
              ],
            ),
            if (issue != null)
              Text(
                issue!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    }

    if (!editable) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        subtitle: Text(
          [_text(value), if (helper.isNotEmpty) helper].join('\n'),
        ),
        trailing: field.source == 'ACTIVO'
            ? const Icon(Icons.lock_outline, size: 16)
            : null,
      );
    }

    final decoration = InputDecoration(
      labelText: label,
      helperText: helper.isEmpty ? null : helper,
      errorText: issue,
      isDense: true,
    );
    final Widget input = switch (field.type) {
      TemplateFieldType.number || TemplateFieldType.km => TextFormField(
        initialValue: value is num ? '$value' : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: decoration,
        onChanged: (t) =>
            set(t.trim().isEmpty ? null : num.tryParse(t.replaceAll(',', '.'))),
      ),
      TemplateFieldType.yesNo => InputDecorator(
        decoration: decoration,
        child: Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l.captYes),
              selected: value == true,
              onSelected: (s) => set(s ? true : null),
            ),
            ChoiceChip(
              label: Text(l.captNo),
              selected: value == false,
              onSelected: (s) => set(s ? false : null),
            ),
          ],
        ),
      ),
      TemplateFieldType.option => DropdownButtonFormField<String>(
        initialValue: field.options.any((o) => o.value == value)
            ? value as String
            : null,
        isExpanded: true,
        decoration: decoration,
        items: [
          for (final o in field.options)
            DropdownMenuItem(value: o.value, child: Text(o.labelFor(language))),
        ],
        onChanged: set,
      ),
      TemplateFieldType.multiple => InputDecorator(
        decoration: decoration,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final o in field.options)
              FilterChip(
                label: Text(o.labelFor(language)),
                selected: value is List && (value as List).contains(o.value),
                onSelected: (s) {
                  final current = [
                    for (final v in (value is List ? value as List : const []))
                      '$v',
                  ];
                  set(
                    s
                        ? [...current, o.value]
                        : current.where((v) => v != o.value).toList(),
                  );
                },
              ),
          ],
        ),
      ),
      TemplateFieldType.conformity => InputDecorator(
        decoration: decoration,
        child: Wrap(
          spacing: 6,
          children: [
            for (final (code, text) in [
              ('CONFORME', l.captConform),
              ('NO_CONFORME', l.captNonConform),
              ('NO_APLICA', l.captNotApplicable),
            ])
              ChoiceChip(
                label: Text(text),
                selected: value == code,
                onSelected: (s) => set(s ? code : null),
              ),
          ],
        ),
      ),
      TemplateFieldType.date => InputDecorator(
        decoration: decoration,
        child: TextButton(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 20),
              lastDate: DateTime(now.year + 5),
              initialDate: DateTime.tryParse('$value') ?? now,
            );
            if (picked != null) {
              set(
                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
          child: Text(value is String ? value as String : '—'),
        ),
      ),
      _ => TextFormField(
        initialValue: value is String ? value as String : '',
        maxLines: null,
        decoration: decoration,
        onChanged: (t) => set(t),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: input,
    );
  }
}

class _Findings extends StatelessWidget {
  const _Findings({
    required this.view,
    required this.state,
    required this.editable,
  });

  final InspectionCaptureView view;
  final InspectionCaptureState state;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.captFindings} (${view.findings.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (editable)
                  TextButton.icon(
                    onPressed: state.busy
                        ? null
                        : () => _addFinding(context, state.failures),
                    icon: const Icon(Icons.add_alert_outlined),
                    label: Text(l.captAddFinding),
                  ),
              ],
            ),
            for (final f in view.findings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  f.pending
                      ? Icons.cloud_upload_outlined
                      : f.ticketId != null
                      ? Icons.confirmation_number_outlined
                      : Icons.report_outlined,
                ),
                title: Text(f.description),
                subtitle: Text(
                  [
                    f.severity,
                    if (f.failureCode != null)
                      state.failures
                              .where((x) => x.code == f.failureCode)
                              .firstOrNull
                              ?.label ??
                          f.failureCode!,
                    if (f.pending) l.captPhotoPending,
                    if (f.ticketId != null) l.captWithTicket,
                  ].join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFinding(
    BuildContext context,
    List<FailureChoice> failures,
  ) async {
    final cubit = context.read<InspectionCaptureCubit>();
    final files = context.read<FileSource>();
    final result =
        await showModalBottomSheet<
          ({
            String description,
            String? failure,
            String? severity,
            List<String> photos,
          })
        >(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FindingSheet(failures: failures, files: files),
        );
    if (result != null) {
      cubit.addFinding(
        description: result.description,
        failureCode: result.failure,
        severity: result.severity,
        photos: result.photos,
      );
    }
  }
}

class _FindingSheet extends StatefulWidget {
  const _FindingSheet({required this.failures, required this.files});

  final List<FailureChoice> failures;
  final FileSource files;

  @override
  State<_FindingSheet> createState() => _FindingSheetState();
}

class _FindingSheetState extends State<_FindingSheet> {
  final _description = TextEditingController();
  String? _failure;
  String? _severity;
  final _photos = <String>[];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chosen = widget.failures.where((f) => f.code == _failure).firstOrNull;
    final valid =
        _description.text.trim().isNotEmpty &&
        (_failure != null || _severity != null) &&
        _photos.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.captAddFinding,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.captFindingDescription),
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<String>(
              initialValue: _failure,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.captFindingFailure),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l.captFindingNoFailure),
                ),
                for (final f in widget.failures)
                  DropdownMenuItem(
                    value: f.code,
                    child: Text(
                      '${f.classification != null ? '${f.classification} · ' : ''}${f.label}${f.attentionLabel != null ? ' (${f.attentionLabel})' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _failure = v),
            ),
            if (chosen?.immediate == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.captImmediate),
              ),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: InputDecoration(labelText: l.captFindingSeverity),
              items: [
                for (final s in const ['CRITICA', 'ALTA', 'MEDIA', 'BAJA'])
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _severity = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final p in _photos)
                  Chip(
                    avatar: const Icon(Icons.photo_outlined, size: 18),
                    label: Text(
                      p.split(RegExp(r'[\\/]')).last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final shot = await widget.files.takePhoto();
                    if (shot != null && File(shot.path).existsSync()) {
                      setState(() => _photos.add(shot.path));
                    }
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l.captAddPhoto),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: valid
                  ? () => Navigator.pop(context, (
                      description: _description.text.trim(),
                      failure: _failure,
                      severity: _severity,
                      photos: [..._photos],
                    ))
                  : null,
              child: Text(l.captConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
