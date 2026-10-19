import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';
import 'module_style.dart';
import 'module_widgets.dart';

/// Un dato de la ficha: icono, nombre y valor.
class ModuleInfo {
  const ModuleInfo(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// Los datos de una ficha en dos columnas, sobre una tarjeta oscura.
class ModuleInfoGrid extends StatelessWidget {
  const ModuleInfoGrid({super.key, required this.items});

  final List<ModuleInfo> items;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: moduleSurface,
        borderRadius: BorderRadius.circular(r.s(16)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i += 2)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < items.length ? r.s(18) : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Cell(info: items[i])),
                  Expanded(
                    child: i + 1 < items.length
                        ? _Cell(info: items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.info});

  final ModuleInfo info;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(info.icon, color: Colors.white, size: r.s(26)),
        SizedBox(width: r.s(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.label,
                style: TextStyle(
                  color: moduleMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: r.s(13),
                ),
              ),
              SizedBox(height: r.s(2)),
              () {
                final text = Text(
                  info.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: r.s(14),
                  ),
                );
                // Un valor de una sola palabra (una coordenada) se reduce
                // en lugar de partirse a media palabra.
                return info.value.contains(' ')
                    ? text
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: text,
                      );
              }(),
            ],
          ),
        ),
      ],
    );
  }
}

class ModuleSectionTitle extends StatelessWidget {
  const ModuleSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.white,
      fontSize: context.responsive.s(20),
      fontWeight: FontWeight.w800,
    ),
  );
}

/// El boton cuadrado verde de la barra de acciones de una ficha.
class ModuleActionButton extends StatelessWidget {
  const ModuleActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.accent,
        borderRadius: BorderRadius.circular(r.s(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(r.s(16)),
          onTap: onTap,
          child: SizedBox(
            width: r.s(58),
            height: r.s(58),
            child: Icon(icon, color: p.onAccent, size: r.s(28)),
          ),
        ),
      ),
    );
  }
}

/// La barra oscura de abajo de una ficha, con sus botones a la derecha.
class ModuleActionBar extends StatelessWidget {
  const ModuleActionBar({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      color: moduleSurface,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(14), r.s(20), r.s(14)),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(width: r.s(16)),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// El aviso de las acciones de la ficha que llegan despues.
void showActionSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).ticketActionSoon)),
    );
}

/// El boton "Volver" redondo de las fichas, sobre una foto o un fondo oscuro.
class ModuleBackPill extends StatelessWidget {
  const ModuleBackPill({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return Material(
      color: Colors.black45,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.s(14), vertical: r.s(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              SizedBox(width: r.s(8)),
              Text(
                l10n.ticketBack,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las fotos de arriba de una ficha (deslizables, con puntos), "Volver" y el
/// estado encima.
class ModuleDetailHero extends StatefulWidget {
  const ModuleDetailHero({
    super.key,
    required this.photoPaths,
    required this.status,
    this.fallbackIcon = Icons.receipt_long_outlined,
    this.backKey,
  });

  final List<String> photoPaths;

  /// Normalmente un [ModuleStatusPill] grande.
  final Widget status;
  final IconData fallbackIcon;
  final Key? backKey;

  @override
  State<ModuleDetailHero> createState() => _ModuleDetailHeroState();
}

class _ModuleDetailHeroState extends State<ModuleDetailHero> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final photos = widget.photoPaths;
    final count = photos.isEmpty ? 1 : photos.length;
    return Column(
      children: [
        SizedBox(
          height: r.s(280),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => ModulePhoto(
                  path: photos.isEmpty ? null : photos[i],
                  fallbackIcon: widget.fallbackIcon,
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black38,
                        Colors.transparent,
                        p.gradientTop,
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(r.s(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModuleBackPill(key: widget.backKey),
                      const Spacer(),
                      widget.status,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (count > 1)
          Padding(
            padding: EdgeInsets.only(top: r.s(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  Container(
                    width: r.s(10),
                    height: r.s(10),
                    margin: EdgeInsets.symmetric(horizontal: r.s(4)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? p.accent
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
