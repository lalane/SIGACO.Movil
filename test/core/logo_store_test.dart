import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/ui/logo_store.dart';

import '../support/fakes.dart';

/// Guardar el logo en disco (DEV-MOB-059): la primera vez se descarga y despues
/// sale del telefono, tambien sin conexion.
void main() {
  late Directory dir;
  late List<String> downloads;
  Uint8List? Function(String url) answer = (_) => tinyPng;

  DiskLogoStore make({int maxFiles = 12}) => DiskLogoStore(
    directory: () async => dir,
    download: (url) async {
      downloads.add(url);
      return answer(url);
    },
    maxFiles: maxFiles,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sigaco_logos_');
    downloads = [];
    answer = (_) => tinyPng;
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  const url = 'https://cdn.example.com/logo.png';

  test('la primera vez descarga y guarda en disco', () async {
    final bytes = await make().bytesFor(url, version: 1);
    expect(bytes, tinyPng);
    expect(downloads, [url]);
    expect(dir.listSync().whereType<File>().length, 1);
  });

  test('la segunda vez sale del disco, sin descargar', () async {
    await make().bytesFor(url, version: 1);
    // Otra instancia: lo guardado sobrevive al reinicio de la app.
    final again = await make().bytesFor(url, version: 1);
    expect(again, tinyPng);
    expect(downloads, hasLength(1));
  });

  test(
    'sin conexion y con copia guardada, el logo sigue apareciendo',
    () async {
      await make().bytesFor(url, version: 1);
      answer = (_) => null;
      expect(await make().bytesFor(url, version: 1), tinyPng);
    },
  );

  test('sin conexion y sin copia no hay logo ni archivo', () async {
    answer = (_) => null;
    expect(await make().bytesFor(url, version: 1), isNull);
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('una version nueva de la marca descarga otra vez', () async {
    await make().bytesFor(url, version: 1);
    await make().bytesFor(url, version: 2);
    expect(downloads, [url, url]);
  });

  test('una URL distinta es otra copia', () async {
    final store = make();
    await store.bytesFor(url, version: 1);
    await store.bytesFor('https://cdn.example.com/otro.png', version: 1);
    expect(dir.listSync().whereType<File>().length, 2);
  });

  test('dos pedidos a la vez comparten una sola descarga', () async {
    final store = make();
    final both = await Future.wait([
      store.bytesFor(url, version: 1),
      store.bytesFor(url, version: 1),
    ]);
    expect(both, [tinyPng, tinyPng]);
    expect(downloads, hasLength(1));
  });

  test('una descarga vacia no se guarda', () async {
    answer = (_) => Uint8List(0);
    expect(await make().bytesFor(url, version: 1), isNull);
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('un archivo guardado vacio se vuelve a descargar', () async {
    final store = make();
    await store.bytesFor(url, version: 1);
    final saved = dir.listSync().whereType<File>().single;
    await saved.writeAsBytes(const []);
    expect(await make().bytesFor(url, version: 1), tinyPng);
    expect(downloads, hasLength(2));
  });

  test('conserva solo los logos mas recientes', () async {
    final store = make(maxFiles: 2);
    for (var i = 0; i < 4; i++) {
      await store.bytesFor('https://cdn.example.com/logo$i.png', version: 1);
      // Fechas distintas entre archivos.
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    final names = dir.listSync().whereType<File>().length;
    expect(names, 2);
    // Los dos ultimos siguen guardados: no se vuelven a descargar.
    downloads.clear();
    await store.bytesFor('https://cdn.example.com/logo3.png', version: 1);
    expect(downloads, isEmpty);
  });
}
