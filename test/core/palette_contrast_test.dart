import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';

/// COL-02 / COL-03: texto con contraste de al menos 4,5:1 sobre su fondo.
void main() {
  const minimum = 4.5;

  for (final (name, p) in [
    ('Original / Noche', SigacoPalette.night),
    ('Dia', SigacoPalette.light),
  ]) {
    group(name, () {
      test('el texto sobre el color de accion se lee', () {
        expect(
          SigacoPalette.contrast(p.onAccent, p.accent),
          greaterThanOrEqualTo(minimum),
        );
      });

      test('el texto de cada fondo se lee', () {
        expect(
          SigacoPalette.contrast(p.textOnTop, p.gradientTop),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          SigacoPalette.contrast(p.textOnBottom, p.gradientBottom),
          greaterThanOrEqualTo(minimum),
        );
      });

      test('el texto de ayuda de los campos se lee', () {
        expect(
          SigacoPalette.contrast(p.hint, p.fieldFill),
          greaterThanOrEqualTo(minimum),
        );
      });

      test('el error se lee sobre el fondo del formulario', () {
        expect(
          SigacoPalette.contrast(p.error, p.fieldFill),
          greaterThanOrEqualTo(minimum),
        );
      });
    });
  }

  group('readableOn (base para los colores de cada concesion)', () {
    test('elige azul de marca sobre colores claros y blanco sobre oscuros', () {
      const navy = Color(0xFF160F3E);
      const white = Color(0xFFFFFFFF);
      expect(SigacoPalette.readableOn(const Color(0xFFA3C623)), navy);
      expect(SigacoPalette.readableOn(const Color(0xFFFFD60A)), navy);
      expect(SigacoPalette.readableOn(white), navy);
      expect(SigacoPalette.readableOn(navy), white);
      expect(SigacoPalette.readableOn(const Color(0xFF1D4ED8)), white);
      expect(SigacoPalette.readableOn(const Color(0xFFB91C1C)), white);
    });

    test('el resultado cumple el contraste en colores de marca habituales', () {
      for (final c in const [
        Color(0xFFA3C623),
        Color(0xFF0EA5E9),
        Color(0xFFF59E0B),
        Color(0xFF16A34A),
        Color(0xFF7C3AED),
        Color(0xFFDC2626),
        Color(0xFFFACC15),
        Color(0xFF0F172A),
      ]) {
        expect(
          SigacoPalette.contrast(SigacoPalette.readableOn(c), c),
          greaterThanOrEqualTo(minimum),
          reason: 'color 0x${c.toARGB32().toRadixString(16)}',
        );
      }
    });

    test('mide el contraste de referencia del blanco sobre el lima', () {
      expect(
        SigacoPalette.contrast(
          const Color(0xFFFFFFFF),
          const Color(0xFFA3C623),
        ),
        closeTo(1.97, 0.01),
      );
    });
  });
}
