import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

/// Cada concesion de la lista (APP-MOB-01, DEV-MOB-044) muestra su logo si el
/// servidor lo entrega, y el nombre de siempre si no.
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

  group('lectura', () {
    test('toma la ruta del logo de cada concesion', () {
      final c = concessionFromJson({
        'id': 'c1',
        'code': 'NOVA',
        'name': 'Nova 381',
        'logoUrl': '/api/configuration-logos/abc',
      });
      expect(c.logoUrl, '/api/configuration-logos/abc');
    });

    test('sin logo, o con uno vacio, queda en null', () {
      expect(
        concessionFromJson({'id': 'c1', 'code': 'A', 'name': 'A'}).logoUrl,
        isNull,
      );
      expect(
        concessionFromJson({
          'id': 'c1',
          'code': 'A',
          'name': 'A',
          'logoUrl': '  ',
        }).logoUrl,
        isNull,
      );
    });
  });

  testWidgets('al elegir concesion, cada una trae su logo si lo tiene', (
    tester,
  ) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final logos = FakeLogoStore();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(
        result: outcome(
          concessions: 3,
          logoUrls: [
            '/api/configuration-logos/a',
            null,
            '/api/configuration-logos/c',
          ],
        ),
      ),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      logoStore: logos,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Concesion 0'), findsOneWidget);
    expect(find.text('Concesion 1'), findsOneWidget);
    expect(find.text('Concesion 2'), findsOneWidget);
    expect(find.byKey(const Key('concession-logo')), findsNWidgets(2));
    expect(
      logos.asked.map((e) => e.$1),
      containsAll(['/api/configuration-logos/a', '/api/configuration-logos/c']),
    );
  });

  testWidgets('sin ningun logo la lista queda como antes', (tester) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(result: outcome(concessions: 2)),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      logoStore: FakeLogoStore(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Concesion 0'), findsOneWidget);
    expect(find.byKey(const Key('concession-logo')), findsNothing);
  });
}
