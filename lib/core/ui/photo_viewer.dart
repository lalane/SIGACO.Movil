import 'dart:io';

import 'package:flutter/material.dart';

/// Abre las fotos a pantalla completa, empezando por la [initial]: se desliza
/// entre ellas y se acerca con los dedos.
Future<void> showPhotoViewer(
  BuildContext context,
  List<String> paths, {
  int initial = 0,
}) {
  if (paths.isEmpty) return Future.value();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoViewerPage(
        paths: paths,
        initial: initial.clamp(0, paths.length - 1),
      ),
    ),
  );
}

class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({super.key, required this.paths, this.initial = 0});

  final List<String> paths;
  final int initial;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _page = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.paths.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: total > 1 ? Text('${_page + 1} / $total') : null,
        leading: CloseButton(key: const Key('photo-viewer-close')),
      ),
      body: PageView.builder(
        key: const Key('photo-viewer'),
        controller: _pages,
        itemCount: total,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(widget.paths[i]),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
