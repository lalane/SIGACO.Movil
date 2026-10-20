import 'dart:io';

import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';
import 'module_style.dart';

/// Fondo de las listas de modulo: el degradado del menu de inicio.
class ModuleGradient extends StatelessWidget {
  const ModuleGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.gradientTop, p.menuBottom],
        ),
      ),
      child: child,
    );
  }
}

/// La etiqueta de estado: texto de color sobre un fondo del mismo color muy
/// apagado, con borde.
class ModuleStatusPill extends StatelessWidget {
  const ModuleStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.large = false,
  });

  final String label;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.s(large ? 18 : 12),
        vertical: r.s(large ? 8 : 5),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(r.s(large ? 22 : 12)),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: r.s(large ? 16 : 14),
        ),
      ),
    );
  }
}

/// Una foto del telefono; si no hay o no se puede leer, un fondo de relleno.
class ModulePhoto extends StatelessWidget {
  const ModulePhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.photo_outlined,
  });

  final String? path;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.08),
              p.gradientTop,
            ),
            p.gradientTop,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 56,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
    final file = path;
    if (file == null) return fallback;
    return Image.file(
      File(file),
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// Los estados de una lista sin tarjetas: error con reintento, sin permiso,
/// "aun no disponible" o vacia. Va sobre la hoja clara del mockup.
class ModuleStateView extends StatelessWidget {
  const ModuleStateView({
    super.key,
    required this.icon,
    this.title,
    this.body,
    this.retryLabel,
    this.onRetry,
    this.retryKey,
  });

  final IconData icon;
  final String? title;
  final String? body;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.s(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.s(48), color: const Color(0xFF64748B)),
            SizedBox(height: r.s(16)),
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: moduleSurface,
                  fontSize: r.s(17),
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (body != null && body!.isNotEmpty) ...[
              SizedBox(height: r.s(8)),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            if (retryLabel != null && onRetry != null) ...[
              SizedBox(height: r.s(16)),
              FilledButton(
                key: retryKey,
                onPressed: onRetry,
                child: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El campo de busqueda del historial y, si se pide, el boton de orden.
class ModuleSearchBar extends StatelessWidget {
  const ModuleSearchBar({
    super.key,
    required this.controller,
    required this.focus,
    required this.hint,
    required this.onChanged,
    this.fieldKey,
    this.sortLabel,
    this.sortActive = false,
    this.onSort,
    this.sortKey,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;

  /// Si se da, aparece el boton de orden junto al campo.
  final String? sortLabel;
  final bool sortActive;
  final VoidCallback? onSort;
  final Key? sortKey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(r.s(14)),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(12)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              focusNode: focus,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: p.textOnTop),
              cursorColor: p.accent,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: p.textOnTop.withValues(alpha: 0.55),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: p.textOnTop.withValues(alpha: 0.8),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: EdgeInsets.symmetric(vertical: r.s(14)),
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: p.accent),
                ),
                border: border,
              ),
            ),
          ),
          if (sortLabel != null) ...[
            SizedBox(width: r.s(10)),
            Semantics(
              button: true,
              selected: sortActive,
              child: Material(
                color: sortActive
                    ? p.accent
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(r.s(14)),
                child: InkWell(
                  key: sortKey,
                  borderRadius: BorderRadius.circular(r.s(14)),
                  onTap: onSort,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(14),
                      vertical: r.s(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: r.s(20),
                          color: sortActive ? p.onAccent : p.textOnTop,
                        ),
                        SizedBox(width: r.s(6)),
                        Text(
                          sortLabel!,
                          style: TextStyle(
                            color: sortActive ? p.onAccent : p.textOnTop,
                            fontWeight: FontWeight.w700,
                            fontSize: r.s(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una pestana de [ModuleFilterChips]: el valor, su texto, cuantos hay y el
/// color de la insignia con la cuenta.
class ModuleChip<T> {
  const ModuleChip({
    required this.value,
    required this.id,
    required this.label,
    required this.count,
    this.badge = Colors.white,
  });

  final T value;

  /// Identificador corto para las llaves (`open`, `choque`).
  final String id;
  final String label;
  final int count;
  final Color badge;
}

/// Las pestanas con cuenta de una lista. Hasta tres comparten el ancho; con mas
/// se deslizan de lado.
class ModuleFilterChips<T> extends StatelessWidget {
  const ModuleFilterChips({
    super.key,
    required this.chips,
    required this.selected,
    required this.onSelect,
    required this.keyPrefix,
  });

  final List<ModuleChip<T>> chips;
  final T selected;
  final ValueChanged<T> onSelect;

  /// Prefijo de las llaves: `$keyPrefix-filter-$id` y `$keyPrefix-count-$id`.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scrolls = chips.length > 3;
    if (scrolls) {
      return SizedBox(
        height: r.s(48),
        child: ListView(
          key: Key('$keyPrefix-chips'),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: r.s(16)),
          children: [
            for (final c in chips) ...[
              _chip(context, c),
              SizedBox(width: r.s(8)),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) SizedBox(width: r.s(8)),
            Expanded(child: _chip(context, chips[i])),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, ModuleChip<T> c) {
    final p = context.palette;
    final r = context.responsive;
    final on = c.value == selected;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? p.accent : Colors.white.withValues(alpha: 0.12),
        shape: StadiumBorder(
          side: BorderSide(
            color: on ? p.accent : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          key: Key('$keyPrefix-filter-${c.id}'),
          customBorder: const StadiumBorder(),
          onTap: () => onSelect(c.value),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.s(10),
              vertical: r.s(8),
            ),
            // Con texto grande el contenido se reduce en vez de salirse.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (on) ...[
                    Icon(Icons.check, size: r.s(20), color: p.onAccent),
                    SizedBox(width: r.s(6)),
                  ],
                  Text(
                    c.label,
                    style: TextStyle(
                      color: on ? p.onAccent : p.textOnTop,
                      fontWeight: FontWeight.w700,
                      fontSize: r.s(15),
                    ),
                  ),
                  SizedBox(width: r.s(8)),
                  Container(
                    key: Key('$keyPrefix-count-${c.id}'),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(8),
                      vertical: r.s(2),
                    ),
                    decoration: BoxDecoration(
                      color: c.badge,
                      borderRadius: BorderRadius.circular(r.s(12)),
                    ),
                    child: Text(
                      '${c.count}',
                      style: TextStyle(
                        color: moduleSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: r.s(13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La hoja clara con las tarjetas de una lista y, fijo abajo, el boton
/// principal.
class ModuleListSheet extends StatelessWidget {
  const ModuleListSheet({
    super.key,
    required this.body,
    this.buttonLabel,
    this.onButton,
    this.buttonKey,
    this.buttonIcon = Icons.add,
  });

  final Widget body;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final Key? buttonKey;
  final IconData buttonIcon;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: moduleSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.s(32))),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: body),
          if (buttonLabel != null)
            Padding(
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(8), r.s(16), r.s(12)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Responsive.formMaxWidth,
                  ),
                  child: FilledButton.icon(
                    key: buttonKey,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(r.s(56)),
                      shape: const StadiumBorder(),
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: r.s(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    onPressed: onButton,
                    icon: Icon(buttonIcon),
                    label: Text(buttonLabel!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una cifra del resumen: valor grande, nombre y una linea de apoyo.
class ModuleStat {
  const ModuleStat({
    required this.value,
    required this.label,
    required this.caption,
    this.color = Colors.white,
    this.key,
  });

  final String value;
  final String label;
  final String caption;
  final Color color;
  final Key? key;
}

/// El resumen redondeado de arriba de las listas: de tres a cuatro cifras
/// separadas por una linea.
class ModuleSummaryCard extends StatelessWidget {
  const ModuleSummaryCard({super.key, required this.stats});

  final List<ModuleStat> stats;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      margin: EdgeInsets.fromLTRB(r.s(16), r.s(4), r.s(16), r.s(16)),
      padding: EdgeInsets.symmetric(vertical: r.s(16), horizontal: r.s(8)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.s(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.s(6)),
                  child: Column(
                    key: stats[i].key,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stats[i].value,
                        style: TextStyle(
                          color: stats[i].color,
                          fontSize: r.s(24),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stats[i].label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.s(13),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stats[i].caption,
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
