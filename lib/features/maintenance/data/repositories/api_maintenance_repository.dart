import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// El mantenimiento preventivo contra el backend (`/api/preventive-maintenance`,
/// M07). Cada indicador (subsistema) es un filtro del servidor; el avance y los
/// montos salen del volumen programado, el ejecutado y el costo unitario.
class ApiMaintenanceRepository implements MaintenanceRepository {
  ApiMaintenanceRepository(this._api);

  final ApiClient _api;

  static const _pageSize = 100;
  static const _maxPages = 10;

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) =>
      _guard(() async {
        final result = <MaintenanceOrder>[];
        var page = 1;
        var received = 0;
        var total = 0;
        do {
          final json = _asMap(
            await _api.getJson(
              '/api/preventive-maintenance',
              query: {
                'subsystemCode': subsystemCode(indicator),
                'page': page,
                'pageSize': _pageSize,
              },
            ),
          );
          total = (json['total'] as num?)?.toInt() ?? 0;
          final items = json['items'];
          if (items is! List) throw const FormatException('sin items');
          if (items.isEmpty) break;
          received += items.length;
          for (final item in items) {
            result.add(orderFromDto(_asMap(item), indicator: indicator));
          }
          page++;
        } while (received < total && page <= _maxPages);
        return result;
      }, listing: true);

  @override
  Future<MaintenanceOrder> get(String id) => _guard(() async {
    final dto = _asMap(
      await _api.getJson(
        '/api/preventive-maintenance/${Uri.encodeComponent(id)}',
      ),
    );
    return orderFromDto(dto);
  });

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    required double percent,
    double? executedVolume,
    String? notes,
    String? clientId,
  }) => _guard(() async {
    final key = Uri.encodeComponent(id);
    final text = notes?.trim();
    await _api.post(
      '/api/preventive-maintenance/$key/progress',
      data: {
        'progressPercent': percent.clamp(0, 100),
        'executedVolume': ?executedVolume,
        if (text != null && text.isNotEmpty) 'notes': text,
        'clientUuid': ?clientId,
      },
    );
    return orderFromDto(
      _asMap(await _api.getJson('/api/preventive-maintenance/$key')),
    );
  });

  /// El codigo de subsistema del servidor: el nombre del indicador en mayusculas.
  static String subsystemCode(MaintenanceIndicator i) => i.name.toUpperCase();

  static MaintenanceIndicator indicatorFromCode(String? code) {
    final c = code?.trim().toUpperCase();
    for (final i in MaintenanceIndicator.values) {
      if (i.name.toUpperCase() == c) return i;
    }
    return MaintenanceIndicator.sgp;
  }

  /// Programado es abierto; en ejecucion, en proceso; completado o cancelado,
  /// cerrado.
  static MaintenanceStatus statusFromCode(String? code) => switch (code) {
    'EN_EJECUCION' => MaintenanceStatus.inProgress,
    'COMPLETADO' || 'CANCELADO' => MaintenanceStatus.closed,
    _ => MaintenanceStatus.open,
  };

  static MaintenanceOrder orderFromDto(
    Map<String, dynamic> m, {
    MaintenanceIndicator? indicator,
  }) {
    final total = _num(m['totalVolume']) ?? 0;
    final executed = _num(m['executedVolume']) ?? 0;
    final unitCost = _num(m['unitCost']);
    final activity = _text(m['activity']) ?? '';
    final folio = _text(m['folio']);
    final kmStart = _num(m['kmStart']);
    final kmEnd = _num(m['kmEnd']);
    final direction = _text(m['direction']);
    return MaintenanceOrder(
      id: _text(m['id']) ?? '',
      indicator: indicator ?? indicatorFromCode(_text(m['subsystemCode'])),
      title: [
        folio,
        activity,
      ].where((s) => s != null && s.isNotEmpty).join(' · '),
      activity: activity,
      status: statusFromCode(_text(m['status'])),
      totalVolume: total,
      executedVolume: executed,
      unit: _text(m['unit']) ?? '',
      unitCost: unitCost,
      programmedAmount: unitCost == null ? null : unitCost * total,
      executedAmount: unitCost == null ? null : unitCost * executed,
      startDate: _date(m['actualStart'] ?? m['plannedStart']),
      endDate: _date(m['actualEnd'] ?? m['plannedEnd']),
      kmStart: kmStart == null ? null : kmLabel(kmStart, null),
      kmEnd: kmEnd == null ? null : kmLabel(kmEnd, null),
      direction: direction == null
          ? null
          : direction[0].toUpperCase() + direction.substring(1).toLowerCase(),
    );
  }

  static DateTime? _date(Object? v) {
    final d = v is String ? DateTime.tryParse(v) : null;
    return d == null ? null : DateTime.utc(d.year, d.month, d.day);
  }

  static String? _text(Object? v) {
    final s = v is String ? v.trim() : null;
    return s == null || s.isEmpty ? null : s;
  }

  static double? _num(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  Future<T> _guard<T>(Future<T> Function() body, {bool listing = false}) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw MaintenanceException(
        e.isNetwork
            ? MaintenanceError.network
            : switch (e.status) {
                403 => MaintenanceError.permissionDenied,
                404 =>
                  listing
                      ? MaintenanceError.notAvailable
                      : MaintenanceError.notFound,
                _ => MaintenanceError.server,
              },
      );
    } on MaintenanceException {
      rethrow;
    } catch (_) {
      throw const MaintenanceException(MaintenanceError.server);
    }
  }
}
