import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/road_segment.dart';
import '../bloc/map_cubit.dart';
import '../map_camera.dart';
import '../map_labels.dart';
import '../tiles/map_tile_source.dart';
import 'map_data.dart';
import 'pin_icons.dart';

/// El mapa dibujado con MapLibre: el mapa base de un estilo (teselas vectoriales
/// o de imagen) y, encima, los tramos, los pines (con agrupacion), la ubicacion
/// del usuario y el punto elegido, como capas. Los botones, fichas y avisos son
/// de Flutter y los pone la pantalla.
class MapLibreEngine extends StatefulWidget {
  const MapLibreEngine({
    super.key,
    required this.state,
    required this.tileSource,
    required this.camera,
    required this.fitKey,
  });

  final MapState state;
  final MapTileSource tileSource;
  final MapCameraController camera;

  /// Cambia con la pestana y los filtros: el mapa se vuelve a encuadrar.
  final String fitKey;

  @override
  State<MapLibreEngine> createState() => _MapLibreEngineState();
}

class _MapLibreEngineState extends State<MapLibreEngine> {
  static const _segSource = 'seg';
  static const _segCasing = 'seg-casing';
  static const _segLine = 'seg-line';
  static const _labelSource = 'seg-labels-src';
  static const _labelLayer = 'seg-labels';
  static const _locSource = 'loc';
  static const _locAccuracy = 'loc-acc';
  static const _locDot = 'loc-dot';
  static const _pinSource = 'pins';
  static const _clusterLayer = 'pins-clusters';
  static const _countLayer = 'pins-counts';
  static const _pointLayer = 'pins-points';
  static const _iconLayer = 'pins-icons';
  static const _selSource = 'sel';
  static const _selLayer = 'sel-ring';
  static const _selIconLayer = 'sel-icon';
  static const _pickSource = 'pick';
  static const _pickLayer = 'pick-marker';

  /// Centro y zoom cuando no hay nada que mostrar (Brasil, vista general).
  static const _fallbackCenter = LatLng(-15.78, -47.93);

  MapLibreMapController? _map;
  var _installed = false;
  String? _fitted;
  final _pushed = <String, int>{};
  var _zoom = 14.0;

  @override
  void dispose() {
    widget.camera.detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapLibreEngine old) {
    super.didUpdateWidget(old);
    if (_installed) {
      _sync();
      _fit();
    }
  }

