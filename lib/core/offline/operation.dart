import 'package:equatable/equatable.dart';

/// Que hace una operacion sobre un registro (igual que `sync.operacion.operacion`).
enum OperationKind { insert, update, delete }

/// Ciclo de una operacion capturada en el telefono (HU-TR-MOB-02 a 04):
///  - `pending`: en la cola, esperando conexion o su turno;
///  - `sending`: se esta enviando;
///  - `accepted`: el servidor la aplico (o reconocio que ya la tenia);
///  - `rejected`: el servidor la rechazo con un motivo; no se reintenta sola;
///  - `conflict`: el registro cambio en el servidor mientras no habia red; se
///    resuelve a mano y nunca se aplica en silencio.
enum OperationStatus { pending, sending, accepted, rejected, conflict }

/// De quien es lo guardado en el telefono: una persona en una concesion. Las
/// operaciones y todo lo local se consultan siempre con este alcance (RN-CTX-02,
/// HU-TR-02): otra persona o otra concesion nunca ve ni envia lo ajeno.
class OfflineScope extends Equatable {
  const OfflineScope({required this.userId, required this.concessionId});

  final String userId;
  final String concessionId;

  @override
  List<Object?> get props => [userId, concessionId];

  @override
  String toString() => 'OfflineScope($userId, $concessionId)';
}

/// Una operacion capturada sin conexion que espera enviarse al servidor.
class PendingOperation extends Equatable {
  const PendingOperation({
    required this.id,
    required this.scope,
    required this.entity,
    required this.kind,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.capturedAt,
    required this.updatedAt,
    this.recordId,
    this.baseVersion,
    this.attempts = 0,
    this.lastError,
    this.response,
    this.nextAttemptAt,
  });

  /// Clave de idempotencia (UUID): identifica a la operacion para siempre. Si la
  /// app reenvia lo mismo, el servidor devuelve el resultado anterior.
  final String id;
  final OfflineScope scope;

  /// Tipo de registro (`documento`, `documento_firma`...), como lo nombra la
  /// base en `sync.operacion.entidad`.
  final String entity;
  final OperationKind kind;

  /// Registro que se cambia; obligatorio en `update` y `delete`.
  final String? recordId;

  /// Version del registro que tenia el telefono al capturar; obligatoria en
  /// `update` y `delete`. Si el servidor ya esta en otra, hay conflicto.
  final int? baseVersion;
  final Map<String, Object?> payload;
  final OperationStatus status;
  final int attempts;
  final String? lastError;

  /// Respuesta del servidor cuando la acepto.
  final Map<String, Object?>? response;

  /// UTC. Cuando entro a la cola.
  final DateTime createdAt;

  /// UTC. Cuando el usuario hizo la captura (puede ser mucho antes del envio).
  final DateTime capturedAt;
  final DateTime updatedAt;

  /// UTC. No se reintenta antes de esta hora (espera entre reintentos).
  final DateTime? nextAttemptAt;

  bool get isOpen =>
      status == OperationStatus.pending || status == OperationStatus.sending;

  /// Falta algo que hacer con ella: esperar, o que el usuario decida.
  bool get needsAttention =>
      status == OperationStatus.rejected || status == OperationStatus.conflict;

  @override
  List<Object?> get props => [
    id,
    scope,
    entity,
    kind,
    recordId,
    baseVersion,
    payload,
    status,
    attempts,
    lastError,
    response,
    createdAt,
    capturedAt,
    updatedAt,
    nextAttemptAt,
  ];
}

/// Que se hizo con un conflicto.
enum ConflictResolution {
  /// Se descarto lo capturado en el telefono y se quedo lo del servidor.
  discarded,

  /// Se volvio a mandar sobre la version actual del servidor.
  retried,
}

/// El registro cambio en el servidor mientras la operacion esperaba. Guarda
/// ambas versiones para que la persona decida (HU-TR-MOB-04).
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.operationId,
    required this.createdAt,
    this.localVersion,
    this.serverVersion,
    this.serverPayload,
    this.message,
    this.resolution,
    this.resolvedAt,
  });

  final String operationId;

  /// Version sobre la que se hizo la captura en el telefono.
  final int? localVersion;

  /// Version que tiene el servidor ahora.
  final int? serverVersion;
  final Map<String, Object?>? serverPayload;

  /// Motivo que dio el servidor, si lo dio.
  final String? message;
  final DateTime createdAt;
  final ConflictResolution? resolution;
  final DateTime? resolvedAt;

  bool get isOpen => resolution == null;

  @override
  List<Object?> get props => [
    operationId,
    localVersion,
    serverVersion,
    serverPayload,
    message,
    createdAt,
    resolution,
    resolvedAt,
  ];
}
