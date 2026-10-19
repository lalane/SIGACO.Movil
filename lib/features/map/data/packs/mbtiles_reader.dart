import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/map_pack_manager.dart';

/// Lee teselas de un archivo MBTiles (una base SQLite con la tabla `tiles`).
/// Solo teselas raster (PNG, JPEG, WebP): las de vectores vienen comprimidas y
/// no se dibujan con el mapa actual.
class MbTilesReader implements TileReader {
  MbTilesReader._(this._db);

  final Database _db;

  /// Abre el archivo en solo lectura. Lanza [FormatException] si no es un
  /// MBTiles.
  static Future<MbTilesReader> open(String path) async {
    final db = await openDatabase(path, readOnly: true, singleInstance: false);
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'tiles'",
      );
      if (tables.isEmpty) {
        throw const FormatException('El archivo no es un MBTiles.');
      }
      final columns = await db.rawQuery('PRAGMA table_info(tiles)');
      final names = {for (final c in columns) c['name']};
      const needed = {'zoom_level', 'tile_column', 'tile_row', 'tile_data'};
      if (!names.containsAll(needed)) {
        throw const FormatException(
          'La tabla tiles no tiene el formato MBTiles.',
        );
      }
    } catch (_) {
      await db.close();
      rethrow;
    }
    return MbTilesReader._(db);
  }

  @override
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (z < 0 || x < 0 || y < 0) return null;
    final n = 1 << z;
    if (x >= n || y >= n) return null;
    // MBTiles numera las filas desde abajo (TMS); el mapa, desde arriba (XYZ).
    final tmsY = n - 1 - y;
    final rows = await _db.rawQuery(
      'SELECT tile_data FROM tiles '
      'WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1',
      [z, x, tmsY],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['tile_data'];
    return data is Uint8List ? data : null;
  }

  @override
  Future<void> close() => _db.close();
}
