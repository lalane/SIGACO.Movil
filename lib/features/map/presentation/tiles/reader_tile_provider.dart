import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../domain/repositories/map_pack_manager.dart';

/// Un PNG transparente de 1x1: es lo que se dibuja donde el paquete no tiene
/// tesela, para que se vea lo que hay debajo (el mapa en linea).
final Uint8List transparentTile = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNkAAIAAAoAAv/lxKUAAAAASUVORK5CYII=',
);

/// Teselas de un paquete instalado: las lee de un [TileReader] en lugar de bajarlas.
class ReaderTileProvider extends TileProvider {
  ReaderTileProvider(this.reader);

  final TileReader reader;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      ReaderTileImage(reader, coordinates.z, coordinates.x, coordinates.y);
}

/// La imagen de una tesela del paquete. Si falta o no se puede leer, es
/// transparente.
@immutable
class ReaderTileImage extends ImageProvider<ReaderTileImage> {
  const ReaderTileImage(this.reader, this.z, this.x, this.y);

  final TileReader reader;
  final int z;
  final int x;
  final int y;

  @override
  Future<ReaderTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    ReaderTileImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    Uint8List bytes;
    try {
      bytes = await reader.tile(z, x, y) ?? transparentTile;
    } catch (_) {
      bytes = transparentTile;
    }
    try {
      // El await es necesario: un fallo del decodificador llega como error del
      // futuro y, sin el, escaparia de este try.
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      // Una tesela danada no debe romper el mapa.
      return decode(await ui.ImmutableBuffer.fromUint8List(transparentTile));
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderTileImage &&
      identical(other.reader, reader) &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(identityHashCode(reader), z, x, y);
}
