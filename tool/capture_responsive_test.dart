// ignore_for_file: invalid_use_of_visible_for_testing_member
// Genera capturas de las pantallas clave en las tres clases de tamano
// (compacta, media y expandida), sin dispositivo y con datos de ejemplo.
// Uso: fvm flutter test tool/capture_responsive_test.dart
// Variables: CAPTURE_DIR (salida, por defecto ./capturas/responsivo) y
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
import 'package:sigaco_movil/features/auth/presentation/pages/recovery_page.dart';
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

/// (nombre, ancho dp, alto dp, densidad)
const _surfaces = <(String, Size, double)>[
  ('1_compacta', Size(360, 800), 3),
  ('2_media', Size(720, 1024), 2),
  ('3_expandida', Size(1280, 800), 2),
  ('4_media_horizontal', Size(800, 360), 3),
];

void main() {
  final outDir = Platform.environment['CAPTURE_DIR'] ?? 'capturas/responsivo';
  final iconsFont = Platform.environment['MATERIAL_ICONS_FONT'];
  GlobalKey? boundary;

  Future<void> shoot(WidgetTester tester, String name, double ratio) async {
    await tester.runAsync(() async {
      final render =
          boundary!.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> launch(
    WidgetTester tester, {
    FakeAuthRepository? repo,
    bool skipSplash = true,
    FakeCredentialStore? store,
    String? deepLink,
  }) async {
    // Enlace que abre la app (por ejemplo el regreso del navegador).
    if (deepLink == null) {
      tester.platformDispatcher.clearDefaultRouteNameTestValue();
    } else {
      tester.platformDispatcher.defaultRouteNameTestValue = deepLink;
    }
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: repo ?? FakeAuthRepository(),
      credentialStore:
          store ?? (FakeCredentialStore()..declineBiometricOffer()),
      navigationRepository: FakeNavigationRepository(menu: _allModules),
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
    if (skipSplash) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.ensureVisible(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  setUpAll(() => Directory(outDir).createSync(recursive: true));

  testWidgets('capturas por clase de tamano', (tester) async {
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });

    for (final (cls, size, ratio) in _surfaces) {
      useSurface(tester, size, pixelRatio: ratio);

      Future<void> reset() => tester.pumpWidget(const SizedBox());

      // Arranque
      await launch(tester, skipSplash: false);
      await tester.pump(const Duration(milliseconds: 300));
      await shoot(tester, '00_arranque_$cls.png', ratio);

      // Login
      await reset();
      await launch(tester);
      await shoot(tester, '01_login_$cls.png', ratio);

      // Recuperar contrasena (pantalla de un paso)
      await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      await shoot(tester, '02_recuperar_$cls.png', ratio);

      // Recuperar contrasena: enlace enviado y pasos para volver
      // El campo de la pantalla de recuperacion (la de login sigue debajo).
      final emailField = find.descendant(
        of: find.byType(RecoveryPage),
        matching: find.byType(EditableText),
      );
      await tester.scrollUntilVisible(
        emailField,
        100,
        scrollable: find
            .descendant(
              of: find.byType(RecoveryPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(emailField, 'a@b.com');
      final send = find.descendant(
        of: find.byType(RecoveryPage),
        matching: find.byType(FilledButton),
      );
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.tap(send);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Qué hacer ahora'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await shoot(tester, '02b_recuperar_enviado_$cls.png', ratio);

      // Regreso del navegador: sigaco://app/login?reset=ok
      await reset();
      final remembered = FakeCredentialStore();
      await remembered.setRemembered(
        remember: true,
        credentials: (email: 'jperez@example.com', password: 'Vieja#1234'),
      );
      await launch(tester, store: remembered, deepLink: '/login?reset=ok');
      await shoot(tester, '02c_regreso_restablecer_$cls.png', ratio);

      // Selector de concesion
      await reset();
      await launch(
        tester,
        repo: FakeAuthRepository(result: outcome(concessions: 2)),
      );
      await signIn(tester);
      await shoot(tester, '03_selector_concesion_$cls.png', ratio);

      // Menu principal
      await reset();
      await launch(tester);
      await signIn(tester);
      await shoot(tester, '04_menu_$cls.png', ratio);

      // Cuenta
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await shoot(tester, '05_cuenta_$cls.png', ratio);

      // Cuenta: cambiar de concesion
      await tester.scrollUntilVisible(
        find.text('Cambiar de concesión'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar de concesión'));
      await tester.pumpAndSettle();
      await shoot(tester, '06_cuenta_cambiar_concesion_$cls.png', ratio);

      // Aviso de sesion por vencer
      await reset();
      final nearExpiry = FakeAuthRepository()
        ..activity = DateTime.now().subtract(
          const Duration(minutes: 9, seconds: 30),
        );
      await launch(tester, repo: nearExpiry);
      await signIn(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await shoot(tester, '07_sesion_por_vencer_$cls.png', ratio);

      await reset();
    }
  });
}
