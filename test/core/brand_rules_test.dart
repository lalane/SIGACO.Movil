import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/theme/brand_rules.dart';
import 'package:sigaco_movil/core/theme/brand_seed.dart';
import 'package:sigaco_movil/core/theme/color_math.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';
import 'package:sigaco_movil/core/theme/status_colors.dart';

/// Colores por concesionaria (S11, seccion 6): el administrador elige pocos
/// colores y la app garantiza que todo siga legible.
void main() {
  Color c(int rgb) => Color(0xFF000000 | rgb);

  group('BrandSeed.parseHex', () {
    test('acepta #RRGGBB y RRGGBB', () {
      expect(BrandSeed.parseHex('#A3C623'), c(0xA3C623));
      expect(BrandSeed.parseHex('a3c623'), c(0xA3C623));
      expect(BrandSeed.parseHex('  #0EA5E9 '), c(0x0EA5E9));
    });

    test('rechaza lo que no es un color', () {
      for (final v in [
        null,
        '',
        '#FFF',
        '#GGGGGG',
        'rojo',
        '#12345',
        '#1234567',
      ]) {
        expect(BrandSeed.parseHex(v), isNull, reason: '$v');
      }
    });

    test(
      'sin color de accion valido no hay marca; los opcionales se omiten',
      () {
        expect(
          BrandSeed.tryFromHex(primary: 'xx', secondary: '#111827'),
          isNull,
        );
        final seed = BrandSeed.tryFromHex(
          primary: '#0EA5E9',
          secondary: 'no',
          headerStart: '#101828',
        )!;
        expect(seed.secondary, isNull);
        expect(seed.headerStart, c(0x101828));
      },
    );
  });

  group('reglas de la marca', () {
    test('el verde de SIGACO cumple todas las reglas', () {
      expect(BrandRules.issuesOf(BrandSeed(primary: c(0xA3C623))), isEmpty);
    });

    test('colores de marca habituales se aceptan', () {
      for (final rgb in [
        0x0EA5E9,
        0xF97316,
        0x7C3AED,
        0x14B8A6,
        0x1E3A8A,
        0xEC4899,
      ]) {
        final seed = BrandSeed(primary: c(rgb));
        expect(
          BrandRules.issuesOf(seed),
          isEmpty,
          reason: '0x${rgb.toRadixString(16)}',
        );
        expect(BrandRules.sanitize(seed), seed);
      }
    });

    test(
      'se rechazan los colores que se confunden con un estatus (MAR-03)',
      () {
        for (final rgb in [0xDC2626, 0x16A34A, 0x22C55E, 0xFACC15, 0xEF4444]) {
          final seed = BrandSeed(primary: c(rgb));
          expect(
            BrandRules.issuesOf(seed),
            contains(BrandIssue.closeToStatus),
            reason: '0x${rgb.toRadixString(16)}',
          );
          expect(BrandRules.sanitize(seed), isNull);
        }
      },
    );

    test(
      'se rechaza el color de accion sobre el que no se lee texto (MAR-01)',
      () {
        // Gris medio: ni el blanco ni el azul de marca llegan a 4,5:1.
        final seed = BrandSeed(primary: c(0x7B7B7B));
        expect(
          BrandRules.issuesOf(seed),
          contains(BrandIssue.actionTextUnreadable),
        );
        expect(BrandRules.sanitize(seed), isNull);
      },
    );

    test('una cabecera clara se descarta pero conserva el color de accion', () {
      final seed = BrandSeed(
        primary: c(0x0EA5E9),
        headerStart: c(0xF5F5F5),
        headerEnd: c(0xF0F0F0),
        secondary: c(0xFFF3A0),
      );
      final issues = BrandRules.issuesOf(seed);
      expect(
        issues,
        containsAll([
          BrandIssue.headerStartUnreadable,
          BrandIssue.headerEndUnreadable,
          BrandIssue.navigationUnreadable,
        ]),
      );
      final clean = BrandRules.sanitize(seed)!;
      expect(clean.primary, c(0x0EA5E9));
      expect(clean.headerStart, isNull);
      expect(clean.headerEnd, isNull);
      expect(clean.secondary, isNull);
    });

    test('una cabecera oscura y una navegacion oscura se conservan', () {
      final seed = BrandSeed(
        primary: c(0x0EA5E9),
        headerStart: c(0x0B1F3A),
        headerEnd: c(0x07121F),
        secondary: c(0x0F172A),
      );
      expect(BrandRules.sanitize(seed), seed);
    });

    test('los colores de estatus no se pueden cambiar', () {
      expect(StatusColors.all, hasLength(3));
      // Mientras sigan siendo distintos entre si, un estatus no se confunde con otro.
      expect(deltaE(StatusColors.open, StatusColors.closed), greaterThan(35));
      expect(deltaE(StatusColors.open, StatusColors.attended), greaterThan(35));
    });
  });

  group('colores derivados (MAR-02)', () {
    for (final rgb in [
      0xA3C623,
      0x0EA5E9,
      0xF97316,
      0x7C3AED,
      0x14B8A6,
      0x1E3A8A,
      0xEC4899,
      0x0F766E,
    ]) {
      test(
        '0x${rgb.toRadixString(16)}: texto e iconos legibles en ambas superficies',
        () {
          final p = SigacoPalette.night.withBrand(BrandSeed(primary: c(rgb)));
          expect(p.accent, c(rgb));
          // Texto sobre el boton.
          expect(
            contrastRatio(p.onAccent, p.accent),
            greaterThanOrEqualTo(4.5),
          );
          // Acento como texto sobre fondo oscuro y sobre fondo claro.
          expect(
            contrastRatio(p.accentOnDark, BrandSurfaces.dark),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(p.accentOnLight, BrandSurfaces.light),
            greaterThanOrEqualTo(4.5),
          );
          // Acento como icono sobre fondo claro.
          expect(
            contrastRatio(p.accentIconOnLight, BrandSurfaces.light),
            greaterThanOrEqualTo(3),
          );
          // El tono se conserva: es la misma marca, solo mas clara u oscura.
          final hue = HSLColor.fromColor(c(rgb)).hue;
          for (final v in [
            p.accentOnDark,
            p.accentOnLight,
            p.accentIconOnLight,
          ]) {
            final d = (HSLColor.fromColor(v).hue - hue).abs();
            expect(d < 2 || d > 358, isTrue, reason: 'tono $d');
          }
        },
      );
    }

    test('el verde de SIGACO solo se oscurece donde hace falta', () {
      final p = SigacoPalette.night;
      // Sobre fondo oscuro ya se lee: no cambia.
      expect(p.accentOnDark, c(0xA3C623));
      // Sobre fondo claro se oscurece.
      expect(contrastRatio(c(0xA3C623), BrandSurfaces.light), lessThan(2));
      expect(p.accentOnLight, isNot(c(0xA3C623)));
      expect(p.accentIconOnLight, isNot(c(0xA3C623)));
    });

    test(
      'la marca cambia cabecera y navegacion, no las superficies neutras',
      () {
        final seed = BrandSeed(
          primary: c(0x0EA5E9),
          headerStart: c(0x0B1F3A),
          headerEnd: c(0x07121F),
          secondary: c(0x0F172A),
        );
        final night = SigacoPalette.night.withBrand(seed);
        expect(night.gradientTop, c(0x0B1F3A));
        expect(night.gradientBottom, c(0x07121F));
        expect(night.navBackground, c(0x0F172A));
        expect(night.fieldFill, SigacoPalette.night.fieldFill);
        expect(night.error, SigacoPalette.night.error);

        // En el tema Dia el fondo inferior claro es del sistema.
        final day = SigacoPalette.light.withBrand(seed);
        expect(day.gradientTop, c(0x0B1F3A));
        expect(day.gradientBottom, SigacoPalette.light.gradientBottom);
      },
    );

    test('sin cabecera ni navegacion propias quedan los de SIGACO', () {
      final p = SigacoPalette.night.withBrand(BrandSeed(primary: c(0x0EA5E9)));
      expect(p.gradientTop, SigacoPalette.night.gradientTop);
      expect(p.gradientBottom, SigacoPalette.night.gradientBottom);
      expect(p.navBackground, SigacoPalette.night.navBackground);
    });
  });

  group('matematica de color', () {
    test('contraste de referencia', () {
      expect(contrastRatio(c(0xFFFFFF), c(0x000000)), closeTo(21, 0.01));
      expect(contrastRatio(c(0x777777), c(0x777777)), 1);
    });

    test(
      'ensureContrast no toca lo que ya cumple y avanza hacia el limite',
      () {
        expect(
          ensureContrast(c(0xFFFFFF), c(0x000000), minimum: 4.5, lighter: true),
          c(0xFFFFFF),
        );
        final darker = ensureContrast(
          c(0xA3C623),
          c(0xF8FAFC),
          minimum: 4.5,
          lighter: false,
        );
        expect(contrastRatio(darker, c(0xF8FAFC)), greaterThanOrEqualTo(4.5));
      },
    );
  });
}
