import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/page_header.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/document_access.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/repositories/documents_repository.dart';
import '../bloc/document_detail_cubit.dart';
import '../document_labels.dart';
import '../widgets/document_state_view.dart';
import '../widgets/signature_badge.dart';

/// Ficha de un documento (DEV-MOB-070, MQ-MOB-14): metadatos y version vigente.
/// No muestra el historial de versiones (HU-MOB-03-01, regla 7).
class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key, required this.access});

  final DocumentAccess access;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.access.canView) context.read<DocumentDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.docsDetailTitle),
          Expanded(
            child: widget.access.canView
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
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<DocumentDetailCubit, DocumentDetailState>(
      listenWhen: (a, b) => b.favoriteFailed > a.favoriteFailed,
      listener: (context, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.docsFavoriteFailed))),
      builder: (context, state) {
        final cubit = context.read<DocumentDetailCubit>();
        switch (state.status) {
          case DocumentDetailStatus.loading:
            return const DocumentStateView(state: DocumentScreenState.loading);
          case DocumentDetailStatus.failure:
            return DocumentStateView(
              state: screenStateFor(state.error ?? DocumentsError.server),
              onRetry: cubit.load,
            );
          case DocumentDetailStatus.ready:
            return _Detail(detail: state.detail!);
        }
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final DocumentDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final s = detail.summary;
    final cubit = context.read<DocumentDetailCubit>();
    return ListView(
      key: const Key('docs-detail'),
      padding: r
          .sidePadding(minGutter: r.s(20))
          .copyWith(top: r.s(20), bottom: r.s(32)),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(fileIcon(s.format), color: p.accentOnBottom, size: r.s(40)),
            SizedBox(width: r.s(12)),
            Expanded(
              child: Text(
                s.name,
                key: const Key('docs-detail-name'),
                style: TextStyle(
                  color: p.textOnBottom,
                  fontSize: r.s(19),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: const Key('docs-detail-favorite'),
              tooltip: s.isFavorite
                  ? l10n.docsFavoriteRemove
                  : l10n.docsFavoriteAdd,
              onPressed: cubit.toggleFavorite,
              icon: Icon(
                s.isFavorite ? Icons.star : Icons.star_border,
                color: s.isFavorite ? p.accentOnBottom : p.hint,
                size: r.s(28),
              ),
            ),
          ],
        ),
        SizedBox(height: r.s(10)),
        Align(
          alignment: Alignment.centerLeft,
          child: SignatureBadge(signature: s.signature),
        ),
        SizedBox(height: r.s(14)),
        if (detail.previewAvailable &&
            PreviewKind.forFormat(s.format) != PreviewKind.unsupported)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('docs-detail-preview'),
              onPressed: () => context.push('/documents/${s.id}/preview'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.docsPreviewOpen),
            ),
          )
        else
          Text(
            l10n.docsPreviewNoneNote,
            key: const Key('docs-detail-no-preview'),
            style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
          ),
        SizedBox(height: r.s(16)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(6)),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(r.s(16)),
            border: Border.all(color: p.hint.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _Field(l10n.docsFieldType, s.typeLabel),
              _Field(
                l10n.docsFieldCategory,
                s.categoryLabel ?? l10n.docsNoCategory,
              ),
              _Field(
                l10n.docsFieldDescription,
                detail.description.isEmpty
                    ? l10n.docsNoDescription
                    : detail.description,
              ),
              _Field(
                l10n.docsFieldFolder,
                detail.folder ?? l10n.docsFolderRoot,
              ),
              _Field(l10n.docsFieldOwner, s.ownerUsername),
              _Field(
                l10n.docsFieldVersion,
                l10n.docsVersion(detail.version),
                fieldKey: const Key('docs-detail-version'),
              ),
              _Field(
                l10n.docsFieldModified,
                _modified(context, s.modifiedAt, zone),
              ),
              _Field(l10n.docsFieldModifiedBy, detail.modifiedBy),
              _Field(l10n.docsFieldSize, formatBytes(detail.sizeBytes)),
              _Field(
                l10n.docsFieldFormat,
                s.format.isEmpty ? '—' : s.format.toUpperCase(),
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _modified(BuildContext context, DateTime utc, ConcessionZone? zone) =>
      formatInZone(context, utc, zone);
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.fieldKey, this.last = false});

  final String label;
  final String value;
  final Key? fieldKey;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: p.hint.withValues(alpha: 0.15))),
      ),
      padding: EdgeInsets.symmetric(vertical: r.s(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: r.s(120),
            child: Text(
              label,
              style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: fieldKey,
              style: TextStyle(
                color: p.textOnBottom,
                fontSize: r.s(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
