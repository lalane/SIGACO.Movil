import 'package:equatable/equatable.dart';

import 'asset_condition_info.dart';
import 'asset_history.dart';
import 'asset_template.dart';

/// Como esta el activo (estado fisico, de la ultima inspeccion). `unknown` es
/// un activo que aun no se evalua: va al final al ordenar y no cuenta entre
/// los estados del resumen.
enum AssetCondition {
  unknown,
  good,
  regular,
  poor;

  /// Los estados que se resumen y se pueden elegir como filtro.
  static const assessed = [good, regular, poor];
}

/// El estado del activo en el inventario (contrato de Activos, 08/11/2026). "En
/// mantenimiento" ya no es un estado: sale de tener un ticket abierto
/// ([InventoryAsset.inMaintenance]).
enum AssetLifecycle {
  /// Nacio en la app (o en la web sobre un tipo con capas) y espera que alguien
  /// lo enlace con su elemento del WebGIS o lo apruebe.
  pendingValidation('PENDIENTE_VALIDACION'),
  active('ACTIVO'),
  outOfService('FUERA_SERVICIO'),
  inactive('INACTIVO'),
  decommissioned('BAJA'),
  discarded('DESCARTADO');

  const AssetLifecycle(this.code);

  /// El codigo del servidor.
  final String code;

  /// El estado de un codigo del servidor; null si no se conoce.
  /// `EN_MANTENIMIENTO` (servidor anterior al contrato) es un activo en uso.
  static AssetLifecycle? fromCode(String? code) {
    final c = code?.trim().toUpperCase();
    if (c == 'EN_MANTENIMIENTO') return active;
    for (final s in values) {
      if (s.code == c) return s;
    }
    return null;
  }
}

