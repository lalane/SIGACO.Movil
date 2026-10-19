import 'dart:math' as math;

import '../../domain/entities/geo_point.dart';

/// Una linea sobre el mapa con la que se puede medir y recorrer: cuanto mide,
/// el punto a cierta distancia, un pedazo, o la misma linea corrida hacia un
/// lado. Trabaja en un plano local (metros), que sobra para unos kilometros.
/// Es la base de los datos de ejemplo: pone cada pin sobre la linea de su tramo.
class GeoPath {
  GeoPath(List<GeoPoint> points) : points = List.unmodifiable(points) {
    assert(points.length >= 2, 'una linea necesita al menos dos puntos');
    final sums = <double>[0];
    for (var i = 1; i < points.length; i++) {
      sums.add(sums.last + _meters(points[i - 1], points[i]));
    }
    _cumulative = sums;
  }

  final List<GeoPoint> points;
  late final List<double> _cumulative;

  static const _metersPerDegree = 111320.0;

  /// Distancia en metros entre dos puntos cercanos.
  static double _meters(GeoPoint a, GeoPoint b) {
    final cosLat = math.cos((a.latitude + b.latitude) / 2 * math.pi / 180);
    final dx = (b.longitude - a.longitude) * _metersPerDegree * cosLat;
    final dy = (b.latitude - a.latitude) * _metersPerDegree;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Largo total, en metros.
  double get length => _cumulative.last;

  /// El punto a [meters] del inicio (se queda en los extremos si se pasa).
  GeoPoint at(double meters) {
    final m = meters.clamp(0.0, length);
    var i = 1;
    while (i < _cumulative.length - 1 && _cumulative[i] < m) {
      i++;
    }
    final span = _cumulative[i] - _cumulative[i - 1];
    final t = span == 0 ? 0.0 : (m - _cumulative[i - 1]) / span;
    final a = points[i - 1];
    final b = points[i];
    return GeoPoint(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// El pedazo entre [from] y [to] metros, con los extremos interpolados para
  /// que empiece y termine justo donde se pidio.
  List<GeoPoint> slice(double from, double to) {
    final start = from.clamp(0.0, length);
    final end = to.clamp(start, length);
    return [
      at(start),
      for (var i = 0; i < points.length; i++)
        if (_cumulative[i] > start && _cumulative[i] < end) points[i],
      at(end),
    ];
  }

  /// A cuantos metros del inicio esta el punto de la linea mas cercano a [p].
  double nearestMeters(GeoPoint p) {
    final cosLat = math.cos(p.latitude * math.pi / 180);
    double x(GeoPoint g) =>
        (g.longitude - p.longitude) * _metersPerDegree * cosLat;
    double y(GeoPoint g) => (g.latitude - p.latitude) * _metersPerDegree;
    var best = double.infinity;
    var bestAlong = 0.0;
    for (var i = 0; i + 1 < points.length; i++) {
      final ax = x(points[i]), ay = y(points[i]);
      final dx = x(points[i + 1]) - ax, dy = y(points[i + 1]) - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0);
      final px = ax + t * dx, py = ay + t * dy;
      final dist = math.sqrt(px * px + py * py);
      if (dist < best) {
        best = dist;
        bestAlong = _cumulative[i] + t * (_cumulative[i + 1] - _cumulative[i]);
      }
    }
    return bestAlong;
  }

  /// La misma linea corrida [meters] hacia la derecha de quien la recorre en su
  /// sentido (negativo = a la izquierda). En una curva cada punto se corre por
  /// la bisectriz de sus dos lados.
  GeoPath offset(double meters) {
    final shifted = <GeoPoint>[];
    for (var i = 0; i < points.length; i++) {
      final before = points[math.max(0, i - 1)];
      final after = points[math.min(points.length - 1, i + 1)];
      final cosLat = math.cos(points[i].latitude * math.pi / 180);
      // Direccion de la linea en metros: este (x) y norte (y).
      final dx = (after.longitude - before.longitude) * cosLat;
      final dy = after.latitude - before.latitude;
      final norm = math.sqrt(dx * dx + dy * dy);
      if (norm == 0) {
        shifted.add(points[i]);
        continue;
      }
      // La derecha de (dx, dy) es (dy, -dx).
      final rx = dy / norm;
      final ry = -dx / norm;
      shifted.add(
        GeoPoint(
          points[i].latitude + ry * meters / _metersPerDegree,
          points[i].longitude + rx * meters / (_metersPerDegree * cosLat),
        ),
      );
    }
    return GeoPath(shifted);
  }

  /// La linea recorrida al reves.
  GeoPath get reversed => GeoPath(points.reversed.toList());
}
