// ignore_for_file: invalid_use_of_visible_for_testing_member
// Genera capturas del menu y la cuenta con distintos colores de concesionaria,
// para revisar que todo siga legible (S11, seccion 6), sin dispositivo.
// Uso: fvm flutter test tool/capture_brand_test.dart
// Variables: CAPTURE_DIR (salida, por defecto ./capturas/marca) y
// MATERIAL_ICONS_FONT.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../test/support/fakes.dart';
import '../test/support/fonts.dart';
import '../test/support/surface.dart';

const _allModules = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
    NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
    NavigationItem(code: 'REPORTES', name: 'Reportes'),
    NavigationItem(code: 'TICKETS', name: 'Tickets'),
    NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
    NavigationItem(
      code: 'ANTT',
      name: 'ANTT',
      submodules: [NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes')],
    ),
  ],
);

/// (nombre, marca). Sin marca = colores de SIGACO.
const _brands = <(String, ConcessionBranding?)>[
  ('0_sigaco', null),
  ('1_azul', ConcessionBranding(version: 1, primary: '#0EA5E9')),
  ('2_naranja', ConcessionBranding(version: 1, primary: '#F97316')),
  ('3_morado', ConcessionBranding(version: 1, primary: '#7C3AED')),
  ('4_azul_oscuro', ConcessionBranding(version: 1, primary: '#1E3A8A')),
  (
    '5_teal_con_cabecera',
    ConcessionBranding(
      version: 1,
      primary: '#14B8A6',
      headerStart: '#0B2B2A',
      headerEnd: '#06191A',
      secondary: '#0B1F1F',
    ),
  ),
  // Se rechaza (parecido al rojo de estatus): se ve como SIGACO.
  ('6_rojo_rechazado', ConcessionBranding(version: 1, primary: '#DC2626')),
];

void main() {
  final outDir = Platform.environment['CAPTURE_DIR'] ?? 'capturas/marca';
  final iconsFont = Platform.environment['MATERIAL_ICONS_FONT'];
  GlobalKey? boundary;

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final render =
          boundary!.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> launch(
    WidgetTester tester,
    ConcessionBranding? brand,
    String appearance,
  ) async {
    SharedPreferences.setMockInitialValues({'appearance': appearance});
    PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore()..declineBiometricOffer(),
      navigationRepository: FakeNavigationRepository(menu: _allModules),
      brandingRepository: FakeBrandingRepository({'c0': ?brand}),
    );
    boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: SigacoApp(dependencies: deps),
      ),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(SigacoApp));
      for (final a in ['pattern', 'tekia_white', 'tekia_dark']) {
        await precacheImage(AssetImage('assets/branding/$a.png'), ctx);
      }
    });
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  setUpAll(() => Directory(outDir).createSync(recursive: true));

  testWidgets('capturas con colores de concesionaria', (tester) async {
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });
    useSurface(tester, TestSurface.phone);

    for (final (name, brand) in _brands) {
      for (final (appearance, label) in [
        ('original', 'original'),
        ('day', 'dia'),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await launch(tester, brand, appearance);
        await signIn(tester);
        await shoot(tester, 'menu_${name}_$label.png');

        if (appearance == 'original') {
          await tester.tap(find.text('JP'));
          await tester.pumpAndSettle();
          await shoot(tester, 'cuenta_${name}_$label.png');
        }
      }
    }

    // Selector de origen de los colores (solo si la concesion los trae).
    await tester.pumpWidget(const SizedBox());
    await launch(tester, _brands[1].$2, 'original');
    await signIn(tester);
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Preferencias'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await shoot(tester, 'cuenta_preferencias_origen.png');
  });
}