  void _onCreated(MapLibreMapController controller) {
    _map = controller;
    widget.camera.attach((point, minZoom) async {
      final z = math.max(_zoom, minZoom);
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(point.latitude, point.longitude), z),
      );
    });
  }

  /// El estilo cargo (la primera vez o al cambiar de mapa base): se vuelven a
  /// crear las fuentes y las capas.
  Future<void> _onStyleLoaded() async {
    _installed = false;
    _pushed.clear();
    _fitted = null;
    await _install();
    _installed = true;
    await _sync();
    await _fit();
  }

  Future<void> _install() async {
    final map = _map;
    if (map == null) return;
    final p = context.palette;
    final s = widget.state;
    const text = ['Noto Sans Regular'];

    // El icono de cada capa, para ponerlo dentro del circulo del pin.
    for (final image in (await pinIconImages()).entries) {
      await map.addImage(image.key, image.value);
    }

    // Los tramos van debajo de los pines: son el fondo en el que se leen.
    await map.addSource(
      _segSource,
      const GeojsonSourceProperties(data: _empty),
    );
    await map.addLineLayer(
      _segSource,
      _segCasing,
      const LineLayerProperties(
        lineColor: '#FFFFFF',
        lineWidth: [
          'case',
          [
            '==',
            ['get', 'hl'],
            1,
          ],
          12,
          9,
        ],
        lineCap: 'round',
        lineJoin: 'round',
      ),
      enableInteraction: false,
    );
    await map.addLineLayer(
      _segSource,
      _segLine,
      LineLayerProperties(
        lineColor: [
          'match',
          ['get', 'dir'],
          'inc',
          hexColor(segmentColor(TravelDirection.increasing)),
          hexColor(segmentColor(TravelDirection.decreasing)),
        ],
        lineWidth: [
          'case',
          [
            '==',
            ['get', 'hl'],
            1,
          ],
          8,
          5,
        ],
        lineCap: 'round',
        lineJoin: 'round',
      ),
      enableInteraction: false,
    );
    await map.addSource(
      _labelSource,
      const GeojsonSourceProperties(data: _empty),
    );
    await map.addSymbolLayer(
      _labelSource,
      _labelLayer,
      const SymbolLayerProperties(
        textField: ['get', 'code'],
        textFont: text,
        textSize: 11,
        textColor: '#1E293B',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 2,
        textAllowOverlap: false,
      ),
      minzoom: 15,
      enableInteraction: false,
    );

    await map.addSource(
      _locSource,
      const GeojsonSourceProperties(data: _empty),
    );
    await map.addCircleLayer(
      _locSource,
      _locAccuracy,
      CircleLayerProperties(
        circleRadius: accuracyRadius(),
        circleColor: '#2196F3',
        circleOpacity: 0.12,
        circleStrokeColor: '#2196F3',
        circleStrokeWidth: 1,
        circleStrokeOpacity: 0.5,
      ),
      enableInteraction: false,
    );

    final color = severityColor(
      normal: p.accent,
      attention: StatusColors.attended,
      critical: StatusColors.open,
    );
    await map.addSource(
      _pinSource,
      GeojsonSourceProperties(
        data: _empty,
        cluster: true,
        clusterRadius: s.settings.clusterRadiusPx,
        clusterMaxZoom: 17,
        clusterProperties: const {
          // Un grupo pide la atencion del peor de sus pines.
          'sev': [
            'max',
            ['get', 'sev'],
          ],
        },
      ),
    );
    await map.addCircleLayer(
      _pinSource,
      _clusterLayer,
      CircleLayerProperties(
        circleColor: color,
        circleRadius: [
          'step',
          ['get', 'point_count'],
          18,
          25,
          22,
          100,
          26,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      ),
      filter: ['has', 'point_count'],
    );
    await map.addSymbolLayer(
      _pinSource,
      _countLayer,
      SymbolLayerProperties(
        textField: const ['get', 'point_count_abbreviated'],
        textFont: text,
        textSize: 14,
        textColor: hexColor(SigacoPalette.readableOn(p.accent)),
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      filter: ['has', 'point_count'],
      enableInteraction: false,
    );
    await map.addCircleLayer(
      _pinSource,
      _pointLayer,
      CircleLayerProperties(
        circleColor: color,
        circleRadius: 11,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.5,
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
    await map.addSymbolLayer(
      _pinSource,
      _iconLayer,
      const SymbolLayerProperties(
        iconImage: ['get', 'ic'],
        iconSize: 0.42,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
      enableInteraction: false,
    );

    await map.addSource(
      _selSource,
      const GeojsonSourceProperties(data: _empty),
    );
    await map.addCircleLayer(
      _selSource,
      _selLayer,
      CircleLayerProperties(
        circleColor: color,
        circleRadius: 16,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 4,
      ),
    );
    await map.addSymbolLayer(
      _selSource,
      _selIconLayer,
      const SymbolLayerProperties(
        iconImage: ['get', 'ic'],
        iconSize: 0.6,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );

    await map.addSource(
      _pickSource,
      const GeojsonSourceProperties(data: _empty),
    );
    await map.addCircleLayer(
      _pickSource,
      _pickLayer,
      const CircleLayerProperties(
        circleColor: '#DC2626',
        circleRadius: 10,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      ),
      enableInteraction: false,
    );
    await map.addCircleLayer(
      _locSource,
      _locDot,
      const CircleLayerProperties(
        circleColor: '#2196F3',
        circleRadius: 8,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
      ),
      enableInteraction: false,
    );
  }

  static const _empty = {'type': 'FeatureCollection', 'features': <Object>[]};

  /// Sube a cada fuente lo que cambio desde la ultima vez (comparado por un
  /// resumen, para no reenviar miles de pines en cada cambio de la pantalla).
  Future<void> _sync() async {
    final map = _map;
    if (map == null || !_installed) return;
    final s = widget.state;
    final pins = s.visiblePins;
    final selected = s.selectedPin;
    final segments = s.segments;
    final selectedSegment = s.selectedSegment;

    bool highlighted(RoadSegment seg) =>
        seg.id == selectedSegment?.id ||
        (selected != null &&
            selected.segmentCode == seg.code &&
            selected.direction == seg.direction);

    Future<void> push(
      String source,
      int signature,
      Map<String, Object?> Function() data,
    ) async {
      if (_pushed[source] == signature) return;
      _pushed[source] = signature;
      await map.setGeoJsonSource(source, data());
    }

    await push(
      _segSource,
      Object.hash(
        Object.hashAll(segments.map((e) => e.id)),
        selectedSegment?.id,
        selected?.segmentCode,
        selected?.direction,
      ),
      () => segmentsGeoJson(segments, highlighted: highlighted),
    );
    await push(
      _labelSource,
      Object.hashAll(segments.map((e) => e.code)),
      () => segmentLabelsGeoJson(segments),
    );
    await push(
      _pinSource,
      Object.hash(
        Object.hashAll(pins.map((e) => e.id)),
        Object.hashAll(pins.map((e) => e.status)),
        s.selectedId,
      ),
      () => pinsGeoJson(pins, exceptId: selected?.id),
    );
    await push(
      _selSource,
      Object.hash(selected?.id, selected?.status),
      () => selectedPinGeoJson(selected),
    );
    await push(
      _locSource,
      Object.hash(s.location?.position, s.location?.accuracyMeters),
      () => locationGeoJson(s.location),
    );
    await push(
      _pickSource,
      s.pickedPoint.hashCode,
      () => pointGeoJson(s.pickedPoint),
    );
  }

  /// El encuadre cambia con la pestana y con los filtros, no al tocar un pin ni
  /// al moverse el usuario.
  Future<void> _fit() async {
    final map = _map;
    if (map == null || !_installed || _fitted == widget.fitKey) return;
    _fitted = widget.fitKey;
    final s = widget.state;
    final points = fitPoints(s.visiblePins, s.segments);
    final r = context.responsive;
    if (points.isEmpty) {
      await map.moveCamera(CameraUpdate.newLatLngZoom(_fallbackCenter, 4));
      return;
    }
    if (points.length == 1) {
      final p = points.first;
      await map.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 14),
      );
      return;
    }
    final b = boundsOf(points)!;
    await map.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(b.southWest.latitude, b.southWest.longitude),
          northeast: LatLng(b.northEast.latitude, b.northEast.longitude),
        ),
        left: r.s(48),
        top: r.s(48),
        right: r.s(48),
        bottom: r.s(180),
      ),
    );
  }

  /// Las propiedades de lo que devuelve el mapa, sea un mapa o un JSON.
  static Map<String, dynamic> _properties(Object? feature) {
    try {
      final f = feature is String ? jsonDecode(feature) : feature;
      final p = f is Map ? f['properties'] : null;
      return p is Map ? Map<String, dynamic>.from(p) : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<List> _hits(math.Point<double> at, List<String> layers) async {
    // Un poco de margen para que un dedo acierte un pin chico.
    final rect = Rect.fromCenter(
      center: Offset(at.x, at.y),
      width: 32,
      height: 32,
    );
    return await _map!.queryRenderedFeaturesInRect(rect, layers, null);
  }

  Future<void> _onTap(math.Point<double> at, LatLng where) async {
    final map = _map;
    if (map == null || !_installed) return;
    final cubit = context.read<MapCubit>();

    final pinHits = await _hits(at, [_selLayer, _pointLayer, _clusterLayer]);
    if (pinHits.isNotEmpty) {
      final props = _properties(pinHits.first);
      if (props['point_count'] != null) {
        // Un grupo: se acerca el mapa para separarlo.
        await map.animateCamera(CameraUpdate.newLatLngZoom(where, _zoom + 2));
        return;
      }
      final id = props['id'];
      if (id is String) {
        cubit.selectPin(id);
        return;
      }
    }
    final segmentHits = await _hits(at, [_segLine]);
    final segmentId = segmentHits.isEmpty
        ? null
        : _properties(segmentHits.first)['id'];
    if (segmentId is String) {
      cubit.selectSegment(segmentId);
      return;
    }
    cubit.selectPin(null);
    cubit.selectSegment(null);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: MapLibreMap(
        styleString: widget.tileSource.styleString,
        initialCameraPosition: const CameraPosition(
          target: _fallbackCenter,
          zoom: 4,
        ),
        minMaxZoomPreference: MinMaxZoomPreference(
          3,
          widget.tileSource.maxZoom,
        ),
        trackCameraPosition: true,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        compassEnabled: false,
        attributionButtonPosition: AttributionButtonPosition.topLeft,
        onMapCreated: _onCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        onMapClick: _onTap,
        // Mantener presionado elige un punto (para registrar o navegar).
        onMapLongClick: (_, where) => context.read<MapCubit>().pickPoint(
          GeoPoint(where.latitude, where.longitude),
        ),
        onCameraIdle: () {
          final z = _map?.cameraPosition?.zoom;
          if (z != null) _zoom = z;
        },
      ),
    );
  }
}
