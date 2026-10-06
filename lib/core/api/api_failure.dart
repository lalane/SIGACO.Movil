import 'package:dio/dio.dart';

/// Error de la API ya normalizado (ProblemDetails con `code` estable).
class ApiFailure implements Exception {
  const ApiFailure({
    this.status,
    this.code,
    this.message,
    this.fieldErrors = const {},
  });

  final int? status;
  final String? code;
  final String? message;
  final Map<String, List<String>> fieldErrors;

  /// Sin respuesta del servidor (sin red, tiempo agotado, DNS).
  bool get isNetwork => status == null;

  factory ApiFailure.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = <String, List<String>>{};
      final raw = data['errors'];
      if (raw is Map<String, dynamic>) {
        raw.forEach((k, v) {
          if (v is List) errors[k] = v.map((x) => x.toString()).toList();
        });
      }
      return ApiFailure(
        status: e.response?.statusCode,
        code: data['code'] as String?,
        message: (data['title'] ?? data['detail']) as String?,
        fieldErrors: errors,
      );
    }
    return ApiFailure(status: e.response?.statusCode);
  }

  @override
  String toString() => 'ApiFailure($status, $code, $message)';
}
