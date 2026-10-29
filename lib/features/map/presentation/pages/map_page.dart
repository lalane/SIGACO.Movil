import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/external_link.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_nav.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/geo_point.dart';
import '../../../../core/ui/device_navigation.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/entities/map_record_target.dart';
import '../map_record_actions.dart';
import '../widgets/picked_point_card.dart';
import '../../domain/entities/pin_cluster.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/repositories/location_source.dart';
import '../../domain/repositories/map_repository.dart';
import '../bloc/map_cubit.dart';
import '../map_camera.dart';
import '../maplibre/maplibre_engine.dart';
import '../map_labels.dart';
import '../tiles/map_tile_source.dart';
import '../tiles/reader_tile_provider.dart';
import '../widgets/map_filters_sheet.dart';
import '../widgets/map_layer_buttons.dart';
import '../widgets/map_results_sheet.dart';
import '../widgets/map_pin_marker.dart';
import '../widgets/map_state_view.dart';
import '../widgets/nearby_sheet.dart';
import '../widgets/pin_cluster_marker.dart';
import '../widgets/pin_detail_card.dart';
import '../widgets/segment_detail_card.dart';

/// El mapa de la concesion (fase 1): cuatro pestanas con filtros, pines con
/// ficha, boton para ubicarse y activos cercanos. El mapa base sale de un
/// [MapTileSource]; sin proveedor configurado se ven solo los pines.
class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.tileSource = const NoTileSource(),
    this.sampleData = false,
    this.initialLayer,
    this.initialPinId,
    this.actions = MapRecordActions.none,
    this.engine = MapEngine.flutterMap,
  });

  final MapTileSource tileSource;

  /// Con que se dibuja el mapa. La app usa MapLibre; las pruebas de la pantalla
  /// usan `flutter_map`, que se puede probar sin el mapa nativo.
  final MapEngine engine;

  /// Abrir el mapa sobre un elemento (desde la ficha de un activo, por
  /// ejemplo): su pestana y su id. Si ya no esta, el mapa se ve normal.
  final MapLayer? initialLayer;
  final String? initialPinId;

  /// Abrir la ficha de un elemento y levantar registros desde el mapa; lo
  /// compone la app segun lo que el usuario puede hacer.
  final MapRecordActions actions;

  /// Los pines son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  @override
  State<MapPage> createState() => _MapPageState();
}

LatLng _ll(GeoPoint p) => LatLng(p.latitude, p.longitude);

class _MapPageState extends State<MapPage> {
  final _controller = MapController();
  final _camera = MapCameraController();

  /// Zoom del mapa, a medio nivel: es lo que decide como se agrupan los pines.
  final _zoom = ValueNotifier<double>(14);

  /// Que tramo quedo bajo el dedo en el ultimo toque (lo llena la capa de
  /// lineas al probar el toque, antes de que llegue el `onTap` del mapa).
  final LayerHitNotifier<String> _segmentHit = ValueNotifier(null);

  /// Centro y zoom cuando no hay nada que mostrar (Brasil, vista general).
  static const _fallbackCenter = LatLng(-15.78, -47.93);

  @override
  void initState() {
    super.initState();
    // Con `flutter_map` la camara se mueve con su controlador; MapLibre conecta
    // la suya al crearse.
    _camera.attach((point, minZoom) async {
      _controller.move(_ll(point), math.max(_controller.camera.zoom, minZoom));
    });
    final cubit = context.read<MapCubit>();
    cubit.load().then((_) => _showInitialPin());
    // Al abrir, el mapa va a donde esta la persona; si llego para ver un
    // elemento concreto, se queda en el.
    if (widget.initialPinId == null) cubit.locate(silent: true);
  }

