import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_failure.dart';
import 'response_cache.dart';

/// Identificador de operacion (UUID v4). El backend lo acepta en
/// `X-Correlation-Id` y lo guarda en su auditoria: permite cruzar un reporte de
/// la app con los eventos y logs de esa peticion.
String newCorrelationId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${[for (var i = 0; i < 4; i++) hex(i)].join()}-'
      '${hex(4)}${hex(5)}-${hex(6)}${hex(7)}-${hex(8)}${hex(9)}-'
      '${[for (var i = 10; i < 16; i++) hex(i)].join()}';
}

class ApiClient {
  ApiClient({Dio? dio, String? userAgent, this.cache = const NoResponseCache()})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              headers: {'Accept': 'application/json', 'User-Agent': ?userAgent},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          options.headers['X-Correlation-Id'] = newCorrelationId();
          handler.next(options);
        },
        onResponse: (response, handler) {
          _trace(response.requestOptions, response.statusCode);
          _reachable.add(true);
          // El servidor mide la inactividad por peticion: se refleja aqui.
          if (accessToken != null) lastActivityAt = DateTime.now();
          handler.next(response);
        },
        onError: (e, handler) {
          final status = e.response?.statusCode;
          _trace(e.requestOptions, status, error: e.type.name);
          // Cualquier respuesta del servidor (aunque sea un error) prueba que hay
          // conexion; solo un fallo de red sin respuesta marca que no la hay.
          if (status != null) {
            _reachable.add(true);
          } else if (_isNetworkFailure(e.type)) {
            _reachable.add(false);
          }
          if (accessToken != null && status != null) {
            lastActivityAt = DateTime.now();
          }
          if (status == 401 && accessToken != null) {
            onUnauthorized?.call();
          } else if (status == 403) {
            final data = e.response?.data;
            final code = data is Map<String, dynamic> ? data['code'] : null;
            if (code is String) onForbiddenCode?.call(code);
            // Un 403 que no pide un paso de la sesion es una accion que el
            // servidor ya no permite: los accesos pudieron cambiar. La consulta
            // del menu se excluye para no repetirse a si misma.
            final isSessionStep =
                code is String && _sessionStepCodes.contains(code);
            if (!isSessionStep &&
                !e.requestOptions.path.endsWith(accessCheckPath)) {
              _accessDenied.add(null);
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;

  /// Lo consultado con conexion, para volver a verlo sin ella: si una consulta de
  /// lectura falla por falta de red y ya se habia hecho antes, se entrega lo
  /// guardado. Un error del servidor nunca se esconde con lo guardado.
  final ResponseCache cache;

  /// Consulta de los accesos de la sesion (el menu): se vuelve a pedir cuando
  /// el servidor niega una accion.
  static const accessCheckPath = '/api/context/navigation';

  /// Codigos de 403 que piden un paso de la sesion (no son una negacion de acceso).
  static const _sessionStepCodes = {
    'MFA_REQUIRED',
    'MFA_ENROLLMENT_REQUIRED',
    'PASSWORD_CHANGE_REQUIRED',
    'CONTEXT_REQUIRED',
  };

  final _accessDenied = StreamController<void>.broadcast();
  final _reachable = StreamController<bool>.broadcast();

  /// true cuando el servidor respondio; false cuando la peticion fallo por red.
  Stream<bool> get reachability => _reachable.stream;

  static bool _isNetworkFailure(DioExceptionType t) =>
      t == DioExceptionType.connectionError ||
      t == DioExceptionType.connectionTimeout ||
      t == DioExceptionType.sendTimeout ||
      t == DioExceptionType.receiveTimeout;

  /// Emite cuando el servidor niega una accion por permisos (403).
  Stream<void> get accessDenied => _accessDenied.stream;

  /// Token Bearer de la sesion activa; el servidor lo invalida al vencer.
  String? accessToken;

  /// Ultima respuesta del servidor con sesion abierta (la inactividad del
  /// servidor se cuenta desde la ultima peticion, no desde un toque en pantalla).
  DateTime? lastActivityAt;

  /// Se invoca cuando una peticion autenticada recibe 401 (sesion vencida/revocada).
  void Function()? onUnauthorized;

  /// Se invoca con el `code` de un 403 (por ejemplo MFA_REQUIRED o
  /// PASSWORD_CHANGE_REQUIRED), para que la sesion reaccione globalmente.
  void Function(String code)? onForbiddenCode;

  /// Solo metodo, ruta, estado y correlation id: nunca cuerpos ni cabeceras.
  void _trace(RequestOptions o, int? status, {String? error}) {
    if (kReleaseMode) return;
    developer.log(
      '${o.method} ${o.path} -> ${status ?? error} '
      '[${o.headers['X-Correlation-Id']}]',
      name: 'sigaco.api',
    );
  }

  Future<Map<String, dynamic>?> post(String path, {Object? data}) async {
    try {
      final r = await _dio.post<dynamic>(path, data: data);
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// POST `multipart/form-data` con un archivo y campos de texto (las fotos de
  /// evidencia de un ticket). Los campos nulos no se mandan. [contentType] es el
  /// tipo del archivo: el servidor exige `image/*` para una foto.
  Future<Map<String, dynamic>?> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    required String fileName,
    required String contentType,
    Map<String, Object?> fields = const {},
  }) async {
    try {
      final form = FormData.fromMap({
        for (final e in fields.entries)
          if (e.value != null) e.key: e.value,
        fileField: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final r = await _dio.post<dynamic>(
        path,
        data: form,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// Direccion base de la API, sin barra final.
  String get baseUrl {
    final base = _dio.options.baseUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  /// Descarga un archivo de la propia API con la sesion iniciada (los logos de
  /// la concesion piden autorizacion). [url] es absoluta bajo [baseUrl] o una
  /// ruta que empieza con `/`. Devuelve null si falla, esta vacio o pasa de
  /// [maxBytes]; una direccion de otro servidor tambien da null.
  Future<Uint8List?> downloadFile(
    String url, {
    int maxBytes = 1024 * 1024,
  }) async {
    final path = url.startsWith(baseUrl) ? url.substring(baseUrl.length) : url;
    if (!path.startsWith('/')) return null;
    try {
      final r = await getBytes(path);
      if (r.bytes.isEmpty || r.bytes.length > maxBytes) return null;
      return r.bytes;
    } on ApiFailure {
      return null;
    }
  }

  /// GET que devuelve el JSON tal cual llega (objeto o lista).
  Future<Object?> getJson(String path, {Map<String, Object?>? query}) async {
    final key = _cacheKey(path, query);
    try {
      final r = await _dio.get<dynamic>(path, queryParameters: _clean(query));
      await _remember(path, key, r.data);
      return r.data;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      final saved = await _recall(path, key, failure);
      if (saved != null) return saved.json;
      throw failure;
    }
  }

  /// La clave de una consulta: el metodo, la ruta y los filtros en orden.
  static String _cacheKey(String path, Map<String, Object?>? query) {
    final clean = _clean(query);
    if (clean == null || clean.isEmpty) return 'GET $path';
    final names = clean.keys.toList()..sort();
    return 'GET $path?${[for (final n in names) '$n=${clean[n]}'].join('&')}';
  }

  /// Guardar es un extra: un fallo del disco no debe romper la consulta.
  Future<void> _remember(String path, String key, Object? json) async {
    if (json == null || !cache.accepts(path)) return;
    try {
      await cache.save(key, json);
    } catch (_) {}
  }

  /// Lo guardado de una consulta, solo cuando fallo por falta de red.
  Future<({Object? json, DateTime savedAt})?> _recall(
    String path,
    String key,
    ApiFailure failure,
  ) async {
    if (!failure.isNetwork || !cache.accepts(path)) return null;
    try {
      return await cache.read(key);
    } catch (_) {
      return null;
    }
  }

  /// GET en flujo de un archivo grande (paquetes de mapa). Con [from] mayor que
  /// cero pide solo desde ese byte (`Range`): si el servidor lo respeta responde
  /// 206 y [resumed] es true; si responde 200 manda todo desde el principio.
  /// Un error devuelve solo el estado HTTP (el cuerpo no se lee).
  Future<({Stream<List<int>> body, bool resumed, int? contentLength})>
  getStream(String path, {int from = 0}) async {
    try {
      final r = await _dio.get<ResponseBody>(
        path,
        options: Options(
          responseType: ResponseType.stream,
          headers: {if (from > 0) 'Range': 'bytes=$from-'},
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (s) => s == 200 || s == 206,
        ),
      );
      final body = r.data!;
      return (
        body: body.stream,
        resumed: r.statusCode == 206,
        contentLength: int.tryParse(
          r.headers.value(Headers.contentLengthHeader) ?? '',
        ),
      );
    } on DioException catch (e) {
      throw ApiFailure(status: e.response?.statusCode);
    }
  }

  /// GET de un archivo (vista previa): los bytes y su tipo de contenido.
  Future<({Uint8List bytes, String contentType})> getBytes(
    String path, {
    Map<String, Object?>? query,
  }) async {
    try {
      final r = await _dio.get<List<int>>(
        path,
        queryParameters: _clean(query),
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return (
        bytes: Uint8List.fromList(r.data ?? const []),
        contentType: (r.headers.value(Headers.contentTypeHeader) ?? '')
            .split(';')
            .first
            .trim()
            .toLowerCase(),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(await _readBytesError(e));
    }
  }

  Future<Map<String, dynamic>?> put(String path, {Object? data}) async {
    try {
      final r = await _dio.put<dynamic>(path, data: data);
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  /// PUT de un cuerpo binario (bloques de una carga).
  Future<Map<String, dynamic>?> putBytes(String path, Uint8List bytes) async {
    try {
      final r = await _dio.put<dynamic>(
        path,
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: 'application/octet-stream',
          headers: {Headers.contentLengthHeader: bytes.length},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>?> delete(String path) async {
    try {
      final r = await _dio.delete<dynamic>(path);
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  static Map<String, Object?>? _clean(Map<String, Object?>? query) =>
      query == null
      ? null
      : {
          for (final e in query.entries)
            if (e.value != null && e.value.toString().isNotEmpty)
              e.key: e.value,
        };

  /// Con respuesta en bytes, el error JSON del servidor llega como bytes: se
  /// vuelve a leer para conservar su `code`.
  static Future<DioException> _readBytesError(DioException e) async {
    final data = e.response?.data;
    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map<String, dynamic>) {
          e.response!.data = decoded;
        }
      } catch (_) {}
    }
    return e;
  }

  Future<Map<String, dynamic>?> get(String path) async {
    final key = _cacheKey(path, null);
    try {
      final r = await _dio.get<dynamic>(path);
      await _remember(path, key, r.data);
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      final saved = await _recall(path, key, failure);
      final json = saved?.json;
      if (json is Map<String, dynamic>) return json;
      throw failure;
    }
  }
}
