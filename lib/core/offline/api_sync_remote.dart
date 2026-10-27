import '../api/api_client.dart';
import '../api/api_failure.dart';
import 'operation.dart';
import 'sync_engine.dart';

/// Envia al servidor las altas capturadas sin conexion por
/// `POST /api/sync/operations` (una operacion por envio):
///  - la clave de idempotencia de la operacion es la del registro
///    (`clientUuid`): reenviar devuelve `DUPLICADA` con el mismo registro, no
///    uno nuevo;
///  - el servidor aplica el permiso vigente de la persona: sin permiso, la
///    operacion queda rechazada y espera su decision;
///  - lo que no viaja en el lote (por ejemplo las fotos) lo hace [afterApplied]
///    cuando el registro ya esta en el servidor.
///
/// Cada modulo hereda esta clase, dice que tipos de registro atiende
/// ([entities], con el nombre que les da el servidor) y, si hace falta, lo que
/// sigue a un alta aceptada.
abstract class ApiSyncRemote implements SyncRemote {
  ApiSyncRemote(this._api, this._deviceIdentifier);

  final ApiClient _api;

  /// El identificador con el que este telefono se registro (`/api/mobile/devices`).
  final Future<String?> Function() _deviceIdentifier;

  static const _applied = 'APLICADA';
  static const _duplicate = 'DUPLICADA';
  static const _rejected = 'RECHAZADA';
  static const _conflict = 'CONFLICTO';

  /// Los tipos de registro que este cliente sabe enviar.
  Set<String> get entities;

  /// Lo que falta tras un alta aceptada. Si lanza [ApiFailure], el registro ya
  /// esta en el servidor: se reintenta y el reenvio vuelve como `DUPLICADA`.
  Future<void> afterApplied(
    PendingOperation operation,
    String? recordId,
  ) async {}

  /// Lo que se manda como `payload`: sin los datos propios de la app, que
  /// empiezan con guion bajo.
  Map<String, Object?> serverPayload(PendingOperation operation) => {
    for (final e in operation.payload.entries)
      if (!e.key.startsWith('_')) e.key: e.value,
  };

  @override
  Future<SyncOutcome> send(PendingOperation operation) async {
    final entity = operation.entity;
    if (operation.kind != OperationKind.insert || !entities.contains(entity)) {
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
              'payload': serverPayload(operation),
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
      await afterApplied(operation, recordId is String ? recordId : null);
    } on ApiFailure catch (e) {
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
