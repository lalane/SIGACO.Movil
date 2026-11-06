import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/map_icons/map_icons.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/maintenance/domain/entities/maintenance.dart';
import 'package:sigaco_movil/features/maintenance/presentation/maintenance_labels.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/presentation/map_labels.dart';

import '../../support/fake_api.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');

/// Los iconos del mapa que elige la concesion en la web (`GET /api/gis/icons`).
void main() {
  tearDown(MapIconOverrides.clear);

  test('sin configurar, los iconos de siempre', () {
    expect(layerIcon(MapLayer.tickets), Icons.confirmation_number_outlined);
    expect(indicatorIcon(MaintenanceIndicator.sgoae), Icons.account_balance);
  });

  test('cada clave del catalogo del servidor tiene dibujo', () {
    const catalog = [
      'milestone', 'signpost', 'bridge', 'droplets', 'mountain', 'fence', //
      'building', 'lightbulb', 'tunnel', 'cctv', 'wrench', 'box', 'ticket',
      'alert', 'hard-hat', 'clipboard', 'map-pin', 'traffic-cone', 'tree',
      'zap', 'flag', 'camera', 'truck', 'shield', 'road', 'waves', 'info',
    ];
    expect(catalog.where((k) => mapIconData(k) == null), isEmpty);
    expect(mapIconData('dragon'), isNull);
  });

  test(
    'al entrar a la concesion toma los suyos y al salir los olvida',
    () async {
      final api = FakeApi()
        ..on(
          'GET /api/gis/icons',
          const FakeReply(200, {
            'catalog': ['road', 'flag'],
            'fallback': 'map-pin',
            'subsystems': [
              {'code': 'SGOAE', 'effectiveIconKey': 'road'},
              {'code': 'SGP', 'effectiveIconKey': 'dragon'},
            ],
            'operationalLayers': [
              {'code': 'TICKETS', 'effectiveIconKey': 'flag'},
            ],
          }),
        );
      final loader = MapIconsLoader(api.client());

      await loader.bind(_scope);
      expect(layerIcon(MapLayer.tickets), Icons.flag_outlined);
      expect(layerIcon(MapLayer.works), Icons.construction_outlined);
      expect(indicatorIcon(MaintenanceIndicator.sgoae), Icons.alt_route);
      // Una clave que la app no conoce deja el de siempre.
      expect(indicatorIcon(MaintenanceIndicator.sgp), Icons.add_road);

      await loader.clear();
      expect(layerIcon(MapLayer.tickets), Icons.confirmation_number_outlined);
    },
  );

  test('sin red o sin el endpoint quedan los de siempre', () async {
    final api = FakeApi()..on('GET /api/gis/icons', const FakeReply(404));
    await MapIconsLoader(api.client()).bind(_scope);
    expect(layerIcon(MapLayer.tickets), Icons.confirmation_number_outlined);
    api.offline = true;
    await MapIconsLoader(api.client()).bind(_scope);
    expect(indicatorIcon(MaintenanceIndicator.sgoae), Icons.account_balance);
  });
}
