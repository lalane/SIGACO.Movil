import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_failure.dart';

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
  ApiClient({Dio? dio, String? userAgent})
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

  Future<Map<String, dynamic>?> get(String path) async {
    try {
      final r = await _dio.get<dynamic>(path);
      return r.data is Map<String, dynamic>
          ? r.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
