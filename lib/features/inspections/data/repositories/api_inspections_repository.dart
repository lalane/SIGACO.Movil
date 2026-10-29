import 'dart:io';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';

/// Las inspecciones (monitoreos) contra el backend (`/api/inspections`, M08). El
/// servidor guarda el tipo con su checklist, los resultados por parametro y los
/// hallazgos; la app los junta en la inspeccion que muestra.
class ApiInspectionsRepository implements InspectionsRepository {
  ApiInspectionsRepository(
    this._api, {
    required this.roadId,
    required this.userId,
    this.language = _spanish,
  });

  final ApiClient _api;

  /// La carretera de la concesion activa (si es una sola) y la persona en
  /// sesion: una inspeccion nueva nace asignada a quien la levanta.
  final Future<String?> Function() roadId;
  final Future<String?> Function() userId;
  final String Function() language;

  static String _spanish() => 'es';

  static const _pageSize = 100;
  static const _maxPages = 5;
  static const _batch = 6;

  List<_Type>? _types;

  @override
  Future<List<Inspection>> list() => _guard(() async {
    final types = await _loadTypes();
    final dtos = <Map<String, dynamic>>[];
    var page = 1;
    var received = 0;
    var total = 0;
    do {
      final json = _asMap(
        await _api.getJson(
          '/api/inspections',
          query: {'page': page, 'pageSize': _pageSize},
        ),
      );
      total = (json['total'] as num?)?.toInt() ?? 0;
      final items = json['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      received += items.length;
      for (final item in items) {
        dtos.add(_asMap(item));
      }
      page++;
    } while (received < total && page <= _maxPages);

    final result = <Inspection>[];
    for (var i = 0; i < dtos.length; i += _batch) {
      final slice = dtos.sublist(i, (i + _batch).clamp(0, dtos.length));
      result.addAll(
        await Future.wait([
          for (final dto in slice) _build(dto, types, quiet: true),
        ]),
      );
    }
    return result;
  }, listing: true);

  @override
  Future<Inspection> get(String id) => _guard(() => _load(id));

  Future<Inspection> _load(String id) async {
    final types = await _loadTypes();
    final dto = _asMap(
      await _api.getJson('/api/inspections/${Uri.encodeComponent(id)}'),
    );
    return _build(dto, types);
  }

  Future<Inspection> _build(
    Map<String, dynamic> dto,
    List<_Type> types, {
    bool quiet = false,
  }) async {
    final id = _text(dto['id']);
    final typeCode = _text(dto['inspectionTypeCode']);
    final type = types.where((t) => t.code == typeCode).firstOrNull;
    var results = const <String, CheckResult>{};
    if (id != null) {
      try {
        final raw = await _api.getJson(
          '/api/inspections/${Uri.encodeComponent(id)}/results',
        );
        results = resultsFromJson(raw);
      } on ApiFailure {
        if (!quiet) rethrow;
      } on FormatException {
        if (!quiet) rethrow;
      }
    }
    return inspectionFromDto(
      dto,
      typeLabel: type?.label(language()) ?? typeCode ?? '',
      checklist: [
        for (final item in type?.items ?? const <ChecklistItem>[])
          item.withResult(results[item.id] ?? CheckResult.pending),
      ],
    );
  }

  @override
  Future<Inspection> saveAnswers(String id, Map<String, CheckResult> answers) =>
      _guard(() async {
        await _saveResults(id, answers);
        return _load(id);
      });

  Future<void> _saveResults(String id, Map<String, CheckResult> answers) async {
    final key = Uri.encodeComponent(id);
    final dto = _asMap(await _api.getJson('/api/inspections/$key'));
    final status = _text(dto['status']);
    // Contestar el checklist es trabajar en ella: una asignada pasa a en proceso.
    if (status == 'ASIGNADA') {
      await _status(key, 'EN_PROCESO', dto['rowVersion']);
    }
    await _api.put(
      '/api/inspections/$key/results',
      data: resultsToJson(answers),
    );
  }

  Future<void> _status(String key, String status, Object? rowVersion) async {
    await _api.post(
      '/api/inspections/$key/status',
      data: {'status': status, 'rowVersion': rowVersion},
    );
  }

  @override
  Future<Inspection> complete(String id, Map<String, CheckResult> answers) =>
      _guard(() async {
        if (answers.isEmpty || answers.values.contains(CheckResult.pending)) {
          throw const InspectionsException(InspectionsError.incomplete);
        }
        await _saveResults(id, answers);
        final key = Uri.encodeComponent(id);
        final dto = _asMap(await _api.getJson('/api/inspections/$key'));
        if (_text(dto['status']) == 'EN_PROCESO') {
          await _status(key, 'ATENDIDA', dto['rowVersion']);
        }
        return _load(id);
      });

  @override
  Future<List<InspectionTemplate>> templates() => _guard(() async {
    final types = await _loadTypes();
    return [
      for (final t in types)
        InspectionTemplate(type: t.label(language()), items: t.items),
    ];
  });

  @override
  Future<Inspection> create(NewInspection draft) => _guard(() async {
    final types = await _loadTypes();
    final type = types.where((t) => t.label(language()) == draft.type).firstOrNull ??
        types.where((t) => t.code == draft.type).firstOrNull;
    if (type == null) throw const InspectionsException(InspectionsError.server);
    final road = await roadId();
    final me = await userId();
    final km = parseKm(draft.kmLabel);
    final dto = await _api.post(
      '/api/inspections',
      data: {
        'inspectionTypeCode': type.code,
        'roadId': ?road,
        'kmStart': ?km,
        'direction': ?_directionCode(draft.direction),
        'inspectorUserId': ?me,
        if (draft.scheduledAt != null)
          'scheduledOn': _day(draft.scheduledAt!),
        'notes': draft.title.trim(),
        'clientUuid': newClientId(),
      },
    );
    final id = _text(dto?['id']);
    if (id == null) throw const FormatException('sin id');
    return _load(id);
  });

  @override
  Future<Inspection> addFinding(String id, InspectionFinding finding) =>
      _guard(() async {
        final key = Uri.encodeComponent(id);
        final types = await _loadTypes();
        final dto = _asMap(await _api.getJson('/api/inspections/$key'));
        final type = types
            .where((t) => t.code == _text(dto['inspectionTypeCode']))
            .firstOrNull;
        final item = type?.items.where((i) => i.id == finding.itemId).firstOrNull;
        final position = finding.position;
        final created = await _api.post(
          '/api/inspections/$key/findings',
          data: {
            'description': finding.note.trim().isEmpty
                ? (item?.text ?? _fallbackNote)
                : finding.note.trim(),
            // Un punto del checklist critico pide mas atencion.
            'severity': item?.critical == true ? 'ALTA' : 'MEDIA',
            'parameter': ?finding.itemId,
            if (position != null)
              'geometry': {
                'type': 'Point',
                'coordinates': [position.longitude, position.latitude],
              },
          },
        );
        final findingId = _text(created?['id']);
        if (findingId != null) {
          for (final photo in finding.photoPaths) {
            if (!File(photo).existsSync()) continue;
            await _api.postMultipart(
              '/api/inspections/$key/findings/$findingId/attachments',
              fileField: 'file',
              filePath: photo,
              fileName: photo.split(RegExp(r'[\\/]')).last,
              contentType: _imageType(photo),
              fields: {
                'kind': 'FOTO',
                'capturedAt': finding.capturedAt.toUtc().toIso8601String(),
                'latitude': position?.latitude,
                'longitude': position?.longitude,
                'clientUuid': newClientId(),
              },
            );
          }
        }
        return _load(id);
      });

  static const _fallbackNote = 'Hallazgo registrado desde la app movil.';

  Future<List<_Type>> _loadTypes() async {
    final cached = _types;
    if (cached != null) return cached;
    final raw = await _api.getJson('/api/inspection-types');
    final items = raw is List
        ? raw
        : (raw is Map ? raw['items'] : null) as List? ?? const [];
    return _types = [
      for (final t in items)
        if (t is Map<String, dynamic> && t['active'] != false) _Type.fromJson(t),
    ];
  }

  /// Pendiente y asignada es lo que aun no se empieza; atendida y en revision,
  /// lo que ya se hizo y espera la revision.
  static InspectionStatus statusFromCode(String? code) => switch (code) {
    'EN_PROCESO' => InspectionStatus.inProgress,
    'ATENDIDA' || 'EN_REVISION' => InspectionStatus.attended,
    'CERRADA' => InspectionStatus.closed,
    'CANCELADA' => InspectionStatus.cancelled,
    _ => InspectionStatus.pending,
  };

  /// Los resultados del servidor por parametro: conforme es bien, no conforme es
  /// hallazgo; lo no aplicable o sin resultado sigue pendiente.
  static Map<String, CheckResult> resultsFromJson(Object? raw) {
    final items = raw is List
        ? raw
        : (raw is Map ? raw['items'] : null) as List? ?? const [];
    return {
      for (final r in items)
        if (r is Map<String, dynamic> && _text(r['parameter']) != null)
          _text(r['parameter'])!: switch (_text(r['status'])) {
            'CONFORME' => CheckResult.ok,
            'NO_CONFORME' => CheckResult.finding,
            _ => CheckResult.pending,
          },
    };
  }

  /// Lo que se manda al guardar: solo lo contestado.
  static List<Map<String, Object?>> resultsToJson(
    Map<String, CheckResult> answers,
  ) => [
    for (final e in answers.entries)
      if (e.value != CheckResult.pending)
        {
          'parameter': e.key,
          'value': e.value == CheckResult.ok ? 'CONFORME' : 'NO_CONFORME',
          'status': e.value == CheckResult.ok ? 'CONFORME' : 'NO_CONFORME',
        },
  ];

  static Inspection inspectionFromDto(
    Map<String, dynamic> m, {
    required String typeLabel,
    required List<ChecklistItem> checklist,
  }) {
    final notes = _text(m['notes']);
    final title = notes?.split('\n').first.trim();
    final folio = _text(m['folio']);
    final km = _num(m['kmStart']);
    final direction = _text(m['direction']);
    return Inspection(
      id: _text(m['id']) ?? '',
      title: title == null || title.isEmpty
          ? [typeLabel, folio].where((s) => s != null && s.isNotEmpty).join(' · ')
          : title,
      type: typeLabel,
      status: statusFromCode(_text(m['status'])),
      checklist: checklist,
      scheduledAt: _date(m['scheduledOn']),
      completedAt: DateTime.tryParse(_text(m['executedAt']) ?? '')?.toUtc(),
      assignee: _text(m['inspectorName']),
      assetId: _text(m['assetId']),
      assetName: _text(m['assetCode']),
      kmLabel: kmLabel(km, _num(m['kmEnd'])),
      direction: direction == null
          ? null
          : direction[0].toUpperCase() + direction.substring(1).toLowerCase(),
    );
  }

  static String? _directionCode(String? d) => switch (d?.trim().toLowerCase()) {
    'creciente' || 'increasing' => 'CRECIENTE',
    'decreciente' || 'decreasing' => 'DECRECIENTE',
    _ => null,
  };

  static String _day(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-'
        '${u.month.toString().padLeft(2, '0')}-'
        '${u.day.toString().padLeft(2, '0')}';
  }

  static String _imageType(String path) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
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

  Future<T> _guard<T>(
    Future<T> Function() body, {
    bool listing = false,
  }) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw InspectionsException(
        e.isNetwork
            ? InspectionsError.network
            : switch (e.status) {
                403 => InspectionsError.permissionDenied,
                404 =>
                  listing
                      ? InspectionsError.notAvailable
                      : InspectionsError.notFound,
                409 => InspectionsError.notEditable,
                _ => InspectionsError.server,
              },
      );
    } on InspectionsException {
      rethrow;
    } catch (_) {
      throw const InspectionsException(InspectionsError.server);
    }
  }
}

/// Un tipo de inspeccion del servidor con su checklist.
class _Type {
  const _Type(this.code, this.labelEs, this.labelPt, this.items);

  factory _Type.fromJson(Map<String, dynamic> m) {
    final checklist = m['checklist'];
    return _Type(
      ApiInspectionsRepository._text(m['code']) ?? '',
      ApiInspectionsRepository._text(m['labelEs']) ?? '',
      ApiInspectionsRepository._text(m['labelPt']),
      [
        if (checklist is List)
          for (final i in checklist)
            if (i is Map<String, dynamic> &&
                ApiInspectionsRepository._text(i['key']) != null)
              ChecklistItem(
                id: ApiInspectionsRepository._text(i['key'])!,
                text:
                    ApiInspectionsRepository._text(i['label']) ??
                    ApiInspectionsRepository._text(i['key'])!,
                critical: i['critical'] == true,
              ),
      ],
    );
  }

  final String code;
  final String labelEs;
  final String? labelPt;
  final List<ChecklistItem> items;

  String label(String language) =>
      (language == 'pt' ? labelPt : null) ?? (labelEs.isEmpty ? code : labelEs);
}
