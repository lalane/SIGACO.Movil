import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/page_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document_access.dart';
import '../../domain/entities/document_upload.dart';
import '../bloc/document_upload_cubit.dart';
import '../document_labels.dart';
import '../widgets/document_state_view.dart';

/// Carga de uno o varios documentos (DEV-MOB-072, 073, 082 y 083, MQ-MOB-16 a
/// 18). Requiere Ver + Cargar. Lo que se guarda queda en el telefono, en la
/// cola, hasta que el servidor lo acepte.
class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key, required this.access});

  final DocumentAccess access;

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  @override
  void initState() {
    super.initState();
    if (widget.access.canUpload) {
      context.read<DocumentUploadCubit>().loadCatalogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.docsUploadTitle),
          Expanded(
            child: widget.access.canUpload
                ? const _Body()
                : const DocumentStateView(
                    state: DocumentScreenState.noPermission,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      builder: (context, state) => state.status == UploadStatus.done
          ? _Done(saved: state.saved)
          : _Form(state: state),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.saved});

  final int saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      key: const Key('upload-done'),
      padding: EdgeInsets.all(r.s(32)),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save_alt, size: r.s(52), color: p.accentOnBottom),
              SizedBox(height: r.s(14)),
              Text(
                l10n.docsUploadDoneTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.textOnBottom,
                  fontSize: r.s(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: r.s(6)),
              Text(
                l10n.docsUploadDoneBody(saved),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.hint, fontSize: r.s(13.5)),
              ),
              SizedBox(height: r.s(20)),
              FilledButton(
                key: const Key('upload-done-back'),
                onPressed: () => context.pop(true),
                child: Text(l10n.docsUploadDoneBack),
              ),
              TextButton(
                key: const Key('upload-done-sync'),
                onPressed: () => context.pushReplacement('/sync'),
                child: Text(l10n.docsUploadDoneSync),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final DocumentUploadState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<DocumentUploadCubit>();
    final saving = state.status == UploadStatus.saving;
    final issues = state.metadataIssues;
    final show = state.showErrors;
    final isOther =
        state.metadata.typeCode == DocumentUploadRules.otherTypeCode;

    String? error(UploadIssue issue) =>
        show && issues.contains(issue) ? issueText(l10n, issue) : null;

    return ListView(
      key: const Key('upload-form'),
      padding: r
          .sidePadding(minGutter: r.s(20))
          .copyWith(top: r.s(16), bottom: r.s(32)),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('upload-pick'),
                onPressed: saving ? null : cubit.pickFiles,
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.docsUploadPickFiles),
              ),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('upload-photo'),
                onPressed: saving ? null : cubit.takePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.docsUploadTakePhoto),
              ),
            ),
          ],
        ),
        SizedBox(height: r.s(12)),
        if (state.items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: r.s(12)),
            child: Text(
              show ? l10n.docsIssueNoFile : l10n.docsUploadNoFiles,
              key: const Key('upload-no-files'),
              style: TextStyle(
                color: show ? p.error : p.hint,
                fontSize: r.s(13.5),
              ),
            ),
          ),
        for (var i = 0; i < state.items.length; i++)
          _ItemCard(
            key: ValueKey(state.items[i].path),
            index: i,
            item: state.items[i],
            issues: show ? state.itemIssues[i] : const [],
            enabled: !saving,
          ),
        SizedBox(height: r.s(8)),
        _Dropdown(
          fieldKey: const Key('upload-type'),
          label: l10n.docsUploadType,
          value: state.metadata.typeCode,
          options: [
            for (final e in state.catalogs.types)
              if (e.active) (e.code, e.label),
          ],
          errorText: error(UploadIssue.typeMissing),
          onChanged: saving ? null : cubit.setType,
        ),
        _Dropdown(
          fieldKey: const Key('upload-category'),
          label: l10n.docsUploadCategory,
          value: state.metadata.categoryCode,
          nullLabel: l10n.docsUploadNoCategory,
          options: [
            for (final e in state.catalogs.categories)
              if (e.active) (e.code, e.label),
          ],
          onChanged: saving ? null : cubit.setCategory,
        ),
        _Dropdown(
          fieldKey: const Key('upload-folder'),
          label: l10n.docsUploadFolder,
          value: state.metadata.folder,
          nullLabel: l10n.docsUploadRoot,
          options: [for (final f in state.catalogs.folders) (f, f)],
          onChanged: saving ? null : cubit.setFolder,
        ),
        Padding(
          padding: EdgeInsets.only(bottom: r.s(12)),
          child: TextFormField(
            key: const Key('upload-description'),
            initialValue: state.metadata.description,
            enabled: !saving,
            minLines: 2,
            maxLines: 4,
            onChanged: cubit.setDescription,
            decoration: InputDecoration(
              labelText: isOther
                  ? l10n.docsUploadDescriptionOther
                  : l10n.docsUploadDescription,
              errorText:
                  error(UploadIssue.descriptionRequired) ??
                  error(UploadIssue.descriptionTooLong),
              errorMaxLines: 3,
            ),
          ),
        ),
        if (state.saveFailed)
          Padding(
            padding: EdgeInsets.only(bottom: r.s(12)),
            child: Text(
              l10n.docsUploadSaveFailed,
              key: const Key('upload-save-failed'),
              style: TextStyle(color: p.error, fontSize: r.s(13)),
            ),
          ),
        Text(
          l10n.docsUploadOfflineNote,
          style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
        ),
        SizedBox(height: r.s(16)),
        FilledButton(
          key: const Key('upload-save'),
          onPressed: saving ? null : cubit.submit,
          child: Text(saving ? l10n.docsUploadSaving : l10n.docsUploadSave),
        ),
        TextButton(
          key: const Key('upload-cancel'),
          onPressed: saving ? null : () => context.pop(false),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.issues,
    required this.enabled,
  });

  final int index;
  final UploadItem item;
  final List<UploadIssue> issues;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<DocumentUploadCubit>();
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(10)),
      child: Container(
        padding: EdgeInsets.fromLTRB(r.s(12), r.s(10), r.s(4), r.s(10)),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(r.s(14)),
          border: Border.all(
            color: issues.isEmpty ? p.hint.withValues(alpha: 0.2) : p.error,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: r.s(12)),
              child: Icon(
                fileIcon(item.format),
                color: p.accentOnBottom,
                size: r.s(28),
              ),
            ),
            SizedBox(width: r.s(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: Key('upload-name-$index'),
                    initialValue: item.baseName,
                    enabled: enabled,
                    onChanged: (v) => cubit.rename(index, v),
                    decoration: InputDecoration(
                      labelText: l10n.docsUploadFileName,
                      // La extension real no se edita.
                      suffixText: item.extension,
                      isDense: true,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: r.s(4)),
                    child: Text(
                      formatBytes(item.sizeBytes),
                      style: TextStyle(color: p.hint, fontSize: r.s(12)),
                    ),
                  ),
                  for (final issue in issues)
                    Padding(
                      padding: EdgeInsets.only(top: r.s(2)),
                      child: Text(
                        issueText(l10n, issue),
                        key: Key('upload-issue-$index-${issue.name}'),
                        style: TextStyle(color: p.error, fontSize: r.s(12.5)),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              key: Key('upload-remove-$index'),
              tooltip: l10n.docsUploadRemove,
              onPressed: enabled ? () => cubit.removeAt(index) : null,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.nullLabel,
    this.errorText,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?>? onChanged;

  /// Texto de la opcion «ninguno»; sin el, el campo es obligatorio.
  final String? nullLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final current = options.any((o) => o.$1 == value) ? value : null;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(12)),
      child: DropdownButtonFormField<String?>(
        key: fieldKey,
        initialValue: current,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, errorText: errorText),
        items: [
          if (nullLabel != null)
            DropdownMenuItem<String?>(value: null, child: Text(nullLabel!)),
          for (final o in options)
            DropdownMenuItem<String?>(
              value: o.$1,
              child: Text(o.$2, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
