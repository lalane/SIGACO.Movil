import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'offline_database.dart';
import 'operation.dart';
import 'uuid.dart';

/// Cola local de operaciones capturadas sin conexion (DEV-MOB-062).
///
/// Cada operacion lleva su clave de idempotencia (UUID): si la app reenvia lo
/// mismo, el servidor devuelve el resultado anterior y no duplica. Todo se
/// consulta con el alcance persona + concesion (`OfflineScope`).
class OperationQueue {
  OperationQueue(this._offline, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final OfflineDatabase _offline;
  final DateTime Function() _now;
  final _changes = StreamController<void>.broadcast();

  Database get _db => _offline.db;

  /// Avisa cada vez que algo cambia en la cola (para el indicador y las pantallas).
  Stream<void> get changes => _changes.stream;

  Future<void> dispose() => _changes.close();

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _at(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true);

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Agrega una operacion a la cola y la deja pendiente.
  ///
  /// [key] es la clave de idempotencia; si ya existe una operacion con esa
  /// clave en el mismo alcance se devuelve la existente sin duplicarla (la
  /// captura no se encola dos veces). `update` y `delete` exigen [recordId] y
  /// [baseVersion].
  Future<PendingOperation> enqueue(
    OfflineScope scope, {
    required String entity,
    required OperationKind kind,
    required Map<String, Object?> payload,
    String? recordId,
    int? baseVersion,
    DateTime? capturedAt,
    String? key,
  }) async {
    if (entity.trim().isEmpty) {
      throw ArgumentError.value(entity, 'entity', 'no puede ir vacio');
    }
    if (kind != OperationKind.insert &&
        (recordId == null || baseVersion == null)) {
      throw ArgumentError(
        'update y delete necesitan recordId y baseVersion (la version sobre la '
        'que se capturo)',
      );
    }
    final id = key ?? newUuid();
    final now = _now();
    final inserted = await _db.insert('pending_operation', {
      'id': id,
      'user_id': scope.userId,
      'concession_id': scope.concessionId,
      'entity': entity,
      'operation': kind.name,
      'record_id': recordId,
      'base_version': baseVersion,
      'payload': jsonEncode(payload),
      'status': OperationStatus.pending.name,
      'attempts': 0,
      'created_at': _ms(now),
      'captured_at': _ms(capturedAt ?? now),
      'updated_at': _ms(now),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final saved = (await find(id))!;
    if (saved.scope != scope) {
      throw StateError(
        'La clave de idempotencia $id ya es de otra persona o concesion',
      );
    }
    if (inserted != 0) _notify();
    return saved;
  }

  Future<PendingOperation?> find(String id) async {
    final rows = await _db.query(
      'pending_operation',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : _read(rows.single);
  }

  /// Las operaciones de [scope], de la mas antigua a la mas reciente, o de la
  /// mas reciente a la mas antigua con [newestFirst]. Con [statuses] solo esas.
  Future<List<PendingOperation>> list(
    OfflineScope scope, {
    Set<OperationStatus>? statuses,
    bool newestFirst = false,
  }) async {
    final where = StringBuffer('user_id = ? AND concession_id = ?');
    final args = <Object?>[scope.userId, scope.concessionId];
    if (statuses != null) {
      if (statuses.isEmpty) return const [];
      where.write(
        ' AND status IN (${List.filled(statuses.length, '?').join(',')})',
      );
      args.addAll(statuses.map((s) => s.name));
    }
    final rows = await _db.query(
      'pending_operation',
      where: where.toString(),
      whereArgs: args,
      orderBy: newestFirst
          ? 'created_at DESC, rowid DESC'
          : 'created_at ASC, rowid ASC',
    );
    return rows.map(_read).toList();
  }

  /// Cuantas hay de cada estado.
  Future<Map<OperationStatus, int>> counts(OfflineScope scope) async {
    final rows = await _db.rawQuery(
      'SELECT status, COUNT(*) AS n FROM pending_operation '
      'WHERE user_id = ? AND concession_id = ? GROUP BY status',
      [scope.userId, scope.concessionId],
    );
    return {
      for (final r in rows)
        OperationStatus.values.byName(r['status']! as String): r['n']! as int,
    };
  }

  /// Las pendientes que ya toca enviar (sin espera de reintento), en el orden
  /// en que se capturaron.
  Future<List<PendingOperation>> due(
    OfflineScope scope, {
    int limit = 50,
  }) async {
    final rows = await _db.query(
      'pending_operation',
      where:
          'user_id = ? AND concession_id = ? AND status = ? '
          'AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
      whereArgs: [
        scope.userId,
        scope.concessionId,
        OperationStatus.pending.name,
        _ms(_now()),
      ],
      orderBy: 'created_at ASC, rowid ASC',
      limit: limit,
    );
    return rows.map(_read).toList();
  }

  /// Las operaciones que esperan hora de reintento: cuando toca la primera.
  Future<DateTime?> nextRetryAt(OfflineScope scope) async {
    final rows = await _db.rawQuery(
      'SELECT MIN(next_attempt_at) AS t FROM pending_operation '
      'WHERE user_id = ? AND concession_id = ? AND status = ? '
      'AND next_attempt_at IS NOT NULL',
      [scope.userId, scope.concessionId, OperationStatus.pending.name],
    );
    final t = rows.single['t'];
    return t == null ? null : _at(t);
  }

  // ---- Transiciones --------------------------------------------------------

  Future<void> _set(
    String id,
    Map<String, Object?> values, {
    required Set<OperationStatus> from,
  }) async {
    final n = await _db.update(
      'pending_operation',
      {...values, 'updated_at': _ms(_now())},
      where:
          'id = ? AND status IN (${List.filled(from.length, '?').join(',')})',
      whereArgs: [id, ...from.map((s) => s.name)],
    );
    if (n != 0) _notify();
  }

  /// Se va a enviar: cuenta un intento.
  Future<void> markSending(String id) => _db
      .rawUpdate(
        'UPDATE pending_operation SET status = ?, attempts = attempts + 1, '
        'next_attempt_at = NULL, updated_at = ? WHERE id = ? AND status = ?',
        [
          OperationStatus.sending.name,
          _ms(_now()),
          id,
          OperationStatus.pending.name,
        ],
      )
      .then((n) {
        if (n != 0) _notify();
      });

  /// El servidor la aplico, o reconocio la clave y devolvio el resultado anterior.
  Future<void> markAccepted(String id, {Map<String, Object?>? response}) =>
      _set(
        id,
        {
          'status': OperationStatus.accepted.name,
          'last_error': null,
          'response': response == null ? null : jsonEncode(response),
        },
        from: {OperationStatus.sending, OperationStatus.pending},
      );

  /// El servidor la rechazo: no se reintenta sola; la persona decide.
  Future<void> markRejected(String id, {required String error}) => _set(
    id,
    {'status': OperationStatus.rejected.name, 'last_error': error},
    from: {OperationStatus.sending, OperationStatus.pending},
  );

  /// No se pudo enviar por red o por un error pasajero del servidor: vuelve a la
  /// cola y no se reintenta antes de [backoff].
  Future<void> markRetry(
    String id, {
    required String error,
    Duration backoff = Duration.zero,
  }) => _set(
    id,
    {
      'status': OperationStatus.pending.name,
      'last_error': error,
      'next_attempt_at': backoff == Duration.zero
          ? null
          : _ms(_now().add(backoff)),
    },
    from: {OperationStatus.sending},
  );

  /// El registro cambio en el servidor: se guardan ambas versiones.
  Future<void> markConflict(
    String id, {
    int? serverVersion,
    Map<String, Object?>? serverPayload,
    String? message,
  }) async {
    final op = await find(id);
    if (op == null || !op.isOpen) return;
    await _db.transaction((txn) async {
      await txn.update(
        'pending_operation',
        {
          'status': OperationStatus.conflict.name,
          'last_error': message,
          'updated_at': _ms(_now()),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('sync_conflict', {
        'operation_id': id,
        'local_version': op.baseVersion,
        'server_version': serverVersion,
        'server_payload': serverPayload == null
            ? null
            : jsonEncode(serverPayload),
        'message': message,
        'created_at': _ms(_now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    _notify();
  }

  Future<SyncConflict?> conflictOf(String id) async {
    final rows = await _db.query(
      'sync_conflict',
      where: 'operation_id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final r = rows.single;
    return SyncConflict(
      operationId: id,
      localVersion: r['local_version'] as int?,
      serverVersion: r['server_version'] as int?,
      serverPayload: _json(r['server_payload']),
      message: r['message'] as String?,
      createdAt: _at(r['created_at']),
      resolution: r['resolution'] == null
          ? null
          : ConflictResolution.values.byName(r['resolution']! as String),
      resolvedAt: r['resolved_at'] == null ? null : _at(r['resolved_at']),
    );
  }

  /// Vuelve a la cola una operacion rechazada o en conflicto. Con [baseVersion]
  /// se reenvia sobre la version actual del servidor (resolver un conflicto
  /// quedandose con lo capturado en el telefono).
  Future<void> requeue(String id, {int? baseVersion}) async {
    final op = await find(id);
    if (op == null || !op.needsAttention) return;
    await _db.transaction((txn) async {
      await txn.update(
        'pending_operation',
        {
          'status': OperationStatus.pending.name,
          'attempts': 0,
          'last_error': null,
          'next_attempt_at': null,
          'updated_at': _ms(_now()),
          'base_version': ?baseVersion,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (op.status == OperationStatus.conflict) {
        await txn.update(
          'sync_conflict',
          {
            'resolution': ConflictResolution.retried.name,
            'resolved_at': _ms(_now()),
          },
          where: 'operation_id = ?',
          whereArgs: [id],
        );
      }
    });
    _notify();
  }

  /// Descarta lo capturado en el telefono (y con ello su conflicto). Solo las
  /// que aun no se enviaron o que el servidor no aplico; nunca una aceptada.
  Future<bool> discard(String id) async {
    final n = await _db.delete(
      'pending_operation',
      where: 'id = ? AND status IN (?, ?, ?)',
      whereArgs: [
        id,
        OperationStatus.pending.name,
        OperationStatus.rejected.name,
        OperationStatus.conflict.name,
      ],
    );
    if (n != 0) _notify();
    return n != 0;
  }

  /// Al arrancar la app: lo que quedo «enviando» porque se cerro la app a medias
  /// vuelve a la cola. Es seguro: la clave de idempotencia evita duplicar.
  Future<int> resetInterrupted() async {
    final n = await _db.update(
      'pending_operation',
      {'status': OperationStatus.pending.name, 'updated_at': _ms(_now())},
      where: 'status = ?',
      whereArgs: [OperationStatus.sending.name],
    );
    if (n != 0) _notify();
    return n;
  }

  /// Borra las aceptadas con mas de [olderThan] (ya no sirven al usuario).
  Future<int> purgeAccepted({
    Duration olderThan = const Duration(days: 7),
  }) async {
    final n = await _db.delete(
      'pending_operation',
      where: 'status = ? AND updated_at < ?',
      whereArgs: [
        OperationStatus.accepted.name,
        _ms(_now().subtract(olderThan)),
      ],
    );
    if (n != 0) _notify();
    return n;
  }

  // ---- Ultima sincronizacion ----------------------------------------------

  Future<DateTime?> lastSync(OfflineScope scope) async {
    final rows = await _db.query(
      'sync_meta',
      where: 'user_id = ? AND concession_id = ?',
      whereArgs: [scope.userId, scope.concessionId],
    );
    final t = rows.isEmpty ? null : rows.single['last_sync_at'];
    return t == null ? null : _at(t);
  }

  Future<void> setLastSync(OfflineScope scope, DateTime at) async {
    await _db.insert('sync_meta', {
      'user_id': scope.userId,
      'concession_id': scope.concessionId,
      'last_sync_at': _ms(at),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _notify();
  }

  // ---- Lectura -------------------------------------------------------------

  static Map<String, Object?>? _json(Object? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw as String);
    return decoded is Map ? Map<String, Object?>.from(decoded) : null;
  }

  PendingOperation _read(Map<String, Object?> r) => PendingOperation(
    id: r['id']! as String,
    scope: OfflineScope(
      userId: r['user_id']! as String,
      concessionId: r['concession_id']! as String,
    ),
    entity: r['entity']! as String,
    kind: OperationKind.values.byName(r['operation']! as String),
    recordId: r['record_id'] as String?,
    baseVersion: r['base_version'] as int?,
    payload: _json(r['payload']) ?? const {},
    status: OperationStatus.values.byName(r['status']! as String),
    attempts: r['attempts']! as int,
    lastError: r['last_error'] as String?,
    response: _json(r['response']),
    createdAt: _at(r['created_at']),
    capturedAt: _at(r['captured_at']),
    updatedAt: _at(r['updated_at']),
    nextAttemptAt: r['next_attempt_at'] == null
        ? null
        : _at(r['next_attempt_at']),
  );
}
