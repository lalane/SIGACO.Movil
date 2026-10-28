import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/theme/brand_rules.dart';
import 'package:sigaco_movil/core/theme/brand_seed.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';
import 'package:sigaco_movil/features/branding/data/repositories/branding_repository_impl.dart';

/// Los colores de la identidad de la concesion que llegan a la app: el principal,
/// el secundario y el texto sobre el principal, ademas de los que ya se aplicaban
/// (botones, encabezado y navegacion). Ninguno deja la app ilegible.
void main() {
  Map<String, dynamic> payload(Map<String, String?> colors) => {
    'configurationVersion': 4,
    'colors': colors,
    'logos': {'principal': null, 'reduced': null, 'document': null},
  };

  group('lectura del servidor', () {
    test('trae el principal, el secundario y el texto sobre el principal', () {
      final b = brandingFromConfiguration(
        payload({
          'primaryColor': '#0E7490',
          'secondaryColor': '#F59E0B',
          'buttonColor': '#14B8A6',
          'primaryTextColor': '#FFFFFF',
          'headerColor': '#0B1F3A',
          'menuBackgroundColor': '#0F172A',
        }),
        baseUrl: 'https://api.test',
      )!;
      expect(b.primary, '#14B8A6', reason: 'el boton manda en la accion');
      expect(b.accent, '#0E7490');
      expect(b.secondaryAccent, '#F59E0B');
      expect(b.secondary, '#0F172A', reason: 'el fondo de la navegacion');
      // El texto blanco es el de SIGACO: no cuenta como elegido por la concesion.
      expect(b.primaryText, isNull);
    });

    test('un texto sobre el principal propio si se toma', () {
      final b = brandingFromConfiguration(
        payload({'primaryColor': '#FACC15', 'primaryTextColor': '#1F2937'}),
        baseUrl: 'https://api.test',
      )!;
      expect(b.primaryText, '#1F2937');
    });

    test('los colores provisionales del servidor no cuentan', () {
      final b = brandingFromConfiguration(
        payload({
          'primaryColor': '#1F4E79',
          'secondaryColor': '#F28C28',
          'buttonColor': '#0EA5E9',
        }),
        baseUrl: 'https://api.test',
      )!;
      expect(b.accent, isNull);
      expect(b.secondaryAccent, isNull);
      expect(b.primary, '#0EA5E9');
    });

    test('se guardan y se recuperan del telefono', () {
      final b = brandingFromConfiguration(
        payload({
          'primaryColor': '#0E7490',
          'secondaryColor': '#F59E0B',
          'buttonColor': '#14B8A6',
          'primaryTextColor': '#111827',
        }),
        baseUrl: 'https://api.test',
      )!;
      final again = brandingFromJson(brandingToJson(b))!;
      expect(again.accent, b.accent);
      expect(again.secondaryAccent, b.secondaryAccent);
      expect(again.primaryText, b.primaryText);
      expect(again, b);
    });
  });

  group('reglas de legibilidad', () {
    final base = BrandSeed.tryFromHex(primary: '#14B8A6')!;

    test('un texto que no se lee sobre el principal se descarta', () {
      final seed = BrandSeed.tryFromHex(
        primary: '#14B8A6',
        onPrimary: '#FFFFFF',
      )!;
      expect(
        BrandRules.issuesOf(seed),
        contains(BrandIssue.primaryTextUnreadable),
      );
      expect(BrandRules.sanitize(seed)!.onPrimary, isNull);
    });

    test('un texto que si se lee se conserva', () {
      final seed = BrandSeed.tryFromHex(
        primary: '#14B8A6',
        onPrimary: '#0B1F3A',
      )!;
      expect(BrandRules.sanitize(seed)!.onPrimary, seed.onPrimary);
    });

    test('un secundario que no se distingue en la navegacion se descarta', () {
      final seed = BrandSeed.tryFromHex(
        primary: '#14B8A6',
        navActive: '#1B2433',
      )!;
      expect(
        BrandRules.issuesOf(seed),
        contains(BrandIssue.activeNavigationUnreadable),
      );
      expect(BrandRules.sanitize(seed)!.navActive, isNull);
    });

    test('se mide contra la navegacion de la concesion si la puso', () {
      final onLight = BrandSeed.tryFromHex(
        primary: '#14B8A6',
        secondary: '#FFFFFF',
        navActive: '#FDE68A',
      )!;
      // Un amarillo claro no se ve sobre fondo blanco.
      expect(
        BrandRules.issuesOf(onLight),
        contains(BrandIssue.activeNavigationUnreadable),
      );
      expect(
        BrandRules.sanitize(base.copyWith2(navActive: '#F59E0B'))!.navActive,
        isNotNull,
      );
    });
  });

  group('paleta', () {
    SigacoPalette apply(BrandSeed s) => SigacoPalette.original.withBrand(s);

    test('sin colores nuevos todo queda como antes', () {
      final p = apply(BrandSeed.tryFromHex(primary: '#14B8A6')!);
      expect(p.accent, const Color(0xFF14B8A6));
      expect(p.navSelected, p.accentOnDark);
      expect(p.navActive, isNull);
    });

    test('la opcion activa de la navegacion usa el secundario', () {
      final p = apply(
        BrandSeed.tryFromHex(primary: '#14B8A6', navActive: '#F59E0B')!,
      );
      expect(p.navSelected, const Color(0xFFF59E0B));
      expect(p.navSelected, isNot(p.accentOnDark));
    });

    test(
      'el texto elegido va sobre los botones si son del color principal',
      () {
        final own = apply(
          BrandSeed.tryFromHex(primary: '#FACC15', onPrimary: '#1F2937')!,
        );
        expect(own.onAccent, const Color(0xFF1F2937));

        final same = apply(
          BrandSeed.tryFromHex(
            primary: '#FACC15',
            accent: '#FACC15',
            onPrimary: '#1F2937',
          )!,
        );
        expect(same.onAccent, const Color(0xFF1F2937));
      },
    );

    test(
      'si el boton es de otro color, el texto se calcula sobre el boton',
      () {
        final p = apply(
          BrandSeed.tryFromHex(
            primary: '#14B8A6',
            accent: '#FACC15',
            onPrimary: '#1F2937',
          )!,
        );
        expect(p.onAccent, SigacoPalette.readableOn(const Color(0xFF14B8A6)));
        expect(p.onAccent, isNot(const Color(0xFF1F2937)));
      },
    );

    test('el principal pone el acento de enlaces e iconos', () {
      final p = apply(
        BrandSeed.tryFromHex(primary: '#14B8A6', accent: '#818CF8')!,
      );
      expect(p.accent, const Color(0xFF14B8A6), reason: 'el boton');
      expect(p.accentOnDark, BrandRules.accentOnDark(const Color(0xFF818CF8)));
      expect(
        p.accentOnLight,
        BrandRules.accentOnLight(const Color(0xFF818CF8)),
      );
    });

    test('el acento siempre se lee sobre los fondos oscuros y claros', () {
      for (final hex in ['#14B8A6', '#FACC15', '#1E3A8A', '#F472B6']) {
        final seed = BrandSeed.tryFromHex(primary: '#14B8A6', accent: hex)!;
        final p = apply(seed);
        expect(
          SigacoPalette.contrast(p.accentOnDark, BrandSurfaces.dark),
          greaterThanOrEqualTo(BrandRules.minimumContrast),
          reason: hex,
        );
        expect(
          SigacoPalette.contrast(p.accentOnLight, BrandSurfaces.light),
          greaterThanOrEqualTo(BrandRules.minimumContrast),
          reason: hex,
        );
      }
    });
  });
}

extension on BrandSeed {
  BrandSeed copyWith2({String? navActive}) => BrandSeed(
    primary: primary,
    secondary: secondary,
    headerStart: headerStart,
    headerEnd: headerEnd,
    accent: accent,
    navActive: BrandSeed.parseHex(navActive) ?? this.navActive,
    onPrimary: onPrimary,
  );
}
