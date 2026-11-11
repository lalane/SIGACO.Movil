import 'dart:io';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/inspection_capture.dart';
import '../../domain/repositories/inspection_capture_repository.dart';
import '../../domain/repositories/inspections_repository.dart';
import 'api_inspections_repository.dart';

/// La captura contra el servidor (`/api/inspections/{id}/capture`, `answers`,
/// `finalize`, `evidence`, `findings`). Lo leido se guarda en el cache del
/// telefono, asi que sin red la ficha se sigue viendo.
class ApiInspectionCaptureRepository implements InspectionCaptureRepository {
  ApiInspectionCaptureRepository(this._api, {this.language = _spanish});

  final ApiClient _api;
  final String Function() language;

  static String _spanish() => 'es';

  @override
  bool get available => true;

  String _key(String id) => Uri.encodeComponent(id);

  @override
  Future<InspectionCaptureView> capture(String id) => guard(
    () async => fromJson(
      _map(await _api.getJson('/api/inspections/${_key(id)}/capture')),
    ),
  );

  @override
  Future<InspectionCaptureView> start(String id, int rowVersion) =>
      guard(() async {
        await _api.post(
          '/api/inspections/${_key(id)}/start',
          data: {'rowVersion': rowVersion},
        );
        return capture(id);
      });

  @override
  Future<InspectionCaptureView> save(
    InspectionCaptureView view,
    Map<String, dynamic> answers,
  ) => guard(() async {
    final saved = await _api.put(
      '/api/inspections/${_key(view.id)}/answers',
      data: {'answers': answers, 'rowVersion': view.rowVersion},
    );
    return saved == null ? capture(view.id) : fromJson(saved);
  });

  @override
  Future<InspectionCaptureView> finalize(
    InspectionCaptureView view, {
    FindingPosition? position,
    String? justification,
    required DateTime executedAt,
  }) => guard(() async {
    final done = await _api.post(
      '/api/inspections/${_key(view.id)}/finalize',
      data: finalizeBody(position, justification, executedAt, view.rowVersion),
    );
    return done == null ? capture(view.id) : fromJson(done);
  });

  /// Lo que manda el telefono al finalizar: posicion, justificacion y la hora de captura.
  static Map<String, Object?> finalizeBody(
    FindingPosition? position,
    String? justification,
    DateTime executedAt,
    int? rowVersion,
  ) => {
    'latitude': position?.latitude,
    'longitude': position?.longitude,
    if (justification != null && justification.trim().isNotEmpty)
      'locationJustification': justification.trim(),
    'executedAt': executedAt.toUtc().toIso8601String(),
    'rowVersion': ?rowVersion,
  };

  @override
  Future<InspectionCaptureView> addPhoto(
    InspectionCaptureView view,
    String path, {
    String? fieldKey,
    FindingPosition? position,
    required DateTime capturedAt,
  }) => guard(() async {
    await uploadEvidence(
      view.id,
      path,
      fieldKey: fieldKey,
      position: position,
      capturedAt: capturedAt,
      clientUuid: newClientId(),
    );
    return capture(view.id);
  });

  /// Sube una evidencia de la inspeccion (reenviar con el mismo [clientUuid] no la duplica).
  Future<void> uploadEvidence(
    String id,
    String path, {
    String? fieldKey,
    FindingPosition? position,
    required DateTime capturedAt,
    required String clientUuid,
  }) async {
    if (!File(path).existsSync()) return;
    await _api.postMultipart(
      '/api/inspections/${_key(id)}/evidence',
      fileField: 'file',
      filePath: path,
      fileName: path.split(RegExp(r'[\\/]')).last,
      contentType: _imageType(path),
      fields: {
        'kind': 'FOTO',
        'fieldKey': ?fieldKey,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'clientUuid': clientUuid,
      },
    );
  }

