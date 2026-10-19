import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/map_tile_source.dart';

void main() {
  test('sin proveedor no hay capa de teselas ni atribucion', () {
    const source = NoTileSource();
    expect(source.buildLayer(), isNull);
    expect(source.attribution, isNull);
  });

  test('con plantilla de URL arma la capa de teselas', () {
    const source = UrlTemplateTileSource(
      urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.png',
      attributionText: '© Ejemplo',
      zoomMax: 17,
    );
    final layer = source.buildLayer();
    expect(layer, isA<TileLayer>());
    final tile = layer! as TileLayer;
    expect(tile.urlTemplate, 'https://tiles.example.com/{z}/{x}/{y}.png');
    expect(tile.maxNativeZoom, 17);
    expect(source.attribution, '© Ejemplo');
    expect(source.maxZoom, 17);
  });
}
