import 'package:equatable/equatable.dart';

import 'inspection.dart';

/// Tipos de campo de la plantilla (DTF M08 §4.5), con el mismo codigo que el
/// servidor.
enum TemplateFieldType {
  text('TEXTO'),
  number('NUMERO'),
  date('FECHA'),
  yesNo('SI_NO'),
  option('OPCION'),
  multiple('MULTIPLE'),
  km('KM'),
  conformity('CONFORMIDAD'),
  evidence('EVIDENCIA');

  const TemplateFieldType(this.code);

  final String code;

  static TemplateFieldType of(String? code) => TemplateFieldType.values
      .firstWhere((t) => t.code == code, orElse: () => TemplateFieldType.text);
}

class TemplateOption extends Equatable {
  const TemplateOption({
    required this.value,
    required this.label,
    this.labelPt,
    this.condition,
  });

  factory TemplateOption.fromJson(Map<String, dynamic> m) => TemplateOption(
    value: '${m['value'] ?? ''}',
    label: '${m['label'] ?? m['value'] ?? ''}',
    labelPt: m['labelPt'] as String?,
    condition: m['condition'] as String?,
  );

  final String value;
  final String label;
  final String? labelPt;

  /// Condicion homologada a la que equivale (Bom -> BUENO, Precario -> MALO).
  final String? condition;

  String labelFor(String language) =>
      (language == 'pt' ? labelPt : null) ?? label;

  @override
  List<Object?> get props => [value, label, labelPt, condition];
}

class TemplateField extends Equatable {
  const TemplateField({
    required this.key,
    required this.label,
    required this.type,
    this.labelPt,
    this.required = false,
    this.requiredIfField,
    this.requiredIfValue,
    this.options = const [],
    this.min,
    this.max,
    this.unit,
    this.source,
    this.minPhotos,
    this.enabled = true,
    this.help,
  });

  factory TemplateField.fromJson(Map<String, dynamic> m) {
    final requiredIf = m['requiredIf'];
    return TemplateField(
      key: '${m['key'] ?? ''}',
      label: '${m['label'] ?? m['key'] ?? ''}',
      labelPt: m['labelPt'] as String?,
      type: TemplateFieldType.of(m['type'] as String?),
      required: m['required'] == true,
      requiredIfField: requiredIf is Map
          ? requiredIf['field'] as String?
          : null,
      requiredIfValue: requiredIf is Map ? requiredIf['equals'] : null,
      options: [
        for (final o in (m['options'] as List?) ?? const [])
          if (o is Map<String, dynamic>) TemplateOption.fromJson(o),
      ],
      min: (m['min'] as num?)?.toDouble(),
      max: (m['max'] as num?)?.toDouble(),
      unit: m['unit'] as String?,
      source: m['source'] as String?,
      minPhotos: (m['minPhotos'] as num?)?.toInt(),
      enabled: m['enabled'] != false,
      help: m['help'] as String?,
    );
  }

  final String key;
  final String label;
  final String? labelPt;
  final TemplateFieldType type;
  final bool required;

  /// Obligatorio solo si el campo [requiredIfField] de la seccion vale
  /// [requiredIfValue] (la extension si se marca «reparar»).
  final String? requiredIfField;
  final Object? requiredIfValue;
  final List<TemplateOption> options;
  final double? min;
  final double? max;
  final String? unit;

  /// CAPTURA, ACTIVO (lo pone el servidor, no se edita) o ANTERIOR.
  final String? source;
  final int? minPhotos;
  final bool enabled;
  final String? help;

  bool get readOnly => source == 'ACTIVO' || source == 'ANTERIOR';

  String labelFor(String language) =>
      (language == 'pt' ? labelPt : null) ?? label;

  @override
  List<Object?> get props => [
    key,
    label,
    type,
    required,
    requiredIfField,
    requiredIfValue,
    options,
    min,
    max,
    unit,
    source,
    minPhotos,
    enabled,
  ];
}

class TemplateSection extends Equatable {
  const TemplateSection({
    required this.key,
    required this.label,
    required this.fields,
    this.labelPt,
    this.repeatable = false,
    this.maxItems,
    this.enabled = true,
  });

