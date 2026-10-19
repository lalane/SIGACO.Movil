import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/features/branding/data/repositories/branding_repository_impl.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';

const _config = '/api/app-configuration';
const _versionPath = '/api/app-configuration/version';

/// Servidor falso: responde por ruta lo que se le pida, o falla como sin red.
class _FakeServer implements HttpClientAdapter {
  /// Respuestas por ruta; sin entrada responde 404.
  final bodies = <String, Object?>{};
  final statuses = <String, int>{};
  bool offline = false;
  final requests = <String>[];

  int count(String path) => requests.where((p) => p == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final status =
        statuses[options.path] ??
        (bodies.containsKey(options.path) ? 200 : 404);
    final body = bodies[options.path];
    if (body is List<int>) {
      return ResponseBody.fromBytes(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    }
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Lo que entrega `GET /api/app-configuration` con colores propios y logos.
Map<String, dynamic> _payload({
  int version = 3,
  Map<String, Object?>? colors,
  Map<String, Object?>? logos,
}) => {
  'concessionId': 'c1',
  'concessionName': 'NOVA 381',
  'configurationVersion': version,
  'serverTimeUtc': '2026-10-15T12:00:00Z',
  'timeZone': 'America/Sao_Paulo',
  'currentUtcOffsetMinutes': -180,
  'colors':
      colors ??
      {
        'primaryColor': '#0EA5E9',
        'secondaryColor': '#F28C28',
        'menuBackgroundColor': '#0F172A',
        'headerColor': '#0B1F3A',
        'buttonColor': '#14B8A6',
        'primaryTextColor': '#FFFFFF',
      },
  'logos':
      logos ??
      {
        'principal': {'id': 'l1', 'url': '/api/configuration-logos/l1'},
        'reduced': {'id': 'l2', 'url': '/api/configuration-logos/l2'},
        'document': null,
      },
  'documentCatalogs': {},
  'blockedExtensions': <String>[],
  'channels': {'email': true, 'push': false, 'telegram': false},
};

void main() {
  late _FakeServer server;
  late SharedPreferences prefs;
  late BrandingRepositoryImpl repo;
  late ApiClient api;

  BrandingRepositoryImpl build({ConcessionBranding? fallback}) {
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    api = ApiClient(dio: dio);
    return BrandingRepositoryImpl(api, prefs, fallback: fallback);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = build();
  });

  group('de la configuracion vigente a la marca', () {
    const base = 'https://api.test';

    test('convierte colores, logos, zona y version', () {
      final b = brandingFromConfiguration(_payload(), baseUrl: base)!;
      expect(b.version, 3);
      // El color del boton manda sobre el primario.
      expect(b.primary, '#14B8A6');
      expect(b.secondary, '#0F172A');
      expect(b.headerStart, '#0B1F3A');
      expect(b.timezone, 'America/Sao_Paulo');
      expect(b.logoLightUrl, 'https://api.test/api/configuration-logos/l1');
      expect(b.logoDarkUrl, b.logoLightUrl);
      expect(b.logoReducedUrl, 'https://api.test/api/configuration-logos/l2');
    });

    test('sin color de boton propio usa el primario', () {
      final b = brandingFromConfiguration(
        _payload(colors: {'primaryColor': '#0EA5E9', 'buttonColor': '#1F4E79'}),
        baseUrl: base,
      )!;
      expect(b.primary, '#0EA5E9');
    });

    test('los colores provisionales del servidor no repintan la app', () {
      final b = brandingFromConfiguration(
        _payload(
          colors: {
            'primaryColor': '#1F4E79',
            'secondaryColor': '#F28C28',
            'menuBackgroundColor': '#0D1B2A',
            'headerColor': '#424241',
            'buttonColor': '#1F4E79',
          },
        ),
        baseUrl: base,
      );
      // Quedan los logos, sin colores propios.
      expect(b?.primary, isNull);
      expect(b?.secondary, isNull);
      expect(b?.headerStart, isNull);
      expect(b?.logoLightUrl, isNotNull);
    });

    test('sin colores propios ni logos no hay marca', () {
      final b = brandingFromConfiguration(
        _payload(
          colors: {'primaryColor': '#1F4E79', 'buttonColor': '#1f4e79'},
          logos: {'principal': null, 'reduced': null, 'document': null},
        ),
        baseUrl: base,
      );
      expect(b, isNull);
    });

    test('una URL absoluta se respeta y una relativa se une a la base', () {
      final b = brandingFromConfiguration(
        _payload(
          logos: {
            'principal': {'url': 'https://cdn.example.com/a.png'},
            'reduced': {'url': 'api/configuration-logos/z'},
          },
        ),
        baseUrl: 'https://api.test/',
      )!;
      expect(b.logoLightUrl, 'https://cdn.example.com/a.png');
      expect(b.logoReducedUrl, 'https://api.test/api/configuration-logos/z');
    });

    test('una respuesta vacia no es marca', () {
      expect(brandingFromConfiguration(null, baseUrl: base), isNull);
      expect(brandingFromConfiguration({}, baseUrl: base), isNull);
    });
  });

  group('lectura del servidor', () {
    test('baja la configuracion y la convierte en marca', () async {
      server.bodies[_config] = _payload();
      final b = await repo.load('c1');
      expect(b?.version, 3);
      expect(b?.primary, '#14B8A6');
      expect(b?.logoLightUrl, 'https://api.test/api/configuration-logos/l1');
    });

    test('un 404 significa que la concesion no tiene marca propia', () async {
      expect(await repo.load('c1'), isNull);
    });

    test('un 204 sin cuerpo tampoco', () async {
      server.statuses[_config] = 204;
      server.bodies[_config] = null;
      expect(await repo.load('c1'), isNull);
    });
  });

  group('guardado por concesion (MAR-06)', () {
    test('lo recibido se guarda y sirve sin conexion', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');

      server.offline = true;
      final offline = await repo.load('c1');
      expect(offline?.version, 3);
      expect(offline?.primary, '#14B8A6');
    });

    test('cada concesion tiene su marca: no se mezclan', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');

      server.offline = true;
      expect(await repo.load('c2'), isNull);
    });

    test('un error del servidor conserva la ultima marca conocida', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');
      server.statuses[_versionPath] = 503;
      expect((await repo.load('c1'))?.version, 3);
    });

    test('con la misma version no se descarga nada mas', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');
      server.bodies[_versionPath] = {'configurationVersion': 3};
      final before = server.count(_config);
      final saved = prefs.getString('branding_c1');

      final again = await repo.load('c1');
      expect(again?.primary, '#14B8A6');
      expect(server.count(_config), before);
      expect(server.count(_versionPath), 1);
      expect(prefs.getString('branding_c1'), saved);
    });

