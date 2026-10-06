import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/features/branding/data/repositories/branding_repository_impl.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';

/// Servidor falso: responde lo que se le pida, o falla como sin red.
class _FakeServer implements HttpClientAdapter {
  int status = 200;
  Object? body;
  bool offline = false;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final text = body == null ? '' : jsonEncode(body);
    return ResponseBody.fromString(
      text,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _json = {
  'version': 3,
  'primary': '#0EA5E9',
  'secondary': '#0F172A',
  'headerStart': '#0B1F3A',
  'headerEnd': '#07121F',
  'logoLightUrl': 'https://cdn.example.com/logo-claro.png',
  'logoDarkUrl': 'https://cdn.example.com/logo-oscuro.png',
};

void main() {
  late _FakeServer server;
  late SharedPreferences prefs;
  late BrandingRepositoryImpl repo;

  BrandingRepositoryImpl build({ConcessionBranding? fallback}) {
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    return BrandingRepositoryImpl(
      ApiClient(dio: dio),
      prefs,
      fallback: fallback,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = build();
  });

  group('lectura del servidor', () {
    test('convierte la respuesta en marca', () async {
      server.body = _json;
      final b = await repo.load('c1');
      expect(b?.version, 3);
      expect(b?.primary, '#0EA5E9');
      expect(b?.secondary, '#0F172A');
      expect(b?.headerStart, '#0B1F3A');
      expect(b?.headerEnd, '#07121F');
      expect(b?.logoLightUrl, 'https://cdn.example.com/logo-claro.png');
      expect(b?.logoDarkUrl, 'https://cdn.example.com/logo-oscuro.png');
    });

    test('acepta la marca envuelta en "branding" y campos faltantes', () async {
      server.body = {
        'branding': {'primary': '#F97316'},
      };
      final b = await repo.load('c1');
      expect(b?.primary, '#F97316');
      expect(b?.version, 0);
      expect(b?.logoDarkUrl, isNull);
    });

    test('sin color de accion no hay marca', () async {
      server.body = {'version': 2, 'logoLightUrl': 'https://x/y.png'};
      expect(await repo.load('c1'), isNull);
    });

    test('un 404 significa que la concesion no tiene marca propia', () async {
      server.status = 404;
      expect(await repo.load('c1'), isNull);
    });

    test('un 204 sin cuerpo tampoco', () async {
      server.status = 204;
      expect(await repo.load('c1'), isNull);
    });
  });

  group('guardado por concesion (MAR-06)', () {
    test('lo recibido se guarda y sirve sin conexion', () async {
      server.body = _json;
      await repo.load('c1');

      server.offline = true;
      final offline = await repo.load('c1');
      expect(offline?.version, 3);
      expect(offline?.primary, '#0EA5E9');
    });

    test('cada concesion tiene su marca: no se mezclan', () async {
      server.body = _json;
      await repo.load('c1');

      server.offline = true;
      expect(await repo.load('c2'), isNull);
    });

    test('un error del servidor conserva la ultima marca conocida', () async {
      server.body = _json;
      await repo.load('c1');
      server.status = 503;
      expect((await repo.load('c1'))?.version, 3);
    });

    test('con la misma version se conserva lo guardado', () async {
      server.body = _json;
      await repo.load('c1');
      final saved = prefs.getString('branding_c1');

      // Mismos datos con otro color pero la misma version: no se reemplaza.
      server.body = {..._json, 'primary': '#F97316'};
      final again = await repo.load('c1');
      expect(again?.primary, '#0EA5E9');
      expect(prefs.getString('branding_c1'), saved);
    });

    test('una version nueva reemplaza lo guardado', () async {
      server.body = _json;
      await repo.load('c1');
      server.body = {..._json, 'version': 4, 'primary': '#F97316'};
      final updated = await repo.load('c1');
      expect(updated?.primary, '#F97316');
      server.offline = true;
      expect((await repo.load('c1'))?.version, 4);
    });

    test('si el servidor ya no la tiene, se borra lo guardado', () async {
      server.body = _json;
      await repo.load('c1');
      server.status = 404;
      server.body = null;
      expect(await repo.load('c1'), isNull);
      server.offline = true;
      expect(await repo.load('c1'), isNull);
    });

    test('sin conexion y sin nada guardado no hay marca', () async {
      server.offline = true;
      expect(await repo.load('c1'), isNull);
    });
  });

  group('marca de prueba (--dart-define)', () {
    const demo = ConcessionBranding(version: 1, primary: '#14B8A6');

    test('se usa cuando el servidor no tiene marca', () async {
      repo = build(fallback: demo);
      server.status = 404;
      expect(await repo.load('c1'), demo);
    });

    test('se usa sin conexion y sin nada guardado', () async {
      repo = build(fallback: demo);
      server.offline = true;
      expect(await repo.load('c1'), demo);
    });

    test('la del servidor tiene prioridad', () async {
      repo = build(fallback: demo);
      server.body = _json;
      expect((await repo.load('c1'))?.primary, '#0EA5E9');
    });
  });
}
