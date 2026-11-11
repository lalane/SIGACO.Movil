import 'package:equatable/equatable.dart';

/// En que va un ticket: abierto (nadie lo ha atendido) o atendido (hay trabajo
/// hecho). El BBP (APP-MOB-03) maneja solo tickets «abiertos o atendidos». Los
/// colores de estatus son del sistema (COL-05).
enum TicketStatus { open, attended }

/// El estado del ticket en el flujo del DTF M11 v0.3 (§4.2): sin validar (nadie
/// lo ha asignado), abierto (asignado a una empresa y un equipo), atendido (el
/// equipo termino y espera la validacion del Supervisor), cerrado o cancelado.
/// [TicketStatus] sigue siendo la vista corta (falta atenderlo o no).
enum TicketStage {
  unvalidated('SIN_VALIDAR'),
  open('ABIERTO'),
  attended('ATENDIDO'),
  closed('CERRADO'),
  cancelled('CANCELADO');

  const TicketStage(this.code);

  /// El codigo del servidor.
  final String code;

  /// El estado que manda el servidor. Los codigos del BBP se leen como su
  /// equivalente (tabla de equivalencias del DTF), por si llega un dato viejo.
  static TicketStage? fromCode(String? code) =>
      switch (code?.trim().toUpperCase()) {
        'SIN_VALIDAR' || 'NUEVO' => unvalidated,
        'ABIERTO' ||
        'ASIGNADO' ||
        'EN_PROCESO' ||
        'EN_ESPERA' ||
        'REABIERTO' => open,
        'ATENDIDO' || 'RESUELTO' => attended,
        'CERRADO' => closed,
        'CANCELADO' => cancelled,
        _ => null,
      };

  /// Falta atenderlo: el SLA corre.
  bool get pending => this == unvalidated || this == open;
}

/// Lo que el usuario puede hacer hoy con un ticket. Lo decide el servidor
/// (`actions` del ticket, segun su estado, el perfil y el equipo): la app solo
/// muestra esas.
enum TicketAction {
  edit('EDITAR'),
  assign('ASIGNAR'),
  reassign('REASIGNAR'),
  followUp('SEGUIMIENTO'),
  attend('ATENDER'),
  close('CERRAR'),
  returnToOpen('REGRESAR'),
  reopen('REABRIR'),
  cancel('CANCELAR');

  const TicketAction(this.code);

  final String code;

  static TicketAction? fromCode(String? code) {
    final c = code?.trim().toUpperCase();
    for (final a in values) {
      if (a.code == c) return a;
    }
    return null;
  }
}

/// La prioridad con la que se levanta un ticket; `code` es el del catalogo
/// PRIORIDAD del servidor.
enum TicketPriority {
  low('BAJA'),
  medium('MEDIA'),
  high('ALTA'),
  critical('CRITICA');

  const TicketPriority(this.code);

  final String code;
}

/// Una anotacion de seguimiento: lo que se hizo, en que estado quedo el ticket
/// y las fotos de evidencia.
class TicketFollowUp extends Equatable {
  const TicketFollowUp({
    required this.id,
    required this.at,
    required this.status,
    required this.description,
    this.photoPaths = const [],
  });

  final String id;

  /// Cuando ocurrio, en UTC.
  final DateTime at;
  final TicketStatus status;
  final String description;

  /// Rutas locales de las fotos.
  final List<String> photoPaths;

  TicketFollowUp withPhotos(List<String> photoPaths) => TicketFollowUp(
    id: id,
    at: at,
    status: status,
    description: description,
    photoPaths: photoPaths,
  );

  @override
  List<Object?> get props => [id, at, status, description, photoPaths];
}