  @override
  Future<InspectionCaptureView> addFinding(
    InspectionCaptureView view, {
    required String description,
    String? failureCode,
    String? severity,
    String? parameter,
    List<String> photoPaths = const [],
    FindingPosition? position,
    required DateTime capturedAt,
  }) => guard(() async {
    final created = await _api.post(
      '/api/inspections/${_key(view.id)}/findings',
      data: findingBody(
        description: description,
        failureCode: failureCode,
        severity: severity,
        parameter: parameter,
        position: position,
        clientUuid: newClientId(),
      ),
    );
    final findingId = created?['id'];
    if (findingId is String) {
      await uploadFindingPhotos(
        view.id,
        findingId,
        photoPaths,
        position: position,
        capturedAt: capturedAt,
      );
    }
    return capture(view.id);
  });

  static Map<String, Object?> findingBody({
    required String description,
    String? failureCode,
    String? severity,
    String? parameter,
    FindingPosition? position,
    required String clientUuid,
  }) => {
    'description': description.trim(),
    'failureTypeCode': ?failureCode,
    'severity': ?severity,
    'parameter': ?parameter,
    if (position != null)
      'geometry': {
        'type': 'Point',
        'coordinates': [position.longitude, position.latitude],
      },
    'clientUuid': clientUuid,
  };

  Future<void> uploadFindingPhotos(
    String inspectionId,
    String findingId,
    List<String> photos, {
    FindingPosition? position,
    required DateTime capturedAt,
  }) async {
    for (final photo in photos) {
      if (!File(photo).existsSync()) continue;
      await _api.postMultipart(
        '/api/inspections/${_key(inspectionId)}/findings/${_key(findingId)}/attachments',
        fileField: 'file',
        filePath: photo,
        fileName: photo.split(RegExp(r'[\\/]')).last,
        contentType: _imageType(photo),
        fields: {
          'kind': 'FOTO',
          'capturedAt': capturedAt.toUtc().toIso8601String(),
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          // La misma foto del mismo hallazgo no se duplica al reintentar.
          'clientUuid': stableUuid('$findingId|$photo'),
        },
      );
    }
  }

  @override
  Future<List<FailureChoice>> failures(String typeId) => guard(() async {
    final raw = await _api.getJson(
      '/api/inspection-types/${_key(typeId)}/failures',
    );
    return [
      for (final f in raw is List ? raw : const [])
        if (f is Map<String, dynamic>)
          FailureChoice(
            code: '${f['code']}',
            label: '${f['labelEs'] ?? f['code']}',
            classification: f['classification'] as String?,
            attentionLabel: f['attentionLabel'] as String?,
            immediate: f['immediate'] == true,
          ),
    ];
  });

  @override
  Future<InspectionCaptureView> accept(InspectionCaptureView view) =>
      guard(() async {
        await _api.post(
          '/api/inspections/${_key(view.id)}/accept',
          data: {'rowVersion': view.rowVersion},
        );
        return capture(view.id);
      });

  @override
  Future<InspectionCaptureView> reject(
    InspectionCaptureView view,
    String reason,
  ) => guard(() async {
    await _api.post(
      '/api/inspections/${_key(view.id)}/reject',
      data: {'rowVersion': view.rowVersion, 'reason': reason.trim()},
    );
    return capture(view.id);
  });

