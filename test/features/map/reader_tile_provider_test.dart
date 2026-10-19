import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/reader_tile_provider.dart';

import '../../support/map_pack_fakes.dart';

void main() {
  /// Resuelve la imagen y devuelve su tamano, o null si fallo.
  Future<ui.Size?> resolve(ReaderTileImage image) {
    final done = Completer<ui.Size?>();
    final stream = image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) {
          done.complete(
            ui.Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!done.isCompleted) done.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  testWidgets('dibuja la tesela del paquete', (tester) async {
    final reader = FakeTileReader({(3, 1, 2): transparentTile});
    final size = await tester.runAsync(
      () => resolve(ReaderTileImage(reader, 3, 1, 2)),
    );
    expect(size, const ui.Size(1, 1));
  });

  testWidgets('una tesela que falta se dibuja transparente, sin error', (
    tester,
  ) async {
    final reader = FakeTileReader();
    final size = await tester.runAsync(
      () => resolve(ReaderTileImage(reader, 3, 1, 2)),
    );
    expect(size, const ui.Size(1, 1));
  });

  testWidgets('si el lector falla se dibuja transparente', (tester) async {
    final reader = FakeTileReader()..failWith = StateError('base cerrada');
    final size = await tester.runAsync(
      () => resolve(ReaderTileImage(reader, 3, 1, 2)),
    );
    expect(size, const ui.Size(1, 1));
  });

  testWidgets('una tesela danada se sustituye por una transparente', (
    tester,
  ) async {
    final reader = FakeTileReader({
      (3, 1, 2): Uint8List.fromList([1, 2, 3, 4]),
    });
    final size = await tester.runAsync(
      () => resolve(ReaderTileImage(reader, 3, 1, 2)),
    );
    expect(size, const ui.Size(1, 1));
  });

  test('dos imagenes de la misma tesela y lector son iguales', () {
    final reader = FakeTileReader();
    expect(ReaderTileImage(reader, 1, 2, 3), ReaderTileImage(reader, 1, 2, 3));
    expect(
      ReaderTileImage(reader, 1, 2, 3),
      isNot(ReaderTileImage(reader, 1, 2, 4)),
    );
    expect(
      ReaderTileImage(reader, 1, 2, 3),
      isNot(ReaderTileImage(FakeTileReader(), 1, 2, 3)),
    );
    expect(
      ReaderTileImage(reader, 1, 2, 3).hashCode,
      ReaderTileImage(reader, 1, 2, 3).hashCode,
    );
  });
}
