import 'package:flutter/widgets.dart';

import 'map_tile_source.dart';

/// El mapa base que la app usa: el que el servidor indica para la concesion
/// activa y, mientras no indique ninguno, el [fallback] de la compilacion. Asi el
/// proveedor de teselas se cambia desde el servidor, sin sacar otra version de
/// la app (DEC-001, P5).
class ConfiguredTileSource extends MapTileSource {
  ConfiguredTileSource({required this.fallback});

  final MapTileSource fallback;
  MapTileSource? _remote;

  /// El mapa base de la concesion activa; null para volver al [fallback].
  void apply(MapTileSource? remote) => _remote = remote;

  /// El que esta en uso, para pruebas.
  MapTileSource get current => _remote ?? fallback;

  @override
  Widget? buildLayer() => current.buildLayer();

  @override
  String get styleString => current.styleString;

  @override
  bool get hasBase => current.hasBase;

  @override
  String? get attribution => current.attribution;

  @override
  String? get attributionUrl => current.attributionUrl;

  @override
  double get maxZoom => current.maxZoom;
}