  /// La vista de captura a partir de `InspectionCaptureDto`.
  static InspectionCaptureView fromJson(Map<String, dynamic> m) {
    final i = _map(m['inspection']);
    final previous = m['previous'];
    return InspectionCaptureView(
      id: '${i['id']}',
      folio: '${i['folio'] ?? ''}',
      status: ApiInspectionsRepository.statusFromCode(i['status'] as String?),
      serverStatus: '${i['status'] ?? ''}',
      typeId: '${i['inspectionTypeId'] ?? ''}',
      typeLabel: '${i['inspectionTypeLabel'] ?? i['inspectionTypeCode'] ?? ''}',
      template: TemplateDefinition.fromJson(m['template']),
      answers: m['answers'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(m['answers'] as Map)
          : <String, dynamic>{},
      rowVersion: (i['rowVersion'] as num?)?.toInt() ?? 0,
      assetId: i['assetId'] as String?,
      assetCode: i['assetCode'] as String?,
      kmLabel: kmLabel(
        (i['kmStart'] as num?)?.toDouble(),
        (i['kmEnd'] as num?)?.toDouble(),
      ),
      reason: i['reason'] as String?,
      previousAnswers:
          previous is Map && previous['answers'] is Map<String, dynamic>
          ? previous['answers'] as Map<String, dynamic>
          : const {},
      evidences: [
        for (final e in (m['evidences'] as List?) ?? const [])
          if (e is Map<String, dynamic> &&
              e['attachment'] is Map<String, dynamic>)
            CaptureEvidence(
              id: '${(e['attachment'] as Map)['id']}',
              fileName: '${(e['attachment'] as Map)['fileName']}',
              fieldKey: e['fieldKey'] as String?,
              latitude: ((e['attachment'] as Map)['latitude'] as num?)
                  ?.toDouble(),
              longitude: ((e['attachment'] as Map)['longitude'] as num?)
                  ?.toDouble(),
              capturedAt: DateTime.tryParse(
                '${(e['attachment'] as Map)['capturedAt']}',
              )?.toUtc(),
            ),
      ],
      findings: [
        for (final f in (m['findings'] as List?) ?? const [])
          if (f is Map<String, dynamic>)
            CaptureFinding(
              id: '${f['id']}',
              description: '${f['description'] ?? ''}',
              severity: '${f['severity'] ?? ''}',
              status: '${f['status'] ?? ''}',
              failureCode: f['failureTypeCode'] as String?,
              ticketId: f['ticketId'] as String?,
            ),
      ],
      missing: [
        for (final x in (m['missing'] as List?) ?? const [])
          if (x is Map<String, dynamic>)
            CaptureIssue('${x['path']}', '${x['message']}'),
      ],
      computedCondition: m['computedCondition'] as String?,
      computedNative: m['computedNativeCondition'] as String?,
      actions: CaptureActions.fromJson(m['actions']),
      templateVersion: (m['templateVersionNumber'] as num?)?.toInt(),
      requiresReview: m['requiresReview'] != false,
      toleranceMeters: (m['locationToleranceMeters'] as num?)?.toInt(),
      correctionReason: i['correctionReason'] as String?,
    );
  }

  /// Un UUID que sale siempre igual de [seed] (FNV-1a): reintentar la misma
  /// foto del mismo registro manda la misma clave y el servidor no la duplica.
  static String stableUuid(String seed) {
    final bytes = <int>[];
    var h1 = 0x4bf29ce484222325;
    var h2 = 0x04222325cbf29ce4;
    for (final c in seed.codeUnits) {
      h1 = ((h1 ^ c) * 0x100000001b3) & 0x7fffffffffffffff;
      h2 = ((h2 ^ (c + 7)) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    for (final h in [h1, h2]) {
      for (var i = 0; i < 8; i++) {
        bytes.add((h >> (i * 8)) & 0xff);
      }
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int from, int to) => [
      for (var i = from; i < to; i++)
        bytes[i].toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  static String _imageType(String path) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  /// Los fallos del servidor como [InspectionsException]; los campos que faltan, con su ruta.
  static Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      if (e.status == 400 && e.fieldErrors.isNotEmpty) {
        throw InspectionIncompleteException([
          for (final entry in e.fieldErrors.entries)
            for (final message in entry.value) CaptureIssue(entry.key, message),
        ]);
      }
      throw InspectionsException(
        e.isNetwork
            ? InspectionsError.network
            : switch (e.status) {
                403 => InspectionsError.permissionDenied,
                404 => InspectionsError.notFound,
                409 => InspectionsError.notEditable,
                _ => InspectionsError.server,
              },
      );
    } on InspectionsException {
      rethrow;
    } on FormatException {
      throw const InspectionsException(InspectionsError.server);
    }
  }
}
