import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// De donde sale el mapa base. El proveedor se cambia desde el servidor o con la
/// compilacion (DEC-001): la pantalla solo conoce esta interfaz, de modo que
/// cambiar de proveedor (teselas propias, un servicio, otro estilo) no obliga a
/// rehacerla.
///
/// El mapa de MapLibre usa [styleString]; el de `flutter_map` (el de respaldo,
/// `MAP_LEGACY=true`) usa [buildLayer].
abstract class MapTileSource {
  const MapTileSource();

  /// La capa de teselas de `flutter_map`, o `null` si no hay mapa base o es un
  /// estilo vectorial (eso solo lo dibuja MapLibre).
  Widget? buildLayer();

  /// El estilo de MapLibre: la direccion de un estilo o su JSON. Sin mapa base,
  /// un fondo liso.
  String get styleString;

  /// Si hay un mapa base (calles, satelite) debajo de los pines.
  bool get hasBase;

  /// Texto de atribucion que debe verse sobre el mapa (OpenStreetMap exige
  /// citar a sus colaboradores). `null` si no hace falta.
  String? get attribution;

  /// A donde lleva tocar la atribucion (la pagina de licencia de los datos).
  String? get attributionUrl;

  /// Zoom maximo que admite el proveedor.
  double get maxZoom;

  /// Un estilo sin mapa: solo un fondo liso donde se leen los pines.
  static const neutralStyle =
      '{"version":8,"sources":{},"layers":[{"id":"background","type":"background",'
      '"paint":{"background-color":"#E5E7EB"}}]}';

  /// El estilo de MapLibre de unas teselas de imagen con plantilla `{z}/{x}/{y}`.
  static String rasterStyle(String urlTemplate, {double maxZoom = 19}) =>
      jsonEncode({
        'version': 8,
        'sources': {
          'base': {
            'type': 'raster',
            'tiles': [urlTemplate],
            'tileSize': 256,
            'maxzoom': maxZoom.floor(),
          },
        },
        'layers': [
          {'id': 'base', 'type': 'raster', 'source': 'base'},
        ],
      });
}

/// Sin mapa base: el mapa muestra los pines sobre un fondo neutro. Es lo que
/// hay si se define `MAP_TILE_URL=` y `MAP_STYLE_URL=` vacios, y lo que usan las
/// pruebas. No se llama a ningun servidor.
class NoTileSource extends MapTileSource {
  const NoTileSource();

  @override
  Widget? buildLayer() => null;

  @override
  String get styleString => MapTileSource.neutralStyle;

  @override
  bool get hasBase => false;

  @override
  String? get attribution => null;

  @override
  String? get attributionUrl => null;

  @override
  double get maxZoom => 19;
}

/// Teselas de imagen de un servidor con plantilla `https://.../{z}/{x}/{y}.png`.
///
/// No usar los servidores publicos de OpenStreetMap en produccion ni para
/// descargar teselas: su politica no lo permite.
class UrlTemplateTileSource extends MapTileSource {
  const UrlTemplateTileSource({
    required this.urlTemplate,
    this.attributionText,
    this.attributionLink,
    this.userAgentPackageName = 'com.idare.sigaco_movil',
    this.zoomMax = 19,
  });

  final String urlTemplate;
  final String? attributionText;
  final String? attributionLink;

  /// `flutter_map` lo manda como User-Agent: las politicas de uso lo exigen.
  final String userAgentPackageName;
  final double zoomMax;

  @override
  Widget? buildLayer() => TileLayer(
    urlTemplate: urlTemplate,
    userAgentPackageName: userAgentPackageName,
    maxNativeZoom: zoomMax.floor(),
  );

  @override
  String get styleString =>
      MapTileSource.rasterStyle(urlTemplate, maxZoom: zoomMax);

  @override
  bool get hasBase => true;

  @override
  String? get attribution => attributionText;

  @override
  String? get attributionUrl => attributionLink;

  @override
  double get maxZoom => zoomMax;
}

/// Un estilo de MapLibre (teselas vectoriales): la direccion del estilo, por
/// ejemplo el de OpenFreeMap. Solo lo dibuja MapLibre.
class StyleUrlTileSource extends MapTileSource {
  const StyleUrlTileSource({
    required this.styleUrl,
    this.attributionText,
    this.attributionLink,
    this.zoomMax = 19,
  });

  final String styleUrl;
  final String? attributionText;
  final String? attributionLink;
  final double zoomMax;

  @override
  Widget? buildLayer() => null;

  @override
  String get styleString => styleUrl;

  @override
  bool get hasBase => true;

  @override
  String? get attribution => attributionText;

  @override
  String? get attributionUrl => attributionLink;

  @override
  double get maxZoom => zoomMax;
}
