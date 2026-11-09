import 'package:equatable/equatable.dart';

/// Canal por el que nace un activo dado de alta en la app.
const mobileBirthChannel = 'MOBILE';

/// Un tipo de activo que se puede elegir al dar de alta en campo
/// (`/api/catalogs/asset-types`).
class AssetTypeOption extends Equatable {
  const AssetTypeOption({
    required this.code,
    required this.labelEs,
    this.labelPt,
    this.subsystemCode,
    this.geometryType,
    this.requiresKmEnd = false,
    this.birthChannels,
    this.sortOrder = 0,
  });

  final String code;
  final String labelEs;
  final String? labelPt;
  final String? subsystemCode;

  /// `POINT`, `LINESTRING`/`LINE` o `POLYGON`; null, cualquiera.
  final String? geometryType;

  /// Se ubica por rango: pide el km final.
  final bool requiresKmEnd;

  /// Por donde puede nacer; null si el servidor aun no lo dice (todos).
  final List<String>? birthChannels;
  final int sortOrder;

  String label(String language) =>
      language == 'pt' && (labelPt?.trim().isNotEmpty ?? false)
      ? labelPt!
      : labelEs;

  /// El punto del GPS sirve como su geometria (un tipo de linea o poligono se
  /// ubica solo por km).
  bool get acceptsPoint {
    final g = geometryType?.trim().toUpperCase();
    return g == null || g.isEmpty || g == 'POINT';
  }

  /// Puede nacer por [channel]; sin la lista, si.
  bool allows(String channel) =>
      birthChannels == null || birthChannels!.contains(channel);

  @override
  List<Object?> get props => [
    code,
    labelEs,
    labelPt,
    subsystemCode,
    geometryType,
    requiresKmEnd,
    birthChannels,
    sortOrder,
  ];
}

/// Un valor de un catalogo generico (los campos CATALOG de la ficha).
class CatalogOption extends Equatable {
  const CatalogOption({
    required this.code,
    required this.labelEs,
    this.labelPt,
  });

  final String code;
  final String labelEs;
  final String? labelPt;

  String label(String language) =>
      language == 'pt' && (labelPt?.trim().isNotEmpty ?? false)
      ? labelPt!
      : labelEs;

  @override
  List<Object?> get props => [code, labelEs, labelPt];
}

/// La posicion del telefono al capturar (GPS).
class AssetPosition extends Equatable {
  const AssetPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.readAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  /// UTC.
  final DateTime? readAt;

  @override
  List<Object?> get props => [latitude, longitude, accuracyMeters, readAt];
}

/// Donde cae el punto sobre la carretera.
enum RoadPlacementStatus {
  /// Se ubico: hay carretera, km y sentido.
  onRoad,

  /// El punto queda lejos del eje.
  offRoad,

  /// No se pudo saber (sin red, sin eje cargado...).
  unknown,
}

/// Lo que dice `/api/road-network/locate` de un punto.
class RoadPlacement extends Equatable {
  const RoadPlacement({
    required this.status,
    this.roadId,
    this.roadCode,
    this.direction,
    this.km,
    this.segmentId,
    this.segmentCode,
    this.distanceMeters,
    this.directionAmbiguous = false,
  });

  const RoadPlacement.offRoad() : this(status: RoadPlacementStatus.offRoad);

  const RoadPlacement.unknown() : this(status: RoadPlacementStatus.unknown);

  final RoadPlacementStatus status;
  final String? roadId;
  final String? roadCode;

  /// `CRECIENTE` o `DECRECIENTE`.
  final String? direction;
  final double? km;
  final String? segmentId;
  final String? segmentCode;
  final double? distanceMeters;

  /// Los dos sentidos comparten trazo aqui: la persona elige.
  final bool directionAmbiguous;

  @override
  List<Object?> get props => [
    status,
    roadId,
    roadCode,
    direction,
    km,
    segmentId,
    segmentCode,
    distanceMeters,
    directionAmbiguous,
  ];
}

/// Un activo capturado en campo, listo para enviarse.
class NewAsset extends Equatable {
  const NewAsset({
    required this.clientId,
    required this.typeCode,
    required this.capturedAt,
    this.roadId,
    this.kmStart,
    this.kmEnd,
    this.direction,
    this.position,
    this.sendPoint = true,
    this.attributes = const {},
    this.description,
    this.notes,
    this.photoPaths = const [],
    this.typeLabel,
  });

  /// Identificador de captura (`clientUuid`): repetir el alta devuelve el mismo
  /// activo en el servidor.
  final String clientId;
  final String typeCode;

  /// Para mostrarlo mientras espera en el telefono.
  final String? typeLabel;

  /// UTC.
  final DateTime capturedAt;
  final String? roadId;
  final double? kmStart;
  final double? kmEnd;

  /// `CRECIENTE` o `DECRECIENTE`. El tramo lo calcula el servidor con el km y
  /// el sentido.
  final String? direction;
  final AssetPosition? position;

  /// El punto del GPS va como geometria (solo si el tipo es de punto).
  final bool sendPoint;

  /// Los campos de la ficha ya como los recibe el servidor.
  final Map<String, Object?> attributes;
  final String? description;
  final String? notes;
  final List<String> photoPaths;

  @override
  List<Object?> get props => [
    clientId,
    typeCode,
    typeLabel,
    capturedAt,
    roadId,
    kmStart,
    kmEnd,
    direction,
    position,
    sendPoint,
    attributes,
    description,
    notes,
    photoPaths,
  ];
}

/// Lo que paso con un alta.
class CapturedAsset extends Equatable {
  const CapturedAsset({
    required this.id,
    this.code,
    this.queued = false,
    this.warning,
  });

  /// El del servidor o, si quedo en el telefono, el de captura.
  final String id;
  final String? code;

  /// Sin conexion: quedo en la cola y sale al volver la senal.
  final bool queued;

  /// Se guardo, pero falto algo (por ejemplo las fotos): lo que dijo el
  /// servidor.
  final String? warning;

  @override
  List<Object?> get props => [id, code, queued, warning];
}
