import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/page_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document_access.dart';
import '../../domain/entities/document_preview.dart';
import '../../domain/repositories/documents_repository.dart';
import '../bloc/document_preview_cubit.dart';
import '../widgets/document_state_view.dart';
import '../widgets/pdf_preview_view.dart';

/// Vista previa (DEV-MOB-071, MQ-MOB-15): imagenes con zoom y PDF por paginas.
/// Solo la representacion para ver: ofrecer descarga o abrir en otra app
/// requeriria un permiso y un alcance que el movil no tiene (DTF M03 §3.1).
class DocumentPreviewPage extends StatefulWidget {
  const DocumentPreviewPage({super.key, required this.access});

  final DocumentAccess access;

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  @override
  void initState() {
    super.initState();
    if (widget.access.canView) context.read<DocumentPreviewCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          SigacoPageHeader(title: l10n.docsPreviewTitle),
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
    return BlocBuilder<DocumentPreviewCubit, DocumentPreviewState>(
      builder: (context, state) {
        final cubit = context.read<DocumentPreviewCubit>();
        switch (state.status) {
          case DocumentPreviewStatus.loading:
            return const DocumentStateView(state: DocumentScreenState.loading);
          case DocumentPreviewStatus.failure:
            return DocumentStateView(
              state: screenStateFor(state.error ?? DocumentsError.server),
              onRetry: cubit.load,
            );
          case DocumentPreviewStatus.ready:
            final preview = state.preview!;
            switch (preview.kind) {
              case PreviewKind.image:
                return _ImageViewer(preview: preview);
              case PreviewKind.pdf:
                return PdfPreviewView(
                  key: const Key('docs-preview-pdf-view'),
                  bytes: preview.bytes,
                );
              case PreviewKind.unsupported:
                return const DocumentStateView(
                  state: DocumentScreenState.previewUnavailable,
                );
            }
        }
      },
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.preview});

  final DocumentPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InteractiveViewer(
      key: const Key('docs-preview-image'),
      minScale: 1,
      maxScale: 6,
      child: Center(
        child: Image.memory(
          preview.bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => DocumentStateView(
            state: DocumentScreenState.previewUnavailable,
            body: l10n.docsPreviewImageError,
          ),
        ),
      ),
    );
  }
}