/// Un ticket de la concesion: un dano o una necesidad en la carretera que hay
/// que atender antes de su vencimiento.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.category,
    this.dueAt,
    this.authorName,
    this.authorProfile,
    this.company,
    this.concessionName,
    this.kmLabel,
    this.latitude,
    this.longitude,
    this.carriageway,
    this.photoPaths = const [],
    this.followUps = const [],
    this._stage,
    this.actions,
    this.rowVersion,
    this.assignedCompanyId,
    this.assignedCompanyName,
    this.assignedTeamId,
    this.assignedTeamName,
    this.responsibleName,
    this.cancelReason,
    this.duplicateOfFolio,
    this.closingAssetCondition,
    this.assetId,
  });

  final String id;

  /// El numero que se ve y se dicta (`0035`).
  final String code;
  final String title;
  final TicketStatus status;

  /// Cuando se levanto, en UTC.
  final DateTime createdAt;
  final String? description;

  /// Tipo de ticket tal como lo entrega el catalogo.
  final String? category;

  /// Limite para atenderlo, en UTC.
  final DateTime? dueAt;
  final String? authorName;
  final String? authorProfile;
  final String? company;
  final String? concessionName;

  /// Cadenamiento tal como lo muestra el negocio (`KM 513+615`).
  final String? kmLabel;
  final double? latitude;
  final double? longitude;

  /// Cuerpo de la carretera (`A`, `B`).
  final String? carriageway;
  final List<String> photoPaths;
  final List<TicketFollowUp> followUps;

  final TicketStage? _stage;

  /// El estado del DTF M11 v0.3. Si el servidor no lo dijo (datos de ejemplo o
  /// capturados sin red), sale de [status].
  TicketStage get stage =>
      _stage ??
      (status == TicketStatus.open ? TicketStage.open : TicketStage.attended);

  /// Lo que el usuario puede hacer hoy segun el servidor; null si no lo dijo
  /// (datos de ejemplo o capturados sin red).
  final Set<TicketAction>? actions;

  /// Version del registro: el servidor la pide para no pisar un cambio ajeno.
  final int? rowVersion;

  /// A quien esta asignado: empresa y equipo (RB-11-09).
  final String? assignedCompanyId;
  final String? assignedCompanyName;
  final String? assignedTeamId;
  final String? assignedTeamName;

  /// La persona de referencia del equipo, si se eligio.
  final String? responsibleName;

  /// Por que se cancelo (DUPLICADO, IMPROCEDENTE u OTRO) y, si es duplicado,
  /// el folio del original.
  final String? cancelReason;
  final String? duplicateOfFolio;

  /// La condicion del activo que dejo el Supervisor al cerrar.
  final String? closingAssetCondition;

  /// El activo del inventario al que se refiere; sin el, cerrar no pide la
  /// condicion (el servidor solo la guarda con activo).
  final String? assetId;

  /// El servidor ofrece [action] para este ticket.
  bool offers(TicketAction action) => actions?.contains(action) ?? false;

  /// Se puede dar seguimiento: lo dice el servidor o, si no dijo nada, si.
  bool get offersFollowUp => actions == null || offers(TicketAction.followUp);

  /// Cuanto falta para el vencimiento (negativo si ya vencio).
  Duration? timeToDue(DateTime now) => dueAt?.difference(now);

  /// Texto para buscar: titulo, numero, cadenamiento y tipo.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      code,
      kmLabel,
      category,
      description,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  Ticket copyWith({
    TicketStatus? status,
    List<TicketFollowUp>? followUps,
    List<String>? photoPaths,
    TicketStage? stage,
    Set<TicketAction>? actions,
    int? rowVersion,
    String? assignedCompanyId,
    String? assignedCompanyName,
    String? assignedTeamId,
    String? assignedTeamName,
    String? cancelReason,
    String? duplicateOfFolio,
    String? closingAssetCondition,
  }) => Ticket(
    id: id,
    code: code,
    title: title,
    status: status ?? this.status,
    createdAt: createdAt,
    description: description,
    category: category,
    dueAt: dueAt,
    authorName: authorName,
    authorProfile: authorProfile,
    company: company,
    concessionName: concessionName,
    kmLabel: kmLabel,
    latitude: latitude,
    longitude: longitude,
    carriageway: carriageway,
    photoPaths: photoPaths ?? this.photoPaths,
    followUps: followUps ?? this.followUps,
    stage: stage ?? _stage,
    actions: actions ?? this.actions,
    rowVersion: rowVersion ?? this.rowVersion,
    assignedCompanyId: assignedCompanyId ?? this.assignedCompanyId,
    assignedCompanyName: assignedCompanyName ?? this.assignedCompanyName,
    assignedTeamId: assignedTeamId ?? this.assignedTeamId,
    assignedTeamName: assignedTeamName ?? this.assignedTeamName,
    responsibleName: responsibleName,
    cancelReason: cancelReason ?? this.cancelReason,
    duplicateOfFolio: duplicateOfFolio ?? this.duplicateOfFolio,
    closingAssetCondition: closingAssetCondition ?? this.closingAssetCondition,
    assetId: assetId,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    status,
    createdAt,
    description,
    category,
    dueAt,
    authorName,
    authorProfile,
    company,
    concessionName,
    kmLabel,
    latitude,
    longitude,
    carriageway,
    photoPaths,
    followUps,
    _stage,
    actions,
    rowVersion,
    assignedCompanyId,
    assignedCompanyName,
    assignedTeamId,
    assignedTeamName,
    responsibleName,
    cancelReason,
    duplicateOfFolio,
    closingAssetCondition,
    assetId,
  ];
}

