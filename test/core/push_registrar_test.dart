import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/core/push/api_push.dart';
import 'package:sigaco_movil/core/push/push_registrar.dart';

class _Token implements PushTokenSource {
  _Token(this.value);

  String? value;

  @override
  Future<String?> token() async => value;
}

class _Channel implements PushChannelSource {
  _Channel(this.active);

  bool? active;
  Object? fail;

  @override
  Future<bool?> isActive(String concessionId) async {
    if (fail != null) throw fail!;
    return active;
  }
}

class _Remote implements PushRemote {
  final calls = <String>[];
  Object? fail;
  var _next = 1;

  @override
  Future<String?> register(String token) async {
    if (fail != null) throw fail!;
    final id = 'dev-${_next++}';
    calls.add('register $token -> $id');
    return id;
  }

  @override
  Future<void> unregister(String deviceId) async {
    if (fail != null) throw fail!;
    calls.add('unregister $deviceId');
  }
}

/// El token push solo se registra si la concesion tiene activo su canal push
/// (RN-19, DEV-MOB-CFG-N04), y se retira al cerrar sesion.
void main() {
  group('registrador', () {
    late SharedPreferences prefs;
    late _Token tokens;
    late _Channel channel;
    late _Remote remote;
    late PushRegistrar registrar;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tokens = _Token('tok-1');
      channel = _Channel(true);
      remote = _Remote();
      registrar = PushRegistrar(
        prefs: prefs,
        tokens: tokens,
        channels: channel,
        remote: remote,
      );
    });

    test('con el canal activo registra el token', () async {
      expect(await registrar.sync('c1'), PushOutcome.registered);
      expect(remote.calls, ['register tok-1 -> dev-1']);
    });

    test('no repite el registro si no cambia nada', () async {
      await registrar.sync('c1');
      expect(await registrar.sync('c1'), PushOutcome.unchanged);
      expect(remote.calls, hasLength(1));
    });

    test('un token nuevo o otra concesion se registra de nuevo', () async {
      await registrar.sync('c1');
      tokens.value = 'tok-2';
      expect(await registrar.sync('c1'), PushOutcome.registered);
      expect(await registrar.sync('c2'), PushOutcome.registered);
      expect(remote.calls, [
        'register tok-1 -> dev-1',
        'register tok-2 -> dev-2',
        'register tok-2 -> dev-3',
      ]);
    });

    test('con el canal apagado no registra nada', () async {
      channel.active = false;
      expect(await registrar.sync('c1'), PushOutcome.skipped);
      expect(remote.calls, isEmpty);
    });

    test('si el canal se apaga, retira el dispositivo registrado', () async {
      await registrar.sync('c1');
      channel.active = false;
      expect(await registrar.sync('c1'), PushOutcome.unregistered);
      expect(remote.calls.last, 'unregister dev-1');
      // Y si se vuelve a encender, se registra otra vez.
      channel.active = true;
      expect(await registrar.sync('c1'), PushOutcome.registered);
    });

    test('si no se sabe el estado del canal no toca lo registrado', () async {
      await registrar.sync('c1');
      channel.active = null;
      expect(await registrar.sync('c1'), PushOutcome.skipped);
      expect(remote.calls, hasLength(1));
    });

    test('sin token en el telefono no hace nada', () async {
      tokens.value = null;
      expect(await registrar.sync('c1'), PushOutcome.noToken);
      tokens.value = '';
      expect(await registrar.sync('c1'), PushOutcome.noToken);
      expect(remote.calls, isEmpty);
    });

    test('un fallo del servidor no rompe y se reintenta despues', () async {
      remote.fail = Exception('sin red');
      expect(await registrar.sync('c1'), PushOutcome.failed);
      remote.fail = null;
      expect(await registrar.sync('c1'), PushOutcome.registered);
    });

    test('un fallo al preguntar el canal tampoco rompe', () async {
      channel.fail = Exception('sin red');
      expect(await registrar.sync('c1'), PushOutcome.failed);
    });

    test('al cerrar sesion retira el dispositivo con el id guardado', () async {
      await registrar.sync('c1');
      await registrar.retire();
      expect(remote.calls.last, 'unregister dev-1');
      // Ya no queda nada registrado: al volver a entrar se registra de nuevo.
      expect(await registrar.sync('c1'), PushOutcome.registered);
    });

    test('si retirarlo falla, igual se olvida y no rompe el cierre', () async {
      await registrar.sync('c1');
      remote.fail = Exception('sin red');
      await registrar.retire();
      remote.fail = null;
      expect(await registrar.sync('c1'), PushOutcome.registered);
    });

    test('retirar sin nada registrado no llama al servidor', () async {
      await registrar.retire();
      expect(remote.calls, isEmpty);
    });

    test('forget olvida sin avisar al servidor', () async {
      await registrar.sync('c1');
      await registrar.forget();
      expect(remote.calls, hasLength(1));
      expect(await registrar.sync('c1'), PushOutcome.registered);
    });

    test('por omision no hay fuente: no registra nada', () async {
      final plain = PushRegistrar(prefs: prefs);
      expect(await plain.sync('c1'), PushOutcome.skipped);
    });
  });

  group('con el servidor (rutas reales)', () {
    late _Server server;
    late ApiClient api;

    setUp(() {
      server = _Server();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = server
        ..options.validateStatus = (s) => s != null && s < 400;
      api = ApiClient(dio: dio);
    });

    test('el canal push sale de app-configuration', () async {
      server.body = {
        'concessionId': 'c1',
        'channels': {'email': true, 'push': true, 'telegram': false},
      };
      final source = ApiPushChannelSource(api);
      expect(await source.isActive('c1'), isTrue);
      expect(server.calls.single, 'GET /api/app-configuration');

      server.body = {
        'concessionId': 'c1',
        'channels': {'email': true, 'push': false, 'telegram': false},
      };
      expect(await source.isActive('c1'), isFalse);
    });

    test(
      'si la configuracion es de otra concesion o no se sabe, es null',
      () async {
        final source = ApiPushChannelSource(api);
        server.body = {
          'concessionId': 'otra',
          'channels': {'push': true},
        };
        expect(await source.isActive('c1'), isNull);
        server.body = {'concessionId': 'c1'};
        expect(await source.isActive('c1'), isNull);
        server.offline = true;
        expect(await source.isActive('c1'), isNull);
      },
    );

    test('registra el dispositivo con token y plataforma ANDROID', () async {
      server.body = {
        'id': 'd-77',
        'platform': 'ANDROID',
        'registeredAt': '2026-10-19T12:00:00Z',
        'lastSeenAt': '2026-10-19T12:00:00Z',
      };
      final id = await ApiPushRemote(api).register('tok-1');
      expect(id, 'd-77');
      expect(server.calls.single, 'POST /api/auth/me/devices');
      expect(server.lastBody, {'token': 'tok-1', 'platform': 'ANDROID'});
    });

    test('retira el dispositivo por su id', () async {
      server.status = 204;
      server.body = null;
      await ApiPushRemote(api).unregister('d-77');
      expect(server.calls.single, 'DELETE /api/auth/me/devices/d-77');
    });

    test('retirar uno que ya no existe (404) no es un error', () async {
      server.status = 404;
      server.errorBody = true;
      await ApiPushRemote(api).unregister('d-77');
    });

    test('otro fallo al retirar si se propaga', () async {
      server.offline = true;
      await expectLater(
        ApiPushRemote(api).unregister('d-77'),
        throwsA(anything),
      );
    });

    test('un registro de punta a punta contra el servidor simulado', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final registrar = PushRegistrar(
        prefs: prefs,
        tokens: _Token('tok-9'),
        channels: ApiPushChannelSource(api),
        remote: ApiPushRemote(api),
      );
      // Una sola respuesta sirve a las dos llamadas: configuracion y registro.
      server.body = {
        'concessionId': 'c1',
        'channels': {'push': true},
        'id': 'd-1',
      };
      expect(await registrar.sync('c1'), PushOutcome.registered);
      expect(server.calls, [
        'GET /api/app-configuration',
        'POST /api/auth/me/devices',
      ]);
      server.calls.clear();
      server.status = 204;
      await registrar.retire();
      expect(server.calls.single, 'DELETE /api/auth/me/devices/d-1');
    });
  });
}

class _Server implements HttpClientAdapter {
  int status = 200;
  Object? body;
  bool errorBody = false;
  bool offline = false;
  Object? lastBody;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    lastBody = options.data;
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final payload = errorBody
        ? {'code': 'not_found', 'message': 'no existe'}
        : body;
    return ResponseBody.fromString(
      payload == null ? '' : jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
