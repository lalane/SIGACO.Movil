import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// De donde salen las teselas del mapa base. El proveedor todavia no esta
/// decidido (DEC-001): la pantalla solo conoce esta interfaz, de modo que
/// cambiar de proveedor (OpenStreetMap con teselas propias, un paquete
/// descargado, otro servicio) no obliga a rehacerla.
abstract class MapTileSource {
  const MapTileSource();

  /// La capa de teselas, o `null` si no hay mapa base configurado.
  Widget? buildLayer();

  /// Texto de atribucion que debe verse sobre el mapa (OpenStreetMap exige
  /// citar a sus colaboradores). `null` si no hace falta.
  String? get attribution;

  /// A donde lleva tocar la atribucion (la pagina de licencia de los datos).
  String? get attributionUrl;

  /// Zoom maximo que admite el proveedor.
  double get maxZoom;
}

/// Sin mapa base: el mapa muestra los pines sobre un fondo neutro. Es lo que
/// hay mientras no se configure un proveedor (`MAP_TILE_URL`) y lo que usan las
/// pruebas. No se llama a ningun servidor.
class NoTileSource extends MapTileSource {
  const NoTileSource();

  @override
  Widget? buildLayer() => null;

  @override
  String? get attribution => null;

  @override
  String? get attributionUrl => null;

  @override
  double get maxZoom => 19;
}

/// Teselas de un servidor con plantilla `https://.../{z}/{x}/{y}.png`.
///
/// No usar los servidores publicos de OpenStreetMap en produccion ni para
/// descargar teselas: su politica no lo permite. Para eso, teselas propias o un
/// paquete por concesion (ver la propuesta del mapa base).
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
  String? get attribution => attributionText;

  @override
  String? get attributionUrl => attributionLink;

  @override
  double get maxZoom => zoomMax;
}
