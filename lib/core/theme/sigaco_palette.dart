import 'package:flutter/material.dart';

import 'brand_rules.dart';
import 'brand_seed.dart';
import 'color_math.dart';

/// Paleta del diseno v2. Es una extension del tema para poder reemplazarla
/// con los colores de la concesion activa ([withBrand]).
@immutable
class SigacoPalette extends ThemeExtension<SigacoPalette> {
  const SigacoPalette({
    required this.gradientTop,
    required this.gradientBottom,
    required this.card,
    required this.fieldFill,
    required this.fieldBorder,
    required this.accent,
    required this.onAccent,
    required this.accentOnDark,
    required this.accentOnLight,
    required this.accentIconOnLight,
    required this.navBackground,
    required this.textOnTop,
    required this.textOnBottom,
    required this.hint,
    required this.error,
    required this.menuBottom,
  });

  final Color gradientTop;
  final Color gradientBottom;
  final Color card;
  final Color fieldFill;
  final Color fieldBorder;

  /// Color de accion: relleno de botones, seleccion y avatar.
  final Color accent;

  /// Texto sobre [accent]: el que mas contraste da (COL-03).
  final Color onAccent;

  /// [accent] como texto o icono sobre superficies oscuras (4,5:1 o mas).
  final Color accentOnDark;

  /// [accent] como texto pequeno sobre superficies claras (4,5:1 o mas).
  final Color accentOnLight;

  /// [accent] como icono sobre superficies claras (3:1 o mas).
  final Color accentIconOnLight;

  /// Fondo de la barra o riel de navegacion.
  final Color navBackground;
  final Color textOnTop;
  final Color textOnBottom;
  final Color hint;
  final Color error;

  /// Color final del degradado del menu principal (diseno v2).
  final Color menuBottom;

  /// El fondo inferior del tema es claro (Dia).
  bool get lightBottom => gradientBottom.computeLuminance() > 0.5;

  /// [accent] como texto o icono sobre el fondo inferior del tema.
  Color get accentOnBottom => lightBottom ? accentOnLight : accentOnDark;

  /// Contraste WCAG entre dos colores (de 1 a 21).
  static double contrast(Color a, Color b) => contrastRatio(a, b);

  /// Texto (blanco o azul de marca) con mas contraste sobre [background].
  static Color readableOn(Color background) => _readable(background);

  static Color _readable(Color background) =>
      contrastRatio(background, const Color(0xFF160F3E)) >=
          contrastRatio(background, Colors.white)
      ? const Color(0xFF160F3E)
      : Colors.white;

  static const _lime = Color(0xFFA3C623);

  static SigacoPalette _base({
    required Color gradientBottom,
    required Color fieldFill,
    required Color fieldBorder,
    required Color textOnBottom,
    required Color hint,
    required Color error,
    required Color menuBottom,
  }) => SigacoPalette(
    gradientTop: const Color(0xFF160F3E),
    gradientBottom: gradientBottom,
    card: const Color(0x1BC8DFEB),
    fieldFill: fieldFill,
    fieldBorder: fieldBorder,
    accent: _lime,
    onAccent: _readable(_lime),
    accentOnDark: BrandRules.accentOnDark(_lime),
    accentOnLight: BrandRules.accentOnLight(_lime),
    accentIconOnLight: BrandRules.accentIconOnLight(_lime),
    navBackground: const Color(0xFF111827),
    textOnTop: Colors.white,
    textOnBottom: textOnBottom,
    hint: hint,
    error: error,
    menuBottom: menuBottom,
  );

  /// Login modo oscuro: degradado #160f3e a #0d1b2a, contenedor #1bc8dfeb.
  static final night = _base(
    gradientBottom: const Color(0xFF0D1B2A),
    fieldFill: const Color(0xFF1E293B),
    fieldBorder: const Color(0xFF334155),
    textOnBottom: const Color(0xFFE2E8F0),
    hint: const Color(0xFF94A3B8),
    error: const Color(0xFFF87171),
    menuBottom: const Color(0xFF64748B),
  );

