import 'package:equatable/equatable.dart';

/// Nivel del pavimento de un tramo con los umbrales del servidor (provisionales
/// hasta que se defina la fuente del cumplimiento PER, DTF M10 P14).
enum PavementLevel { good, fair, bad }

/// El estado del pavimento de un tramo en el indicador mostrado (DTF M10
/// HU-MOB-10-01: al elegir pavimento se pinta el tramo medido).
class SegmentPavement extends Equatable {
  const SegmentPavement({
    required this.segmentId,
    this.level,
    this.average,
    this.samples = 0,
    this.coveragePercent = 0,
  });

  final String segmentId;

  /// Null si el tramo no tiene mediciones en el ciclo.
  final PavementLevel? level;
  final double? average;
  final int samples;

  /// Kilometros del tramo con alguna medicion, en porcentaje.
  final int coveragePercent;

  @override
  List<Object?> get props => [
    segmentId,
    level,
    average,
    samples,
    coveragePercent,
  ];
}

/// La capa de pavimento: un indicador (IRI) en un ciclo de Strata, por tramo.
/// Si [cachedAt] no es null, sale de lo guardado en el telefono (sin conexion).
class PavementLayer extends Equatable {
  const PavementLayer({
    required this.indicator,
    required this.label,
    required this.unit,
    required this.segments,
    this.cycleName,
    this.provisional = true,
    this.cachedAt,
  });

  final String indicator;
  final String label;
  final String unit;

  /// Nombre del ciclo mostrado; null si el indicador no tiene datos.
  final String? cycleName;

  /// Umbrales provisionales: el mapa muestra el estado, no el cumplimiento.
  final bool provisional;
  final Map<String, SegmentPavement> segments;

  /// UTC.
  final DateTime? cachedAt;

  PavementLevel? levelOf(String segmentId) => segments[segmentId]?.level;

  bool get hasData => segments.values.any((s) => s.level != null);

  PavementLayer withCachedAt(DateTime at) => PavementLayer(
    indicator: indicator,
    label: label,
    unit: unit,
    segments: segments,
    cycleName: cycleName,
    provisional: provisional,
    cachedAt: at,
  );

  @override
  List<Object?> get props => [
    indicator,
    label,
    unit,
    cycleName,
    provisional,
    segments,
    cachedAt,
  ];
}
