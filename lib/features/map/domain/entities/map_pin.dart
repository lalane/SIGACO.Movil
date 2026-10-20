import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'geo_point.dart';
import 'road_segment.dart';

/// Las cuatro pestanas del mapa (MQ-MOB de la sesion del 14/10/2026).
enum MapLayer { tickets, inventory, maintenance, works }

/// Cuanta atencion pide un elemento; el color sale de aqui, no del modulo
/// (los colores de estatus son del sistema, COL-05).
enum PinStatus { normal, attention, critical }

/// Estado operativo de un equipo (DTF M10, pantalla 4.2). Es distinto de la
/// atencion que pide ([PinStatus]): un equipo fuera de servicio puede estar
/// "normal" para el negocio si esta programado.
enum OperatingState { inOperation, inMaintenance, outOfService }

/// Un elemento dibujado en el mapa: un ticket, un activo, un mantenimiento o
/// una obra. Lo que el servidor entrega para el mapa, sin mas detalle: la ficha
/// completa es del modulo de cada uno.
class MapPin extends Equatable {
  const MapPin({
    required this.id,
    required this.layer,
    required this.title,
    required this.position,
    this.subtitle,
    this.category,
    this.kmLabel,
    this.segmentCode,
    this.direction,
    this.status = PinStatus.normal,
    this.operatingState,
  });

  final String id;
  final MapLayer layer;
  final String title;
  final String? subtitle;

  /// Nombre de la categoria tal como lo entrega el servidor (tipo de activo,
  /// tipo de ticket...). Es lo que filtra la pestana y lo que se muestra.
  final String? category;

  /// Referencia kilometrica tal como la muestra el negocio (`KM 150+200`).
  final String? kmLabel;

  /// El tramo en el que esta el elemento y su sentido. Junto con el kilometro
  /// son los datos con los que el negocio ubica un ticket o un activo; el pin
  /// cae sobre la linea de ese tramo. Null si el servidor no los trae.
  final String? segmentCode;
  final TravelDirection? direction;
  final PinStatus status;

  /// Solo los equipos lo traen; null en tickets, obras o mantenimientos.
  final OperatingState? operatingState;
  final GeoPoint position;

  @override
  List<Object?> get props => [
    id,
    layer,
    title,
    subtitle,
    category,
    kmLabel,
    segmentCode,
    direction,
    status,
    operatingState,
    position,
  ];
}

/// Los pines de una pestana. Si [cachedAt] no es null, no vienen del servidor:
/// son los ultimos que se pudieron consultar, guardados en el telefono en ese
/// momento (el mapa tambien se ve sin conexion).
class PinListing extends ListBase<MapPin> {
  PinListing(List<MapPin> pins, {this.cachedAt})
    : _pins = List.unmodifiable(pins);

  final List<MapPin> _pins;

  /// UTC.
  final DateTime? cachedAt;

  @override
  int get length => _pins.length;

  @override
  set length(int value) => throw UnsupportedError('PinListing es de lectura');

  @override
  MapPin operator [](int index) => _pins[index];

  @override
  void operator []=(int index, MapPin value) =>
      throw UnsupportedError('PinListing es de lectura');
}