/// Lo que la persona captura para dar seguimiento a un ticket.
class NewFollowUp extends Equatable {
  const NewFollowUp({
    required this.at,
    required this.status,
    required this.description,
    this.photoPaths = const [],
  });

  /// Fecha y hora elegidas, en UTC.
  final DateTime at;
  final TicketStatus status;
  final String description;
  final List<String> photoPaths;

  @override
  List<Object?> get props => [at, status, description, photoPaths];
}

/// De donde salio la ubicacion de un registro (DTF M10, RB-10-22).
enum TicketLocationOrigin {
  /// Lectura reciente del GPS.
  gps,

  /// La ultima posicion conocida, no una lectura actual: se marca como tal.
  lastKnown,

  /// Un punto que la persona eligio en el mapa.
  mapPoint,

  /// La del activo seleccionado.
  asset,
}

/// Lo que puede estar mal con una ubicacion antes de guardarla.
enum TicketLocationIssue { lowAccuracy, lastKnown }

/// La ubicacion de un registro: donde, que tan confiable es y de donde salio.
class TicketLocation extends Equatable {
  const TicketLocation({
    required this.latitude,
    required this.longitude,
    required this.origin,
    this.accuracyMeters,
    this.readAt,
    this.assetId,
    this.kmLabel,
  });

  final double latitude;
  final double longitude;
  final TicketLocationOrigin origin;

  /// Radio de incertidumbre en metros; null si no se conoce (un punto elegido
  /// o un activo no tienen precision de lectura).
  final double? accuracyMeters;

  /// Cuando se leyo, en UTC.
  final DateTime? readAt;

  /// El activo del inventario al que se refiere, si se levanta desde su ficha.
  final String? assetId;
  final String? kmLabel;

  /// Lo que hay que avisar antes de guardar: una posicion vieja o una precision
  /// peor que [minAccuracyMeters]. Null si la ubicacion es confiable.
  TicketLocationIssue? issue(double minAccuracyMeters) {
    if (origin == TicketLocationOrigin.lastKnown) {
      return TicketLocationIssue.lastKnown;
    }
    final accuracy = accuracyMeters;
    if (origin == TicketLocationOrigin.gps &&
        accuracy != null &&
        accuracy > minAccuracyMeters) {
      return TicketLocationIssue.lowAccuracy;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    origin,
    accuracyMeters,
    readAt,
    assetId,
    kmLabel,
  ];
}

/// El activo del inventario sobre el que se levanta el ticket, cuando se hace
/// desde su ficha: puede no tener punto; el servidor toma de el la carretera,
/// el km, el sentido y la geometria (`assetId`).
class TicketAssetRef extends Equatable {
  const TicketAssetRef({
    required this.id,
    this.code,
    this.kmLabel,
    this.kmEndLabel,
    this.subsystemCode,
  });

  final String id;

  /// El codigo que ve el negocio (`DEFENSA-000001`); sin el se muestra [id].
  final String? code;

  /// Donde esta (`KM 150+200`) y, si ocupa un tramo, donde termina.
  final String? kmLabel;
  final String? kmEndLabel;

  /// Su indicador (`SGS`): se propone en la Matriz de falhas.
  final String? subsystemCode;

  String get label => code ?? id;

  @override
  List<Object?> get props => [id, code, kmLabel, kmEndLabel, subsystemCode];
}

/// Lo que la persona captura para levantar un ticket nuevo.
/// Una falla de la Matriz de falhas (reunion con TEKIA del 05/11/2026): el
/// ticket se levanta eligiendo indicador, subclasificacion y falla, y el plazo
/// de atencion sale de ella (fijo, 24x7).
class TicketFailure extends Equatable {
  const TicketFailure({
    required this.code,
    required this.label,
    required this.subsystemCode,
    required this.group,
    required this.attentionHours,
    this.attentionLabel,
  });

  /// El codigo del tipo de ticket en el servidor.
  final String code;
  final String label;

  /// El indicador (SGP, SGS...).
  final String subsystemCode;

  /// La subclasificacion de la Matriz.
  final String group;

  /// El plazo en horas corridas.
  final double attentionHours;

