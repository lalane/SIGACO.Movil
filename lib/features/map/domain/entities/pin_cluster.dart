import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'geo_point.dart';
import 'map_pin.dart';

/// Lo que se dibuja en el mapa: un pin solo o un grupo de pines cercanos.
sealed class MapMarkerItem extends Equatable {
  const MapMarkerItem();

  GeoPoint get position;
}

class SinglePin extends MapMarkerItem {
  const SinglePin(this.pin);

  final MapPin pin;

  @override
  GeoPoint get position => pin.position;

  @override
  List<Object?> get props => [pin];
}

/// Varios pines tan juntos, a este zoom, que se taparian entre si.
class PinCluster extends MapMarkerItem {
  const PinCluster(this.pins, this.position);

  final List<MapPin> pins;

  /// El centro de los pines del grupo.
  @override
  final GeoPoint position;

  int get count => pins.length;

  /// El estado mas grave del grupo: un grupo con un critico se ve critico.
  PinStatus get status =>
      pins.map((p) => p.status).reduce((a, b) => a.index >= b.index ? a : b);

  /// Identificador estable: no cambia mientras el grupo tenga los mismos pines.
  String get key => pins.map((p) => p.id).join('|');

  @override
  List<Object?> get props => [pins, position];
}

/// Zoom a partir del cual ya no se agrupa (cada pin sale solo).
const defaultClusterMaxZoom = 17.0;

/// Agrupa los [pins] que, al [zoom] dado, quedan a menos de [radiusPx] pixeles
/// uno de otro. Usa una cuadricula sobre la proyeccion Web Mercator (la de los
/// mapas de teselas), asi que el resultado es el mismo en cualquier telefono.
///
/// * [radiusPx] `<= 0` o [zoom] `>= maxZoom`: no se agrupa nada.
/// * [keepSingleId]: ese pin sale siempre solo (el seleccionado no se esconde
///   dentro de un grupo).
/// * El orden de entrada no cambia el resultado.
List<MapMarkerItem> clusterPins(
  Iterable<MapPin> pins, {
  required double zoom,
  double radiusPx = 56,
  double maxZoom = defaultClusterMaxZoom,
  String? keepSingleId,
}) {
  final sorted = [
    for (final p in pins)
      if (p.position.isValid) p,
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (radiusPx <= 0 || zoom >= maxZoom) {
    return [for (final p in sorted) SinglePin(p)];
  }
  final scale = 256 * math.pow(2, zoom);
  final cells = <(int, int), List<MapPin>>{};
  final result = <MapMarkerItem>[];
  for (final p in sorted) {
    if (p.id == keepSingleId) {
      result.add(SinglePin(p));
      continue;
    }
    final x = (p.position.longitude + 180) / 360 * scale;
    final lat =
        p.position.latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    final y =
        (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * scale;
    cells
        .putIfAbsent(((x / radiusPx).floor(), (y / radiusPx).floor()), () => [])
        .add(p);
  }
  for (final group in cells.values) {
    if (group.length == 1) {
      result.add(SinglePin(group.first));
    } else {
      final lat =
          group.map((p) => p.position.latitude).reduce((a, b) => a + b) /
          group.length;
      final lon =
          group.map((p) => p.position.longitude).reduce((a, b) => a + b) /
          group.length;
      result.add(PinCluster(group, GeoPoint(lat, lon)));
    }
  }
  return result;
}
