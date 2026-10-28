import 'package:flutter/painting.dart';

import 'brand_seed.dart';
import 'color_math.dart';
import 'status_colors.dart';

/// Motivos por los que un color de marca no se acepta (MAR-01 a MAR-03).
enum BrandIssue {
  /// Ni blanco ni el azul de marca se leen sobre el color de accion.
  actionTextUnreadable,

  /// Se confunde con un color de estatus (rojo, ambar o verde).
  closeToStatus,

  /// El texto blanco no se lee sobre el inicio del degradado.
  headerStartUnreadable,

  /// El texto claro no se lee sobre el fin del degradado.
  headerEndUnreadable,

  /// Las etiquetas o el elemento seleccionado no se leen sobre la navegacion.
  navigationUnreadable,

  /// El texto que eligio la concesion no se lee sobre su color principal.
  primaryTextUnreadable,

  /// El color secundario no se distingue como opcion activa sobre la navegacion.
  activeNavigationUnreadable,
}

/// Superficies de la app sobre las que se dibujan los colores de marca.
abstract final class BrandSurfaces {
  /// Campos y tarjetas oscuras.
  static const dark = Color(0xFF1E293B);

  /// Fondo claro del tema Dia.
  static const light = Color(0xFFF8FAFC);

  /// Fondo de la navegacion cuando la concesion no pone el suyo.
  static const navigation = Color(0xFF111827);

  static const navigationLabel = Color(0xFF94A3B8);
  static const textOnBottom = Color(0xFFE2E8F0);
  static const white = Color(0xFFFFFFFF);
}

/// Reglas que impiden que un color mal elegido deje la app ilegible.
abstract final class BrandRules {
  static const minimumContrast = 4.5;
  static const minimumIconContrast = 3.0;

  /// Distancia de color minima respecto de los colores de estatus.
  static const minimumStatusDistance = 35.0;

  /// El color de accion dibujado como texto o icono sobre fondos oscuros.
  static Color accentOnDark(Color primary) => ensureContrast(
    primary,
    BrandSurfaces.dark,
    minimum: minimumContrast,
    lighter: true,
  );

  /// El color de accion dibujado como texto pequeno sobre fondos claros.
  static Color accentOnLight(Color primary) => ensureContrast(
    primary,
    BrandSurfaces.light,
    minimum: minimumContrast,
    lighter: false,
  );

  /// El color de accion dibujado como icono (3:1) sobre fondos claros.
  static Color accentIconOnLight(Color primary) => ensureContrast(
    primary,
    BrandSurfaces.light,
    minimum: minimumIconContrast,
    lighter: false,
  );

  static List<BrandIssue> issuesOf(BrandSeed seed) {
    final issues = <BrandIssue>[];
    final p = seed.primary;
    if (contrastRatio(readableOn(p), p) < minimumContrast) {
      issues.add(BrandIssue.actionTextUnreadable);
    }
    for (final status in StatusColors.all) {
      if (deltaE(p, status) < minimumStatusDistance) {
        issues.add(BrandIssue.closeToStatus);
        break;
      }
    }
    final start = seed.headerStart;
    if (start != null &&
        contrastRatio(BrandSurfaces.white, start) < minimumContrast) {
      issues.add(BrandIssue.headerStartUnreadable);
    }
    final end = seed.headerEnd;
    if (end != null &&
        contrastRatio(BrandSurfaces.textOnBottom, end) < minimumContrast) {
      issues.add(BrandIssue.headerEndUnreadable);
    }
    final onPrimary = seed.onPrimary;
    if (onPrimary != null && contrastRatio(onPrimary, p) < minimumContrast) {
      issues.add(BrandIssue.primaryTextUnreadable);
    }
    final active = seed.navActive;
    if (active != null &&
        contrastRatio(active, seed.secondary ?? BrandSurfaces.navigation) <
            minimumIconContrast) {
      issues.add(BrandIssue.activeNavigationUnreadable);
    }
    final nav = seed.secondary;
    if (nav != null &&
        (contrastRatio(BrandSurfaces.navigationLabel, nav) < minimumContrast ||
            contrastRatio(accentOnDark(p), nav) < minimumIconContrast)) {
      issues.add(BrandIssue.navigationUnreadable);
    }
    return issues;
  }

  /// Marca aceptada. Si el color de accion no sirve no hay marca (se usa la de
  /// SIGACO); los demas colores que no cumplen se descartan uno a uno.
  static BrandSeed? sanitize(BrandSeed seed) {
    final issues = issuesOf(seed);
    if (issues.contains(BrandIssue.actionTextUnreadable) ||
        issues.contains(BrandIssue.closeToStatus)) {
      return null;
    }
    return BrandSeed(
      primary: seed.primary,
      secondary: issues.contains(BrandIssue.navigationUnreadable)
          ? null
          : seed.secondary,
      headerStart: issues.contains(BrandIssue.headerStartUnreadable)
          ? null
          : seed.headerStart,
      headerEnd: issues.contains(BrandIssue.headerEndUnreadable)
          ? null
          : seed.headerEnd,
      accent: seed.accent,
      navActive: issues.contains(BrandIssue.activeNavigationUnreadable)
          ? null
          : seed.navActive,
      onPrimary: issues.contains(BrandIssue.primaryTextUnreadable)
          ? null
          : seed.onPrimary,
    );
  }
}
