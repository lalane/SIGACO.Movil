import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/branding_cubit.dart';

/// Logo de la concesion activa (variante para fondo claro u oscuro). Si no hay
/// logo, o no se puede descargar, no ocupa espacio.
class ConcessionLogo extends StatelessWidget {
  const ConcessionLogo({
    super.key,
    required this.height,
    required this.darkBackground,
    this.semanticLabel,
  });

  final double height;

  /// El logo se dibuja sobre un fondo oscuro.
  final bool darkBackground;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final url = context.select(
      (BrandingCubit c) => c.state.logoFor(darkBackground: darkBackground),
    );
    if (url == null) return const SizedBox.shrink();
    return Image.network(
      url,
      key: ValueKey(url),
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      // Sin conexion o con una URL rota se muestra la app sin logo, sin error.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
