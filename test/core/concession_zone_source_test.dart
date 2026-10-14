import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/core/time/concession_zone_source.dart';

class _Server implements HttpClientAdapter {
  int status = 200;
  Object? body;
  bool offline = false;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? {}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// La zona de la concesion cuando la marca no la trae (DEV-MOB-057, RN-04).
void main() {
  late _Server server;
  late ApiConcessionZoneSource source;

  setUp(() {
    server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server
      ..options.validateStatus = (s) => s != null && s < 400;
    source = ApiConcessionZoneSource(ApiClient(dio: dio));
  });

  test('lee la zona de la concesion', () async {
    server.body = {
      'concessionId': 'c1',
      'timeZone': 'America/Sao_Paulo',
      'currentUtcOffsetMinutes': -180,
    };

    final zone = await source.load('c1');

    expect(zone?.id, 'America/Sao_Paulo');
    expect(
      server.paths.single,
      '/api/document-settings/concessions/c1/time-zone',
    );
  });

  test('una zona desconocida se ignora', () async {
    server.body = {'timeZone': 'Marte/Olimpo'};

    expect(await source.load('c1'), isNull);
  });

  test('sin zona configurada o sin red, no hay zona y no falla', () async {
    server.status = 409;
    server.body = {'code': 'TIME_ZONE_UNAVAILABLE'};
    expect(await source.load('c1'), isNull);

    server.status = 404;
    expect(await source.load('c1'), isNull);

    server.offline = true;
    expect(await source.load('c1'), isNull);
  });

  test('sin fuente, la concesion no trae zona', () async {
    expect(await const NoConcessionZoneSource().load('c1'), isNull);
  });
}
