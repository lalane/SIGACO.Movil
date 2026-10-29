import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';
import '../../support/account_nav.dart';

class _Device implements DeviceInfoSource {
  const _Device(this.text);

  final String text;

  @override
  Future<String> describe() async => text;
}

/// La pantalla de cuenta (APP-MOB-01): version de la app, telefono y la hoja para
/// cambiar la foto de perfil.
void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.1.0',
      buildNumber: '7',
      buildSignature: '',
    ),
  );

  /// [settings]: la pantalla de configuracion; si no, Mi cuenta (el perfil).
  Future<void> openAccount(
    WidgetTester tester, {
    String device = '',
    bool settings = true,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      deviceInfo: _Device(device),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    if (settings) {
      await openAccountSettings(tester);
    } else {
      await openMyAccount(tester);
    }
  }

  testWidgets('muestra la version de la app y el telefono', (tester) async {
    await openAccount(tester, device: 'HONOR NTH-NX9 · Android 13');
    await tester.scrollUntilVisible(
      find.text('Versión de la app'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Versión de la app'), findsOneWidget);
    expect(find.text('1.1.0'), findsOneWidget);
    expect(find.text('HONOR NTH-NX9 · Android 13'), findsOneWidget);
  });

  testWidgets('si no se puede leer el telefono, no muestra esa fila', (
    tester,
  ) async {
    await openAccount(tester);
    await tester.scrollUntilVisible(
      find.text('Versión de la app'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dispositivo'), findsNothing);
  });

  testWidgets('la hoja de la foto ofrece camara y galeria, sin quitar', (
    tester,
  ) async {
    await openAccount(tester, settings: false);
    await tester.tap(find.byKey(const Key('account-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Foto de perfil'), findsOneWidget);
    expect(find.byKey(const Key('photo-camera')), findsOneWidget);
    expect(find.byKey(const Key('photo-gallery')), findsOneWidget);
    expect(
      find.byKey(const Key('photo-remove')),
      findsNothing,
      reason: 'sin foto no hay nada que quitar',
    );
  });
}
