import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/composition/map_base_source.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/configured_tile_source.dart';
import 'package:sigaco_movil/features/map/presentation/tiles/map_tile_source.dart';

import '../support/fake_api.dart';

const _good = {
  'urlTemplate': 'https://tiles.tekia.example/{z}/{x}/{y}.png?key=abc',
  'attribution': '© TEKIA',
  'attributionUrl': 'https://tekia.example/licencia',
  'maxZoom': 18,
};

const _fallback = UrlTemplateTileSource(
  urlTemplate: 'https://respaldo.example/{z}/{x}/{y}.png',
  attributionText: 'respaldo',
  zoomMax: 17,
);

Map<String, Object?> _config(Object? mapBase, {String concession = 'c1'}) => {
  'concessionId': concession,
  'mapBase': mapBase,
};

void main() {
  group('ApiMapBaseSource.parse', () {
    test('una plantilla valida se vuelve el mapa base', () {
      final source = ApiMapBaseSource.parse(_good)! as UrlTemplateTileSource;
      expect(source.urlTemplate, 'https://tiles.tekia.example/{z}/{x}/{y}.png?key=abc');
      expect(source.attribution, '© TEKIA');
      expect(source.attributionUrl, 'https://tekia.example/licencia');
      expect(source.maxZoom, 18);
    });

    test('sin zoom ni atribucion usa lo normal', () {
      final source = ApiMapBaseSource.parse({'urlTemplate': 'https://t.example/{z}/{x}/{y}.png'})!;
      expect(source.maxZoom, 19);
      expect(source.attribution, isNull);
      expect(source.attributionUrl, isNull);
    });

    test('el zoom se acota entre 1 y 22', () {
      expect(ApiMapBaseSource.parse({..._good, 'maxZoom': 40})!.maxZoom, 22);
      expect(ApiMapBaseSource.parse({..._good, 'maxZoom': -3})!.maxZoom, 1);
    });

    test('una direccion que no es https o le falta una parte no sirve', () {
      for (final url in [
        'http://t.example/{z}/{x}/{y}.png',
        'https://t.example/{z}/{x}.png',
        'https://t.example/tiles.png',
        'javascript:alert(1)',
        '',
        ' ',
      ]) {
        expect(ApiMapBaseSource.parse({'urlTemplate': url}), isNull, reason: url);
      }
      expect(ApiMapBaseSource.parse(null), isNull);
      expect(ApiMapBaseSource.parse('texto'), isNull);
      expect(ApiMapBaseSource.parse({'urlTemplate': 42}), isNull);
    });

    test('un enlace de atribucion que no es https se descarta', () {
      final source = ApiMapBaseSource.parse({..._good, 'attributionUrl': 'http://x.example'})!;
      expect(source.attributionUrl, isNull);
    });
  });

  group('ApiMapBaseSource.load', () {
    late FakeApi api;
    late ApiMapBaseSource source;

    setUp(() {
      api = FakeApi();
      source = ApiMapBaseSource(api.client());
    });

    test('lee mapBase de la configuracion de la concesion', () async {
      api.on('GET /api/app-configuration', FakeReply(200, _config(_good)));
      expect((await source.load('c1'))?.maxZoom, 18);
    });

    test('una configuracion de otra concesion no vale', () async {
      api.on('GET /api/app-configuration', FakeReply(200, _config(_good, concession: 'otra')));
      expect(await source.load('c1'), isNull);
    });

    test('sin mapBase, o con un fallo, no cambia nada', () async {
      api.on('GET /api/app-configuration', FakeReply(200, _config(null)));
      expect(await source.load('c1'), isNull);
      api.on('GET /api/app-configuration', const FakeReply(500));
      expect(await source.load('c1'), isNull);
      api.offline = true;
      expect(await source.load('c1'), isNull);
    });
  });

  group('ConfiguredTileSource y MapBaseLoader', () {
    test('usa el de respaldo hasta que el servidor indique otro', () {
      final tiles = ConfiguredTileSource(fallback: _fallback);
      expect(tiles.attribution, 'respaldo');
      expect(tiles.maxZoom, 17);
      tiles.apply(ApiMapBaseSource.parse(_good));
      expect(tiles.attribution, '© TEKIA');
      expect(tiles.maxZoom, 18);
      tiles.apply(null);
      expect(tiles.attribution, 'respaldo');
    });

    test('al iniciar sesion aplica el del servidor y al cerrarla vuelve', () async {
      final api = FakeApi()..on('GET /api/app-configuration', FakeReply(200, _config(_good)));
      final tiles = ConfiguredTileSource(fallback: _fallback);
      final loader = MapBaseLoader(tiles: tiles, source: ApiMapBaseSource(api.client()));

      await loader.load('c1');
      expect(tiles.attribution, '© TEKIA');

      loader.reset();
      expect(tiles.attribution, 'respaldo');
    });

    test('un fallo del servidor deja el mapa que ya habia', () async {
      final api = FakeApi()..on('GET /api/app-configuration', const FakeReply(500));
      final tiles = ConfiguredTileSource(fallback: _fallback);
      await MapBaseLoader(tiles: tiles, source: ApiMapBaseSource(api.client())).load('c1');
      expect(tiles.attribution, 'respaldo');
    });

    test('sin servidor no hace nada', () async {
      final loader = MapBaseLoader.none();
      await loader.load('c1');
      expect(loader.tiles.current, isA<NoTileSource>());
    });
  });
}