  /// Selecciona y centra el elemento pedido al abrir el mapa.
  Future<void> _showInitialPin() async {
    final id = widget.initialPinId;
    final layer = widget.initialLayer;
    if (id == null || layer == null || !mounted) return;
    final cubit = context.read<MapCubit>();
    await cubit.selectLayer(layer);
    // El mapa se dibuja un cuadro despues de tener los pines.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || cubit.isClosed) return;
    for (final pin in cubit.state.pinsByLayer[layer] ?? const <MapPin>[]) {
      if (pin.id == id) {
        _focusPin(pin);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _zoom.dispose();
    _segmentHit.dispose();
    super.dispose();
  }

  void _onState(BuildContext context, MapState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MapCubit>();
    final message = switch (state.locate) {
      LocateStatus.serviceDisabled => l10n.mapLocateServiceOff,
      LocateStatus.permissionDenied => l10n.mapLocateDenied,
      LocateStatus.permissionDeniedForever => l10n.mapLocateDeniedForever,
      LocateStatus.unavailable => l10n.mapLocateUnavailable,
      _ => null,
    };
    if (message == null) return;
    final reason = switch (state.locate) {
      LocateStatus.serviceDisabled => LocationFailure.serviceDisabled,
      LocateStatus.permissionDeniedForever =>
        LocationFailure.permissionDeniedForever,
      _ => null,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('map-locate-message'),
          content: Text(message),
          action: reason != null
              ? SnackBarAction(
                  label: l10n.mapOpenSettings,
                  onPressed: () => cubit.openSettings(reason),
                )
              : null,
        ),
      );
    cubit.dismissLocateMessage();
  }

  void _focusOnUser(MapState state) {
    final here = state.location;
    if (here == null) return;
    // Si el mapa todavia no esta listo, la proxima ubicacion lo centrara.
    _camera.moveTo(here.position);
  }

  /// Los mapas sin conexion: al volver se vuelve a buscar el paquete instalado.
  Future<void> _openPacks() async {
    final cubit = context.read<MapCubit>();
    await context.push('/map/packs');
    if (mounted && !cubit.isClosed) await cubit.loadOffline();
  }

  /// Elegir un elemento de la lista de abajo: se selecciona y el mapa se centra.
  void _focusPin(MapPin pin) {
    context.read<MapCubit>().selectPin(pin.id);
    _camera.moveTo(pin.position);
  }

  Future<void> _openNearby() async {
    final cubit = context.read<MapCubit>();
    final picked = await showNearbySheet(context);
    if (picked == null || !mounted) return;
    await cubit.selectLayer(MapLayer.inventory);
    cubit.selectPin(picked.id);
    _camera.moveTo(picked.position);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      bottomNavigationBar: const SigacoModuleNav(current: ModuleTab.map),
      body: BlocConsumer<MapCubit, MapState>(
        listenWhen: (a, b) =>
            a.locate != b.locate || a.focusTick != b.focusTick,
        listener: (context, state) {
          if (state.focusTick > 0) _focusOnUser(state);
          _onState(context, state);
        },
        builder: (context, state) => Column(
          children: [
            SigacoModuleHeader(
              title: l10n.mapTitle,
              subtitle: l10n.mapLayerSubtitle(layerLabel(l10n, state.layer)),
              actions: [
                ModuleHeaderAction(
                  key: const Key('map-nearby-button'),
                  tooltip: l10n.mapNearby,
                  onPressed: _openNearby,
                  icon: Icons.near_me_outlined,
                ),
                // Los mapas descargables son de teselas de imagen: con MapLibre no
                // hay paquetes (el sin conexion sera con sus regiones).
                if (widget.engine == MapEngine.flutterMap)
                  ModuleHeaderAction(
                    key: const Key('map-packs-button'),
                    tooltip: l10n.mapPacksAction,
                    onPressed: _openPacks,
                    icon: Icons.download_for_offline_outlined,
                  ),
                ModuleHeaderAction(
                  key: const Key('map-filter-button'),
                  tooltip: state.activeFilterCount == 0
                      ? l10n.mapFilters
                      : l10n.mapFiltersCount(state.activeFilterCount),
                  badge: state.activeFilterCount,
                  onPressed: () => showMapFilters(context),
                  icon: Icons.filter_list,
                ),
              ],
            ),
            if (widget.sampleData)
              _Banner(
                key: const Key('map-sample-banner'),
                text: l10n.mapSampleBanner,
              ),
            if (state.status == MapStatus.ready && state.layerSavedAt != null)
              _SavedBanner(savedAt: state.layerSavedAt!),
            Expanded(child: _content(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, MapState state) {
    final cubit = context.read<MapCubit>();
    switch (state.status) {
      case MapStatus.loading:
        return _WithLayers(state: state, child: const MapStateView.loading());
      case MapStatus.failure:
        return _WithLayers(
          state: state,
          child: MapStateView.error(
            state.error ?? MapError.server,
            onRetry: cubit.refresh,
          ),
        );
      case MapStatus.ready:
        return _MapArea(
          state: state,
          tileSource: widget.tileSource,
          controller: _controller,
          zoom: _zoom,
          segmentHit: _segmentHit,
          onPick: _focusPin,
          actions: widget.actions,
          engine: widget.engine,
          camera: _camera,
        );
    }
  }
}

/// Una pantalla de estado (cargando, error) con los botones de capa a la
/// izquierda: una capa sin permiso no debe impedir abrir las demas.
class _WithLayers extends StatelessWidget {
  const _WithLayers({required this.state, required this.child});

  final MapState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: r.s(12),
          bottom: r.s(12),
          child: MapLayerButtons(
            current: state.layer,
            onSelect: context.read<MapCubit>().selectLayer,
          ),
        ),
      ],
    );
  }
}

/// Los pines salen del telefono: se dice de cuando son para no presentarlos como
/// si fueran de ahora.
class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.savedAt});

  /// UTC.
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final zone = context.watch<ConcessionZoneCubit>().state;
    return _Banner(
      key: const Key('map-saved-banner'),
      text: AppLocalizations.of(
        context,
      ).mapFromPhone(formatInZone(context, savedAt, zone)),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      width: double.infinity,
      color: StatusColors.attended.withValues(alpha: 0.25),
      padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(6)),
      child: Text(text, style: TextStyle(fontSize: r.s(12))),
    );
  }
}

