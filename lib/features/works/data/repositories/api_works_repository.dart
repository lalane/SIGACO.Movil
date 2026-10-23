import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../../../core/geo/km_label.dart';
import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';

/// Las obras contra el backend (`/api/works`, M06). El servidor aplica el ambito
/// de la persona; el avance y el monto ejercido salen del resumen de cada obra
/// (`/api/works/{id}/summary`), que es lo que el servidor calcula del ultimo
/// periodo capturado.
class ApiWorksRepository implements WorksRepository {
  ApiWorksRepository(this._api);

  final ApiClient _api;

  static const _pageSize = 100;
  static const _maxPages = 10;

  /// Resumenes que se piden a la vez al armar la lista.
  static const _batch = 6;

  @override
  Future<List<PublicWork>> list() => _guard(() async {
    final dtos = <Map<String, dynamic>>[];
    var page = 1;
    var total = 0;
    // Lo recibido, cancelado o no: con eso se sabe cuando se acabaron las paginas.
    var received = 0;
    do {
      final json = _asMap(
        await _api.getJson(
          '/api/works',
          query: {'page': page, 'pageSize': _pageSize},
        ),
      );
      total = (json['total'] as num?)?.toInt() ?? 0;
      final items = json['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      received += items.length;
      for (final item in items) {
        final dto = _asMap(item);
        // Una obra cancelada ya no se muestra.
        if (_text(dto['status']) != 'CANCELADA') dtos.add(dto);
      }
      page++;
    } while (received < total && page <= _maxPages);

    final works = <PublicWork>[];
    for (var i = 0; i < dtos.length; i += _batch) {
      final slice = dtos.sublist(i, (i + _batch).clamp(0, dtos.length));
      works.addAll(
        await Future.wait([
          for (final dto in slice) _withSummary(dto, quiet: true),
        ]),
      );
    }
    return works;
  }, listing: true);

  @override
  Future<PublicWork> get(String id) => _guard(() async {
    final dto = _asMap(
      await _api.getJson('/api/works/${Uri.encodeComponent(id)}'),
    );
    return _withSummary(dto);
  });

  /// [quiet]: un resumen que no baja no tira la lista; la obra se ve sin avance.
  Future<PublicWork> _withSummary(
    Map<String, dynamic> dto, {
    bool quiet = false,
  }) async {
    Map<String, dynamic>? summary;
    final id = _text(dto['id']);
    if (id != null) {
      try {
        summary = _asMap(
          await _api.getJson('/api/works/${Uri.encodeComponent(id)}/summary'),
        );
      } on ApiFailure {
        if (!quiet) rethrow;
      } on FormatException {
        if (!quiet) rethrow;
      }
    }
    return workFromDto(dto, summary);
  }

  /// Abierta a la ejecucion, con desviacion o terminada; lo demas, por iniciar.
  static WorkStatus statusFromCode(String? code) => switch (code) {
    'EN_EJECUCION' => WorkStatus.inProgress,
    'SUSPENDIDA' || 'CON_DESVIACION' => WorkStatus.delayed,
    'TERMINADA' || 'CERRADA' => WorkStatus.finished,
    _ => WorkStatus.notStarted,
  };

  /// Una obra de `GET /api/works` con su resumen. Los porcentajes del servidor
  /// van de 0 a 100; la app trabaja de 0 a 1.
  static PublicWork workFromDto(
    Map<String, dynamic> m,
    Map<String, dynamic>? summary,
  ) {
    final anchor = geoJsonAnchor(m['geometry']);
    final direction = _text(m['direction']);
    final kmStart = _num(m['kmStart']);
    final kmEnd = _num(m['kmEnd']);
    return PublicWork(
      id: _text(m['id']) ?? '',
      name: _text(m['name']) ?? _text(m['code']) ?? '',
      status: statusFromCode(_text(m['status'])),
      physicalProgress: _fraction(summary?['physicalPercent']),
      programmedProgress: _fraction(summary?['plannedPercent']),
      description: _text(m['description']),
      budget: _num(m['budget']),
      executedAmount: _num(summary?['executedAmount']),
      startDate: _date(m['actualStart'] ?? m['plannedStart']),
      endDate: _date(m['actualEnd'] ?? m['plannedEnd']),
      kmStart: kmStart == null ? null : kmLabel(kmStart, null),
      kmEnd: kmEnd == null ? null : kmLabel(kmEnd, null),
      direction: direction == null ? null : _capitalize(direction),
      latitude: anchor?.$1,
      longitude: anchor?.$2,
    );
  }

  static double _fraction(Object? percent) {
    final v = _num(percent);
    if (v == null || !v.isFinite) return 0;
    return (v / 100).clamp(0.0, 1.0);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

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

  Future<T> _guard<T>(
    Future<T> Function() body, {
    bool listing = false,
  }) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw WorksException(
        e.isNetwork
            ? WorksError.network
            : switch (e.status) {
                403 => WorksError.permissionDenied,
                404 => listing ? WorksError.notAvailable : WorksError.notFound,
                _ => WorksError.server,
              },
      );
    } on WorksException {
      rethrow;
    } catch (_) {
      throw const WorksException(WorksError.server);
    }
  }
}
