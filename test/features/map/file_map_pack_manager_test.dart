import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/map/data/packs/file_map_pack_manager.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pack.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_pack_manager.dart';

import '../../support/map_pack_fakes.dart';

void main() {
  const scopeA = OfflineScope(userId: 'u1', concessionId: 'c1');
  const scopeB = OfflineScope(userId: 'u1', concessionId: 'c2');

  late Directory tmp;
  late FakeMapPackRemote remote;
  late Uint8List bytes;
  late MapPack pack;
  late FileMapPackManager manager;
  late List<String> opened;
  late FakeTileReader reader;

  Directory dataDir() => Directory(p.join(tmp.path, 'data'));
  List<String> filesIn() => dataDir().existsSync()
      ? (dataDir().listSync().map((e) => p.basename(e.path)).toList()..sort())
      : [];

  Future<List<PackProgress>> run(MapPack pack) =>
      manager.download(pack).toList();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sigaco_packs_');
    bytes = packBytes(1000);
    pack = packFor(bytes);
    remote = FakeMapPackRemote(packs: [pack], files: {pack.id: bytes});
    opened = [];
    reader = FakeTileReader();
    manager = FileMapPackManager(
      remote: remote,
      root: () async => tmp,
      openReader: (path) async {
        opened.add(p.basename(path));
        return reader;
      },
      clock: () => DateTime.utc(2026, 10, 14, 12),
    );
    await manager.bind(scopeA);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('descarga', () {
    test('baja, verifica, instala y deja el paquete listado', () async {
      final progress = await run(pack);
      expect(progress.last.receivedBytes, 1000);
      expect(progress.any((e) => e.verifying), isTrue);
      expect(filesIn(), ['br381-1.mbtiles', 'index.json']);
      final installed = await manager.installed();
      expect(installed.single.id, 'br381');
      expect(installed.single.version, 1);
      expect(installed.single.sizeBytes, 1000);
      expect(
        File(p.join(dataDir().path, 'br381-1.mbtiles')).readAsBytesSync(),
        bytes,
      );
    });

    test('el avance solo crece y termina en el total', () async {
      final progress = await run(pack);
      final received = progress.map((e) => e.receivedBytes).toList();
      expect([...received]..sort(), received);
      expect(progress.first.fraction, lessThan(1.0));
      expect(progress.last.fraction, 1.0);
    });

    test('un paquete que se corta se reanuda desde donde quedo', () async {
      remote.cutAfter = 400;
      await expectLater(
        run(pack),
        throwsA(
          isA<MapPackException>().having(
            (e) => e.error,
            'error',
            MapPackError.network,
          ),
        ),
      );
      expect(await manager.partialBytes('br381'), 400);
      expect(await manager.installed(), isEmpty);

      remote.cutAfter = null;
      remote.requestedFrom.clear();
      await run(pack);
      expect(remote.requestedFrom, [400]);
      expect((await manager.installed()).single.id, 'br381');
      expect(filesIn(), ['br381-1.mbtiles', 'index.json']);
    });

    test('pausar conserva lo bajado y se reanuda', () async {
      // Pausa en cuanto llegan 300 bytes, dentro del propio evento: sin esperas
      // ni carreras con la descarga.
      late final StreamSubscription<PackProgress> sub;
      sub = manager.download(pack).listen((progress) {
        if (progress.receivedBytes >= 300) sub.cancel();
      });
      await sub.asFuture<void>().timeout(
        const Duration(milliseconds: 200),
        onTimeout: () {},
      );
      await sub.cancel();
      final kept = await manager.partialBytes('br381');
      expect(kept, greaterThanOrEqualTo(300));
      expect(kept, lessThan(1000));

      remote.requestedFrom.clear();
      await run(pack);
      expect(remote.requestedFrom.single, greaterThan(0));
      expect((await manager.installed()).single.sizeBytes, 1000);
    });

    test(
      'si el servidor ignora el Range se empieza de cero sin corromper',
      () async {
        remote.cutAfter = 400;
        await expectLater(run(pack), throwsA(isA<MapPackException>()));
        remote
          ..cutAfter = null
          ..honorRange = false;
        await run(pack);
        expect(
          File(p.join(dataDir().path, 'br381-1.mbtiles')).readAsBytesSync(),
          bytes,
        );
      },
    );

    test('una huella distinta descarta lo bajado y no instala', () async {
      final bad = MapPack(
        id: pack.id,
        name: pack.name,
        version: pack.version,
        sizeBytes: pack.sizeBytes,
        sha256: sha256Of(packBytes(1000, seed: 99)),
        minZoom: pack.minZoom,
        maxZoom: pack.maxZoom,
        bounds: pack.bounds,
      );
      await expectLater(
        run(bad),
        throwsA(
          isA<MapPackException>().having(
            (e) => e.error,
            'error',
            MapPackError.corrupt,
          ),
        ),
      );
      expect(await manager.installed(), isEmpty);
      expect(await manager.partialBytes('br381'), 0);
      expect(filesIn().where((f) => f.endsWith('.mbtiles')), isEmpty);
    });

    test(
      'si llegan mas bytes de los que dice el paquete, se descarta',
      () async {
        remote.extraBytes = 50;
        await expectLater(
          run(pack),
          throwsA(
            isA<MapPackException>().having(
              (e) => e.error,
              'error',
              MapPackError.corrupt,
            ),
          ),
        );
        expect(await manager.partialBytes('br381'), 0);
        expect(await manager.installed(), isEmpty);
      },
    );

    test(
      'si termina antes de tiempo queda a medias y se puede reanudar',
      () async {
        remote.endEarlyAfter = 500;
        await expectLater(
          run(pack),
          throwsA(
            isA<MapPackException>().having(
              (e) => e.error,
              'error',
              MapPackError.network,
            ),
          ),
        );
        expect(await manager.partialBytes('br381'), 500);
      },
    );

    test('un fallo del servidor al pedir el contenido se propaga', () async {
      remote.contentFailure = const MapPackException(MapPackError.notFound);
      await expectLater(
        run(pack),
        throwsA(
          isA<MapPackException>().having(
            (e) => e.error,
            'error',
            MapPackError.notFound,
          ),
        ),
      );
    });

    test('un paquete mal formado no se baja', () async {
      final bad = MapPack(
        id: 'x',
        name: 'x',
        version: 1,
        sizeBytes: 0,
        sha256: 'no-es-una-huella',
        minZoom: 1,
        maxZoom: 2,
        bounds: pack.bounds,
      );
      await expectLater(
        run(bad),
        throwsA(
          isA<MapPackException>().having(
            (e) => e.error,
            'error',
            MapPackError.corrupt,
          ),
        ),
      );
      expect(remote.requestedFrom, isEmpty);
    });

    test('no se puede bajar dos veces a la vez el mismo paquete', () async {
      final first = manager.download(pack).toList();
      // Espera a que la primera ya este en curso.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await expectLater(manager.download(pack).toList(), throwsStateError);
      await first;
    });

    test('un id raro no sale de la carpeta de datos', () async {
      final evil = packFor(bytes, id: '../../fuera');
      remote.files[evil.id] = bytes;
      await run(evil);
      expect(
        Directory(
          p.join(tmp.path, '..'),
        ).listSync().whereType<File>().where((f) => f.path.contains('fuera')),
        isEmpty,
      );
      expect(filesIn().any((f) => f.contains('fuera')), isTrue);
    });

    test('descartar lo bajado libera el espacio', () async {
      remote.cutAfter = 400;
      await expectLater(run(pack), throwsA(isA<MapPackException>()));
      await manager.discardPartial('br381');
      expect(await manager.partialBytes('br381'), 0);
      expect(filesIn().where((f) => f.contains('.part')), isEmpty);
    });

    test('lo bajado de otra version no se reutiliza', () async {
      remote.cutAfter = 400;
      await expectLater(run(pack), throwsA(isA<MapPackException>()));
      final newBytes = packBytes(1000, seed: 11);
      final v2 = packFor(newBytes, version: 2);
      remote
        ..cutAfter = null
        ..files[v2.id] = newBytes
        ..requestedFrom.clear();
      await run(v2);
      expect(remote.requestedFrom, [0]);
      expect(
        File(p.join(dataDir().path, 'br381-2.mbtiles')).readAsBytesSync(),
        newBytes,
      );
    });
  });

  group('versiones', () {
    test('una version nueva reemplaza a la anterior', () async {
      await run(pack);
      final newBytes = packBytes(1200, seed: 5);
      final v2 = packFor(newBytes, version: 2);
      remote.files[v2.id] = newBytes;
      await run(v2);
      final installed = await manager.installed();
      expect(installed, hasLength(1));
      expect(installed.single.version, 2);
      expect(filesIn(), ['br381-2.mbtiles', 'index.json']);
      expect(
        installed.single.isOlderThan(packFor(newBytes, version: 3)),
        isTrue,
      );
      expect(installed.single.isOlderThan(v2), isFalse);
    });

    test('borrar quita el archivo y el registro', () async {
      await run(pack);
      await manager.remove('br381');
      expect(await manager.installed(), isEmpty);
      expect(filesIn().where((f) => f.endsWith('.mbtiles')), isEmpty);
    });

    test('borrar tambien tira lo bajado a medias', () async {
      remote.cutAfter = 300;
      await expectLater(run(pack), throwsA(isA<MapPackException>()));
      await manager.remove('br381');
      expect(await manager.partialBytes('br381'), 0);
    });

    test(
      'un registro cuyo archivo falta o cambio de tamano se descarta',
      () async {
        await run(pack);
        File(
          p.join(dataDir().path, 'br381-1.mbtiles'),
        ).writeAsBytesSync([1, 2, 3]);
        expect(await manager.installed(), isEmpty);
      },
    );
  });

  group('lector de teselas', () {
    test('abre el paquete mas reciente', () async {
      await run(pack);
      final r = await manager.openActive();
      expect(r, same(reader));
      expect(opened, ['br381-1.mbtiles']);
    });

    test('sin paquetes no hay lector', () async {
      expect(await manager.openActive(), isNull);
    });

    test('un archivo que no abre se borra y no estorba', () async {
      await run(pack);
      final broken = FileMapPackManager(
        remote: remote,
        root: () async => tmp,
        openReader: (_) async => throw const FormatException('no es MBTiles'),
      );
      await broken.bind(scopeA);
      expect(await broken.openActive(), isNull);
      expect(await broken.installed(), isEmpty);
    });
  });

  group('alcance de la persona y la concesion', () {
    test('al cambiar de concesion se borra todo', () async {
      await run(pack);
      await manager.bind(scopeB);
      expect(await manager.installed(), isEmpty);
      expect(filesIn().where((f) => f.endsWith('.mbtiles')), isEmpty);
    });

    test('con el mismo alcance se conserva', () async {
      await run(pack);
      await manager.bind(scopeA);
      expect((await manager.installed()).single.id, 'br381');
    });

    test(
      'lo guardado por otro alcance se descarta al iniciar sesion',
      () async {
        await run(pack);
        // Otra instancia (la app se reinicio) con otro alcance.
        final other = FileMapPackManager(remote: remote, root: () async => tmp);
        await other.bind(scopeB);
        expect(await other.installed(), isEmpty);
      },
    );

    test('al cerrar sesion se borra todo', () async {
      await run(pack);
      await manager.bind(null);
      expect(await manager.installed(), isEmpty);
      expect(dataDir().existsSync(), isFalse);
    });

    test(
      'clear (cambio de concesion) borra paquetes y descargas a medias',
      () async {
        remote.cutAfter = 300;
        await expectLater(run(pack), throwsA(isA<MapPackException>()));
        await manager.clear();
        expect(dataDir().existsSync(), isFalse);
      },
    );

    test('sin alcance no se baja ni se lista nada', () async {
      final unbound = FileMapPackManager(remote: remote, root: () async => tmp);
      expect(await unbound.installed(), isEmpty);
      await expectLater(
        unbound.download(pack).toList(),
        throwsA(
          isA<MapPackException>().having(
            (e) => e.error,
            'error',
            MapPackError.notAvailable,
          ),
        ),
      );
    });
  });

  test('available delega en el servidor', () async {
    expect(await manager.available(), [pack]);
    remote.listFailure = const MapPackException(MapPackError.permissionDenied);
    await expectLater(
      manager.available(),
      throwsA(
        isA<MapPackException>().having(
          (e) => e.error,
          'error',
          MapPackError.permissionDenied,
        ),
      ),
    );
  });
}
