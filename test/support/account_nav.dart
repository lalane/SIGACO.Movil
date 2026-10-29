import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Del menu a Mi cuenta: el circulo de la cabecera abre el panel y de ahi se
/// entra al perfil.
Future<void> openMyAccount(WidgetTester tester) async {
  await tester.tap(find.text('JP'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('panel-my-account')));
  await tester.pumpAndSettle();
}

/// Del menu a Configuracion (seguridad, preferencias, dispositivo).
Future<void> openAccountSettings(WidgetTester tester) async {
  await openMyAccount(tester);
  final entry = find.byKey(const Key('account-settings-entry'));
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
}
