import 'package:crypto/crypto.dart';

import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';

/// Lectura tolerante de lo que entrega el servidor de inventario: un campo que
/// falta o llega con otra forma no rompe la pantalla (el contrato de Activos se
/// amplia por partes).
abstract final class InventoryJson {
  static String? text(Object? v) {
    final s = v is String ? v.trim() : null;
    return s == null || s.isEmpty ? null : s;
  }

  static double? number(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
    return null;
  }

  static int? integer(Object? v) => v is num ? v.toInt() : null;

  static Map<String, dynamic>? map(Object? v) => v is Map<String, dynamic>
      ? v
      : (v is Map ? v.cast<String, dynamic>() : null);

  static List<Object?> list(Object? v) {
    if (v is List) return v;
    final m = map(v);
    final items = m?['items'];
    return items is List ? items : const [];
  }

  /// Una lista de textos (`["WEBGIS","MOBILE"]`); null si no viene.
  static List<String>? texts(Object? v) {
    if (v is! List) return null;
    return [
      for (final x in v)
        if (text(x) case final s?) s.toUpperCase(),
    ];
  }

  /// Un campo de la ficha (`AttributeDefinitionDto`).
  static AttributeDefinition? attribute(Object? json) {
    final m = map(json);
    final key = text(m?['key']);
    if (m == null || key == null) return null;
    return AttributeDefinition(
      key: key,
      labelEs: text(m['labelEs']) ?? text(m['label']) ?? key,
      labelPt: text(m['labelPt']),
      type: AttributeType.fromCode(text(m['dataType']) ?? text(m['type'])),
      unit: text(m['unit']),
      required: m['required'] == true,
      catalogCode: text(m['catalogCode'])?.toUpperCase(),
      min: number(m['minValue'] ?? m['min']),
      max: number(m['maxValue'] ?? m['max']),
      sortOrder: integer(m['sortOrder']) ?? 0,
      help: text(m['help']),
      origin: AttributeOrigin.fromCode(text(m['origin'])),
    );
  }

  /// Una ficha (`AssetTemplateDto`); null si no trae tipo.
  static AssetTemplate? template(Object? json, {String? typeCode}) {
    final m = map(json);
    if (m == null) return null;
    final type = text(m['assetTypeCode']) ?? typeCode;
    if (type == null) return null;
    final fields = [for (final a in list(m['attributes'])) ?attribute(a)]
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
      });
    return AssetTemplate(
      typeCode: type.toUpperCase(),
      number: integer(m['number']) ?? 0,
      name: text(m['name']),
      status: text(m['status'])?.toUpperCase(),
      attributes: fields,
    );
  }

  /// La ficha vigente de lo que responda el servidor: una ficha sola, la lista
  /// de versiones de un tipo (`VIGENTE`) o la lista de vigentes de todos los
  /// tipos. Null si no hay.
  static AssetTemplate? currentTemplate(Object? json, String typeCode) {
    final type = typeCode.toUpperCase();
    final single = map(json);
    if (single != null && single['attributes'] is List) {
      final t = template(single, typeCode: type);
      return t != null && t.typeCode == type ? t : null;
    }
    AssetTemplate? best;
    for (final item in list(json)) {
      final t = template(item, typeCode: type);
      if (t == null || t.typeCode != type) continue;
      // La vigente; si el servidor no dice el estado, la de numero mayor.
      if (t.status == 'VIGENTE') return t;
      if (t.status != null && t.status != 'VIGENTE') continue;
      if (best == null || t.number > best.number) best = t;
    }
    return best;
  }

  /// Un tipo de activo (`AssetTypeDto`); null si esta inactivo o no tiene
  /// codigo.
  static AssetTypeOption? assetType(Object? json) {
    final m = map(json);
    final code = text(m?['code']);
    if (m == null || code == null || m['active'] == false) return null;
    return AssetTypeOption(
      code: code.toUpperCase(),
      labelEs: text(m['labelEs']) ?? code,
      labelPt: text(m['labelPt']),
      subsystemCode: text(m['subsystemCode']),
      geometryType: text(m['geometryType'])?.toUpperCase(),
      requiresKmEnd: m['requiresKmEnd'] == true,
      birthChannels: texts(m['birthChannels']),
      sortOrder: integer(m['sortOrder']) ?? 0,
    );
  }

  /// Los catalogos genericos (`CatalogDto[]`) por codigo, solo valores activos.
  static Map<String, List<CatalogOption>> catalogs(Object? json) {
    final result = <String, List<CatalogOption>>{};
    for (final c in list(json)) {
      final m = map(c);
      final code = text(m?['code']);
      if (m == null || code == null) continue;
      final values = <(int, CatalogOption)>[];
      for (final v in list(m['values'])) {
        final vm = map(v);
        final vc = text(vm?['code']);
        if (vm == null || vc == null || vm['active'] == false) continue;
        values.add((
          integer(vm['sortOrder']) ?? 0,
          CatalogOption(
            code: vc.toUpperCase(),
            labelEs: text(vm['labelEs']) ?? vc,
            labelPt: text(vm['labelPt']),
          ),
        ));
      }
      values.sort((a, b) => a.$1.compareTo(b.$1));
      result[code.toUpperCase()] = [for (final v in values) v.$2];
    }
    return result;
  }

  /// La clave de captura de la foto [index] de un alta: siempre la misma para
  /// la misma captura, asi reenviarla no la duplica en el servidor (UUID con
  /// forma de version 5, sacado de la clave del activo).
  static String photoKey(String clientId, int index) {
    final digest = sha1.convert('$clientId/foto/$index'.codeUnits).bytes;
    final b = digest.sublist(0, 16);
    b[6] = (b[6] & 0x0f) | 0x50;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int from, int to) => [
      for (var i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
