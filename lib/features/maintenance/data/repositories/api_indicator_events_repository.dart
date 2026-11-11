import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/indicator_events.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/indicator_events_repository.dart';

class ApiIndicatorEventsRepository implements IndicatorEventsRepository {
  ApiIndicatorEventsRepository(this._api);

  final ApiClient _api;

  String _base(MaintenanceIndicator indicator) =>
      '/api/maintenance/indicators/${indicator.name.toUpperCase()}';

  Map<String, dynamic> _map(Object? json) =>
      json is Map<String, dynamic> ? json : const <String, dynamic>{};

  @override
  Future<List<IndicatorEvent>> events(MaintenanceIndicator indicator) async {
    final json = _map(
      await _api.getJson(
        '${_base(indicator)}/events',
        query: {'pageSize': 100},
      ),
    );
    final items = json['items'];
    return items is List
        ? [
            for (final item in items)
              if (item is Map<String, dynamic>) IndicatorEvent.fromJson(item),
          ]
        : const [];
  }

  @override
  Future<List<IndicatorParameterStatus>> performance(
    MaintenanceIndicator indicator,
  ) async {
    final json = _map(await _api.getJson('${_base(indicator)}/performance'));
    final items = json['parameters'];
    return items is List
        ? [
            for (final item in items)
              if (item is Map<String, dynamic>)
                IndicatorParameterStatus.fromJson(item),
          ]
        : const [];
  }

  @override
  Future<List<IndicatorAssetOption>> searchAssets(
    MaintenanceIndicator indicator,
    String term,
  ) async {
    final json = _map(
      await _api.getJson(
        '/api/assets',
        query: {
          if (indicator != MaintenanceIndicator.sgost)
            'subsystemCode': indicator.name.toUpperCase(),
          if (indicator == MaintenanceIndicator.sgost) 'assetTypeCode': 'OAE',
          'search': term,
          'pageSize': 20,
        },
      ),
    );
    final items = json['items'];
    return items is List
        ? [
            for (final item in items)
              if (item is Map<String, dynamic>)
                IndicatorAssetOption(
                  id: item['id'] as String,
                  code: item['code'] as String? ?? '?',
                ),
          ]
        : const [];
  }

  @override
  Future<IndicatorEvent> create(
    MaintenanceIndicator indicator, {
    required String assetId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String cause,
    required String clientUuid,
  }) async {
    final Map<String, dynamic>? json;
    try {
      json = await _api.post(
        '${_base(indicator)}/events',
        data: {
          'assetId': assetId,
          'startedAt': startedAt.toUtc().toIso8601String(),
          if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
          'cause': cause,
          'clientUuid': clientUuid,
        },
      );
    } on ApiFailure catch (e) {
      // Una regla del servidor (400, 409): se dice cual, para que la persona
      // sepa que falta (p. ej. clasificar el equipo en la web).
      final status = e.status;
      if (status == 400 || status == 409 || status == 422) {
        final field = e.fieldErrors.values.expand((m) => m).firstOrNull;
        final text = (field ?? e.message)?.trim();
        final tag = e.code ?? '$status';
        throw IndicatorEventRejected(
          text == null || text.isEmpty ? tag : '$text ($tag)',
        );
      }
      rethrow;
    }
    return IndicatorEvent.fromJson(json ?? const {});
  }
}

/// Sin API (pruebas y modo sin servidor): nada que mostrar.
class UnavailableIndicatorEventsRepository
    implements IndicatorEventsRepository {
  const UnavailableIndicatorEventsRepository();

  @override
  Future<List<IndicatorEvent>> events(MaintenanceIndicator indicator) async =>
      const [];

  @override
  Future<List<IndicatorParameterStatus>> performance(
    MaintenanceIndicator indicator,
  ) async => const [];

  @override
  Future<List<IndicatorAssetOption>> searchAssets(
    MaintenanceIndicator indicator,
    String term,
  ) async => const [];

  @override
  Future<IndicatorEvent> create(
    MaintenanceIndicator indicator, {
    required String assetId,
    required DateTime startedAt,
    DateTime? endedAt,
    required String cause,
    required String clientUuid,
  }) => throw UnsupportedError('Sin servidor');
}
