// Recorta el espacio transparente de los logos de TEKIA para que, a igual
// alto o ancho, se vean del mismo tamano. No modifica el dibujo del logo.
// Uso: fvm flutter test tool/trim_logos_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<void> _trim(String path, {int maxWidth = 900}) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  final w = image.width, h = image.height;
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (data.getUint8((y * w + x) * 4 + 3) > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final cw = maxX - minX + 1, ch = maxY - minY + 1;
  final scale = cw > maxWidth ? maxWidth / cw : 1.0;
  final ow = (cw * scale).round(), oh = (ch * scale).round();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    image,
    ui.Rect.fromLTWH(
      minX.toDouble(),
      minY.toDouble(),
      cw.toDouble(),
      ch.toDouble(),
    ),
    ui.Rect.fromLTWH(0, 0, ow.toDouble(), oh.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final out = await recorder.endRecording().toImage(ow, oh);
  final png = (await out.toByteData(format: ui.ImageByteFormat.png))!;
  File(path).writeAsBytesSync(Uint8List.view(png.buffer));
  // ignore: avoid_print
  print(
    '$path: ${w}x$h -> ${ow}x$oh (aspecto ${(ow / oh).toStringAsFixed(2)})',
  );
}

/// Misma composicion en un solo color (para fondo claro). Variante derivada del
/// logo blanco; conviene confirmarla con quien administra la marca.
Future<void> _tint(String from, String to, ui.Color color) async {
  final codec = await ui.instantiateImageCodec(File(from).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(
    image,
    ui.Offset.zero,
    ui.Paint()..colorFilter = ui.ColorFilter.mode(color, ui.BlendMode.srcIn),
  );
  final out = await recorder.endRecording().toImage(image.width, image.height);
  final png = (await out.toByteData(format: ui.ImageByteFormat.png))!;
  File(to).writeAsBytesSync(Uint8List.view(png.buffer));
  // ignore: avoid_print
  print('$to: ${image.width}x${image.height}');
}

void main() {
  test('recorta y tine logos TEKIA', () async {
    await _trim('assets/branding/tekia_white.png', maxWidth: 600);
    await _tint(
      'assets/branding/tekia_white.png',
      'assets/branding/tekia_dark.png',
      const ui.Color(0xFF475569),
    );
  });
}
