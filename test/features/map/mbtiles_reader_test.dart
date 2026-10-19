import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sigaco_movil/features/map/data/packs/mbtiles_reader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sigaco_mbtiles_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Un MBTiles minimo con las teselas dadas como (z, x, yXYZ) -> bytes.
  Future<String> build(Map<(int, int, int), List<int>> tiles) async {
    final path = p.join(tmp.path, 'pack.mbtiles');
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute(
      'CREATE TABLE metadata (name TEXT, value TEXT);'
      'CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, '
      'tile_row INTEGER, tile_data BLOB);',
    );
    for (final e in tiles.entries) {
      final (z, x, y) = e.key;
      // MBTiles guarda la fila contando desde abajo (TMS).
      final tms = (1 << z) - 1 - y;
      await db.insert('tiles', {
        'zoom_level': z,
        'tile_column': x,
        'tile_row': tms,
        'tile_data': Uint8List.fromList(e.value),
      });
    }
    await db.close();
    return path;
  }

  test('lee una tesela con la fila invertida de MBTiles', () async {
    final path = await build({
      (3, 5, 2): [1, 2, 3],
      (3, 5, 3): [9, 9],
    });
    final reader = await MbTilesReader.open(path);
    expect(await reader.tile(3, 5, 2), [1, 2, 3]);
    expect(await reader.tile(3, 5, 3), [9, 9]);
    await reader.close();
  });

  test('una tesela que no esta devuelve null', () async {
    final reader = await MbTilesReader.open(
      await build({
        (1, 0, 0): [7],
      }),
    );
    expect(await reader.tile(1, 1, 1), isNull);
    expect(await reader.tile(5, 3, 3), isNull);
    await reader.close();
  });

  test('coordenadas fuera de rango o negativas devuelven null', () async {
    final reader = await MbTilesReader.open(
      await build({
        (1, 0, 0): [7],
      }),
    );
    expect(await reader.tile(1, 2, 0), isNull);
    expect(await reader.tile(1, 0, 2), isNull);
    expect(await reader.tile(-1, 0, 0), isNull);
    expect(await reader.tile(1, -1, 0), isNull);
    await reader.close();
  });

  test('el zoom 0 tiene una sola tesela', () async {
    final reader = await MbTilesReader.open(
      await build({
        (0, 0, 0): [4, 4],
      }),
    );
    expect(await reader.tile(0, 0, 0), [4, 4]);
    await reader.close();
  });

  test('un archivo sin la tabla tiles no es un MBTiles', () async {
    final path = p.join(tmp.path, 'otro.db');
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE otra (a INTEGER)');
    await db.close();
    await expectLater(MbTilesReader.open(path), throwsFormatException);
  });

  test('una tabla tiles con otras columnas no es un MBTiles', () async {
    final path = p.join(tmp.path, 'mal.db');
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('CREATE TABLE tiles (a INTEGER, b TEXT)');
    await db.close();
    await expectLater(MbTilesReader.open(path), throwsFormatException);
  });

  test('un archivo que no es SQLite falla al abrir', () async {
    final path = p.join(tmp.path, 'basura.mbtiles');
    File(path).writeAsBytesSync(List.filled(200, 7));
    await expectLater(MbTilesReader.open(path), throwsA(isA<Object>()));
  });
}
