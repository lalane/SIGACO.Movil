import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sigaco_movil/core/api/api_client.dart';

/// La respuesta de una ruta del servidor falso.
class FakeReply {
  const FakeReply(this.status, [this.body]);

  FakeReply.bytes(this.status, Uint8List this.body);

  final int status;

  /// JSON (mapa o lista) o bytes.
  final Object? body;
}

/// Servidor falso de la API: responde segun `METODO /ruta` (sin la consulta) y
/// anota lo que le llega. Una ruta sin respuesta devuelve 404.
class FakeApi implements HttpClientAdapter {
  final routes = <String, FakeReply Function(RequestOptions)>{};
  final requests = <RequestOptions>[];

  /// Sin red: toda peticion falla como si no hubiera conexion.
  bool offline = false;

  /// Rutas (`METODO /ruta`) que fallan como si no hubiera conexion, mientras el
  /// resto responde: un corte justo en un paso.
  final failingRoutes = <String>{};

  void reply(String route, FakeReply Function(RequestOptions) handler) =>
      routes[route] = handler;

  /// Una respuesta fija.
  void on(String route, FakeReply reply) => routes[route] = (_) => reply;

  ApiClient client() => ApiClient(dio: Dio()..httpClientAdapter = this);

  Iterable<RequestOptions> to(String route) =>
      requests.where((r) => '${r.method} ${r.path}' == route);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline ||
        failingRoutes.contains('${options.method} ${options.path}')) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final reply = routes['${options.method} ${options.path}']?.call(options);
    if (reply == null) return _json(404, {'title': 'no existe'});
    final body = reply.body;
    if (body is Uint8List) {
      return ResponseBody.fromBytes(
        body,
        reply.status,
        headers: {
          Headers.contentTypeHeader: ['image/jpeg'],
        },
      );
    }
    final response = _json(reply.status, body ?? {});
    // Un error de Dio es lo que ve el repositorio con un estado 4xx/5xx.
    if (reply.status >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: reply.status,
          data: body ?? {},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return response;
  }

  static ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}
