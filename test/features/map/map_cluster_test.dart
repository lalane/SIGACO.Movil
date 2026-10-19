import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/entities/pin_cluster.dart';

import '../../support/map_fakes.dart';

void main() {
  // Dos pines a unos 11 m y uno a unos 11 km.
  final a = fakePin('a', position: const GeoPoint(-18.8500, -41.9800));
  final b = fakePin('b', position: const GeoPoint(-18.8501, -41.9800));
  final far = fakePin('far', position: const GeoPoint(-18.9500, -41.9800));

  List<PinCluster> clusters(List<MapMarkerItem> items) =>
      items.whereType<PinCluster>().toList();
  List<SinglePin> singles(List<MapMarkerItem> items) =>
      items.whereType<SinglePin>().toList();

  test('pines muy juntos se agrupan y el lejano sale solo', () {
    final items = clusterPins([a, b, far], zoom: 12);
    expect(clusters(items), hasLength(1));
    expect(clusters(items).single.pins.map((p) => p.id), ['a', 'b']);
    expect(singles(items).single.pin.id, 'far');
  });

  test('el centro del grupo es el promedio de sus pines', () {
    final cluster = clusters(clusterPins([a, b], zoom: 12)).single;
    expect(cluster.position.latitude, closeTo(-18.85005, 1e-9));
    expect(cluster.position.longitude, closeTo(-41.98, 1e-9));
    expect(cluster.count, 2);
  });

  test('al acercar lo suficiente el grupo se deshace', () {
    // A zoom 17 ya no se agrupa nada.
    final items = clusterPins([a, b], zoom: 17);
    expect(clusters(items), isEmpty);
    expect(singles(items), hasLength(2));
    // Y a zoom 16 con 11 m de separacion (1,8 px) todavia se agrupan.
    expect(clusters(clusterPins([a, b], zoom: 16)), hasLength(1));
  });

  test('con un radio de cero no se agrupa', () {
    final items = clusterPins([a, b, far], zoom: 5, radiusPx: 0);
    expect(clusters(items), isEmpty);
    expect(singles(items), hasLength(3));
  });

  test('a poco zoom todo se agrupa y a mucho zoom se separa', () {
    expect(clusters(clusterPins([a, far], zoom: 5)), hasLength(1));
    expect(clusters(clusterPins([a, far], zoom: 14)), isEmpty);
  });

  test('el pin seleccionado nunca queda dentro de un grupo', () {
    final items = clusterPins([a, b, far], zoom: 12, keepSingleId: 'a');
    expect(singles(items).map((s) => s.pin.id), containsAll(['a', 'far']));
    // El otro queda solo porque ya no tiene con quien agruparse.
    expect(singles(items).map((s) => s.pin.id), contains('b'));
    expect(clusters(items), isEmpty);
  });

  test('el orden de entrada no cambia el resultado', () {
    final one = clusterPins([a, b, far], zoom: 12);
    final two = clusterPins([far, b, a], zoom: 12);
    expect(one, two);
  });

  test('el grupo toma el estado mas grave y su clave es estable', () {
    final ok = fakePin('p1', position: a.position);
    final bad = fakePin('p2', position: b.position, status: PinStatus.critical);
    final mid = fakePin(
      'p3',
      position: b.position,
      status: PinStatus.attention,
    );
    final cluster = clusters(clusterPins([ok, bad, mid], zoom: 12)).single;
    expect(cluster.status, PinStatus.critical);
    expect(cluster.key, 'p1|p2|p3');
  });

  test('descarta pines con coordenadas invalidas', () {
    final bad = fakePin('x', position: const GeoPoint(120, 0));
    expect(clusterPins([bad], zoom: 5), isEmpty);
  });

  test('sin pines no hay nada que agrupar', () {
    expect(clusterPins(const <MapPin>[], zoom: 5), isEmpty);
  });

  test('cerca de los polos y del antimeridiano no falla', () {
    final polar = fakePin('n', position: const GeoPoint(89.9, 179.9));
    final polar2 = fakePin('s', position: const GeoPoint(-89.9, -179.9));
    expect(() => clusterPins([polar, polar2], zoom: 3), returnsNormally);
  });
}
