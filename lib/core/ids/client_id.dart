import 'dart:math';

/// Un identificador unico (UUID v4) que genera el telefono al crear un registro:
/// el servidor lo usa como clave de idempotencia (`cliente_uuid`), para que un
/// registro creado sin conexion no se duplique al sincronizar.
String newClientId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  // Version 4 y variante RFC 4122.
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => [
    for (var i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
