import 'dart:io';

import 'package:flutter/services.dart';

/// Las pruebas usan por defecto una fuente cuadrada y muy ancha; para medir
/// textos y detectar desbordes como en el telefono hay que cargar las reales.
Future<void> loadAppFonts() async {
  for (final (family, path) in [
    ('PlusJakartaSans', 'assets/fonts/PlusJakartaSans.ttf'),
    ('Inter', 'assets/fonts/Inter.ttf'),
  ]) {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
