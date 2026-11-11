/// Definiciones pendientes (tanda 4): lo que SIGACO ya hace con un supuesto y
/// TEKIA debe confirmar. Las responde quien administra («De acuerdo» o «No: asi
/// es...») y cualquiera puede comentarlas (supuestos S-DEF-01 y S-DEF-02).
library;

enum DefinitionStatus {
  open('ABIERTA'),
  answered('RESPONDIDA'),
  accepted('ACEPTADA'),
  changeRequested('CAMBIO_SOLICITADO'),
  retired('RETIRADA');

  const DefinitionStatus(this.code);

  final String code;

  static DefinitionStatus fromCode(String? code) =>
      values.where((s) => s.code == code).firstOrNull ?? DefinitionStatus.open;

  /// Espera la respuesta de TEKIA.
  bool get pending => this == open || this == answered;
}

enum DefinitionPriority {
  high('ALTA'),
  medium('MEDIA'),
  low('BAJA');

  const DefinitionPriority(this.code);

  final String code;

  static DefinitionPriority fromCode(String? code) =>
      values.where((p) => p.code == code).firstOrNull ?? DefinitionPriority.low;
}

/// Lo que una persona puede responder.
enum DefinitionAnswerKind {
  agree('ACUERDO'),
  change('CAMBIO'),
  comment('COMENTARIO');

  const DefinitionAnswerKind(this.code);

  final String code;

  /// Pide texto: el cambio dice como debe ser y el comentario, que.
  bool get needsText => this != agree;
}

class DefinitionPermissions {
  const DefinitionPermissions({
    this.canComment = false,
    this.canDecide = false,
    this.canReopen = false,
  });

  final bool canComment;

  /// «De acuerdo» y «No: asi es...».
  final bool canDecide;
  final bool canReopen;
}

/// Una entrada del historial: respuesta de una persona o lo que hizo el sistema.
class DefinitionAnswer {
  const DefinitionAnswer({
    required this.kind,
    required this.newStatus,
    required this.createdAt,
    this.text,
    this.previousStatus,
    this.userName,
    this.profileName,
    this.fromApp = false,
  });

  /// ACUERDO, CAMBIO, COMENTARIO, REAPERTURA, SUPUESTO_ACTUALIZADO...
  final String kind;
  final String? text;
  final DefinitionStatus? previousStatus;
  final DefinitionStatus newStatus;
  final String? userName;
  final String? profileName;
  final bool fromApp;
  final DateTime createdAt;
}

class PendingDefinition {
  const PendingDefinition({
    required this.code,
    required this.module,
    required this.moduleLabel,
    required this.title,
    required this.question,
    required this.assumption,
    required this.ifVetoed,
    required this.source,
    required this.priority,
    required this.status,
    this.indicator,
    this.mobileModule,
    this.answerCount = 0,
    this.lastAnswer,
  });

  final String code;
  final String module;
  final String moduleLabel;
  final String? indicator;
  final String title;
  final String question;

  /// Lo que hace hoy SIGACO.
  final String assumption;

  /// Que cambia si TEKIA dice otra cosa.
  final String ifVetoed;
  final String source;
  final DefinitionPriority priority;
  final DefinitionStatus status;

  /// Modulo de la app donde aplica (tickets, inventory...), si lo dice.
  final String? mobileModule;
  final int answerCount;
  final DefinitionAnswer? lastAnswer;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      code,
      title,
      question,
      assumption,
    ].any((t) => t.toLowerCase().contains(q));
  }
}

class DefinitionPage {
  const DefinitionPage({required this.items, required this.permissions});

  final List<PendingDefinition> items;
  final DefinitionPermissions permissions;
}

class DefinitionDetail {
  const DefinitionDetail({
    required this.definition,
    required this.history,
    required this.permissions,
  });

  final PendingDefinition definition;

  /// Del mas antiguo al mas reciente.
  final List<DefinitionAnswer> history;
  final DefinitionPermissions permissions;
}
