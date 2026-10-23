import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/repositories/map_repository.dart';

/// PRUEBA DE CONCEPTO (rama `spike/maplibre`, no es la pantalla del mapa): el
/// mapa base de OpenFreeMap con MapLibre y los pines del servidor como una capa
/// con agrupacion. Sirve para decidir si se migra el mapa de `flutter_map`.
///
/// Se abre con `--dart-define=MAP_SPIKE=true`; el estilo se cambia con
/// `--dart-define=MAP_STYLE_URL=...`.
class MapLibreSpikePage extends StatefulWidget {
  const MapLibreSpikePage({super.key, required this.repository});

  final MapRepository repository;

  @override
  State<MapLibreSpikePage> createState() => _MapLibreSpikePageState();
}

class _MapLibreSpikePageState extends State<MapLibreSpikePage> {
  static const _source = 'pins';
  static const _clusters = 'pins-clusters';
  static const _counts = 'pins-counts';
  static const _points = 'pins-points';

  /// La BR-381 a la altura de Governador Valadares.
  static const _start = LatLng(-18.85, -41.98);

  MapLibreMapController? _map;
  var _layer = MapLayer.inventory;
  var _pins = const <MapPin>[];
  var _styleReady = false;
  var _loading = false;
  String? _error;
  MapPin? _selected;
  var _located = false;
  var _zoom = 9.0;

  @override
  void initState() {
    super.initState();
    _askLocation();
    _loadPins();
  }

  /// Sin permiso de ubicacion el mapa funciona igual, sin el punto azul.
  Future<void> _askLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final ok =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (mounted) setState(() => _located = ok);
    } catch (_) {
      // Sin servicio de ubicacion: no se muestra "ubicarme".
    }
  }

  Future<void> _loadPins() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final pins = await widget.repository.pins(_layer);
      if (!mounted) return;
      setState(() {
        _pins = pins;
        _loading = false;
      });
      await _paint();
    } on MapException catch (e) {
      if (mounted) {
        setState(() {
          _pins = const [];
          _loading = false;
          _error = e.error.name;
        });
        await _paint();
      }
    }
  }

  Map<String, Object?> _geoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final p in _pins)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [p.position.longitude, p.position.latitude],
          },
          'properties': {'id': p.id, 'status': p.status.name},
        },
    ],
  };

  /// Pone los pines en el mapa: la primera vez crea la fuente y las capas; despues
  /// solo cambia los datos.
  Future<void> _paint() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final data = _geoJson();
    if (_painted) {
      await map.setGeoJsonSource(_source, data);
      return;
    }
    await map.addSource(
      _source,
      GeojsonSourceProperties(
        data: data,
        cluster: true,
        clusterRadius: 50,
        clusterMaxZoom: 14,
      ),
    );
    await map.addCircleLayer(
      _source,
      _clusters,
      const CircleLayerProperties(
        circleColor: '#1565C0',
        circleRadius: [
          'step',
          ['get', 'point_count'],
          16,
          20,
          22,
          100,
          28,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
      filter: ['has', 'point_count'],
    );
    await map.addSymbolLayer(
      _source,
      _counts,
      const SymbolLayerProperties(
        textField: ['get', 'point_count_abbreviated'],
        textFont: ['Noto Sans Regular'],
        textSize: 12,
        textColor: '#FFFFFF',
        textAllowOverlap: true,
      ),
      filter: ['has', 'point_count'],
      enableInteraction: false,
    );
    await map.addCircleLayer(
      _source,
      _points,
      const CircleLayerProperties(
        circleColor: [
          'match',
          ['get', 'status'],
          'critical',
          '#D32F2F',
          'attention',
          '#F9A825',
          '#2E7D32',
        ],
        circleRadius: 8,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
    _painted = true;
  }

  var _painted = false;

  Future<void> _onTap(math.Point<double> point, LatLng at) async {
    final map = _map;
    if (map == null || !_painted) return;
    final hits = await map.queryRenderedFeatures(point, [
      _clusters,
      _points,
    ], null);
    if (hits.isEmpty) {
      if (_selected != null) setState(() => _selected = null);
      return;
    }
    final props = _properties(hits.first);
    if (props['point_count'] != null) {
      // Un grupo: se acerca el mapa para separarlo.
      await map.animateCamera(CameraUpdate.newLatLngZoom(at, _zoom + 2));
      return;
    }
    final id = props['id'];
    final pin = _pins.where((p) => p.id == id).firstOrNull;
    if (pin != null) setState(() => _selected = pin);
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

  Future<void> _locateMe() async {
    final here = await _map?.requestMyLocationLatLng();
    if (here != null) {
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba MapLibre'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<MapLayer>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: MapLayer.inventory,
                  label: Text('Catálogo'),
                ),
                ButtonSegment(value: MapLayer.tickets, label: Text('Tickets')),
                ButtonSegment(value: MapLayer.works, label: Text('Obras')),
              ],
              selected: {_layer},
              onSelectionChanged: (s) {
                setState(() => _layer = s.first);
                _loadPins();
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: AppConfig.mapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: _start,
              zoom: 9,
            ),
            trackCameraPosition: true,
            myLocationEnabled: _located,
            onMapCreated: (c) => _map = c,
            onStyleLoadedCallback: () {
              _styleReady = true;
              _painted = false;
              _paint();
            },
            onMapClick: _onTap,
            onCameraIdle: () {
              final z = _map?.cameraPosition?.zoom;
              if (z != null) _zoom = z;
            },
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  _loading
                      ? 'Cargando…'
                      : _error != null
                      ? 'Error: $_error'
                      : '${_pins.length} pines',
                ),
              ),
            ),
          ),
          if (_selected case final pin?)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                child: ListTile(
                  title: Text(pin.title),
                  subtitle: Text(
                    [
                      pin.subtitle,
                      pin.category,
                      pin.kmLabel,
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selected = null),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _located
          ? FloatingActionButton(
              onPressed: _locateMe,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
