import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/ui/capped_download.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/branding/presentation/bloc/branding_cubit.dart';
import 'package:sigaco_movil/features/branding/presentation/widgets/concession_logo.dart';

import '../../support/fakes.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

ConcessionBranding _brand({
  String? light,
  String? dark,
  String? reduced,
  int version = 1,
}) => ConcessionBranding(
  version: version,
  primary: '#0EA5E9',
  logoLightUrl: light,
  logoDarkUrl: dark,
  logoReducedUrl: reduced,
);

Future<FakeLogoStore> _show(
  WidgetTester tester,
  ConcessionBranding brand, {
  bool darkBackground = true,
  bool preferReduced = false,
  FakeLogoStore? store,
}) async {
  final logos = store ?? FakeLogoStore();
  final cubit = BrandingCubit(FakeBrandingRepository({'c0': brand}));
  await cubit.load('c0');
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(
          body: ConcessionLogo(
            height: 34,
            darkBackground: darkBackground,
            preferReduced: preferReduced,
            store: logos,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return logos;
}

void main() {
  group('isSvgLogoUrl', () {
    test('reconoce la extension en la ruta', () {
      expect(isSvgLogoUrl('https://cdn.example.com/logo.svg'), isTrue);
      expect(isSvgLogoUrl('https://cdn.example.com/a/b/Logo.SVG'), isTrue);
    });

    test('una URL firmada sigue valiendo: la firma va en la consulta', () {
      expect(
        isSvgLogoUrl('https://cdn.example.com/logo.svg?sig=abc&exp=1'),
        isTrue,
      );
    });

    test('la extension solo cuenta en la ruta, no en la consulta', () {
      expect(isSvgLogoUrl('https://cdn.example.com/logo?f=logo.svg'), isFalse);
      expect(isSvgLogoUrl('https://cdn.example.com/logo.svg.png'), isFalse);
    });

    test('png, jpg, webp y sin extension no son SVG', () {
      for (final u in [
        'https://cdn.example.com/logo.png',
        'https://cdn.example.com/logo.jpg',
        'https://cdn.example.com/logo.webp',
        'https://cdn.example.com/logo',
      ]) {
        expect(isSvgLogoUrl(u), isFalse, reason: u);
      }
    });

    test('una URL invalida no rompe', () {
      expect(isSvgLogoUrl('::no es una url::'), isFalse);
      expect(isSvgLogoUrl(''), isFalse);
    });
  });

  group('looksLikeSvg', () {
    test('un SVG, con o sin cabecera XML', () {
      expect(looksLikeSvg(_bytes(tinySvg)), isTrue);
      expect(looksLikeSvg(_bytes('<?xml version="1.0"?>\n$tinySvg')), isTrue);
      expect(looksLikeSvg(_bytes('<SVG viewBox="0 0 1 1"/>')), isTrue);
    });

    test('una pagina de error con estado 200 no lo es', () {
      expect(
        looksLikeSvg(_bytes('<html><body>Not found</body></html>')),
        isFalse,
      );
      expect(looksLikeSvg(_bytes('')), isFalse);
      expect(looksLikeSvg(tinyPng), isFalse);
    });
  });

  group('readCapped', () {
    test('junta los bloques si caben', () async {
      final out = await readCapped(
        Stream.fromIterable([
          [1, 2],
          [3],
        ]),
        maxBytes: 10,
      );
      expect(out, [1, 2, 3]);
    });

    test('devuelve null si pasa del tope y deja de leer', () async {
      var read = 0;
      Stream<List<int>> chunks() async* {
        for (var i = 0; i < 100; i++) {
          read++;
          yield List<int>.filled(10, 1);
        }
      }

      expect(await readCapped(chunks(), maxBytes: 25), isNull);
      expect(read, lessThan(100), reason: 'no sigue leyendo');
    });
  });

  group('ConcessionLogo', () {
    testWidgets(
      'un logo SVG se pide al almacen y se dibuja a la altura pedida',
      (tester) async {
        final logos = await _show(
          tester,
          _brand(dark: 'https://cdn.example.com/logo.svg'),
        );
        expect(logos.asked, [('https://cdn.example.com/logo.svg', 1)]);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        final size = tester.getSize(find.byType(SvgPicture));
        expect(size.height, 34);
        expect(size.width, closeTo(85, 0.5), reason: 'conserva la proporcion');
      },
    );

    testWidgets('un logo PNG se dibuja como imagen', (tester) async {
      await _show(tester, _brand(dark: 'https://cdn.example.com/logo.png'));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('la variante clara y la oscura pueden ser de tipos distintos', (
      tester,
    ) async {
      final brand = _brand(
        light: 'https://cdn.example.com/claro.png',
        dark: 'https://cdn.example.com/oscuro.svg',
      );
      await _show(tester, brand, darkBackground: true);
      expect(find.byType(SvgPicture), findsOneWidget);
      await _show(tester, brand, darkBackground: false);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('la version de la marca viaja al almacen', (tester) async {
      final logos = await _show(
        tester,
        _brand(dark: 'https://cdn.example.com/logo.png', version: 7),
      );
      expect(logos.asked.single.$2, 7);
    });

    testWidgets('si no se obtiene el logo no deja espacio ni error', (
      tester,
    ) async {
      await _show(
        tester,
        _brand(dark: 'https://cdn.example.com/roto.svg'),
        store: FakeLogoStore(failing: true),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNothing);
      expect(tester.getSize(find.byType(ConcessionLogo)).height, 0);
    });

    testWidgets('un SVG que en realidad no lo es no se dibuja ni da error', (
      tester,
    ) async {
      final store = _NotAnSvgStore();
      await _show(
        tester,
        _brand(dark: 'https://cdn.example.com/logo.svg'),
        store: store,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('sin logo no se dibuja nada', (tester) async {
      await _show(tester, _brand());
      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('variante reducida (DEV-MOB-089)', () {
    final brand = _brand(
      light: 'https://cdn.example.com/claro.png',
      dark: 'https://cdn.example.com/oscuro.png',
      reduced: 'https://cdn.example.com/reducido.png',
    );

    testWidgets('con preferReduced se usa la reducida si existe', (
      tester,
    ) async {
      final logos = await _show(tester, brand, preferReduced: true);
      expect(logos.asked.single.$1, 'https://cdn.example.com/reducido.png');
    });

    testWidgets('sin preferReduced se usa la del fondo', (tester) async {
      final logos = await _show(tester, brand);
      expect(logos.asked.single.$1, 'https://cdn.example.com/oscuro.png');
    });

    testWidgets('si la concesion no tiene reducida se usa la del fondo', (
      tester,
    ) async {
      final logos = await _show(
        tester,
        _brand(dark: 'https://cdn.example.com/oscuro.png'),
        preferReduced: true,
      );
      expect(logos.asked.single.$1, 'https://cdn.example.com/oscuro.png');
    });

    test('la reducida tambien debe ser https', () {
      final state = BrandingState(
        branding: _brand(
          dark: 'https://cdn.example.com/oscuro.png',
          reduced: 'ftp://cdn.example.com/reducido.png',
        ),
      );
      expect(state.logoReducedUrl, isNull);
      expect(
        state.logoFor(darkBackground: true, preferReduced: true),
        'https://cdn.example.com/oscuro.png',
      );
    });
  });
}

class _NotAnSvgStore extends FakeLogoStore {
  @override
  Future<Uint8List?> bytesFor(String url, {int version = 0}) async =>
      _bytes('<html>Error 404</html>');
}
