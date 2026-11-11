import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/offline/api_sync_remote.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/sync_engine.dart';
import '../../domain/entities/inspection.dart';
import '../repositories/api_inspection_capture_repository.dart';
import '../repositories/offline_inspection_capture_repository.dart';

/// Envia al servidor lo capturado sin conexion en Monitoreo (ver
/// [OfflineInspectionCaptureRepository]):
///  - la captura (UPDATE de INSPECTION): primero suben sus fotos (cada una con
///    su clave: reenviar no duplica) y despues las respuestas y, si se
///    finalizo, la finalizacion con la hora y posicion del telefono; si la
///    inspeccion cambio en el servidor, queda en conflicto con las dos
///    versiones;
///  - los hallazgos (INSERT de INSPECTION_FINDING): el registro y luego sus
///    fotos, ya con el id que le dio el servidor.
class InspectionsSyncRemote implements SyncRemote {
  InspectionsSyncRemote(this._api, this._device, this._capture)
    : _findings = _FindingsSyncRemote(_api, _device, _capture);

  final ApiClient _api;
  final Future<String?> Function() _device;
  final ApiInspectionCaptureRepository _capture;
  final _FindingsSyncRemote _findings;

  @override
  Future<SyncOutcome> send(PendingOperation operation) {
    if (operation.entity ==
            OfflineInspectionCaptureRepository.inspectionEntity &&
        operation.kind == OperationKind.update) {
      return _sendCapture(operation);
    }
    return _findings.send(operation);
  }

  Future<SyncOutcome> _sendCapture(PendingOperation operation) async {
    final id = operation.recordId;
    if (id == null) {
      return const SyncRejected('La captura no dice de que inspeccion es');
    }
    final device = await _device();
    if (device == null) {
      return const SyncRetryLater(
        'Este telefono todavia no se registra en el servidor',
      );
    }

    // Las fotos antes que la captura: finalizar valida las obligatorias.
    for (final p
        in (operation.payload[OfflineInspectionCaptureRepository.photosKey]
                as List?) ??
            const []) {
      if (p is! Map) continue;
      final lat = p['latitude'];
      final lng = p['longitude'];
      try {
        await _capture.uploadEvidence(
          id,
          '${p['path']}',
          fieldKey: p['fieldKey'] as String?,
          position: lat is num && lng is num
              ? FindingPosition(
                  latitude: lat.toDouble(),
                  longitude: lng.toDouble(),
                  accuracyMeters: 0,
                )
              : null,
          capturedAt:
              DateTime.tryParse('${p['capturedAt']}') ?? operation.capturedAt,
          clientUuid: '${p['clientUuid']}',
        );
      } on ApiFailure catch (e) {
        return _failure(e);
      }
    }

    final Map<String, dynamic>? result;
    try {
      result = await _api.post(
        '/api/sync/operations',
        data: {
          'deviceIdentifier': device,
          'operations': [
            {
              'idempotencyKey': operation.id,
              'entity': operation.entity,
              'operation': 'UPDATE',
              'recordId': id,
              'baseVersion': operation.baseVersion,
              'payload': {
                for (final e in operation.payload.entries)
                  if (!e.key.startsWith('_')) e.key: e.value,
              },
              'capturedAt': operation.capturedAt.toUtc().toIso8601String(),
              'deviceClock': DateTime.now().toUtc().toIso8601String(),
            },
          ],
        },
      );
    } on ApiFailure catch (e) {
      return _failure(e);
    }
    final rows = result?['operations'];
    final row = rows is List && rows.isNotEmpty && rows.first is Map
        ? (rows.first as Map).cast<String, Object?>()
        : null;
    return switch (row?['status']) {
      'APLICADA' || 'DUPLICADA' => SyncAccepted(
        duplicate: row?['status'] == 'DUPLICADA',
        response: {'recordId': id},
      ),
      'CONFLICTO' => SyncConflicted(
        message:
            _message(row?['result']) ?? 'La inspeccion cambio en el servidor',
      ),
      'RECHAZADA' => SyncRejected(
        _message(row?['error']) ?? 'El servidor rechazo la captura',
      ),
      _ => const SyncRetryLater('El servidor no respondio la operacion'),
    };
  }

  static String? _message(Object? error) {
    if (error is Map) {
      final fields = error['fields'];
      if (fields is Map && fields.isNotEmpty) {
        return fields.values.expand((v) => v is List ? v : [v]).join(' ');
      }
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }

  static SyncOutcome _failure(ApiFailure e) {
    if (e.isNetwork) return SyncRetryLater(e.message ?? 'Sin conexion');
    final status = e.status ?? 0;
    if (status == 401) return const SyncSessionLost();
    if (status == 429 || status >= 500) {
      return SyncRetryLater(e.message ?? 'Error del servidor ($status)');
    }
    if ((e.code ?? '').toUpperCase().contains('DEVICE')) {
      return SyncRetryLater(e.message ?? 'Telefono no registrado');
    }
    return SyncRejected(e.message ?? e.code ?? 'Rechazado ($status)');
  }
}

/// Los hallazgos (INSERT de INSPECTION_FINDING) van por el envio comun; sus
/// fotos suben despues, con el id que dio el servidor.
class _FindingsSyncRemote extends ApiSyncRemote {
  _FindingsSyncRemote(super.api, super.deviceIdentifier, this._capture);

  final ApiInspectionCaptureRepository _capture;

  @override
  Set<String> get entities => const {
    OfflineInspectionCaptureRepository.findingEntity,
  };

  @override
  Future<void> afterApplied(
    PendingOperation operation,
    String? recordId,
  ) async {
    final inspectionId = operation.recordId;
    final photos = [
      for (final p
          in (operation.payload[OfflineInspectionCaptureRepository.photosKey]
                  as List?) ??
              const [])
        if (p is String) p,
    ];
    if (inspectionId == null || recordId == null || photos.isEmpty) return;
    final lat = operation.payload[OfflineInspectionCaptureRepository.latKey];
    final lng = operation.payload[OfflineInspectionCaptureRepository.lngKey];
    await _capture.uploadFindingPhotos(
      inspectionId,
      recordId,
      photos,
      position: lat is num && lng is num
          ? FindingPosition(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              accuracyMeters: 0,
            )
          : null,
      capturedAt:
          DateTime.tryParse(
            '${operation.payload[OfflineInspectionCaptureRepository.atKey]}',
          ) ??
          operation.capturedAt,
    );
  }
}