  factory TemplateSection.fromJson(Map<String, dynamic> m) => TemplateSection(
    key: '${m['key'] ?? ''}',
    label: '${m['label'] ?? ''}',
    labelPt: m['labelPt'] as String?,
    repeatable: m['repeatable'] == true,
    maxItems: (m['maxItems'] as num?)?.toInt(),
    enabled: m['enabled'] != false,
    fields: [
      for (final f in (m['fields'] as List?) ?? const [])
        if (f is Map<String, dynamic>) TemplateField.fromJson(f),
    ],
  );

  final String key;
  final String label;
  final String? labelPt;
  final bool repeatable;
  final int? maxItems;
  final bool enabled;
  final List<TemplateField> fields;

  List<TemplateField> get activeFields => [
    for (final f in fields)
      if (f.enabled) f,
  ];

  String labelFor(String language) =>
      (language == 'pt' ? labelPt : null) ?? label;

  @override
  List<Object?> get props => [
    key,
    label,
    labelPt,
    repeatable,
    maxItems,
    enabled,
    fields,
  ];
}

/// Regla de condicion: CAMPO, PEOR o CONTEO (M13 Parte 2 §4.3).
class ConditionRule extends Equatable {
  const ConditionRule({
    required this.mode,
    required this.fields,
    this.rules = const [],
    this.defaultResult,
    this.defaultNative,
  });

  factory ConditionRule.fromJson(Map<String, dynamic> m) => ConditionRule(
    mode: '${m['mode'] ?? ''}',
    fields: [for (final f in (m['fields'] as List?) ?? const []) '$f'],
    rules: [
      for (final r in (m['rules'] as List?) ?? const [])
        if (r is Map<String, dynamic>)
          (
            value: '${r['value']}',
            atLeast: (r['atLeast'] as num?)?.toInt() ?? 1,
            result: '${r['result']}',
            native: r['native'] as String?,
          ),
    ],
    defaultResult: m['defaultResult'] as String?,
    defaultNative: m['defaultNative'] as String?,
  );

  final String mode;
  final List<String> fields;
  final List<({String value, int atLeast, String result, String? native})>
  rules;
  final String? defaultResult;
  final String? defaultNative;

  @override
  List<Object?> get props => [
    mode,
    fields,
    rules,
    defaultResult,
    defaultNative,
  ];
}

class TemplateDefinition extends Equatable {
  const TemplateDefinition({required this.sections, this.condition});

  factory TemplateDefinition.fromJson(Object? raw) {
    final m = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final condition = m['condition'];
    return TemplateDefinition(
      sections: [
        for (final s in (m['sections'] as List?) ?? const [])
          if (s is Map<String, dynamic>) TemplateSection.fromJson(s),
      ],
      condition: condition is Map<String, dynamic>
          ? ConditionRule.fromJson(condition)
          : null,
    );
  }

  final List<TemplateSection> sections;
  final ConditionRule? condition;

  List<TemplateSection> get activeSections => [
    for (final s in sections)
      if (s.enabled) s,
  ];

  @override
  List<Object?> get props => [sections, condition];
}

/// Un dato que falta o esta mal: la ruta del servidor (`answers.seccion.campo`)
/// y el mensaje.
class CaptureIssue extends Equatable {
  const CaptureIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  List<Object?> get props => [path, message];
}

/// «seccion.campo» (solo «campo» en la plantilla implicita del checklist).
String fieldPath(String section, String field) =>
    section.isEmpty ? field : '$section.$field';

/// Las mismas reglas que el servidor (TemplateEngine), para que la app diga lo
/// que falta y la condicion aunque no haya senal. El servidor vuelve a validar.
abstract final class TemplateEvaluator {
  static const conditionOrder = ['BUENO', 'REGULAR', 'MALO', 'PESIMO'];

