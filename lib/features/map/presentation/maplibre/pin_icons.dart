import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/map_pin.dart';
import '../map_labels.dart';
import 'map_data.dart';

/// El icono de cada capa (el mismo de la pestana y de la ficha) dibujado en
/// blanco, para ponerlo sobre el circulo de color del pin. MapLibre solo sabe
/// pintar imagenes: el glifo de Material se convierte en una.
Future<Map<String, Uint8List>> pinIconImages({double size = 40}) async => {
  for (final layer in MapLayer.values)
    pinIconName(layer): await glyphPng(layerIcon(layer), size),
};

/// [icon] como imagen PNG blanca de [size] pixeles de alto, sobre fondo
/// transparente.
Future<Uint8List> glyphPng(IconData icon, double size) async {
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    ),
  )..layout();
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), ui.Offset.zero);
  final image = await recorder.endRecording().toImage(
    painter.width.ceil(),
    painter.height.ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