  /// Apariencia "Original": paleta de marca SIGACO (azul #160f3e y verde #a3c623).
  /// Es el valor por defecto y la base sobre la que se aplican los colores de
  /// la concesion.
  static final original = night;

  /// Login modo dia: degradado #160f3e a #f8fafc.
  static final light = _base(
    gradientBottom: const Color(0xFFF8FAFC),
    fieldFill: Colors.white,
    fieldBorder: const Color(0xFFE2E8F0),
    textOnBottom: const Color(0xFF1E293B),
    // Gris con contraste de 4,5:1 o mas sobre blanco (el anterior daba 2,6:1).
    hint: const Color(0xFF64748B),
    error: const Color(0xFFDC2626),
    menuBottom: const Color(0xFFF8FAFC),
  );

  /// Aplica los colores de la concesion. Los colores de estatus, error y las
  /// superficies neutras no cambian; lo derivado (texto sobre el color de
  /// accion y las variantes para fondo claro y oscuro) se recalcula (capa 3).
  SigacoPalette withBrand(BrandSeed seed) => copyWith(
    gradientTop: seed.headerStart,
    // En los temas claros el fondo inferior es del sistema.
    gradientBottom: lightBottom ? null : seed.headerEnd,
    accent: seed.primary,
    onAccent: _readable(seed.primary),
    accentOnDark: BrandRules.accentOnDark(seed.primary),
    accentOnLight: BrandRules.accentOnLight(seed.primary),
    accentIconOnLight: BrandRules.accentIconOnLight(seed.primary),
    navBackground: seed.secondary,
  );

  @override
  SigacoPalette copyWith({
    Color? gradientTop,
    Color? gradientBottom,
    Color? card,
    Color? fieldFill,
    Color? fieldBorder,
    Color? accent,
    Color? onAccent,
    Color? accentOnDark,
    Color? accentOnLight,
    Color? accentIconOnLight,
    Color? navBackground,
    Color? textOnTop,
    Color? textOnBottom,
    Color? hint,
    Color? error,
    Color? menuBottom,
  }) => SigacoPalette(
    gradientTop: gradientTop ?? this.gradientTop,
    gradientBottom: gradientBottom ?? this.gradientBottom,
    card: card ?? this.card,
    fieldFill: fieldFill ?? this.fieldFill,
    fieldBorder: fieldBorder ?? this.fieldBorder,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentOnDark: accentOnDark ?? this.accentOnDark,
    accentOnLight: accentOnLight ?? this.accentOnLight,
    accentIconOnLight: accentIconOnLight ?? this.accentIconOnLight,
    navBackground: navBackground ?? this.navBackground,
    textOnTop: textOnTop ?? this.textOnTop,
    textOnBottom: textOnBottom ?? this.textOnBottom,
    hint: hint ?? this.hint,
    error: error ?? this.error,
    menuBottom: menuBottom ?? this.menuBottom,
  );

  @override
  SigacoPalette lerp(ThemeExtension<SigacoPalette>? other, double t) {
    if (other is! SigacoPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SigacoPalette(
      gradientTop: mix(gradientTop, other.gradientTop),
      gradientBottom: mix(gradientBottom, other.gradientBottom),
      card: mix(card, other.card),
      fieldFill: mix(fieldFill, other.fieldFill),
      fieldBorder: mix(fieldBorder, other.fieldBorder),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentOnDark: mix(accentOnDark, other.accentOnDark),
      accentOnLight: mix(accentOnLight, other.accentOnLight),
      accentIconOnLight: mix(accentIconOnLight, other.accentIconOnLight),
      navBackground: mix(navBackground, other.navBackground),
      textOnTop: mix(textOnTop, other.textOnTop),
      textOnBottom: mix(textOnBottom, other.textOnBottom),
      hint: mix(hint, other.hint),
      error: mix(error, other.error),
      menuBottom: mix(menuBottom, other.menuBottom),
    );
  }
}

extension SigacoPaletteContext on BuildContext {
  SigacoPalette get palette => Theme.of(this).extension<SigacoPalette>()!;
}