/// Un activo de la carretera (senal, defensa, drenaje, obra de arte...). La app
/// lo consulta y lo da de alta en campo; validarlo, editarlo o darlo de baja es
/// de la plataforma web (M13).
class InventoryAsset extends Equatable {
  const InventoryAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    this.kmLabel,
    this.segmentCode,
    this.direction,
    this.latitude,
    this.longitude,
    this.installedAt,
    this.lastInspectionAt,
    this.notes,
    this.code,
    this.mainPhotoId,
    this.typeCode,
    this.subsystemCode,
    this.roadCode,
    this.lifecycle,
    this.statusReason,
    this.inMaintenance = false,
    this.openTicketCount,
    this.source,
    this.externalLayerCode,
    this.externalId,
    this.description,
    this.brand,
    this.model,
    this.serialNumber,
    this.usefulLifeMonths,
    this.attributes = const {},
    this.externalAttributes,
    this.template,
    this.templateNumber,
    this.attachmentCount,
    this.pendingSync = false,
    this.history,
    this.conditionInfo,
  });

  /// Identificador del servidor (es el de las rutas y el del mapa). En un
  /// activo capturado sin conexion que aun no sale del telefono, su
  /// identificador de captura.
  final String id;

  /// Codigo que ve el negocio (`BARRERA-000001`); sin el se muestra [id].
  final String? code;
  final String name;

  /// La foto principal del activo ("vista en sitio"), si la tiene.
  final String? mainPhotoId;

  /// Tipo de activo tal como lo entrega el servidor (`Defensa metálica`).
  final String category;

  /// El codigo del tipo (`DEFENSA`): con el se pide su ficha.
  final String? typeCode;
  final String? subsystemCode;
  final String? roadCode;
  final AssetCondition condition;

  /// El estado en el inventario; null si el servidor no lo dio.
  final AssetLifecycle? lifecycle;

  /// Por que quedo inactivo (`CAPA_RETIRADA`, `DESAPARECIO_DEL_ORIGEN`).
  final String? statusReason;

  /// Tiene algun ticket abierto: se muestra "En mantenimiento" junto al estado.
  final bool inMaintenance;
  final int? openTicketCount;

  /// De donde nacio (`MOVIL`, `INDIVIDUAL`, `MASIVA`, `WEBGIS`...).
  final String? source;

  /// La capa y el elemento del WebGIS de los que nacio, si nacio ahi.
  final String? externalLayerCode;
  final String? externalId;

  /// Referencia kilometrica tal como la muestra el negocio (`KM 150+200`).
  final String? kmLabel;
  final String? segmentCode;

  /// Sentido de la carretera, tal como lo entrega el servidor.
  final String? direction;

  /// Donde esta; sin ella no se puede abrir en el mapa.
  final double? latitude;
  final double? longitude;

  /// Fechas, en UTC.
  final DateTime? installedAt;
  final DateTime? lastInspectionAt;
  final String? notes;

  /// Datos de gestion (columnas del activo, no de la ficha).
  final String? description;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final int? usefulLifeMonths;

  /// Los campos de la ficha: clave -> valor tal como lo guarda el servidor.
  final Map<String, Object?> attributes;

  /// Las columnas crudas del elemento del WebGIS ("Datos del WebGIS", solo
  /// lectura); null si no nacio ahi o el servidor no las da.
  final Map<String, Object?>? externalAttributes;

  /// La ficha con la que se valido; null si el servidor no la manda con el
  /// activo (se pide aparte).
  final AssetTemplate? template;
  final int? templateNumber;
  final int? attachmentCount;

  /// Capturado en el telefono sin conexion: espera salir al servidor.
  final bool pendingSync;

  /// Cuantos tickets, inspecciones y mantenimientos tiene (`operationalHistory`
  /// de la ficha); null si el servidor no los da: no se muestra la historia.
  final AssetHistoryCounts? history;

  /// La condicion con su origen y las marcas de campo (M13 Parte 2); null si
  /// el servidor no la da.
  final AssetConditionInfo? conditionInfo;

  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;

  /// Nacio de una capa del WebGIS: su ubicacion y sus campos de capa no se
  /// editan.
  bool get fromWebGis => externalLayerCode != null;

  /// Texto para buscar: nombre, tipo, codigo, tramo y kilometro (la ubicacion).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      id,
      code,
      name,
      category,
      segmentCode,
      kmLabel,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  /// El mismo activo con la ficha que se pidio aparte.
  InventoryAsset withTemplate(AssetTemplate? template) => template == null
      ? this
      : InventoryAsset(
          id: id,
          name: name,
          category: category,
          condition: condition,
          kmLabel: kmLabel,
          segmentCode: segmentCode,
          direction: direction,
          latitude: latitude,
          longitude: longitude,
          installedAt: installedAt,
          lastInspectionAt: lastInspectionAt,
          notes: notes,
          code: code,
          mainPhotoId: mainPhotoId,
          typeCode: typeCode,
          subsystemCode: subsystemCode,
          roadCode: roadCode,
          lifecycle: lifecycle,
          statusReason: statusReason,
          inMaintenance: inMaintenance,
          openTicketCount: openTicketCount,
          source: source,
          externalLayerCode: externalLayerCode,
          externalId: externalId,
          description: description,
          brand: brand,
          model: model,
          serialNumber: serialNumber,
          usefulLifeMonths: usefulLifeMonths,
          attributes: attributes,
          externalAttributes: externalAttributes,
          template: template,
          templateNumber: templateNumber,
          attachmentCount: attachmentCount,
          pendingSync: pendingSync,
          history: history,
          conditionInfo: conditionInfo,
        );

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    condition,
    kmLabel,
    segmentCode,
    direction,
    latitude,
    longitude,
    installedAt,
    lastInspectionAt,
    notes,
    code,
    mainPhotoId,
    typeCode,
    subsystemCode,
    roadCode,
    lifecycle,
    statusReason,
    inMaintenance,
    openTicketCount,
    source,
    externalLayerCode,
    externalId,
    description,
    brand,
    model,
    serialNumber,
    usefulLifeMonths,
    attributes,
    externalAttributes,
    template,
    templateNumber,
    attachmentCount,
    pendingSync,
    history,
    conditionInfo,
  ];
}
