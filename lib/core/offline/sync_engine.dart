import 'dart:async';

import 'operation.dart';
import 'operation_queue.dart';

/// Lo que respondio el servidor a una operacion (HU-TR-MOB-03 y 04).
sealed class SyncOutcome {
  const SyncOutcome();
}

/// Aplicada. [duplicate] indica que el servidor ya la tenia (la clave de
/// idempotencia coincide) y devolvio el resultado anterior.
class SyncAccepted extends SyncOutcome {
  const SyncAccepted({this.response, this.duplicate = false});

  final Map<String, Object?>? response;
  final bool duplicate;
}

/// El servidor la rechazo por una regla (permiso, validacion, hash...). No se
/// reintenta sola.
class SyncRejected extends SyncOutcome {
  const SyncRejected(this.message, {this.code});

  final String message;
  final String? code;
}

/// El registro cambio en el servidor mientras la operacion esperaba. Nunca se
/// aplica en silencio.
class SyncConflicted extends SyncOutcome {
  const SyncConflicted({this.serverVersion, this.serverPayload, this.message});

  final int? serverVersion;
  final Map<String, Object?>? serverPayload;
  final String? message;
}

/// Sin red o error pasajero del servidor: se vuelve a intentar mas tarde.
class SyncRetryLater extends SyncOutcome {
  const SyncRetryLater(this.message, {this.retryAfter});

  final String message;

  /// Espera que pidio el servidor (`Retry-After`); si no, la de la app.
  final Duration? retryAfter;
}

/// La sesion ya no vale (token vencido, cuenta bloqueada): no se envia mas; lo
/// pendiente espera a que la persona vuelva a entrar.
class SyncSessionLost extends SyncOutcome {
  const SyncSessionLost();
}

/// Envia una operacion al servidor. Es lo unico que cambia entre entidades: la
/// ruta y la forma de cada tipo de registro (documento, firma...).
abstract interface class SyncRemote {
  Future<SyncOutcome> send(PendingOperation operation);
}

/// Antes de enviar se revalida la sesion y los permisos (DEV-MOB-094).
enum SyncGate {
  /// La sesion y los permisos siguen vigentes: se puede enviar.
  proceed,

  /// No se envia nada ahora; lo pendiente se conserva.
  hold,
}

typedef SyncPreflight = Future<SyncGate> Function(OfflineScope scope);

/// Espera entre reintentos de una operacion: 5 s, 10 s, 20 s... hasta 15 min.
Duration defaultBackoff(int attempts) {
  final n = attempts < 1 ? 1 : attempts;
  final seconds = 5 * (1 << (n > 8 ? 8 : n - 1));
  final capped = seconds > 15 * 60 ? 15 * 60 : seconds;
  return Duration(seconds: capped);
}

/// Resultado de una pasada de sincronizacion.
class SyncReport {
  const SyncReport({
    this.accepted = 0,
    this.rejected = 0,
    this.conflicts = 0,
    this.retried = 0,
    this.skipped = 0,
    this.held = false,
    this.sessionLost = false,
    this.networkFailed = false,
  });

  /// Aplicadas por el servidor (incluye las que ya tenia).
  final int accepted;

  /// Rechazadas: esperan una decision de la persona.
  final int rejected;

  /// En conflicto: esperan una decision de la persona.
  final int conflicts;

  /// Que fallaron por red o error pasajero y volvieron a la cola.
  final int retried;

  /// Que no se intentaron: esperan su turno, su hora de reintento, o dependen de
  /// otra operacion sobre el mismo registro que quedo sin resolver.
  final int skipped;

  /// La revalidacion previa pidio no enviar.
  final bool held;
  final bool sessionLost;
  final bool networkFailed;

  /// Termino sin problemas de red ni de sesion (lo que haya quedado esperando
  /// es por reglas, no por falta de conexion).
  bool get completed => !held && !sessionLost && !networkFailed;

  bool get changedAnything =>
      accepted > 0 || rejected > 0 || conflicts > 0 || retried > 0;

  @override
  String toString() =>
      'SyncReport(aceptadas: $accepted, rechazadas: $rejected, '
      'conflictos: $conflicts, reintentos: $retried, omitidas: $skipped, '
      'retenida: $held, sesion: $sessionLost, red: $networkFailed)';
}

