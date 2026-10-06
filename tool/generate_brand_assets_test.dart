// Genera los PNG de marca (wordmark, icono, splash) en assets/branding/.
// Uso: fvm flutter test tool/generate_brand_assets_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/branding/brand_colors.dart';
import 'package:sigaco_movil/core/branding/sigaco_wordmark.dart';

const _out = 'assets/branding';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  await loader.load();
}

Future<void> _render(
  WidgetTester tester, {
  required String file,
  required Size size,
  required Widget child,
  Color? background,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: size.width,
          height: size.height,
          color: background,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$file').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Widget _stacked(
  double width, {
  Color sig = BrandColors.white,
  Color aco = BrandColors.green,
}) => SizedBox(
  width: width,
  child: FittedBox(
    fit: BoxFit.contain,
    child: SigacoWordmark(
      fontSize: 200,
      stacked: true,
      sigColor: sig,
      acoColor: aco,
    ),
  ),
);

void main() {
  testWidgets('genera assets de marca', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.runAsync(
      () => _loadFont('PlusJakartaSans', 'assets/fonts/PlusJakartaSans.ttf'),
    );
    addTearDown(tester.view.reset);
    Directory(_out).createSync(recursive: true);

    // Wordmark en una linea, fondo transparente (login / splash sobre oscuro).
    await _render(
      tester,
      file: 'sigaco_wordmark.png',
      size: const Size(1200, 340),
      child: const SigacoWordmark(fontSize: 250),
    );
    await _render(
      tester,
      file: 'sigaco_wordmark_light.png',
      size: const Size(1200, 340),
      child: const SigacoWordmark.onLight(fontSize: 250),
    );

    // Icono legacy cuadrado: fondo azul de marca.
    await _render(
      tester,
      file: 'icon_full.png',
      size: const Size(1024, 1024),
      background: BrandColors.navy,
      child: _stacked(640),
    );

    // Adaptive icon: primer plano dentro de la zona segura (66 %).
    await _render(
      tester,
      file: 'icon_foreground.png',
      size: const Size(1024, 1024),
      child: _stacked(560),
    );
    await _render(
      tester,
      file: 'icon_monochrome.png',
      size: const Size(1024, 1024),
      child: _stacked(560, sig: BrandColors.white, aco: BrandColors.white),
    );

    // Android 12+ recorta el icono del splash en un circulo, asi que el nativo va
    // vacio (solo color) y la marca se muestra en un splash de Flutter.
    await _render(
      tester,
      file: 'splash_empty.png',
      size: const Size(960, 960),
      child: const SizedBox.shrink(),
    );

    // Splash Android 12: debe caber en el circulo central (640 de 960).
    await _render(
      tester,
      file: 'splash_android12.png',
      size: const Size(960, 960),
      child: _stacked(420),
    );
  });
}
