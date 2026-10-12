import 'dart:math';

final _random = Random.secure();

/// Un UUID v4 (aleatorio). Sirve de clave de idempotencia de una operacion:
/// lo genera el telefono y el servidor lo reconoce si la app reenvia lo mismo
/// (HU-TR-MOB-03; en la base, `sync.operacion.clave_idempotencia`).
String newUuid([Random? random]) {
  final r = random ?? _random;
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
  String hex(int from, int to) => bytes
      .sublist(from, to)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool isUuid(String value) => _uuid.hasMatch(value.toLowerCase());
