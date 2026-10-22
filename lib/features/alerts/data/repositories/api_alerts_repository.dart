import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

/// Las alertas de la persona contra el backend (`/api/auth/me/notifications`):
/// la bandeja de notificaciones dentro de la app que sustituye al push (decision
/// del cliente del 21/10/2026). El servidor ya filtra por persona y concesion
/// activa; cada una trae el tipo y el id del registro al que lleva.
class ApiAlertsRepository implements AlertsRepository {
  ApiAlertsRepository(this._api);

  final ApiClient _api;

  /// Tamano de pagina maximo del servidor y tope de paginas: la lista movil no
  /// tiene paginacion propia, y con 500 las mas recientes alcanzan.
  static const _pageSize = 100;
  static const _maxPages = 5;

  static const _base = '/api/auth/me/notifications';

  @override
  Future<List<AppAlert>> list() => _guard(() async {
    final result = <AppAlert>[];
    var page = 1;
    var total = 0;
    do {
      final json = await _api.getJson(
        _base,
        query: {'page': page, 'pageSize': _pageSize},
      );
      final map = _asMap(json);
      total = (map['total'] as num?)?.toInt() ?? 0;
      final items = map['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      for (final item in items) {
        result.add(_alert(_asMap(item)));
      }
      page++;
    } while (result.length < total && page <= _maxPages);
    return result;
  });

  @override
  Future<void> markRead(String id) => _guard(() async {
    await _api.post('$_base/${Uri.encodeComponent(id)}/read');
  });

  @override
  Future<void> markAllRead() => _guard(() async {
    await _api.post('$_base/read-all');
  });

  static AppAlert _alert(Map<String, dynamic> m) {
    final entityType = (m['entityType'] as String?)?.trim();
    final entityId = (m['entityId'] as String?)?.trim();
    final body = (m['message'] as String?)?.trim();
    return AppAlert(
      id: m['id'] as String,
      title: (m['title'] as String?)?.trim() ?? '',
      body: body == null || body.isEmpty ? null : body,
      createdAt: DateTime.parse(m['createdAt'] as String).toUtc(),
      read: m['readAt'] != null,
      // El servidor no manda importancia: todas se muestran como informativas.
      severity: AlertSeverity.info,
      entityType: entityType == null || entityType.isEmpty ? null : entityType,
      entityId: entityId == null || entityId.isEmpty ? null : entityId,
    );
  }

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw AlertsException(
        e.isNetwork
            ? AlertsError.network
            : switch (e.status) {
                403 => AlertsError.permissionDenied,
                404 => AlertsError.notAvailable,
                _ => AlertsError.server,
              },
      );
    } on AlertsException {
      rethrow;
    } catch (_) {
      throw const AlertsException(AlertsError.server);
    }
  }
}
