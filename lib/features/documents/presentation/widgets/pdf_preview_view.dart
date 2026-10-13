import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/pdf/pdf_renderer.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import 'document_state_view.dart';

/// Vista previa de un PDF (DEV-MOB-071): las paginas una debajo de otra, con
/// acercar y alejar. Dibuja solo lo que se ve, pagina por pagina. No ofrece
/// guardar, compartir ni abrir en otra app (DTF M03 §3.1).
class PdfPreviewView extends StatefulWidget {
  const PdfPreviewView({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PdfPreviewView> createState() => _PdfPreviewViewState();
}

class _PdfPreviewViewState extends State<PdfPreviewView> {
  static const _zoomSteps = [1.0, 1.5, 2.0, 3.0];
  static const _pageGap = 12.0;

  late final PdfRenderer _renderer = context.read<PdfRenderer>();
  final _scroll = ScrollController();
  final _pages = <(int, int), Future<Uint8List>>{};

  PdfDocumentHandle? _document;
  bool _failed = false;
  int _zoomIndex = 0;
  int _current = 1;
  double _viewportWidth = 0;
  double _viewportHeight = 0;

  double get _zoom => _zoomSteps[_zoomIndex];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackPage);
    _open();
  }

  Future<void> _open() async {
    try {
      final document = await _renderer.open(widget.bytes);
      if (!mounted) {
        await _renderer.close(document);
        return;
      }
      setState(() => _document = document);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    final document = _document;
    if (document != null) _renderer.close(document);
    super.dispose();
  }

  /// Alto de una pagina en pantalla, con el ancho dado.
  double _pageHeight(PdfPageSize size, double width) =>
      width / size.aspectRatio;

  void _trackPage() {
    final document = _document;
    if (document == null || _viewportWidth == 0) return;
    final width = _viewportWidth * _zoom;
    final middle = _scroll.offset + _viewportHeight / 2;
    var top = 0.0;
    var page = document.pages.length;
    for (var i = 0; i < document.pages.length; i++) {
      top += _pageHeight(document.pages[i], width) + _pageGap;
      if (top > middle) {
        page = i + 1;
        break;
      }
    }
    if (page != _current) setState(() => _current = page);
  }

  void _setZoom(int index) {
    if (index < 0 || index >= _zoomSteps.length || index == _zoomIndex) return;
    setState(() {
      _zoomIndex = index;
      // Las paginas se vuelven a dibujar al nuevo ancho: lo anterior sobra.
      _pages.clear();
    });
  }

  Future<Uint8List> _page(PdfDocumentHandle document, int index, int width) =>
      _pages.putIfAbsent((
        index,
        width,
      ), () => _renderer.renderPage(document, index, width: width));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_failed) {
      return DocumentStateView(
        state: DocumentScreenState.previewUnavailable,
        body: l10n.docsPreviewPdfError,
      );
    }
    final document = _document;
    if (document == null) {
      return const DocumentStateView(state: DocumentScreenState.loading);
    }
    final p = context.palette;
    final r = context.responsive;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewportWidth = constraints.maxWidth;
              _viewportHeight = constraints.maxHeight;
              final contentWidth = constraints.maxWidth * _zoom;
              final pageWidth = contentWidth - 2 * r.s(12);
              // Se pide en pasos de 64 px para reutilizar lo ya dibujado.
              final pixels = min(2400, ((pageWidth * ratio) / 64).ceil() * 64);
              return SingleChildScrollView(
                key: const Key('docs-preview-pdf-horizontal'),
                scrollDirection: Axis.horizontal,
                physics: _zoom == 1
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: ListView.separated(
                    key: const Key('docs-preview-pdf'),
                    controller: _scroll,
                    padding: EdgeInsets.all(r.s(12)),
                    itemCount: document.pages.length,
                    separatorBuilder: (_, _) => SizedBox(height: r.s(_pageGap)),
                    itemBuilder: (context, index) => _PageImage(
                      key: Key('docs-pdf-page-${index + 1}'),
                      label: l10n.docsPdfPageOf(
                        index + 1,
                        document.pages.length,
                      ),
                      aspectRatio: document.pages[index].aspectRatio,
                      future: _page(document, index, pixels),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Material(
          color: p.card,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: r.s(12),
                vertical: r.s(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('docs-pdf-zoom-out'),
                    tooltip: l10n.docsPdfZoomOut,
                    onPressed: _zoomIndex == 0
                        ? null
                        : () => _setZoom(_zoomIndex - 1),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  Expanded(
                    child: Text(
                      l10n.docsPdfPageOf(_current, document.pages.length),
                      key: const Key('docs-pdf-page-indicator'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textOnBottom),
                    ),
                  ),
                  IconButton(
                    key: const Key('docs-pdf-zoom-in'),
                    tooltip: l10n.docsPdfZoomIn,
                    onPressed: _zoomIndex == _zoomSteps.length - 1
                        ? null
                        : () => _setZoom(_zoomIndex + 1),
                    icon: const Icon(Icons.zoom_in),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageImage extends StatelessWidget {
  const _PageImage({
    super.key,
    required this.label,
    required this.aspectRatio,
    required this.future,
  });

  final String label;
  final double aspectRatio;
  final Future<Uint8List> future;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: label,
      image: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
          ),
          child: FutureBuilder<Uint8List>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Icon(Icons.broken_image_outlined, color: p.hint),
                );
              }
              final bytes = snapshot.data;
              if (bytes == null) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Image.memory(
                bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.broken_image_outlined, color: p.hint),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
