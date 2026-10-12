import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local de la app (DEV-MOB-060): lo que se captura sin conexion
/// y la cola para sincronizarlo. SQLite del telefono (`sqflite`).
///
/// Todo lleva persona y concesion (`OfflineScope`): las consultas siempre
/// filtran por ambos, asi que lo de otra persona u otra concesion no se ve ni
/// se envia (HU-TR-02, DEV-MOB-053).
///
/// El esquema se versiona con `PRAGMA user_version`; cada cambio agrega una
/// migracion en [_migrate].
class OfflineDatabase {
  OfflineDatabase._(this.db);

  final Database db;

  static const schemaVersion = 1;
  static const fileName = 'sigaco_offline.db';

  /// Abre (o crea) la base. Sin parametros usa la del telefono; las pruebas
  /// pasan su propia [factory] y una [path] en memoria.
  static Future<OfflineDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final location = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: location != inMemoryDatabasePath,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _migrate(db, 0, version),
        onUpgrade: _migrate,
      ),
    );
    return OfflineDatabase._(db);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      switch (v) {
        case 1:
          await _v1(db);
      }
    }
  }

  static Future<void> _v1(Database db) async {
    // Un espejo local de sync.operacion (base de datos del servidor).
    await db.execute('''
      CREATE TABLE pending_operation (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        concession_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('insert','update','delete')),
        record_id TEXT,
        base_version INTEGER,
        payload TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('pending','sending','accepted','rejected','conflict')),
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        response TEXT,
        created_at INTEGER NOT NULL,
        captured_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        next_attempt_at INTEGER,
        CHECK (operation = 'insert' OR (record_id IS NOT NULL AND base_version IS NOT NULL))
      )
    ''');
    await db.execute('''
      CREATE INDEX ix_pending_scope
      ON pending_operation (user_id, concession_id, status, created_at)
    ''');
    await db.execute('''
      CREATE TABLE sync_conflict (
        operation_id TEXT PRIMARY KEY
          REFERENCES pending_operation (id) ON DELETE CASCADE,
        local_version INTEGER,
        server_version INTEGER,
        server_payload TEXT,
        message TEXT,
        created_at INTEGER NOT NULL,
        resolution TEXT CHECK (resolution IN ('discarded','retried')),
        resolved_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        user_id TEXT NOT NULL,
        concession_id TEXT NOT NULL,
        last_sync_at INTEGER,
        PRIMARY KEY (user_id, concession_id)
      )
    ''');
  }

  Future<void> close() => db.close();
}
