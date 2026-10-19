import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';

/// Cabecera de las pantallas de modulo del mockup nuevo: flecha atras, titulo,
/// un renglon verde debajo (resumen o contexto) y botones redondos a la
/// derecha. Sobre un fondo con degradado va [transparent]; sobre el mapa, solida.
class SigacoModuleHeader extends StatelessWidget {
  const SigacoModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.transparent = false,
    this.showBack = true,
  });

  final String title;

  /// Renglon de contexto en el color de accion, bajo el titulo.
  final String? subtitle;
  final List<Widget> actions;

  /// Sin color propio: deja ver el degradado de la pantalla.
  final bool transparent;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      width: double.infinity,
      color: transparent ? null : p.gradientTop,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.s(8), r.s(8), r.s(12), r.s(12)),
          child: Row(
            children: [
              if (showBack)
                BackButton(key: const Key('module-back'), color: p.textOnTop)
              else
                SizedBox(width: r.s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: r.s(22),
                          color: p.textOnTop,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.accentOnDark,
                          fontSize: r.s(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              for (final a in actions) ...[SizedBox(width: r.s(8)), a],
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton redondo de la cabecera (buscar, filtrar...). [badge] marca cuantos
/// filtros hay activos.
class ModuleHeaderAction extends StatelessWidget {
  const ModuleHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final button = Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: p.textOnTop, size: r.s(22)),
      ),
    );
    if (badge <= 0) return button;
    return Badge.count(
      count: badge,
      backgroundColor: p.accent,
      textColor: p.onAccent,
      child: button,
    );
  }
}
