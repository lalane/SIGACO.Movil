import 'package:flutter/material.dart';

import '../settings/settings_cubit.dart';
import 'brand_seed.dart';
import 'sigaco_palette.dart';

abstract final class AppTheme {
  /// Tema de la apariencia elegida. Con [brand] se aplican los colores de la
  /// concesion; sin el, los de SIGACO.
  static ThemeData forAppearance(Appearance a, {BrandSeed? brand}) {
    final (brightness, base) = switch (a) {
      Appearance.original => (Brightness.dark, SigacoPalette.original),
      Appearance.day => (Brightness.light, SigacoPalette.light),
      Appearance.night => (Brightness.dark, SigacoPalette.night),
    };
    return _build(brightness, brand == null ? base : base.withBrand(brand));
  }

  static ThemeData _build(Brightness brightness, SigacoPalette p) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        error: p.error,
      ),
      scaffoldBackgroundColor: p.gradientBottom,
      // Dialogos y hojas inferiores con la paleta de la marca, no la de Material.
      dialogTheme: DialogThemeData(
        backgroundColor: p.fieldFill,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textOnBottom,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: p.textOnBottom,
        ),
      ),
      // Botones de texto (dialogos, reintentar): color legible sobre la superficie
      // del tema, que es oscura en Original/Noche y clara en Dia.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accentOnBottom),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.fieldFill,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.fieldFill,
      ),
      extensions: [p],
    );
  }
}
