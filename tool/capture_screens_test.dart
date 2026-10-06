// ignore_for_file: invalid_use_of_visible_for_testing_member
// Genera capturas (1080x2400) de todas las pantallas implementadas, sin
// dispositivo y con datos de ejemplo.
// Uso: fvm flutter test tool/capture_screens_test.dart
// Variables: CAPTURE_DIR (salida, por defecto ./capturas) y MATERIAL_ICONS_FONT.
import 'dart:async';
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
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../test/support/fakes.dart';
import '../test/support/fonts.dart';

class _CaptureNetwork implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

class _CaptureDevice implements DeviceInfoSource {
  @override
  Future<String> describe() async => 'Samsung SM-A155M · Android 14';
}

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

void main() {
  final outDir = Platform.environment['CAPTURE_DIR'] ?? 'capturas';
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

  /// Abre la app desde cero con los datos de ejemplo indicados.
  Future<void> launch(
    WidgetTester tester, {
    String appearance = 'original',
    String locale = 'es',
    FakeAuthRepository? repo,
    bool skipSplash = true,
    FakeCredentialStore? store,
    String? deepLink,
    FakeNavigationRepository? nav,
    ConnectivitySource? network,
    Stream<bool>? server,
  }) async {
    // Enlace que abre la app (por ejemplo el regreso del navegador).
    if (deepLink == null) {
      tester.platformDispatcher.clearDefaultRouteNameTestValue();
    } else {
      tester.platformDispatcher.defaultRouteNameTestValue = deepLink;
    }
    SharedPreferences.setMockInitialValues({
      'appearance': appearance,
      'app_locale': locale,
    });
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
      // Por omision el aviso de biometria ya esta rechazado, para no tapar las vistas.
      credentialStore:
          store ?? (FakeCredentialStore()..declineBiometricOffer()),
      navigationRepository: nav ?? FakeNavigationRepository(menu: _allModules),
      connectivity: network ?? const AlwaysOnlineSource(),
      serverReachable: server ?? const Stream<bool>.empty(),
      deviceInfo: _CaptureDevice(),
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
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> reset(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  setUpAll(() => Directory(outDir).createSync(recursive: true));

  testWidgets('capturas de todas las pantallas', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });

    // Arranque
    await launch(tester, skipSplash: false);
    await tester.pump(const Duration(milliseconds: 300));
    await shoot(tester, '00_arranque.png');

    // Login: tres apariencias, error y portugues
    for (final (a, n) in [
      ('original', '01_login_original'),
      ('day', '02_login_dia'),
      ('night', '03_login_noche'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a);
      await shoot(tester, '$n.png');
    }
    await reset(tester);
    await launch(
      tester,
      repo: FakeAuthRepository()..failure = AuthError.invalidCredentials,
    );
    await signIn(tester);
    await shoot(tester, '04_login_error.png');
    await reset(tester);
    await launch(tester, locale: 'pt');
    await shoot(tester, '05_login_portugues.png');

    // Recuperar contrasena
    await reset(tester);
    await launch(tester);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await shoot(tester, '06_recuperar_contrasena.png');

    // Pasos que exige el servidor tras el login
    for (final (result, n) in [
      (outcome(mfa: true, active: 'c0'), '07_mfa_codigo'),
      (outcome(enroll: true, active: 'c0'), '08_mfa_enrolamiento'),
      (outcome(force: true, active: 'c0'), '09_cambio_obligatorio_contrasena'),
      (outcome(concessions: 2), '10_selector_concesion'),
    ]) {
      await reset(tester);
      await launch(tester, repo: FakeAuthRepository(result: result));
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Menu principal
    for (final (a, l, n) in [
      ('original', 'es', '11_menu_original'),
      ('day', 'es', '12_menu_dia'),
      ('night', 'es', '13_menu_noche'),
      ('original', 'pt', '14_menu_portugues'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a, locale: l);
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Cuenta
    for (final (a, n) in [
      ('original', '15_cuenta_original'),
      ('day', '16_cuenta_dia'),
      ('night', '17_cuenta_noche'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a);
      await signIn(tester);
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await shoot(tester, '$n.png');
    }

    // Cuenta: cambiar contrasena y cambiar de concesion
    await reset(tester);
    await launch(tester);
    await signIn(tester);
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar de concesión'));
    await tester.pumpAndSettle();
    await shoot(tester, '19_cuenta_cambiar_concesion.png');
    await tester.tapAt(const Offset(180, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    await shoot(tester, '18_cuenta_cambiar_contrasena.png');

    // Aviso de sesion por vencer (a 30 s del cierre por inactividad)
    await reset(tester);
    final nearExpiry = FakeAuthRepository()
      ..activity = DateTime.now().subtract(
        const Duration(minutes: 9, seconds: 30),
      );
    await launch(tester, repo: nearExpiry);
    await signIn(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await shoot(tester, '20_sesion_por_vencer.png');

    // Aviso para activar la biometria tras el primer acceso con contrasena
    await reset(tester);
    await launch(tester, store: FakeCredentialStore());
    await signIn(tester);
    await shoot(tester, '21_oferta_biometria.png');

    // Cuenta con la biometria activada desde el aviso
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await shoot(tester, '22_cuenta_biometria_activa.png');

    // Recuperar contrasena: enlace enviado y pasos para volver
    await reset(tester);
    await launch(tester);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'jperez@example.com',
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await shoot(tester, '23_recuperar_enviado.png');

    // Regreso del navegador tras restablecer: sigaco://app/login?reset=ok
    await reset(tester);
    final remembered = FakeCredentialStore();
    await remembered.setRemembered(
      remember: true,
      credentials: (email: 'jperez@example.com', password: 'Vieja#1234'),
    );
    await launch(tester, store: remembered, deepLink: '/login?reset=ok');
    await shoot(tester, '24_regreso_restablecer.png');

    // Perfil: seguridad y preferencias (idioma, apariencia) al final de la lista
    await reset(tester);
    await launch(
      tester,
      repo: FakeAuthRepository(result: outcome(mfa: true, active: 'c0')),
    );
    await signIn(tester);
    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await shoot(tester, '25_cuenta_seguridad_preferencias.png');

    // Hoja para elegir el idioma
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await shoot(tester, '26_cuenta_elegir_idioma.png');
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    // Volver a configurar la verificacion en dos pasos
    await tester.tap(find.text('Verificación en dos pasos'));
    await tester.pumpAndSettle();
    await shoot(tester, '27_mfa_reconfigurar.png');
    await tester.tap(find.text('Generar clave nueva'));
    await tester.pumpAndSettle();
    await shoot(tester, '28_mfa_clave_nueva.png');

    // Estados de acceso del inicio (MQ-MOB-08): sin permiso, error al validar
    // los accesos y perfil sin modulos.
    for (final (nav, n) in [
      (
        FakeNavigationRepository(failure: NavigationError.permissionDenied),
        '29_sin_permiso',
      ),
      (
        FakeNavigationRepository(failure: NavigationError.server),
        '30_error_autorizacion',
      ),
      (
        FakeNavigationRepository(menu: const NavigationMenu()),
        '31_perfil_sin_modulos',
      ),
    ]) {
      await reset(tester);
      await launch(tester, nav: nav);
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Sin conexion (MQ-MOB-10): aviso persistente y aviso al volver la red.
    await reset(tester);
    final network = _CaptureNetwork();
    final server = StreamController<bool>.broadcast();
    await launch(tester, network: network, server: server.stream);
    await signIn(tester);
    server.add(true);
    await tester.pump();
    network.controller.add(false);
    await tester.pumpAndSettle();
    await shoot(tester, '32_sin_conexion.png');
    network.controller.add(true);
    await tester.pump();
    await tester.pump();
    await shoot(tester, '33_conexion_restablecida.png');
    await tester.pump(const Duration(seconds: 4));

    // Cuenta con los datos del telefono y la ultima conexion.
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -330));
    await tester.pumpAndSettle();
    await shoot(tester, '34_cuenta_dispositivo.png');
    await server.close();
    await network.controller.close();
  });
}
