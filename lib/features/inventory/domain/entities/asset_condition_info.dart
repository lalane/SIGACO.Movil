import 'package:equatable/equatable.dart';

/// La condicion del activo en la ficha (DTF M13 Parte 2, HU-MOB-13-05): de
/// donde salio, cuando se ejecuto, si su tipo la lleva y las marcas que avisan
/// en campo (hallazgos abiertos, no localizado). Llega con el detalle del
/// servidor (`condition` y `marks`); un servidor anterior no la manda.
class AssetConditionInfo extends Equatable {
  const AssetConditionInfo({
    this.applies = true,
    this.nativeValue,
    this.source,
    this.sourceRef,
    this.executedAt,
    this.cycle,
    this.openFindings = 0,
    this.notLocatedAt,
    this.notLocatedNote,
    this.nextInspectionOn,
  });

  /// Su tipo lleva condicion fisica; si no, "No aplica".
  final bool applies;

  /// El valor en la escala de la plantilla (Precario, nota 3...).
  final String? nativeValue;

  /// WEBGIS, INSPECCION, MANUAL, TICKET, MANTENIMIENTO o CARGA_INICIAL.
  final String? source;

  /// El folio o la capa de la que salio.
  final String? sourceRef;

  /// Fecha de ejecucion de la condicion vigente (UTC).
  final DateTime? executedAt;

  /// Ano de concesion de esa fecha.
  final int? cycle;

  final int openFindings;

  /// Una inspeccion lo reporto "no localizado en campo".
  final DateTime? notLocatedAt;
  final String? notLocatedNote;

  /// Proxima inspeccion programada (dia).
  final DateTime? nextInspectionOn;

  bool get notLocated => notLocatedAt != null;

  @override
  List<Object?> get props => [
    applies,
    nativeValue,
    source,
    sourceRef,
    executedAt,
    cycle,
    openFindings,
    notLocatedAt,
    notLocatedNote,
    nextInspectionOn,
  ];
}
