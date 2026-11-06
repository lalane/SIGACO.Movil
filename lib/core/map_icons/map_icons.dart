import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../offline/operation.dart';
import '../session/session_scope.dart';

/// El dibujo de cada clave del catalogo de iconos del servidor
/// (`MapIconCatalog`, `GET /api/gis/icons`). Es una lista cerrada: una clave
/// nueva se agrega en el API, en la web y aqui. La que no se conoce da null y
/// se usa el icono de siempre.
IconData? mapIconData(String key) => switch (key) {
  'milestone' => Icons.add_road,
  'signpost' => Icons.signpost_outlined,
  'bridge' => Icons.account_balance,
  'droplets' => Icons.water_drop_outlined,
  'mountain' => Icons.landscape_outlined,
  'fence' => Icons.fence,
  'building' => Icons.apartment,
  'lightbulb' => Icons.lightbulb_outline,
  'tunnel' => Icons.stream,
  'cctv' => Icons.videocam_outlined,
  'wrench' => Icons.build_outlined,
  'box' => Icons.inventory_2_outlined,
  'ticket' => Icons.confirmation_number_outlined,
  'alert' => Icons.warning_amber_rounded,
  'hard-hat' => Icons.construction_outlined,
  'clipboard' => Icons.assignment_turned_in_outlined,
  'map-pin' => Icons.place_outlined,
  'traffic-cone' => Icons.traffic_outlined,
  'tree' => Icons.park_outlined,
  'zap' => Icons.bolt,
  'flag' => Icons.flag_outlined,
  'camera' => Icons.photo_camera_outlined,
  'truck' => Icons.local_shipping_outlined,
  'shield' => Icons.shield_outlined,
  'road' => Icons.alt_route,
  'waves' => Icons.waves,
  'info' => Icons.info_outline,
  _ => null,
};

/// Los iconos que eligio la concesion activa para cada subsistema (SGP,
/// SGOAE...) y cada capa de SIGACO (TICKETS, OBRAS...). Vacio, se usan los de
/// siempre. Los pinta cualquier pantalla sin esperar: los llena
/// [MapIconsLoader] al entrar a una concesion.
abstract final class MapIconOverrides {
  static Map<String, String> _subsystems = const {};
  static Map<String, String> _operational = const {};

  /// Lo que entrega `GET /api/gis/icons`.
  static void apply(Map<String, dynamic> json) {
    Map<String, String> read(Object? list) => {
      if (list is List)
        for (final e in list)
          if (e is Map &&
              e['code'] is String &&
              e['effectiveIconKey'] is String)
            (e['code'] as String).toUpperCase():
                e['effectiveIconKey'] as String,
    };
    _subsystems = read(json['subsystems']);
    _operational = read(json['operationalLayers']);
  }

  static void clear() {
    _subsystems = const {};
    _operational = const {};
  }

  /// El icono configurado para un subsistema; null, el de siempre.
  static IconData? subsystem(String code) {
    final key = _subsystems[code.toUpperCase()];
    return key == null ? null : mapIconData(key);
  }

  /// El icono configurado para una capa de SIGACO; null, el de siempre.
  static IconData? operational(String code) {
    final key = _operational[code.toUpperCase()];
    return key == null ? null : mapIconData(key);
  }
}

/// Trae los iconos de la concesion al entrar a ella y los olvida al salir. Sin
/// red o con un servidor anterior a los iconos configurables, quedan los de
/// siempre: nunca impide entrar.
class MapIconsLoader implements ScopeBound {
  MapIconsLoader(this._api);

  final ApiClient _api;

  @override
  Future<void> bind(OfflineScope? scope) async {
    MapIconOverrides.clear();
    if (scope == null) return;
    try {
      final json = await _api.getJson('/api/gis/icons');
      if (json is Map<String, dynamic>) MapIconOverrides.apply(json);
    } catch (_) {
      // Los de siempre.
    }
  }

  @override
  Future<void> clear() async => MapIconOverrides.clear();
}