    test('una version nueva descarga y reemplaza lo guardado', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');
      server.bodies[_versionPath] = {'configurationVersion': 4};
      server.bodies[_config] = _payload(
        version: 4,
        colors: {'buttonColor': '#F97316'},
      );
      final updated = await repo.load('c1');
      expect(updated?.primary, '#F97316');
      server.offline = true;
      expect((await repo.load('c1'))?.version, 4);
    });

    test('si la consulta de version falla, se intenta la descarga', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');
      server.statuses[_versionPath] = 404;
      server.bodies[_config] = _payload(version: 5);
      expect((await repo.load('c1'))?.version, 5);
    });

    test('si el servidor ya no la tiene, se borra lo guardado', () async {
      server.bodies[_config] = _payload();
      await repo.load('c1');
      server.statuses[_versionPath] = 404;
      server.statuses[_config] = 404;
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
      expect(await repo.load('c1'), demo);
    });

    test('se usa sin conexion y sin nada guardado', () async {
      repo = build(fallback: demo);
      server.offline = true;
      expect(await repo.load('c1'), demo);
    });

    test('la del servidor tiene prioridad', () async {
      repo = build(fallback: demo);
      server.bodies[_config] = _payload();
      expect((await repo.load('c1'))?.primary, '#14B8A6');
    });
  });

  group('descarga de logos con la sesion', () {
    test(
      'baja un archivo de la propia API por su direccion completa',
      () async {
        server.bodies['/api/configuration-logos/l1'] = [1, 2, 3, 4];
        final bytes = await api.downloadFile(
          'https://api.test/api/configuration-logos/l1',
        );
        expect(bytes, [1, 2, 3, 4]);
      },
    );

    test('tambien por una ruta relativa', () async {
      server.bodies['/api/configuration-logos/l1'] = [9, 9];
      expect(await api.downloadFile('/api/configuration-logos/l1'), [9, 9]);
    });

    test('una direccion de otro servidor no se descarga', () async {
      expect(await api.downloadFile('https://cdn.example.com/a.png'), isNull);
      expect(server.requests, isEmpty);
    });

    test('un error, un archivo vacio o uno enorme dan null', () async {
      expect(await api.downloadFile('/api/configuration-logos/falta'), isNull);
      server.bodies['/api/configuration-logos/vacio'] = <int>[];
      expect(await api.downloadFile('/api/configuration-logos/vacio'), isNull);
      server.bodies['/api/configuration-logos/grande'] = List.filled(40, 1);
      expect(
        await api.downloadFile('/api/configuration-logos/grande', maxBytes: 10),
        isNull,
      );
    });
  });
}