class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.state,
    required this.tileSource,
    required this.controller,
    required this.zoom,
    required this.segmentHit,
    required this.onPick,
    required this.actions,
    required this.engine,
    required this.camera,
  });

  final MapRecordActions actions;
  final MapEngine engine;
  final MapCameraController camera;
  final MapState state;
  final MapTileSource tileSource;
  final MapController controller;
  final ValueNotifier<double> zoom;
  final LayerHitNotifier<String> segmentHit;
  final ValueChanged<MapPin> onPick;

  /// Una lectura mas vieja que esto ya no es "la de ahora": se marca como la
  /// ultima posicion conocida (DTF M10, RB-10-22).
  static const _staleAfter = Duration(minutes: 2);

  /// Levanta un registro en la ubicacion del usuario.
  void _recordHere(BuildContext context, UserLocation here) {
    if (!here.isTrusted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mapRecordMocked)),
        );
      return;
    }
    final fresh =
        DateTime.now().toUtc().difference(here.capturedAt) <= _staleAfter;
    _create(
      context,
      MapRecordTarget(
        latitude: here.position.latitude,
        longitude: here.position.longitude,
        origin: fresh ? MapTargetOrigin.gps : MapTargetOrigin.lastKnown,
        accuracyMeters: here.accuracyMeters,
        readAt: here.capturedAt,
      ),
    );
  }

  /// Abre el formulario del registro y, al volver, vuelve a consultar la capa:
  /// lo recien creado ya debe verse en el mapa y en su lista.
  Future<void> _create(BuildContext context, MapRecordTarget target) async {
    final cubit = context.read<MapCubit>();
    await actions.onCreate?.call(target);
    if (context.mounted && !cubit.isClosed) await cubit.refresh();
  }

  /// Levanta un registro sobre el elemento: conserva el activo y su ubicacion.
  Future<void> _createFromPin(BuildContext context, MapPin pin) => _create(
    context,
    MapRecordTarget(
      latitude: pin.position.latitude,
      longitude: pin.position.longitude,
      origin: MapTargetOrigin.asset,
      assetId: pin.layer == MapLayer.inventory ? pin.id : null,
      kmLabel: pin.kmLabel,
    ),
  );

  Future<void> _createFromPoint(BuildContext context, GeoPoint point) =>
      _create(
        context,
        MapRecordTarget(
          latitude: point.latitude,
          longitude: point.longitude,
          origin: MapTargetOrigin.mapPoint,
        ),
      );

  /// Entrega el punto a la app de navegacion del telefono.
  Future<void> _navigate(
    BuildContext context,
    GeoPoint point, {
    String? label,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).mapNavigateFailed;
    final ok = await DeviceNavigation.open(
      point.latitude,
      point.longitude,
      label: label,
    );
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('map-navigate-failed'),
            content: Text(message),
          ),
        );
    }
  }

  /// Actualiza el zoom que usa la agrupacion, a medio nivel para no
  /// reagrupar en cada gesto.
  void _syncZoom([double? z]) {
    final double value;
    try {
      value = z ?? controller.camera.zoom;
    } catch (_) {
      return;
    }
    final q = (value * 2).round() / 2;
    if (q != zoom.value) zoom.value = q;
  }

  /// Desde que zoom se escribe el codigo de cada tramo sobre la linea.
  static const _segmentLabelZoom = 15.0;

  /// Una etiqueta por codigo de tramo (los dos sentidos comparten codigo), en el
  /// punto medio de la primera linea.
  static List<Marker> _segmentLabels(List<RoadSegment> segments) {
    final seen = <String>{};
    return [
      for (final s in segments)
        if (seen.add(s.code))
          Marker(
            point: _ll(s.points[s.points.length ~/ 2]),
            width: 120,
            height: 24,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  key: Key('map-segment-label-${s.code}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.code,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
    ];
  }

  /// Acerca el mapa a los pines de un grupo.
  void _zoomInto(PinCluster cluster) {
    try {
      controller.fitCamera(
        CameraFit.coordinates(
          coordinates: [for (final p in cluster.pins) _ll(p.position)],
          padding: const EdgeInsets.all(72),
          maxZoom: tileSource.maxZoom,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<MapCubit>();
    final pins = state.visiblePins;
    final selected = state.selectedPin;
    final here = state.location;
    // Mapa base: el de en linea y, si hay un paquete instalado, sus teselas
    // encima. Sin conexion solo queda el paquete; con conexion el de en linea
    // rellena lo que el paquete no cubre.
    final online = context.select((ConnectivityCubit c) => c.state.online);
    // Los paquetes sin conexion son teselas de imagen de `flutter_map`.
    final reader = engine == MapEngine.flutterMap ? state.offlineReader : null;
    final pack = engine == MapEngine.flutterMap ? state.offlinePack : null;
    final onlineLayer = tileSource.buildLayer();
    final tileLayers = <Widget>[
      if (onlineLayer != null && (reader == null || online)) onlineLayer,
      if (reader != null)
        TileLayer(
          key: ValueKey(reader),
          tileProvider: ReaderTileProvider(reader),
          urlTemplate: 'sigaco-pack://{z}/{x}/{y}',
          userAgentPackageName: 'com.idare.sigaco_movil',
          minNativeZoom: pack?.minZoom ?? 0,
          maxNativeZoom: pack?.maxZoom ?? 19,
        ),
    ];
    final usingPackOnly = reader != null && !online;

    // El encuadre inicial cambia con la pestana y con los filtros, no al
    // tocar un pin ni al moverse el usuario.
    final segments = state.segments;
    final selectedSegment = state.selectedSegment;
    // Se resalta el tramo elegido o, si se eligio un pin, el tramo al que
    // pertenece: asi se ve que el elemento esta dentro de el.
    bool isHighlighted(RoadSegment s) =>
        s.id == selectedSegment?.id ||
        (selected != null &&
            selected.segmentCode == s.code &&
            selected.direction == s.direction);
    // Sin pines que encuadrar se encuadra la carretera.
    final fitKey =
        '${state.layer.name}|${pins.map((e) => e.id).join(',')}|${pins.isEmpty ? segments.length : 0}';
    final points = pins.isNotEmpty
        ? [for (final pin in pins) _ll(pin.position)]
        : [
            for (final s in segments)
              for (final point in s.points) _ll(point),
          ];

    return Stack(
      children: [
        if (engine == MapEngine.maplibre)
          MapLibreEngine(
            state: state,
            tileSource: tileSource,
            camera: camera,
            fitKey: fitKey,
          )
        else
          ClipRect(
            child: FlutterMap(
              key: ValueKey(fitKey),
              mapController: controller,
              options: MapOptions(
                initialCenter: points.isEmpty
                    ? _MapPageState._fallbackCenter
                    : points.first,
                initialZoom: points.isEmpty ? 4 : 14,
                initialCameraFit: points.length > 1
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: EdgeInsets.fromLTRB(
                          r.s(48),
                          r.s(48),
                          r.s(48),
                          r.s(180),
                        ),
                        maxZoom: 16,
                      )
                    : null,
                minZoom: 3,
                maxZoom: tileSource.maxZoom,
                backgroundColor: p.fieldFill,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) {
                  // El toque cae en un tramo solo si la capa de lineas lo anoto
                  // justo antes; se lee y se borra para no arrastrar uno viejo.
                  final hit = segmentHit.value?.hitValues.firstOrNull;
                  segmentHit.value = null;
                  if (hit != null) {
                    cubit.selectSegment(hit);
                  } else {
                    cubit.selectPin(null);
                    cubit.selectSegment(null);
                  }
                },
                // Mantener presionado elige un punto (para registrar o navegar).
                onLongPress: (_, point) =>
                    cubit.pickPoint(GeoPoint(point.latitude, point.longitude)),
                onMapReady: () => _syncZoom(),
                onPositionChanged: (camera, hasGesture) {
                  // Un arrastre que empezo sobre una linea no es un toque en ella.
                  if (hasGesture) segmentHit.value = null;
                  _syncZoom(camera.zoom);
                },
              ),
              children: [
                ...tileLayers,
                // La carretera va debajo de los pines: son el fondo en el que se
                // leen.
                if (segments.isNotEmpty)
                  PolylineLayer<String>(
                    hitNotifier: segmentHit,
                    polylines: [
                      for (final s in segments)
                        Polyline<String>(
                          points: [for (final point in s.points) _ll(point)],
                          strokeWidth: isHighlighted(s) ? 8 : 5,
                          color: segmentColor(s.direction),
                          borderStrokeWidth: 2,
                          borderColor: Colors.white,
                          hitValue: s.id,
                        ),
                    ],
                  ),
                if (segments.isNotEmpty)
                  ValueListenableBuilder<double>(
                    valueListenable: zoom,
                    builder: (context, z, _) => z < _segmentLabelZoom
                        ? const SizedBox.shrink()
                        : MarkerLayer(markers: _segmentLabels(segments)),
                  ),
                if (here != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _ll(here.position),
                        radius: here.accuracyMeters,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderColor: Colors.blue.withValues(alpha: 0.5),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                ValueListenableBuilder<double>(
                  valueListenable: zoom,
                  builder: (context, z, _) => MarkerLayer(
                    markers: [
                      for (final item in clusterPins(
                        pins,
                        zoom: z,
                        radiusPx: state.settings.clusterRadiusPx,
                        keepSingleId: state.selectedId,
                      ))
                        switch (item) {
                          SinglePin(:final pin) => Marker(
                            point: _ll(pin.position),
                            width: 48,
                            height: 48,
                            child: MapPinMarker(
                              key: Key('map-pin-${pin.id}'),
                              pin: pin,
                              selected: pin.id == state.selectedId,
                              onTap: () => cubit.selectPin(pin.id),
                            ),
                          ),
                          PinCluster() => Marker(
                            point: _ll(item.position),
                            width: 52,
                            height: 52,
                            child: PinClusterMarker(
                              key: Key('map-cluster-${item.key}'),
                              cluster: item,
                              onTap: () => _zoomInto(item),
                            ),
                          ),
                        },
                    ],
                  ),
                ),
                if (state.pickedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ll(state.pickedPoint!),
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.place,
                          key: Key('map-picked-marker'),
                          size: 40,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                if (here != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ll(here.position),
                        width: 22,
                        height: 22,
                        child: Container(
                          key: const Key('map-user-marker'),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        if (pins.isEmpty)
          Positioned(
            top: r.s(16),
            left: r.s(24),
            right: r.s(24),
            child: Card(
              key: const Key('map-empty'),
              color: solidCard(p),
              child: Padding(
                padding: EdgeInsets.all(r.s(12)),
                child: Text(
                  state.activeFilterCount > 0
                      ? l10n.mapEmptyFiltered
                      : l10n.mapEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Positioned(
          top: r.s(8),
          right: r.s(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (reader != null)
                Chip(
                  key: const Key('map-offline-badge'),
                  avatar: Icon(
                    online ? Icons.download_done : Icons.cloud_off_outlined,
                    size: 16,
                  ),
                  label: Text(l10n.mapOfflineBadge(pack?.name ?? '')),
                  visualDensity: VisualDensity.compact,
                ),
              if (here != null) _AccuracyChip(state: state),
            ],
          ),
        ),
        // Abajo, en una sola columna: botones de capa y de ubicar, la
        // atribucion y la hoja de resultados (o la ficha del pin elegido).
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.s(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Con una ficha abierta se oculta: el mapa necesita
                    // el espacio.
                    if (selected == null && selectedSegment == null)
                      MapLayerButtons(
                        current: state.layer,
                        onSelect: cubit.selectLayer,
                      ),
                    const Spacer(),
                    if (actions.onCreate != null &&
                        here != null &&
                        selected == null &&
                        state.pickedPoint == null) ...[
                      FloatingActionButton.small(
                        key: const Key('map-record-here'),
                        heroTag: 'map-record-here',
                        tooltip: l10n.mapRecordHere,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        onPressed: () => _recordHere(context, here),
                        child: const Icon(Icons.add_location_alt_outlined),
                      ),
                      SizedBox(width: r.s(8)),
                    ],
                    FloatingActionButton(
                      key: const Key('map-locate'),
                      heroTag: 'map-locate',
                      tooltip: l10n.mapLocate,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E293B),
                      shape: const CircleBorder(),
                      onPressed: state.locate == LocateStatus.locating
                          ? null
                          : cubit.locate,
                      child: state.locate == LocateStatus.locating
                          ? SizedBox(
                              width: r.s(22),
                              height: r.s(22),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(r.s(12), r.s(6), r.s(12), r.s(6)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Attribution(
                    source: tileSource,
                    packAttribution: reader == null ? null : pack?.attribution,
                    hasTiles: engine == MapEngine.maplibre
                        ? tileSource.hasBase
                        : tileLayers.isNotEmpty,
                    usingPackOnly: usingPackOnly,
                  ),
                ),
              ),
              if (state.pickedPoint != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(12), 0, r.s(12), r.s(12)),
                  child: PickedPointCard(
                    point: state.pickedPoint!,
                    onClose: cubit.clearPickedPoint,
                    onNavigate: () => _navigate(context, state.pickedPoint!),
                    onCreate: actions.onCreate == null
                        ? null
                        : () => _createFromPoint(context, state.pickedPoint!),
                  ),
                )
              else if (selected != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(12), 0, r.s(12), r.s(12)),
                  child: PinDetailCard(
                    pin: selected,
                    distanceMeters: here?.position.distanceTo(
                      selected.position,
                    ),
                    onClose: () => cubit.selectPin(null),
                    onOpen: actions.openRoute?.call(selected) == null
                        ? null
                        : () => context.push(actions.openRoute!(selected)!),
                    onCreate: actions.onCreate == null
                        ? null
                        : () => _createFromPin(context, selected),
                    onNavigate: () => _navigate(
                      context,
                      selected.position,
                      label: selected.title,
                    ),
                  ),
                )
              else if (selectedSegment != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(12), 0, r.s(12), r.s(12)),
                  child: SegmentDetailCard(
                    segment: selectedSegment,
                    layer: state.layer,
                    pinCount: pins
                        .where(
                          (pin) =>
                              pin.segmentCode == selectedSegment.code &&
                              pin.direction == selectedSegment.direction,
                        )
                        .length,
                    onClose: () => cubit.selectSegment(null),
                  ),
                )
              else
                MapResultsSheet(
                  pins: pins,
                  onPick: onPick,
                  onRefine: () => showMapFilters(context),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccuracyChip extends StatelessWidget {
  const _AccuracyChip({required this.state});

  final MapState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final here = state.location!;
    final max = state.settings.minAccuracyMeters;
    final meters = here.accuracyMeters.round().toString();
    final good = here.isTrusted && here.meetsAccuracy(max);
    final text = !here.isTrusted
        ? l10n.mapMockedLocation
        : good
        ? l10n.mapAccuracy(meters)
        : l10n.mapAccuracyLow(meters, max.round().toString());
    return Tooltip(
      message: text,
      child: Chip(
        key: Key(good ? 'map-accuracy-ok' : 'map-accuracy-low'),
        avatar: Icon(
          good ? Icons.gps_fixed : Icons.gps_not_fixed,
          size: 16,
          color: good ? StatusColors.closed : StatusColors.attended,
        ),
        label: Text(
          good ? l10n.mapAccuracy(meters) : '±$meters m',
          overflow: TextOverflow.ellipsis,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({
    required this.source,
    required this.hasTiles,
    this.packAttribution,
    this.usingPackOnly = false,
  });

  final MapTileSource source;
  final bool hasTiles;

  /// Atribucion que trae el paquete instalado, si la trae.
  final String? packAttribution;

  /// Sin conexion: solo se ven las teselas del paquete.
  final bool usingPackOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = !hasTiles
        ? l10n.mapNoTiles
        : (usingPackOnly
              ? (packAttribution ?? source.attribution)
              : source.attribution ?? packAttribution);
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final url = hasTiles ? source.attributionUrl : null;
    final label = Container(
      key: Key(hasTiles ? 'map-attribution' : 'map-no-tiles'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF1F2937),
          decoration: url == null ? null : TextDecoration.underline,
        ),
      ),
    );
    if (url == null) return label;
    return Semantics(
      link: true,
      label: text,
      child: InkWell(
        key: const Key('map-attribution-link'),
        onTap: () => ExternalLink.open(url),
        child: label,
      ),
    );
  }
}
