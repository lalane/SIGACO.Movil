import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/logo_store.dart';
import '../bloc/branding_cubit.dart';

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

/// Logo de la concesion activa, en PNG, JPG, WebP o SVG. Se guarda en el
/// telefono (`LogoStore`), asi que tambien aparece sin conexion. Si no hay
/// logo, o no se puede obtener, no ocupa espacio.
class ConcessionLogo extends StatelessWidget {
  const ConcessionLogo({
    super.key,
    required this.height,
    required this.darkBackground,
    this.preferReduced = false,
    this.semanticLabel,
    this.store,
  });

  final double height;

  /// El logo se dibuja sobre un fondo oscuro.
  final bool darkBackground;

  /// Prefiere la variante reducida si la concesion la tiene (cabecera).
  final bool preferReduced;
  final String? semanticLabel;

  /// De donde salen los bytes; por omision, el de la app (`LogoStore`).
  final LogoStore? store;

  @override
  Widget build(BuildContext context) {
    final url = context.select(
      (BrandingCubit c) => c.state.logoFor(
        darkBackground: darkBackground,
        preferReduced: preferReduced,
      ),
    );
    if (url == null) return const SizedBox.shrink();
    final version = context.select(
      (BrandingCubit c) => c.state.branding?.version ?? 0,
    );
    return _LogoView(
      // Una URL o version nueva vuelve a pedir el logo.
      key: ValueKey('$url#$version'),
      url: url,
      version: version,
      height: height,
      semanticLabel: semanticLabel,
      store: store ?? context.read<LogoStore>(),
    );
  }
}

/// Pide el logo al almacen y lo dibuja solo si de verdad es una imagen: una URL
/// rota, un error del servidor o un archivo que no sirve dejan la app sin
/// logo, sin errores.
class _LogoView extends StatefulWidget {
  const _LogoView({
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
  State<_LogoView> createState() => _LogoViewState();
}

class _LogoViewState extends State<_LogoView> {
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
        if (isSvgLogoUrl(widget.url)) {
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
