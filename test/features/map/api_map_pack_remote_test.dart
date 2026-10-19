import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/features/map/data/packs/map_pack_remote.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_pack_manager.dart';

import '../../support/map_pack_fakes.dart';

/// Servidor falso de la API de paquetes de mapa (contrato propuesto).
class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object? listBody;
  int listStatus = 200;
  int contentStatus = 200;
  bool offline = false;
  Uint8List content = Uint8List.fromList([1, 2, 3, 4, 5]);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (options.path.endsWith('/content')) {
      if (contentStatus >= 400) {
        return ResponseBody.fromString(
          '{}',
          contentStatus,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      final range = options.headers['Range'] as String?;
      final from = range == null
          ? 0
          : int.parse(range.split('=')[1].split('-')[0]);
      final body = content.sublist(from);
      return ResponseBody.fromBytes(
        body,
        contentStatus,
        headers: {
          Headers.contentLengthHeader: ['${body.length}'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(listBody ?? []),
      listStatus,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Map<String, Object?> _json({
  String id = 'br381',
  Object? version = 3,
  Object? size = 1000,
  String? sha,
  Map<String, Object?>? bounds,
  String format = 'mbtiles',
}) => {
  'id': id,
  'name': 'BR-381',
  'version': version,
  'format': format,
  'sizeBytes': size,
  'sha256': sha ?? sha256Of(packBytes(10)),
  'minZoom': 8,
  'maxZoom': 16,
  'bounds':
      bounds ?? {'south': -19.2, 'west': -42.3, 'north': -18.7, 'east': -41.8},
  'generatedAt': '2026-10-14T12:00:00Z',
  'attribution': '© OpenStreetMap contributors',
};

void main() {
  late _Server server;
  late ApiMapPackRemote remote;

  setUp(() {
    server = _Server();
    remote = ApiMapPackRemote(
      ApiClient(dio: Dio()..httpClientAdapter = server),
    );
  });

  Matcher failsWith(MapPackError error) =>
      throwsA(isA<MapPackException>().having((e) => e.error, 'error', error));

  group('lista de paquetes', () {
    test('lee una lista simple', () async {
      server.listBody = [_json()];
      final packs = await remote.list();
      expect(server.requests.single.path, '/api/maps/packs');
      expect(packs.single.id, 'br381');
      expect(packs.single.version, 3);
      expect(packs.single.sizeBytes, 1000);
      expect(packs.single.bounds.north, -18.7);
      expect(packs.single.generatedAt, DateTime.utc(2026, 10, 14, 12));
      expect(packs.single.attribution, '© OpenStreetMap contributors');
    });

    test('acepta la lista dentro de items o data', () async {
      server.listBody = {
        'items': [_json()],
      };
      expect(await remote.list(), hasLength(1));
      server.listBody = {
        'data': [_json(id: 'otro')],
      };
      expect((await remote.list()).single.id, 'otro');
    });

    test('tolera numeros como texto y huellas en mayusculas', () async {
      server.listBody = [
        _json(
          version: '4',
          size: '2048',
          sha: sha256Of(packBytes(3)).toUpperCase(),
        ),
      ];
      final p = (await remote.list()).single;
      expect(p.version, 4);
      expect(p.sizeBytes, 2048);
      expect(p.sha256, sha256Of(packBytes(3)));
    });

    test('descarta lo que no sirve', () async {
      server.listBody = [
        _json(id: 'bueno'),
        {'id': 'sin-campos'},
        _json(id: 'pmtiles', format: 'pmtiles'),
        _json(id: 'huella', sha: 'abc'),
        _json(
          id: 'limites',
          bounds: {'south': 10, 'west': 0, 'north': -10, 'east': 5},
        ),
        _json(id: 'tamano', size: 0),
        'basura',
      ];
      expect((await remote.list()).map((e) => e.id), ['bueno']);
    });

    test('una respuesta sin lista da una lista vacia', () async {
      server.listBody = {'otra': 1};
      expect(await remote.list(), isEmpty);
    });

    for (final (status, error) in [
      (404, MapPackError.notAvailable),
      (501, MapPackError.notAvailable),
      (403, MapPackError.permissionDenied),
      (500, MapPackError.server),
    ]) {
      test('el estado $status se informa como ${error.name}', () async {
        server.listStatus = status;
        await expectLater(remote.list(), failsWith(error));
      });
    }

    test('sin red se informa como network', () async {
      server.offline = true;
      await expectLater(remote.list(), failsWith(MapPackError.network));
    });
  });

  group('contenido', () {
    final pack = packFor(packBytes(5));

    Future<List<int>> read(PackContent c) async => [
      for (final chunk in await c.body.toList()) ...chunk,
    ];

    test('baja desde el principio sin pedir Range', () async {
      final c = await remote.content(pack);
      expect(server.requests.single.path, '/api/maps/packs/br381/content');
      expect(server.requests.single.headers.containsKey('Range'), isFalse);
      expect(c.resumed, isFalse);
      expect(await read(c), [1, 2, 3, 4, 5]);
    });

    test('pide Range desde el byte donde quedo y reconoce el 206', () async {
      server.contentStatus = 206;
      final c = await remote.content(pack, from: 2);
      expect(server.requests.single.headers['Range'], 'bytes=2-');
      expect(c.resumed, isTrue);
      expect(await read(c), [3, 4, 5]);
    });

    test('si el servidor responde 200 a un Range, resumed es false', () async {
      final c = await remote.content(pack, from: 2);
      expect(c.resumed, isFalse);
    });

    test('un id con caracteres raros se codifica en la ruta', () async {
      await remote.content(packFor(packBytes(5), id: 'a b/c'));
      expect(server.requests.single.path, '/api/maps/packs/a%20b%2Fc/content');
    });

    for (final (status, error) in [
      (404, MapPackError.notFound),
      (403, MapPackError.permissionDenied),
      (500, MapPackError.server),
      (416, MapPackError.corrupt),
    ]) {
      test('el estado $status se informa como ${error.name}', () async {
        server.contentStatus = status;
        await expectLater(remote.content(pack), failsWith(error));
      });
    }

    test('sin red se informa como network', () async {
      server.offline = true;
      await expectLater(remote.content(pack), failsWith(MapPackError.network));
    });
  });
}