/// Envia la cola local al servidor (DEV-MOB-064).
///
///  - Una pasada a la vez por persona y concesion.
///  - En el orden en que se capturaron. Si una operacion queda rechazada, en
///    conflicto o esperando un reintento, las siguientes sobre el mismo registro
///    esperan, para no aplicar cambios fuera de orden.
///  - Cada operacion viaja con su clave de idempotencia: reenviar no duplica.
///  - Un fallo de red detiene la pasada y deja lo demas en la cola, con espera
///    creciente antes de reintentar.
class SyncEngine {
  SyncEngine(
    this._queue,
    this._remote, {
    this.preflight,
    DateTime Function()? clock,
    Duration Function(int attempts)? backoff,
  }) : _now = clock ?? DateTime.now,
       _backoff = backoff ?? defaultBackoff;

  final OperationQueue _queue;
  final SyncRemote _remote;
  final SyncPreflight? preflight;
  final DateTime Function() _now;
  final Duration Function(int attempts) _backoff;

  final _running = <OfflineScope, Future<SyncReport>>{};

  bool isRunning(OfflineScope scope) => _running.containsKey(scope);

  /// Sincroniza lo pendiente de [scope]. Si ya hay una pasada en curso para ese
  /// alcance, devuelve esa misma.
  Future<SyncReport> run(OfflineScope scope) {
    return _running.putIfAbsent(scope, () {
      return _run(scope).whenComplete(() {
        _running.remove(scope);
      });
    });
  }

  Future<SyncReport> _run(OfflineScope scope) async {
    final gate = await preflight?.call(scope) ?? SyncGate.proceed;
    if (gate == SyncGate.hold) return const SyncReport(held: true);

    var accepted = 0, rejected = 0, conflicts = 0, retried = 0, skipped = 0;
    var sessionLost = false, networkFailed = false;

    // Registros con algo sin resolver: lo que sigue sobre ellos espera.
    final blocked = <String>{
      for (final op in await _queue.list(
        scope,
        statuses: {OperationStatus.rejected, OperationStatus.conflict},
      ))
        if (op.recordId != null) _recordKey(op),
    };

    final now = _now();
    final pending = await _queue.list(
      scope,
      statuses: {OperationStatus.pending},
    );
    for (final op in pending) {
      final key = op.recordId == null ? null : _recordKey(op);
      if (key != null && blocked.contains(key)) {
        skipped++;
        continue;
      }
      final waiting =
          op.nextAttemptAt != null && op.nextAttemptAt!.isAfter(now);
      if (waiting) {
        if (key != null) blocked.add(key);
        skipped++;
        continue;
      }

      await _queue.markSending(op.id);
      SyncOutcome outcome;
      try {
        outcome = await _remote.send(op);
      } catch (e) {
        outcome = SyncRetryLater('$e');
      }

      switch (outcome) {
        case SyncAccepted(:final response):
          await _queue.markAccepted(op.id, response: response);
          accepted++;
        case SyncRejected(:final message):
          await _queue.markRejected(op.id, error: message);
          if (key != null) blocked.add(key);
          rejected++;
        case SyncConflicted(
          :final serverVersion,
          :final serverPayload,
          :final message,
        ):
          await _queue.markConflict(
            op.id,
            serverVersion: serverVersion,
            serverPayload: serverPayload,
            message: message,
          );
          if (key != null) blocked.add(key);
          conflicts++;
        case SyncRetryLater(:final message, :final retryAfter):
          final attempts = op.attempts + 1;
          await _queue.markRetry(
            op.id,
            error: message,
            backoff: retryAfter ?? _backoff(attempts),
          );
          retried++;
          networkFailed = true;
        case SyncSessionLost():
          await _queue.markRetry(op.id, error: 'sesion vencida');
          sessionLost = true;
      }
      if (networkFailed || sessionLost) {
        skipped += pending.length - pending.indexOf(op) - 1;
        break;
      }
    }

    final report = SyncReport(
      accepted: accepted,
      rejected: rejected,
      conflicts: conflicts,
      retried: retried,
      skipped: skipped,
      sessionLost: sessionLost,
      networkFailed: networkFailed,
    );
    if (report.completed) await _queue.setLastSync(scope, _now());
    return report;
  }

  static String _recordKey(PendingOperation op) =>
      '${op.entity}/${op.recordId}';
}
