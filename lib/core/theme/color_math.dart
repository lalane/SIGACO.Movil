import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Azul de marca: es el texto "oscuro" sobre colores claros.
const _brandDark = Color(0xFF160F3E);
const _white = Color(0xFFFFFFFF);

double _lum(Color c) => c.computeLuminance();

/// Contraste WCAG entre dos colores (de 1 a 21).
double contrastRatio(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Texto (blanco o azul de marca) con mas contraste sobre [background].
Color readableOn(Color background) =>
    contrastRatio(background, _brandDark) >= contrastRatio(background, _white)
    ? _brandDark
    : _white;

/// Cambia la luminosidad (HSL) de [color], sin tocar su tono, hasta que su
/// contraste con [surface] sea de al menos [minimum]. Si ya cumple, lo devuelve
/// igual. [lighter] aclara (para fondos oscuros); si no, oscurece.
Color ensureContrast(
  Color color,
  Color surface, {
  required double minimum,
  required bool lighter,
}) {
  if (contrastRatio(color, surface) >= minimum) return color;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 100; i++) {
    final next = (hsl.lightness + (lighter ? 0.01 : -0.01)).clamp(0.0, 1.0);
    if (next == hsl.lightness) break;
    hsl = hsl.withLightness(next);
    final candidate = hsl.toColor();
    if (contrastRatio(candidate, surface) >= minimum) return candidate;
  }
  return hsl.toColor();
}

double _linear(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

(double, double, double) _lab(Color c) {
  final r = _linear(c.r);
  final g = _linear(c.g);
  final b = _linear(c.b);
  final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
  final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
  final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)));
}

/// Distancia de color CIE76 (Delta E): por debajo de ~35 dos colores se
/// confunden con facilidad.
double deltaE(Color a, Color b) {
  final (l1, a1, b1) = _lab(a);
  final (l2, a2, b2) = _lab(b);
  return math.sqrt(
    math.pow(l1 - l2, 2) + math.pow(a1 - a2, 2) + math.pow(b1 - b2, 2),
  );
}
