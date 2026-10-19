import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/app/feature_flags.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/surface.dart';

/// El gestor documental no esta entre los modulos moviles del Business
/// Blueprint (APP-MOB-01 a 09): aunque el usuario tenga el modulo y el permiso,
/// su tarjeta no se ofrece mientras la bandera este apagada.
void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  Future<void> launch(WidgetTester tester, {FeatureFlags? flags}) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(
        menu: menuWith(['PANEL', 'DOCUMENTOS']),
      ),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      features: flags ?? const FeatureFlags(),
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  testWidgets('por omision el gestor documental no sale en el menu', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Gestor documental'), findsNothing);
    // Lo demas del menu sigue ahi.
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('con la bandera encendida vuelve a salir', (tester) async {
    await launch(tester, flags: const FeatureFlags(documents: true));
    expect(find.text('Gestor documental'), findsOneWidget);
  });
}
