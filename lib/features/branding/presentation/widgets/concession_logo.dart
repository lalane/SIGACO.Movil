import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/branding/logo_image.dart';
import '../../../../core/ui/logo_store.dart';
import '../bloc/branding_cubit.dart';

export '../../../../core/branding/logo_image.dart'
    show isSvgLogoUrl, looksLikeSvg;

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
    return LogoImage(
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
