import 'dart:io';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
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
  Future<MaintenanceIndicatorSummary?> summary(
    MaintenanceIndicator indicator, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final json = _asMap(
        await _api.getJson(
          '/api/maintenance/subsystems/${subsystemCode(indicator)}/summary',
          query: {
            if (from != null)
              'from': DateTime(from.year, from.month, from.day).toUtc().toIso8601String(),
            if (to != null)
              'to': DateTime(to.year, to.month, to.day, 23, 59, 59).toUtc().toIso8601String(),
          },
        ),
      );
      return summaryFromDto(json);
    } catch (_) {
      // Un servidor sin el endpoint, sin red o sin permiso: la lista sigue sin conteos.
      return null;
    }
  }

  /// El resumen del servidor; la evaluacion es la mas reciente del año mas reciente.
  static MaintenanceIndicatorSummary summaryFromDto(Map<String, Object?> json) {
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final latest = json['latestEvaluation'];
    final evaluation = latest is Map ? latest.cast<String, Object?>() : null;
    return MaintenanceIndicatorSummary(
      ticketsTotal: n(json['ticketsTotal']),
      ticketsOpen: n(json['ticketsOpen']),
      ticketsAttended: n(json['ticketsAttended']),
      ticketsClosed: n(json['ticketsClosed']),
      compliancePercent: (evaluation?['compliancePercent'] as num?)?.toDouble(),
      evaluationYear: (evaluation?['concessionYear'] as num?)?.toInt(),
      openProposals: n(json['openNonConformities']),
    );
  }

  @override
  Future<List<MaintenanceIndicator>> visibleIndicators() async {
    try {
      final json = _asMap(await _api.getJson('/api/maintenance/navigation'));
      final subsystems = json['subsystems'];
      if (subsystems is! List) return MaintenanceIndicator.values;
      final codes = {
        for (final s in subsystems)
          if (s is Map && s['code'] is String)
            (s['code'] as String).trim().toUpperCase(),
      };
      return [
        for (final i in MaintenanceIndicator.values)
          if (codes.contains(subsystemCode(i))) i,
      ];
    } on ApiFailure catch (e) {
      // Un servidor anterior al PR 88 no tiene el endpoint: se ven todos. Sin
      // red tambien, porque cada lista ya avisa si no puede cargarse.
      if (e.isNetwork || e.status == 404) return MaintenanceIndicator.values;
      throw MaintenanceException(
        e.status == 403
            ? MaintenanceError.permissionDenied
            : MaintenanceError.server,
      );
    } catch (_) {
      return MaintenanceIndicator.values;
    }
  }

  /// Lo que el servidor recibe para registrar el seguimiento: el volumen de
  /// este seguimiento o, sin el, el avance acumulado; nunca los dos, porque con
  /// volumen el servidor ignora el porcentaje y lo suma al acumulado.
  static Map<String, Object?> progressBody({
    double? executedVolume,
    double? percent,
    String? notes,
    DateTime? at,
  }) {
    final text = notes?.trim();
    final local = (at ?? DateTime.now()).toLocal();
    return {
      if (executedVolume != null)
        'executedVolume': executedVolume
      else if (percent != null)
        'progressPercent': percent.clamp(0, 100),
      // El dia en que se capturo, no el del envio.
      'reportedOn':
          '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}',
      if (text != null && text.isNotEmpty) 'notes': text,
    };
  }

  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  }) => _guard(() async {
    if (executedVolume == null && percent == null) {
      throw const MaintenanceException(MaintenanceError.invalid);
    }
    final key = Uri.encodeComponent(id);
    final created = await _api.post(
      '/api/preventive-maintenance/$key/progress',
      data: {
        ...progressBody(
          executedVolume: executedVolume,
          percent: percent,
          notes: notes,
          at: at,
        ),
        'clientUuid': ?clientId,
      },
    );
    try {
      await attachPhotos(
        id,
        photoPaths,
        progressId: _text(created?['id']),
        capturedAt: at,
      );
    } on ApiFailure catch (e) {
      // Sin red se reintenta todo: el servidor reconoce el seguimiento por su
      // clave y no lo suma dos veces. Con otro fallo, solo faltan las fotos.
      if (e.isNetwork) rethrow;
      throw MaintenanceException(
        MaintenanceError.photosNotSaved,
        message: _reason(e),
      );
    }
    return orderFromDto(
      _asMap(await _api.getJson('/api/preventive-maintenance/$key')),
    );
  });

  /// Sube las fotos de un seguimiento ya registrado (`progressId`). Lanza
  /// [ApiFailure].
  Future<void> attachPhotos(
    String maintenanceId,
    List<String> photos, {
    String? progressId,
    DateTime? capturedAt,
  }) async {
    final path =
        '/api/preventive-maintenance/${Uri.encodeComponent(maintenanceId)}'
        '/attachments';
    for (final photo in photos) {
      if (!File(photo).existsSync()) continue;
      await _api.postMultipart(
        path,
        fileField: 'file',
        filePath: photo,
        fileName: photo.split(RegExp(r'[\\/]')).last,
        contentType: _imageType(photo),
        fields: {
          'kind': 'FOTO',
          'capturedAt': capturedAt?.toUtc().toIso8601String(),
          'clientUuid': newClientId(),
          'progressId': progressId,
        },
      );
    }
  }

  /// El tipo de imagen segun la extension; el servidor exige `image/*`.
  static String _imageType(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  static String? _reason(ApiFailure e) {
    for (final messages in e.fieldErrors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return e.message;
  }

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
                400 || 409 || 422 => MaintenanceError.invalid,
                _ => MaintenanceError.server,
              },
        message: e.isNetwork ? null : _reason(e),
      );
    } on MaintenanceException {
      rethrow;
    } catch (_) {
      throw const MaintenanceException(MaintenanceError.server);
    }
  }
}
