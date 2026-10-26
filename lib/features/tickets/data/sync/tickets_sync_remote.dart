import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/sync_engine.dart';
import '../../domain/entities/ticket.dart';
import '../repositories/api_tickets_repository.dart';
import '../repositories/offline_tickets_repository.dart';

/// Envia al servidor los tickets y seguimientos capturados sin conexion, por
/// `POST /api/sync/operations` (una operacion por envio):
///  - la clave de idempotencia de la operacion es la del ticket (`clientUuid`):
///    reenviar devuelve `DUPLICADA` con el mismo registro, no uno nuevo;
///  - el servidor aplica el permiso vigente de la persona: sin permiso, la
///    operacion queda rechazada y espera su decision;
///  - las fotos no viajan en el lote: se suben al ticket ya creado.
class TicketsSyncRemote implements SyncRemote {
  TicketsSyncRemote(this._api, this._tickets, this._deviceIdentifier);

  final ApiClient _api;
  final ApiTicketsRepository _tickets;

  /// El identificador con el que este telefono se registro (`/api/mobile/devices`).
  final Future<String?> Function() _deviceIdentifier;

  static const _applied = 'APLICADA';
  static const _duplicate = 'DUPLICADA';
  static const _rejected = 'RECHAZADA';
  static const _conflict = 'CONFLICTO';

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    final entity = operation.entity;
    if (operation.kind != OperationKind.insert ||
        (entity != OfflineTicketsRepository.ticketEntity &&
            entity != OfflineTicketsRepository.followUpEntity)) {
      return SyncRejected(
        'La app no sabe enviar «$entity» (${operation.kind.name})',
      );
    }
    final device = await _deviceIdentifier();
    if (device == null) {
      return const SyncRetryLater(
        'Este telefono todavia no se registra en el servidor',
      );
    }

    final payload = {
      for (final e in operation.payload.entries)
        if (!e.key.startsWith('_')) e.key: e.value,
    };
    final Map<String, dynamic>? result;
    try {
      result = await _api.post(
        '/api/sync/operations',
        data: {
          'deviceIdentifier': device,
          'operations': [
            {
              'idempotencyKey': operation.id,
              'entity': entity,
              'operation': 'INSERT',
              'payload': payload,
              'recordId': ?operation.recordId,
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
    if (row == null) {
      return const SyncRetryLater('El servidor no respondio la operacion');
    }
    final status = row['status'];
    if (status == _rejected) return SyncRejected(_errorText(row['error']));
    if (status == _conflict) {
      return SyncConflicted(message: _errorText(row['error']));
    }
    if (status != _applied && status != _duplicate) {
      return SyncRetryLater('Respuesta desconocida del servidor: $status');
    }

    final recordId = row['recordId'];
    try {
      await _afterApplied(operation, recordId is String ? recordId : null);
    } on ApiFailure catch (e) {
      // El registro ya esta en el servidor; lo que falta (fotos, estado) se
      // reintenta y el reenvio vuelve como DUPLICADA.
      final outcome = _failure(e);
      return outcome is SyncRejected
          ? SyncRetryLater(outcome.message)
          : outcome;
    }
    return SyncAccepted(
      duplicate: status == _duplicate,
      response: {'recordId': ?recordId},
    );
  }

  /// Las fotos y el estado que siguen a lo ya registrado.
  Future<void> _afterApplied(PendingOperation op, String? recordId) async {
    final photos = [
      for (final p
          in (op.payload[OfflineTicketsRepository.photosKey] as List?) ??
              const [])
        if (p is String) p,
    ];
    final at = DateTime.tryParse(
      '${op.payload[OfflineTicketsRepository.atKey] ?? ''}',
    );
    if (op.entity == OfflineTicketsRepository.ticketEntity) {
      if (recordId == null || photos.isEmpty) return;
      final lat = op.payload[OfflineTicketsRepository.latKey];
      final lng = op.payload[OfflineTicketsRepository.lngKey];
      await _tickets.attachPhotos(
        recordId,
        photos,
        capturedAt: at ?? op.capturedAt,
        location: lat is num && lng is num
            ? TicketLocation(
                latitude: lat.toDouble(),
                longitude: lng.toDouble(),
                origin: TicketLocationOrigin.gps,
              )
            : null,
      );
      return;
    }
    final ticketId = op.recordId;
    if (ticketId == null) return;
    await _tickets.finishFollowUp(
      ticketId,
      recordId,
      photos: photos,
      at: at ?? op.capturedAt,
      attended: op.payload[OfflineTicketsRepository.attendedKey] == true,
    );
  }

  SyncOutcome _failure(ApiFailure e) {
    if (e.isNetwork) return SyncRetryLater(e.message ?? 'Sin conexion');
    final status = e.status ?? 0;
    if (status == 401) return const SyncSessionLost();
    if (status == 429 || status >= 500) {
      return SyncRetryLater(e.message ?? 'Error del servidor ($status)');
    }
    // El telefono aun no esta registrado o esta bloqueado: se vuelve a intentar
    // cuando el registro lo resuelva.
    final code = (e.code ?? '').toUpperCase();
    if (code.contains('DEVICE')) {
      return SyncRetryLater(e.message ?? 'Telefono no registrado');
    }
    return SyncRejected(e.message ?? e.code ?? 'Rechazado ($status)');
  }

  static String _errorText(Object? error) {
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
      final code = error['code'];
      if (code is String && code.isNotEmpty) return code;
    }
    return 'El servidor rechazo la operacion';
  }
}