  static List<Map<String, dynamic>?> rowsOf(
    TemplateSection section,
    Map<String, dynamic> answers,
  ) {
    if (section.key.isEmpty) return [answers];
    final node = answers[section.key];
    if (section.repeatable) {
      return node is List
          ? [for (final r in node) r is Map<String, dynamic> ? r : null]
          : const [];
    }
    return node is Map<String, dynamic> ? [node] : const [];
  }

  static bool isEmpty(Object? v) =>
      v == null ||
      (v is String && v.trim().isEmpty) ||
      (v is List && v.isEmpty);

  static bool _requiredNow(TemplateField f, Map<String, dynamic>? row) {
    if (f.requiredIfField != null) {
      return row != null && row[f.requiredIfField] == f.requiredIfValue;
    }
    return f.required;
  }

  /// Un valor con el tipo o el rango equivocado; null si esta bien.
  static String? checkValue(TemplateField f, Object value) {
    switch (f.type) {
      case TemplateFieldType.number:
      case TemplateFieldType.km:
        if (value is! num) return 'Se espera un numero.';
        if (f.min != null && value < f.min!) {
          return 'El minimo es ${_n(f.min!)}${f.unit == null ? '' : ' ${f.unit}'}.';
        }
        if (f.max != null && value > f.max!) {
          return 'El maximo es ${_n(f.max!)}${f.unit == null ? '' : ' ${f.unit}'}.';
        }
        return null;
      case TemplateFieldType.option:
        return f.options.any((o) => o.value == value)
            ? null
            : 'Elige una opcion de la lista.';
      case TemplateFieldType.yesNo:
        return value is bool ? null : 'Se espera si o no.';
      default:
        return null;
    }
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Lo que falta: al guardar, solo tipo y rango; al finalizar, tambien
  /// obligatorios y fotos ([photos] por ruta de campo).
  static List<CaptureIssue> validate(
    TemplateDefinition t,
    Map<String, dynamic> answers, {
    required bool finalize,
    required int Function(String path) photos,
  }) {
    final issues = <CaptureIssue>[];
    for (final section in t.activeSections) {
      final rows = rowsOf(section, answers);
      final effective = !section.repeatable && rows.isEmpty
          ? <Map<String, dynamic>?>[null]
          : rows;
      for (var i = 0; i < effective.length; i++) {
        final row = effective[i];
        final prefix = section.repeatable
            ? 'answers.${section.key}[$i]'
            : section.key.isEmpty
            ? 'answers'
            : 'answers.${section.key}';
        for (final f in section.activeFields) {
          final path = '$prefix.${f.key}';
          final value = row?[f.key];
          if (f.type != TemplateFieldType.evidence && !isEmpty(value)) {
            final problem = checkValue(f, value!);
            if (problem != null) issues.add(CaptureIssue(path, problem));
          }
          if (!finalize || f.readOnly || !_requiredNow(f, row)) continue;
          if (f.type == TemplateFieldType.evidence) {
            final needed = (f.minPhotos ?? 1) < 1 ? 1 : (f.minPhotos ?? 1);
            if (photos(fieldPath(section.key, f.key)) < needed) {
              issues.add(
                CaptureIssue(
                  path,
                  needed == 1
                      ? 'Falta la foto obligatoria.'
                      : 'Faltan fotos: se piden $needed.',
                ),
              );
            }
          } else if (isEmpty(value)) {
            issues.add(CaptureIssue(path, 'Es obligatorio para finalizar.'));
          }
        }
      }
    }
    return issues;
  }

  /// La condicion homologada y la nativa segun la regla de la plantilla.
  static ({String? state, String? native}) evaluate(
    TemplateDefinition t,
    Map<String, dynamic> answers,
  ) {
    final rule = t.condition;
    if (rule == null) return (state: null, native: null);
    final picks = <TemplateOption>[];
    for (final section in t.activeSections) {
      for (final f in section.activeFields) {
        if (f.type != TemplateFieldType.option &&
            f.type != TemplateFieldType.multiple) {
          continue;
        }
        final path = fieldPath(section.key, f.key);
        if (!rule.fields.contains(path) &&
            !rule.fields.contains('${section.key}.*')) {
          continue;
        }
        for (final row in rowsOf(section, answers)) {
          final v = row?[f.key];
          final values = v is List
              ? v.map((e) => '$e')
              : v == null
              ? const <String>[]
              : ['$v'];
          for (final value in values) {
            final option = f.options.where((o) => o.value == value).firstOrNull;
            if (option != null) picks.add(option);
          }
        }
      }
    }
    if (rule.mode == 'CONTEO') {
      if (picks.isEmpty) return (state: null, native: null);
      for (final r in rule.rules) {
        if (picks.where((p) => p.value == r.value).length >=
            (r.atLeast < 1 ? 1 : r.atLeast)) {
          return (state: r.result, native: r.native ?? r.result);
        }
      }
      return (
        state: rule.defaultResult,
        native: rule.defaultNative ?? rule.defaultResult,
      );
    }
    final rated = [
      for (final p in picks)
        if (p.condition != null) p,
    ];
    if (rated.isEmpty) return (state: null, native: null);
    rated.sort(
      (a, b) => conditionOrder
          .indexOf(b.condition!)
          .compareTo(conditionOrder.indexOf(a.condition!)),
    );
    return (state: rated.first.condition, native: rated.first.label);
  }
}

/// Una foto o archivo de la inspeccion, ya en el servidor o esperando red.
class CaptureEvidence extends Equatable {
  const CaptureEvidence({
    required this.id,
    required this.fileName,
    this.fieldKey,
    this.latitude,
    this.longitude,
    this.capturedAt,
    this.localPath,
  });

