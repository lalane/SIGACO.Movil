import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamanos de ventana de referencia para las pruebas, en dp.
///
/// La superficie por omision de `flutter test` mide 800x600 dp (clase media),
/// asi que las pruebas que dependen del diseno fijan un tamano explicito.
abstract final class TestSurface {
  /// Telefono del mockup: 1080x2400 px a 3x.
  static const phone = Size(360, 800);

  /// Telefono pequeno.
  static const smallPhone = Size(320, 640);

  /// Telefono grande.
  static const largePhone = Size(412, 915);

  /// Plegable abierto o tableta pequena en vertical.
  static const medium = Size(720, 1024);

  /// Tableta en horizontal.
  static const expanded = Size(1280, 800);
}

/// Fija el tamano de la ventana (en dp, a 3x) y la escala de texto del sistema.
void useSurface(
  WidgetTester tester,
  Size dp, {
  double textScale = 1.0,
  double pixelRatio = 3,
}) {
  tester.view.physicalSize = dp * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
