import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'geo_point.dart';

/// Hacia donde corre un tramo: el mismo codigo de tramo existe una vez por
/// sentido y son tramos distintos (clave codigo + sentido).
enum TravelDirection { increasing, decreasing }

/// Un tramo de la carretera dibujado como linea: su codigo, su sentido, los
/// kilometros que cubre y la trayectoria. La geometria la entrega el servidor
/// (todavia no se define de que sistema sale: WebGIS, SGP o SIGACO).
class RoadSegment extends Equatable {
  const RoadSegment({
    required this.id,
    required this.code,
    required this.direction,
    required this.points,
    this.name,
    this.startKmLabel,
    this.endKmLabel,
  });

  final String id;

  /// Codigo del tramo tal como lo maneja el negocio (por ejemplo `381BMG0160`).
  final String code;
  final TravelDirection direction;

  /// Nombre legible, si el servidor lo trae.
  final String? name;

  /// Referencias kilometricas tal como las muestra el negocio (`KM 146+900`).
  final String? startKmLabel;
  final String? endKmLabel;

  /// La trayectoria, en el orden en que se recorre el tramo.
  final List<GeoPoint> points;

  /// Se puede dibujar: hace falta una linea de al menos dos puntos validos.
  bool get isDrawable => points.length >= 2 && points.every((p) => p.isValid);

  @override
  List<Object?> get props => [
    id,
    code,
    direction,
    name,
    startKmLabel,
    endKmLabel,
    points,
  ];
}

/// Los tramos de la concesion. Si [cachedAt] no es null, no vienen del
/// servidor: son los ultimos que se pudieron consultar, guardados en el
/// telefono en ese momento.
class SegmentListing extends ListBase<RoadSegment> {
  SegmentListing(List<RoadSegment> segments, {this.cachedAt})
    : _segments = List.unmodifiable(segments);

  final List<RoadSegment> _segments;

  /// UTC.
  final DateTime? cachedAt;

  @override
  int get length => _segments.length;

  @override
  set length(int value) =>
      throw UnsupportedError('SegmentListing es de lectura');

  @override
  RoadSegment operator [](int index) => _segments[index];

  @override
  void operator []=(int index, RoadSegment value) =>
      throw UnsupportedError('SegmentListing es de lectura');
}
