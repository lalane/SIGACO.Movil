import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/ids/client_id.dart';
import 'package:sigaco_movil/core/ui/device_navigation.dart';

/// El identificador de cliente (`cliente_uuid`) y la entrega de coordenadas a la
/// app de navegacion (DTF M10, HU-MOB-10-06 y la idempotencia de BD v6).
void main() {
  group('identificador de cliente', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('es un UUID v4 valido', () {
      for (var i = 0; i < 50; i++) {
        expect(newClientId(), matches(uuid));
      }
    });

    test('no se repite', () {
      expect({for (var i = 0; i < 500; i++) newClientId()}, hasLength(500));
    });

    test('con la misma semilla da el mismo valor (para pruebas)', () {
      expect(newClientId(Random(7)), newClientId(Random(7)));
      expect(newClientId(Random(7)), isNot(newClientId(Random(8))));
    });
  });

  group('navegar a un punto', () {
    late Future<bool> Function(Uri) original;
    late List<Uri> opened;

    setUp(() {
      original = DeviceNavigation.opener;
      opened = [];
    });
    tearDown(() => DeviceNavigation.opener = original);

    test('arma la direccion geo con el punto y el nombre', () {
      final uri = DeviceNavigation.uriFor(
        -18.85,
        -41.98,
        label: 'Señal SV-114',
      );
      expect(uri.scheme, 'geo');
      expect(uri.toString(), startsWith('geo:-18.85,-41.98?q=-18.85,-41.98'));
      expect(Uri.decodeComponent(uri.toString()), contains('(Señal SV-114)'));
    });

    test('sin nombre solo lleva el punto', () {
      expect(
        DeviceNavigation.uriFor(1.5, -2.5).toString(),
        'geo:1.5,-2.5?q=1.5,-2.5',
      );
    });

    test('entrega el punto al telefono', () async {
      DeviceNavigation.opener = (uri) async {
        opened.add(uri);
        return true;
      };
      expect(await DeviceNavigation.open(-18.85, -41.98, label: 'A'), isTrue);
      expect(opened.single.scheme, 'geo');
    });

    test('un punto invalido no se manda', () async {
      DeviceNavigation.opener = (uri) async {
        opened.add(uri);
        return true;
      };
      expect(await DeviceNavigation.open(91, 0), isFalse);
      expect(await DeviceNavigation.open(0, 181), isFalse);
      expect(await DeviceNavigation.open(double.nan, 0), isFalse);
      expect(opened, isEmpty);
    });

    test('si no hay app de navegacion o falla, devuelve false', () async {
      DeviceNavigation.opener = (uri) async => false;
      expect(await DeviceNavigation.open(1, 1), isFalse);
      DeviceNavigation.opener = (uri) async => throw StateError('sin app');
      expect(await DeviceNavigation.open(1, 1), isFalse);
    });
  });
}
