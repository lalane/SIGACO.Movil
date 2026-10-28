import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/logo_store.dart';

/// La URL del logo apunta a un SVG: su ruta (sin consulta ni fragmento) termina
/// en `.svg`. Las URL firmadas siguen valiendo porque la firma va en la consulta.
bool isSvgLogoUrl(String url) {
  final path = Uri.tryParse(url)?.path;
  return path != null && path.toLowerCase().endsWith('.svg');
}

/// Lo descargado parece un SVG (y no una pagina de error con estado 200).
bool looksLikeSvg(Uint8List bytes) {
  final head = utf8.decode(
    bytes.length > 2048 ? bytes.sublist(0, 2048) : bytes,
    allowMalformed: true,
  );
  return head.toLowerCase().contains('<svg');
}

/// Pide el logo al almacen y lo dibuja solo si de verdad es una imagen: una URL
/// rota, un error del servidor o un archivo que no sirve dejan la app sin
/// logo, sin errores. Acepta PNG, JPG, WebP y SVG.
class LogoImage extends StatefulWidget {
  const LogoImage({
    super.key,
    required this.url,
    required this.version,
    required this.height,
    required this.store,
    this.semanticLabel,
  });

  final String url;
  final int version;
  final double height;
  final String? semanticLabel;
  final LogoStore store;

  @override
  State<LogoImage> createState() => _LogoImageState();
}

class _LogoImageState extends State<LogoImage> {
  late final Future<Uint8List?> _bytes = widget.store.bytesFor(
    widget.url,
    version: widget.version,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
        const empty = SizedBox.shrink();
        // El servidor entrega los logos por una ruta sin extension: el SVG se
        // reconoce tambien por su contenido.
        if (isSvgLogoUrl(widget.url) || looksLikeSvg(bytes)) {
          if (!looksLikeSvg(bytes)) return empty;
          return SvgPicture.memory(
            bytes,
            height: widget.height,
            fit: BoxFit.contain,
            semanticsLabel: widget.semanticLabel,
            errorBuilder: (_, _, _) => empty,
          );
        }
        return Image.memory(
          bytes,
          height: widget.height,
          fit: BoxFit.contain,
          semanticLabel: widget.semanticLabel,
          errorBuilder: (_, _, _) => empty,
        );
      },
    );
  }
}

/// El logo de una concesion de la lista (selector), por su ruta en el servidor.
/// Como el de la activa, se guarda en el telefono y no ocupa espacio si falta.
class ConcessionLogoByUrl extends StatelessWidget {
  const ConcessionLogoByUrl({
    super.key,
    required this.url,
    required this.height,
    this.semanticLabel,
    this.store,
  });

  final String? url;
  final double height;
  final String? semanticLabel;
  final LogoStore? store;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null) return const SizedBox.shrink();
    return LogoImage(
      key: ValueKey(u),
      url: u,
      version: 0,
      height: height,
      semanticLabel: semanticLabel,
      store: store ?? context.read<LogoStore>(),
    );
  }
}
