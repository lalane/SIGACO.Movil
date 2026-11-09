import 'package:equatable/equatable.dart';

/// Los tipos de dato de un campo de la ficha (`/api/asset-templates`).
enum AttributeType {
  text('TEXT'),
  integer('INTEGER'),
  decimal('DECIMAL'),
  boolean('BOOLEAN'),
  date('DATE'),
  dateTime('DATETIME'),
  catalog('CATALOG'),

  /// Un tipo que esta version de la app no conoce: se muestra como texto.
  unknown('');

  const AttributeType(this.code);

  final String code;

  static AttributeType fromCode(String? code) {
    final c = code?.trim().toUpperCase();
    for (final t in values) {
      if (t != unknown && t.code == c) return t;
    }
    return unknown;
  }

  bool get isNumber => this == integer || this == decimal;
}

/// De donde sale el valor de un campo: lo captura la persona o, en un activo
/// nacido del WebGIS, la columna de su capa (y entonces no se edita). En un alta
/// a mano los dos se capturan igual.
enum AttributeOrigin {
  captured,
  layer;

  static AttributeOrigin fromCode(String? code) =>
      code?.trim().toUpperCase() == 'LAYER' ? layer : captured;
}

/// Por que un valor no sirve para su campo (las mismas reglas que valida el
/// servidor; el servidor tiene la ultima palabra).
enum AttributeIssue {
  required,
  notNumber,
  notInteger,
  belowMin,
  aboveMax,
  tooLong,
  invalid,
}

/// Un campo de la ficha de un tipo de activo.
class AttributeDefinition extends Equatable {
  const AttributeDefinition({
    required this.key,
    required this.labelEs,
    required this.type,
    this.labelPt,
    this.unit,
    this.required = false,
    this.catalogCode,
    this.min,
    this.max,
    this.sortOrder = 0,
    this.help,
    this.origin = AttributeOrigin.captured,
  });

  /// Lo que admite como maximo un campo de texto (AttributeRules del servidor).
  static const textMaxLength = 500;

  /// La clave en `attributes` del activo.
  final String key;
  final String labelEs;
  final String? labelPt;
  final AttributeType type;

  /// Unidad (`m`, `km`, `un`); null si no tiene.
  final String? unit;
  final bool required;

  /// El catalogo generico de sus valores, si es [AttributeType.catalog].
  final String? catalogCode;

  /// Minimo y maximo de un numero; null si no tiene.
  final double? min;
  final double? max;
  final int sortOrder;
  final String? help;
  final AttributeOrigin origin;

  /// El nombre en el idioma de la app (`es` o `pt`).
  String label(String language) =>
      language == 'pt' && (labelPt?.trim().isNotEmpty ?? false)
      ? labelPt!
      : labelEs;

  /// Revisa lo capturado: texto para texto y numeros (como se escribe), bool,
  /// fecha ([DateTime]) o codigo de catalogo. Null si sirve.
  AttributeIssue? check(Object? value) {
    if (isEmptyValue(value)) return required ? AttributeIssue.required : null;
    switch (type) {
      case AttributeType.integer:
      case AttributeType.decimal:
        final n = parseNumber(value);
        if (n == null) return AttributeIssue.notNumber;
        if (type == AttributeType.integer && n != n.truncateToDouble()) {
          return AttributeIssue.notInteger;
        }
        if (min != null && n < min!) return AttributeIssue.belowMin;
        if (max != null && n > max!) return AttributeIssue.aboveMax;
        return null;
      case AttributeType.boolean:
        return value is bool ? null : AttributeIssue.invalid;
      case AttributeType.date:
      case AttributeType.dateTime:
        return value is DateTime ? null : AttributeIssue.invalid;
      case AttributeType.text:
      case AttributeType.unknown:
        return '$value'.trim().length > textMaxLength
            ? AttributeIssue.tooLong
            : null;
      case AttributeType.catalog:
        return value is String ? null : AttributeIssue.invalid;
    }
  }

  /// Lo capturado como lo recibe el servidor: numeros como numero, fechas
  /// `AAAA-MM-DD`, fecha y hora ISO en UTC, codigos de catalogo en mayusculas.
  /// Null si esta vacio (no se manda).
  Object? toServer(Object? value) {
    if (isEmptyValue(value)) return null;
    switch (type) {
      case AttributeType.integer:
        return parseNumber(value)?.round();
      case AttributeType.decimal:
        return parseNumber(value);
      case AttributeType.boolean:
        return value is bool ? value : null;
      case AttributeType.date:
        if (value is! DateTime) return null;
        return '${value.year.toString().padLeft(4, '0')}-'
            '${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';
      case AttributeType.dateTime:
        return value is DateTime ? value.toUtc().toIso8601String() : null;
      case AttributeType.catalog:
        return '$value'.trim().toUpperCase();
      case AttributeType.text:
      case AttributeType.unknown:
        return '$value'.trim();
    }
  }

  static bool isEmptyValue(Object? value) =>
      value == null || (value is String && value.trim().isEmpty);

  /// Un numero escrito con punto o coma decimal (`12,5`, `12.5`).
  static double? parseNumber(Object? value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;
    var t = value.trim();
    if (t.isEmpty) return null;
    if (t.contains(',') && !t.contains('.')) t = t.replaceAll(',', '.');
    final n = double.tryParse(t);
    return n != null && n.isFinite ? n : null;
  }

  @override
  List<Object?> get props => [
    key,
    labelEs,
    labelPt,
    type,
    unit,
    required,
    catalogCode,
    min,
    max,
    sortOrder,
    help,
    origin,
  ];
}

/// La ficha de un tipo de activo: sus campos, en orden.
class AssetTemplate extends Equatable {
  const AssetTemplate({
    required this.typeCode,
    required this.number,
    required this.attributes,
    this.name,
    this.status,
  });

  final String typeCode;
  final int number;
  final String? name;

  /// `VIGENTE`, `BORRADOR` o `RETIRADA`.
  final String? status;
  final List<AttributeDefinition> attributes;

  bool get isCurrent => status == null || status == 'VIGENTE';

  AttributeDefinition? field(String key) {
    for (final a in attributes) {
      if (a.key == key) return a;
    }
    return null;
  }

  @override
  List<Object?> get props => [typeCode, number, name, status, attributes];
}