  /// El plazo como lo escribe la Matriz ("30 dias", "Imediato").
  final String? attentionLabel;

  /// "Imediato" o una cantidad de dias, para mostrarlo.
  bool get immediate {
    final l = attentionLabel?.trim().toLowerCase() ?? '';
    return l.startsWith('imediat') || l.startsWith('inmediat');
  }

  /// Los dias del plazo si es un numero entero de dias; si no, null.
  int? get days =>
      attentionHours >= 24 && attentionHours % 24 == 0 && !immediate
      ? attentionHours ~/ 24
      : null;

  @override
  List<Object?> get props => [
    code,
    label,
    subsystemCode,
    group,
    attentionHours,
    attentionLabel,
  ];
}

/// Una carretera de la concesion activa, para elegir donde se levanta un
/// ticket sin punto ni activo cuando la concesion tiene varias.
class TicketRoad extends Equatable {
  const TicketRoad({required this.id, required this.code, this.name});

  final String id;

  /// `BR-381`.
  final String code;
  final String? name;

  @override
  List<Object?> get props => [id, code, name];
}

class NewTicket extends Equatable {
  const NewTicket({
    required this.title,
    required this.category,
    this.priority = TicketPriority.medium,
    this.kmLabel,
    this.description,
    this.photoPaths = const [],
    this.capturedAt,
    this.deviceClockAt,
    this.location,
    this.clientId,
    this.fixedAttention = false,
    this.direction,
    this.kmEndLabel,
    this.assetId,
    this.roadId,
  });

  /// El activo, si se levanta desde su ficha aunque no tenga punto (si viene
  /// del mapa, va en [location]).
  final String? assetId;

  /// La carretera elegida en el formulario (sin punto ni activo, cuando la
  /// concesion tiene varias); null = la de la concesion o la del punto.
  final String? roadId;

  /// El km final, si la falla ocupa un tramo (`KM 150+400`).
  final String? kmEndLabel;

  /// El sentido (CRECIENTE o DECRECIENTE) cuando el punto lo dice; null si no.
  final String? direction;

  /// La categoria es una falla de la Matriz: el plazo es fijo y la prioridad la
  /// calcula el servidor, asi que no se manda.
  final bool fixedAttention;

  final String title;
  final String category;
  final TicketPriority priority;
  final String? kmLabel;
  final String? description;
  final List<String> photoPaths;

  /// Cuando se abrio el formulario, en UTC (RN-12 y RN-14): no depende de la
  /// zona del telefono. Es la hora del registro.
  final DateTime? capturedAt;

  /// La hora del reloj del telefono al enviar, en UTC (RN-15): el servidor la
  /// compara con la suya para corregir un reloj desfasado.
  final DateTime? deviceClockAt;

  /// Donde se levanta, si se hizo desde el mapa o desde un activo.
  final TicketLocation? location;

  /// Identificador unico que genera el telefono (`cliente_uuid`): evita
  /// duplicados si el registro se sincroniza dos veces.
  final String? clientId;

  @override
  List<Object?> get props => [
    title,
    category,
    priority,
    kmLabel,
    description,
    photoPaths,
    capturedAt,
    deviceClockAt,
    location,
    clientId,
    fixedAttention,
    direction,
    kmEndLabel,
    assetId,
    roadId,
  ];
}

/// Donde cae el punto del ticket sobre la carretera (`/api/road-network/locate`).
enum TicketPlacementStatus {
  /// Dentro de la tolerancia: trae km, sentido y tramo.
  onRoad,

  /// Lejos de la carretera: el servidor rechaza el ticket.
  offRoad,

  /// Sin red o sin eje cargado: no se puede saber, el servidor lo revisa.
  unknown,
}

class TicketPlacement extends Equatable {
  const TicketPlacement({
    required this.status,
    this.km,
    this.direction,
    this.segmentCode,
    this.distanceMeters,
    this.directionAmbiguous = false,
  });

  const TicketPlacement.unknown() : this(status: TicketPlacementStatus.unknown);

  const TicketPlacement.offRoad() : this(status: TicketPlacementStatus.offRoad);

  final TicketPlacementStatus status;
  final double? km;
  final String? direction;
  final String? segmentCode;
  final double? distanceMeters;

  /// Los dos sentidos comparten trazo: el punto no dice el sentido.
  final bool directionAmbiguous;

  @override
  List<Object?> get props => [
    status,
    km,
    direction,
    segmentCode,
    distanceMeters,
    directionAmbiguous,
  ];
}