  final String id;
  final String fileName;
  final String? fieldKey;
  final double? latitude;
  final double? longitude;
  final DateTime? capturedAt;

  /// Solo mientras espera red: la foto esta en el telefono.
  final String? localPath;

  bool get pending => localPath != null;

  @override
  List<Object?> get props => [
    id,
    fileName,
    fieldKey,
    latitude,
    longitude,
    capturedAt,
    localPath,
  ];
}

/// Un hallazgo de la inspeccion tal como lo ve la captura.
class CaptureFinding extends Equatable {
  const CaptureFinding({
    required this.id,
    required this.description,
    required this.severity,
    required this.status,
    this.failureCode,
    this.ticketId,
    this.pending = false,
  });

  final String id;
  final String description;
  final String severity;

  /// ABIERTO, CON_TICKET, DESCARTADO o RESUELTO.
  final String status;
  final String? failureCode;
  final String? ticketId;

  /// Capturado sin conexion: no genera ticket hasta sincronizarse (RB-08-17).
  final bool pending;

  @override
  List<Object?> get props => [
    id,
    description,
    severity,
    status,
    failureCode,
    ticketId,
    pending,
  ];
}

/// Una falla de la Matriz que se puede elegir en un hallazgo del tipo.
class FailureChoice extends Equatable {
  const FailureChoice({
    required this.code,
    required this.label,
    this.classification,
    this.attentionLabel,
    this.immediate = false,
  });

  final String code;
  final String label;
  final String? classification;
  final String? attentionLabel;
  final bool immediate;

  @override
  List<Object?> get props => [
    code,
    label,
    classification,
    attentionLabel,
    immediate,
  ];
}

/// Que puede hacer la persona con la inspeccion (lo decide el servidor).
class CaptureActions extends Equatable {
  const CaptureActions({
    this.accept = false,
    this.reject = false,
    this.start = false,
    this.save = false,
    this.finalize = false,
  });

  factory CaptureActions.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    return CaptureActions(
      accept: m['accept'] == true,
      reject: m['reject'] == true,
      start: m['start'] == true,
      save: m['save'] == true,
      finalize: m['finalize'] == true,
    );
  }

  final bool accept;
  final bool reject;
  final bool start;
  final bool save;
  final bool finalize;

  @override
  List<Object?> get props => [accept, reject, start, save, finalize];
}

