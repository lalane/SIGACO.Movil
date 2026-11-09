import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/core/api/api_failure.dart';
import 'package:sigaco_movil/core/api/response_cache.dart';
import 'package:sigaco_movil/core/offline/operation.dart';

import '../../support/fake_api.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaOtra = OfflineScope(userId: 'ana', concessionId: 'c2');

/// Lo consultado con conexion se queda en el telefono y se ve sin ella, solo para
/// la persona y la concesion que lo consultaron.
void main() {
  late Directory dir;
  late FakeApi api;
  late FileResponseCache cache;
  late ApiClient client;
  var now = DateTime.utc(2026, 10, 26, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('rc_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    });
    now = DateTime.utc(2026, 10, 26, 12);
    cache = FileResponseCache(root: () async => dir, clock: () => now);
    api = FakeApi();
    client = ApiClient(dio: Dio()..httpClientAdapter = api, cache: cache);
    await cache.bind(_ana);
  });

  group('que se guarda', () {
    test('lo operativo si; la sesion, los archivos y lo demas no', () {
      for (final path in [
        '/api/tickets',
        '/api/tickets?page=1',
        '/api/tickets/9/follow-ups',
        '/api/preventive-maintenance',
        '/api/assets',
        '/api/assets/a-1',
        '/api/inspections/4/findings',
        '/api/works',
        '/api/app-configuration',
        '/api/auth/me/notifications',
      ]) {
        expect(cache.accepts(path), isTrue, reason: path);
      }
      for (final path in [
        '/api/auth/me',
        '/api/auth/login',
        '/api/auth/session/revalidate',
        '/api/tickets/9/attachments/a/content',
        '/api/documents',
        '/api/uploads',
        '/api/map/pins',
        // Por zona: cada movimiento del mapa seria un archivo; lo guarda el
        // cache del mapa.
        '/api/assets/map',
        '/api/assets/nearby',
        '/api/sync/operations',
      ]) {
        expect(cache.accepts(path), isFalse, reason: path);
      }
    });
  });

  group('sin red', () {
    test('ve lo ultimo que se consulto con conexion', () async {
      api.on(
        'GET /api/tickets',
        const FakeReply(200, {'items': [], 'total': 0}),
      );
      expect(await client.getJson('/api/tickets'), {'items': [], 'total': 0});
      api.offline = true;
      expect(await client.getJson('/api/tickets'), {'items': [], 'total': 0});
    });

    test('distingue las consultas por sus filtros', () async {
      api.reply(
        'GET /api/tickets',
        (o) => FakeReply(200, {'page': o.queryParameters['page']}),
      );
      await client.getJson('/api/tickets', query: {'page': 1});
      await client.getJson('/api/tickets', query: {'page': 2});
      api.offline = true;
      expect(await client.getJson('/api/tickets', query: {'page': 1}), {
        'page': 1,
      });
      expect(await client.getJson('/api/tickets', query: {'page': 2}), {
        'page': 2,
      });
    });

    test('get de un objeto tambien', () async {
      api.on(
        'GET /api/app-configuration',
        const FakeReply(200, {'timeZone': 'UTC'}),
      );
      await client.get('/api/app-configuration');
      api.offline = true;
      expect((await client.get('/api/app-configuration'))?['timeZone'], 'UTC');
    });

    test('lo que nunca se consulto falla como antes', () async {
      api.offline = true;
      await expectLater(
        client.getJson('/api/tickets'),
        throwsA(isA<ApiFailure>().having((e) => e.isNetwork, 'red', isTrue)),
      );
    });

    test('lo que no se guarda tampoco se entrega', () async {
      api.on('GET /api/auth/me', const FakeReply(200, {'account': {}}));
      await client.get('/api/auth/me');
      api.offline = true;
      await expectLater(client.get('/api/auth/me'), throwsA(isA<ApiFailure>()));
    });

    test('un error del servidor no se esconde con lo guardado', () async {
      api.on('GET /api/tickets', const FakeReply(200, {'items': []}));
      await client.getJson('/api/tickets');
      api.on('GET /api/tickets', const FakeReply(500));
      await expectLater(
        client.getJson('/api/tickets'),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 500)),
      );
      api.on('GET /api/tickets', const FakeReply(403));
      await expectLater(
        client.getJson('/api/tickets'),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 403)),
      );
    });

    test('la consulta con conexion renueva lo guardado', () async {
      api.on('GET /api/tickets', const FakeReply(200, {'v': 1}));
      await client.getJson('/api/tickets');
      api.on('GET /api/tickets', const FakeReply(200, {'v': 2}));
      await client.getJson('/api/tickets');
      api.offline = true;
      expect(await client.getJson('/api/tickets'), {'v': 2});
    });
  });

  group('de quien es', () {
    test('otra concesion no ve lo de la anterior', () async {
      api.on('GET /api/tickets', const FakeReply(200, {'v': 1}));
      await client.getJson('/api/tickets');
      await cache.bind(_anaOtra);
      api.offline = true;
      await expectLater(
        client.getJson('/api/tickets'),
        throwsA(isA<ApiFailure>()),
      );
    });

    test(
      'lo guardado sobrevive a reabrir la app con la misma persona',
      () async {
        api.on('GET /api/tickets', const FakeReply(200, {'v': 1}));
        await client.getJson('/api/tickets');
        final reopened = FileResponseCache(
          root: () async => dir,
          clock: () => now,
        );
        await reopened.bind(_ana);
        expect((await reopened.read('GET /api/tickets'))?.json, {'v': 1});
      },
    );

    test('al cerrar sesion se borra todo', () async {
      api.on('GET /api/tickets', const FakeReply(200, {'v': 1}));
      await client.getJson('/api/tickets');
      await cache.bind(null);
      await cache.bind(_ana);
      api.offline = true;
      await expectLater(
        client.getJson('/api/tickets'),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('sin sesion no guarda ni entrega nada', () async {
      final fresh = FileResponseCache(root: () async => dir, clock: () => now);
      await fresh.save('GET /api/tickets', {'v': 1});
      expect(await fresh.read('GET /api/tickets'), isNull);
    });
  });

  test('recuerda cuando se guardo', () async {
    api.on('GET /api/tickets', const FakeReply(200, {'v': 1}));
    await client.getJson('/api/tickets');
    now = DateTime.utc(2026, 10, 27);
    expect(
      (await cache.read('GET /api/tickets'))?.savedAt,
      DateTime.utc(2026, 10, 26, 12),
    );
  });
}
