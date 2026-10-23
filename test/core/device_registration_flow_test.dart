import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/device/device_registrar.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/map_fakes.dart';
import '../support/surface.dart';

class _Remote implements DeviceRemote {
  final sent = <DeviceProfile>[];

  @override
  Future<DeviceRegistration?> register(DeviceProfile profile) async {
    sent.add(profile);
    return const DeviceRegistration(status: 'ACTIVO');
  }
}

class _Source implements DeviceProfileSource {
  @override
  Future<DeviceProfile?> read() async => const DeviceProfile(
    identifier: 'dev-1',
    appVersion: '1.0.1+23',
    osVersion: 'Android 14',
    model: 'Samsung SM-A155M',
  );
}

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

  testWidgets('al iniciar sesion el telefono se registra con su version', (
    tester,
  ) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.largePhone);
    SharedPreferences.setMockInitialValues({});
    final remote = _Remote();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(menu: menuWith(['PANEL'])),
      brandingRepository: FakeBrandingRepository(const {}),
      logoStore: FakeLogoStore(),
      roadSegmentsRepository: FakeRoadSegmentsRepository(),
      deviceRegistrar: DeviceRegistrar(source: _Source(), remote: remote),
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Antes de entrar no hay sesion: no se registra nada.
    expect(remote.sent, isEmpty);

    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(remote.sent, hasLength(1));
    expect(remote.sent.single.appVersion, '1.0.1+23');
    expect(remote.sent.single.identifier, 'dev-1');
  });
}