/// Lo que se necesita para capturar una inspeccion en campo: su plantilla, sus
/// respuestas, fotos, hallazgos, lo que falta y lo que se puede hacer.
class InspectionCaptureView extends Equatable {
  const InspectionCaptureView({
    required this.id,
    required this.folio,
    required this.status,
    required this.serverStatus,
    required this.typeId,
    required this.typeLabel,
    required this.template,
    required this.answers,
    required this.rowVersion,
    this.assetId,
    this.assetCode,
    this.kmLabel,
    this.reason,
    this.previousAnswers = const {},
    this.evidences = const [],
    this.findings = const [],
    this.missing = const [],
    this.computedCondition,
    this.computedNative,
    this.actions = const CaptureActions(),
    this.templateVersion,
    this.requiresReview = true,
    this.toleranceMeters,
    this.pendingSync = false,
    this.correctionReason,
  });

  final String id;
  final String folio;
  final InspectionStatus status;

  /// El codigo del servidor (EN_REVISION, ASIGNADA...), para mostrarlo tal cual.
  final String serverStatus;
  final String typeId;
  final String typeLabel;
  final TemplateDefinition template;
  final Map<String, dynamic> answers;
  final int rowVersion;
  final String? assetId;
  final String? assetCode;
  final String? kmLabel;
  final String? reason;
  final Map<String, dynamic> previousAnswers;
  final List<CaptureEvidence> evidences;
  final List<CaptureFinding> findings;
  final List<CaptureIssue> missing;
  final String? computedCondition;
  final String? computedNative;
  final CaptureActions actions;
  final int? templateVersion;
  final bool requiresReview;
  final int? toleranceMeters;

  /// Hay cambios capturados sin conexion que aun no llegan al servidor.
  final bool pendingSync;
  final String? correctionReason;

  bool get editable => serverStatus == 'EN_PROCESO' && actions.save;

  int photosOf(String path) =>
      evidences.where((e) => e.fieldKey == path).length;

  InspectionCaptureView copyWith({
    Map<String, dynamic>? answers,
    List<CaptureEvidence>? evidences,
    List<CaptureFinding>? findings,
    List<CaptureIssue>? missing,
    String? computedCondition,
    String? computedNative,
    bool? pendingSync,
    String? serverStatus,
    InspectionStatus? status,
    CaptureActions? actions,
  }) => InspectionCaptureView(
    id: id,
    folio: folio,
    status: status ?? this.status,
    serverStatus: serverStatus ?? this.serverStatus,
    typeId: typeId,
    typeLabel: typeLabel,
    template: template,
    answers: answers ?? this.answers,
    rowVersion: rowVersion,
    assetId: assetId,
    assetCode: assetCode,
    kmLabel: kmLabel,
    reason: reason,
    previousAnswers: previousAnswers,
    evidences: evidences ?? this.evidences,
    findings: findings ?? this.findings,
    missing: missing ?? this.missing,
    computedCondition: computedCondition ?? this.computedCondition,
    computedNative: computedNative ?? this.computedNative,
    actions: actions ?? this.actions,
    templateVersion: templateVersion,
    requiresReview: requiresReview,
    toleranceMeters: toleranceMeters,
    pendingSync: pendingSync ?? this.pendingSync,
    correctionReason: correctionReason,
  );

  /// La misma vista recalculada en el telefono: lo que falta y la condicion.
  /// Lo de los hallazgos (su foto) lo conserva tal como lo dijo el servidor.
  InspectionCaptureView recomputed() {
    final result = TemplateEvaluator.evaluate(template, answers);
    return copyWith(
      missing: [
        ...TemplateEvaluator.validate(
          template,
          answers,
          finalize: true,
          photos: photosOf,
        ),
        ...missing.where((m) => m.path.startsWith('findings.')),
      ],
      computedCondition: result.state ?? computedCondition,
      computedNative: result.native ?? computedNative,
    );
  }

  @override
  List<Object?> get props => [
    id,
    folio,
    status,
    serverStatus,
    typeId,
    typeLabel,
    template,
    answers,
    rowVersion,
    assetId,
    assetCode,
    kmLabel,
    reason,
    previousAnswers,
    evidences,
    findings,
    missing,
    computedCondition,
    computedNative,
    actions,
    templateVersion,
    requiresReview,
    toleranceMeters,
    pendingSync,
    correctionReason,
  ];
}
