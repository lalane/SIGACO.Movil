import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';
import '../../support/account_nav.dart';

class _Network implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

class _Device implements DeviceInfoSource {
  @override
  Future<String> describe() async => 'Samsung SM-A155M · Android 14';
}

/// Aviso «Sin conexion» (MQ-MOB-10) y datos del telefono en la cuenta.
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

  Future<(_Network, StreamController<bool>, FakeNavigationRepository)> launch(
    WidgetTester tester, {
    bool signIn = true,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final network = _Network();
    final server = StreamController<bool>.broadcast();
    final nav = FakeNavigationRepository();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: nav,
      accessRefreshGap: Duration.zero,
      connectivity: network,
      serverReachable: server.stream,
      deviceInfo: _Device(),
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    if (signIn) {
      await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
      await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
    }
    addTearDown(network.controller.close);
    addTearDown(server.close);
    return (network, server, nav);
  }

  final offline = find.byKey(const Key('connection-offline'));
  final restored = find.byKey(const Key('connection-restored'));

  testWidgets('sin red del telefono aparece el aviso y al volver se retira', (
    tester,
  ) async {
    final (network, _, _) = await launch(tester);
    expect(offline, findsNothing);

    network.controller.add(false);
    await tester.pumpAndSettle();
    expect(offline, findsOneWidget);
    expect(find.text('Sin conexión'), findsOneWidget);

    network.controller.add(true);
    await tester.pump();
    await tester.pump();
    expect(offline, findsNothing);
    expect(restored, findsOneWidget);
    expect(find.text('Conexión restablecida'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(restored, findsNothing);
  });

  testWidgets('el aviso no tapa el contenido ni la barra de estado', (
    tester,
  ) async {
    final (network, _, _) = await launch(tester);
    final before = tester.getTopLeft(find.text('MÓDULOS')).dy;
    network.controller.add(false);
    await tester.pumpAndSettle();
    final bar = tester.getRect(offline);
    expect(bar.top, 0);
    // El contenido baja lo que mide el aviso en lugar de quedar debajo.
    expect(tester.getTopLeft(find.text('MÓDULOS')).dy, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'una peticion fallida por red tambien lo muestra, con la ultima conexion',
    (tester) async {
      final (_, server, _) = await launch(tester);
      server.add(true); // una respuesta correcta guarda la hora de contacto
      await tester.pump();
      server.add(false);
      await tester.pumpAndSettle();
      expect(offline, findsOneWidget);
      expect(find.textContaining('última conexión'), findsOneWidget);
    },
  );

  testWidgets('antes de iniciar sesion no se muestra el aviso', (tester) async {
    final (network, _, _) = await launch(tester, signIn: false);
    network.controller.add(false);
    await tester.pumpAndSettle();
    expect(offline, findsNothing);
  });

  testWidgets('al volver la conexion se actualizan los accesos', (
    tester,
  ) async {
    final (network, _, nav) = await launch(tester);
    network.controller.add(false);
    await tester.pumpAndSettle();
    final before = nav.loads;
    network.controller.add(true);
    await tester.pumpAndSettle();
    expect(nav.loads, greaterThan(before));
  });

  testWidgets(
    'sin conexion se sondea cada tanto hasta que el servidor responde',
    (tester) async {
      final (_, server, nav) = await launch(tester);
      server.add(false);
      await tester.pumpAndSettle();
      final before = nav.loads;

      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(
        nav.loads,
        greaterThan(before),
        reason: 'la sonda consulta el menu',
      );

      // El servidor vuelve a responder: se retira el aviso y se deja de sondear.
      server.add(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(offline, findsNothing);
      final settled = nav.loads;
      await tester.pump(const Duration(seconds: 60));
      expect(nav.loads, settled);
    },
  );

  testWidgets('la cuenta muestra el telefono y la ultima conexion', (
    tester,
  ) async {
    final (_, server, _) = await launch(tester);
    server.add(true);
    await tester.pump();
    await openAccountSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Última conexión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispositivo'), findsOneWidget);
    expect(find.text('Samsung SM-A155M · Android 14'), findsOneWidget);
    expect(find.text('Última conexión'), findsOneWidget);
    // Ya hubo una respuesta del servidor: no queda el guion.
    final value = find.descendant(
      of: find
          .ancestor(
            of: find.text('Última conexión'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(Text),
    );
    expect(
      tester.widgetList<Text>(value).any((t) => (t.data ?? '').contains('/')),
      isTrue,
    );
  });
}
