import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/map_pack.dart';
import '../../domain/entities/geo_bounds.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/map_settings.dart';
import '../../domain/entities/nearby_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/entities/segment_pavement.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_source.dart';
import '../../domain/repositories/map_pack_manager.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';
import '../../domain/repositories/segment_pavement_source.dart';

enum MapStatus { loading, ready, failure }

/// Como va la capa de pavimento por tramo. [unavailable]: el perfil no ve la
/// capa «Indicadores y pavimento» (DTF M10 §4.2) o no hay fuente; no se ofrece.
enum PavementStatus { idle, loading, ready, unavailable, failure }

/// Como va la busqueda de la ubicacion del usuario.
enum LocateStatus {
  idle,
  locating,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class MapState extends Equatable {
  const MapState({
    this.layer = MapLayer.tickets,
    this.status = MapStatus.loading,
    this.pinsByLayer = const {},
    this.savedAt = const {},
    this.segments = const [],
    this.segmentsSavedAt,
    this.selectedSegmentId,
    this.error,
    this.categories = const {},
    this.statusFilter,
    this.operatingFilter,
    this.groupFilter,
    this.serverNearby,
    this.pickedPoint,
    this.selectedId,
    this.settings = const MapSettings(),
    this.location,
    this.locate = LocateStatus.idle,
    this.focusTick = 0,
    this.offlinePack,
    this.offlineReader,
    this.byArea = false,
    this.areaZoomedOut = false,
    this.areaLoading = false,
    this.areaTruncated = false,
    this.areaError,
    this.pavementOn = false,
    this.pavement,
    this.pavementStatus = PavementStatus.idle,
  });

  final MapLayer layer;

  /// Estado de la pestana abierta.
  final MapStatus status;
  final Map<MapLayer, List<MapPin>> pinsByLayer;

  /// Pestanas cuyos pines salen del telefono y no del servidor (sin conexion),
  /// con cuando se guardaron (UTC).
  final Map<MapLayer, DateTime> savedAt;

  /// Los tramos de la carretera, que no dependen de la pestana, y cuando se
  /// guardaron si salen del telefono (UTC).
  final List<RoadSegment> segments;
  final DateTime? segmentsSavedAt;
  final String? selectedSegmentId;
  final MapError? error;

  /// Categorias marcadas en el filtro; vacio = todas.
  final Set<String> categories;
  final PinStatus? statusFilter;

  /// Estado operativo elegido en el filtro de equipos; null = todos.
  final OperatingState? operatingFilter;

  /// El grupo elegido (en los activos, el subsistema); null = todos.
  final String? groupFilter;

  /// Los activos cercanos que dio el servidor para la ultima ubicacion y radio;
  /// null si no los dio (sin conexion): entonces se calculan en el telefono.
  final List<NearbyPin>? serverNearby;

  /// El punto que la persona eligio manteniendo presionado el mapa.
  final GeoPoint? pickedPoint;
  final String? selectedId;
  final MapSettings settings;
  final UserLocation? location;
  final LocateStatus locate;

  /// Sube cada vez que hay que centrar el mapa en la ubicacion del usuario.
  final int focusTick;

  /// El paquete de mapa sin conexion instalado, si hay uno, y su lector de
  /// teselas (abierto mientras el mapa esta en pantalla).
  final InstalledPack? offlinePack;
  final TileReader? offlineReader;

  /// La pestana abierta se pide por zona (el inventario): sus pines son los del
  /// rectangulo visible y cambian al mover el mapa.
  final bool byArea;

  /// Pidiendo por zona, el mapa esta mas lejos que [MapCubit.areaMinZoom]: no
  /// se piden activos sueltos y se pide acercarse.
  final bool areaZoomedOut;

  /// Hay una consulta de zona en curso; los pines anteriores siguen a la vista.
  final bool areaLoading;

  /// La ultima zona tenia mas activos de los que trae una consulta.
  final bool areaTruncated;

  /// La ultima consulta de zona fallo; los pines que ya estaban se conservan.
  final MapError? areaError;

  /// Los tramos se pintan por el estado de su pavimento (HU-MOB-10-01 CA-04)
  /// en vez de por su sentido. Es independiente de la pestana de pines.
  final bool pavementOn;
  final PavementLayer? pavement;
  final PavementStatus pavementStatus;

  /// El nivel de pavimento de cada tramo, si la capa esta prendida y cargada.
  PavementLayer? get shownPavement =>
      pavementOn && pavementStatus == PavementStatus.ready ? pavement : null;

  List<MapPin> get layerPins => pinsByLayer[layer] ?? const [];

  /// Cuando se guardaron los pines de la pestana abierta, si son del telefono.
  DateTime? get layerSavedAt => savedAt[layer];

  /// Categorias de la pestana, en orden, para el filtro. Las marcadas siempre
  /// estan, aunque la zona que se ve no tenga ninguna: asi se pueden desmarcar.
  List<String> get availableCategories {
    final set = <String>{
      ...categories,
      for (final p in layerPins)
        if (p.category != null) p.category!,
    };
    return set.toList()..sort();
  }

  int get activeFilterCount =>
      categories.length +
      (statusFilter == null ? 0 : 1) +
      (operatingFilter == null ? 0 : 1) +
      (groupFilter == null ? 0 : 1);

  /// Los grupos de la pestana (subsistemas de los activos), en orden. El elegido
  /// siempre esta.
  List<String> get availableGroups {
    final set = <String>{
      ?groupFilter,
      for (final p in layerPins)
        if (p.group != null) p.group!,
    };
    return set.toList()..sort();
  }

  /// Si la pestana abierta tiene equipos con estado operativo (para mostrar su
  /// filtro solo donde aplica).
  bool get hasOperatingStates =>
      operatingFilter != null || layerPins.any((p) => p.operatingState != null);

  /// Lo que se dibuja: la pestana con sus filtros.
  List<MapPin> get visiblePins => [
    for (final p in layerPins)
      if ((categories.isEmpty ||
              (p.category != null && categories.contains(p.category))) &&
          (statusFilter == null || p.status == statusFilter) &&
          (operatingFilter == null || p.operatingState == operatingFilter) &&
          (groupFilter == null || p.group == groupFilter))
        p,
  ];

  RoadSegment? get selectedSegment {
    for (final s in segments) {
      if (s.id == selectedSegmentId) return s;
    }
    return null;
  }

  MapPin? get selectedPin {
    for (final p in layerPins) {
      if (p.id == selectedId) return p;
    }
    return null;
  }

  // Supuesto S-GIS-12: «Cercanos» lista activos (lo que se elige para levantar
  // un registro), no todas las capas.
  /// Los activos de inventario cercanos a la ultima ubicacion, con el radio
  /// elegido. Son lo que se elige para levantar un ticket, una inspeccion o un
  /// mantenimiento. Con conexion los da el servidor (mide hasta la geometria de
  /// cada activo); sin ella se calculan en el telefono con los pines.
  List<NearbyPin> get nearby {
    final here = location;
    if (here == null) return const [];
    final fromServer = serverNearby;
    if (fromServer != null) return fromServer;
    return nearbyPins(
      pinsByLayer[MapLayer.inventory] ?? const [],
      here.position,
      settings.nearbyRadiusMeters,
    );
  }

  bool get inventoryLoaded => pinsByLayer.containsKey(MapLayer.inventory);

  MapState copyWith({
    MapLayer? layer,
    MapStatus? status,
    Map<MapLayer, List<MapPin>>? pinsByLayer,
    Map<MapLayer, DateTime>? savedAt,
    List<RoadSegment>? segments,
    DateTime? segmentsSavedAt,
    bool clearSegmentsSavedAt = false,
    String? selectedSegmentId,
    bool clearSegmentSelection = false,
    MapError? error,
    bool clearError = false,
    Set<String>? categories,
    PinStatus? statusFilter,
    bool clearStatusFilter = false,
    OperatingState? operatingFilter,
    bool clearOperatingFilter = false,
    String? groupFilter,
    bool clearGroupFilter = false,
    List<NearbyPin>? serverNearby,
    bool clearServerNearby = false,
    GeoPoint? pickedPoint,
    bool clearPickedPoint = false,
    String? selectedId,
    bool clearSelection = false,
    MapSettings? settings,
    UserLocation? location,
    LocateStatus? locate,
    int? focusTick,
    InstalledPack? offlinePack,
    TileReader? offlineReader,
    bool clearOffline = false,
    bool? byArea,
    bool? areaZoomedOut,
    bool? areaLoading,
    bool? areaTruncated,
    MapError? areaError,
    bool clearAreaError = false,
    bool? pavementOn,
    PavementLayer? pavement,
    PavementStatus? pavementStatus,
  }) => MapState(
    layer: layer ?? this.layer,
    status: status ?? this.status,
    pinsByLayer: pinsByLayer ?? this.pinsByLayer,
    savedAt: savedAt ?? this.savedAt,
    segments: segments ?? this.segments,
    segmentsSavedAt: clearSegmentsSavedAt
        ? null
        : (segmentsSavedAt ?? this.segmentsSavedAt),
    selectedSegmentId: clearSegmentSelection
        ? null
        : (selectedSegmentId ?? this.selectedSegmentId),
    error: clearError ? null : (error ?? this.error),
    categories: categories ?? this.categories,
    statusFilter: clearStatusFilter
        ? null
        : (statusFilter ?? this.statusFilter),
    operatingFilter: clearOperatingFilter
        ? null
        : (operatingFilter ?? this.operatingFilter),
    groupFilter: clearGroupFilter ? null : (groupFilter ?? this.groupFilter),
    serverNearby: clearServerNearby
        ? null
        : (serverNearby ?? this.serverNearby),
    pickedPoint: clearPickedPoint ? null : (pickedPoint ?? this.pickedPoint),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    settings: settings ?? this.settings,
    location: location ?? this.location,
    locate: locate ?? this.locate,
    focusTick: focusTick ?? this.focusTick,
    offlinePack: clearOffline ? null : (offlinePack ?? this.offlinePack),
    offlineReader: clearOffline ? null : (offlineReader ?? this.offlineReader),
    byArea: byArea ?? this.byArea,
    areaZoomedOut: areaZoomedOut ?? this.areaZoomedOut,
    areaLoading: areaLoading ?? this.areaLoading,
    areaTruncated: areaTruncated ?? this.areaTruncated,
    areaError: clearAreaError ? null : (areaError ?? this.areaError),
    pavementOn: pavementOn ?? this.pavementOn,
    pavement: pavement ?? this.pavement,
    pavementStatus: pavementStatus ?? this.pavementStatus,
  );

  @override
  List<Object?> get props => [
    layer,
    status,
    pinsByLayer,
    savedAt,
    segments,
    segmentsSavedAt,
    selectedSegmentId,
    error,
    categories,
    statusFilter,
    operatingFilter,
    groupFilter,
    serverNearby,
    pickedPoint,
    selectedId,
    settings,
    location,
    locate,
    focusTick,
    offlinePack,
    offlineReader,
    byArea,
    areaZoomedOut,
    areaLoading,
    areaTruncated,
    areaError,
    pavementOn,
    pavement,
    pavementStatus,
  ];
}

/// Los pines de una zona recien consultada sin que parpadeen los que ya se
/// veian: entran los [fresh] y, de los [previous], se quedan los que siguen en
/// [visible] (lo que se ve ahora, que pudo moverse mientras llegaba la
/// respuesta) y que la consulta no desmiente. Dentro de [area] la respuesta
/// manda, salvo si vino recortada ([truncated]): entonces lo que ya estaba a la
/// vista se conserva.
List<MapPin> mergeAreaPins({
  required List<MapPin> previous,
  required List<MapPin> fresh,
  required GeoBounds area,
  required GeoBounds visible,
  required bool truncated,
}) {
  final ids = {for (final p in fresh) p.id};
  return [
    ...fresh,
    for (final p in previous)
      if (!ids.contains(p.id) &&
          visible.contains(p.position) &&
          (truncated || !area.contains(p.position)))
        p,
  ];
}

/// El mapa: pestanas, filtros, ubicacion del usuario y activos cercanos.
class MapCubit extends Cubit<MapState> {
  MapCubit({
    required this.repository,
    required this.locationSource,
    this.packs,
    this.segmentsRepository,
    MapSettings settings = const MapSettings(),
    this.areaDelay = const Duration(milliseconds: 400),
  }) : super(MapState(settings: settings));

  final MapRepository repository;
  final LocationSource locationSource;

  /// Paquetes de mapa sin conexion; sin esto el mapa solo usa el de en linea.
  final MapPackManager? packs;

  /// Los tramos de la carretera; sin esto el mapa solo dibuja pines.
  final RoadSegmentsRepository? segmentsRepository;

  /// Cuanto se espera, despues de que el mapa deja de moverse, para pedir la
  /// zona: arrastrar o acercar con los dedos no dispara una consulta por cuadro.
  final Duration areaDelay;

  /// Desde que zoom se piden los activos por zona (zoom de teselas de 256 px,
  /// el mismo que usa el visor de la web). Mas lejos serian miles de pines.
  static const areaMinZoom = 12.0;

  /// Cuanto se agranda por cada lado el rectangulo visible al pedirlo: mover un
  /// poco el mapa no obliga a otra consulta.
  static const areaMargin = 0.25;

  /// Lo minimo que se pide alrededor de la persona para calcular sus cercanos
  /// sin conexion (metros).
  static const _aroundMeters = 1000.0;

  /// Lo que se ve del mapa (lo reporta la pantalla) y su zoom.
  GeoBounds? _viewport;
  double _viewportZoom = 0;
  Timer? _areaTimer;

  /// La consulta de zona en curso: una nueva cancela la anterior.
  MapQueryCancel? _areaQuery;

  /// La ultima zona que se trajo completa o recortada.
  GeoBounds? _loadedArea;
  var _loadedTruncated = false;

  /// El centro de lo que se ve, para acercar el mapa sin moverlo de lugar.
  GeoPoint? get viewportCenter => _viewport?.center;

  /// Si [layer] se pide por zona (el inventario contra el servidor).
  bool _byArea(MapLayer layer) {
    final source = repository;
    return source is AreaPinsSource &&
        (source as AreaPinsSource).loadsByArea(layer);
  }

  /// Carga la pestana abierta y el paquete de mapa sin conexion, si hay.
  Future<void> load() async {
    if (_byArea(state.layer) != state.byArea) {
      emit(state.copyWith(byArea: _byArea(state.layer)));
    }
    await Future.wait([
      _loadLayer(state.layer, showLoading: true),
      loadSegments(),
      loadOffline(),
    ]);
  }

  /// Busca el paquete instalado y abre sus teselas. Se vuelve a llamar al
  /// volver de la pantalla de paquetes. Un fallo aqui no estorba al mapa.
  Future<void> loadOffline() async {
    final manager = packs;
    if (manager == null) return;
    InstalledPack? pack;
    TileReader? reader;
    try {
      final all = await manager.installed();
      if (all.isNotEmpty) {
        pack = ([
          ...all,
        ]..sort((a, b) => b.installedAt.compareTo(a.installedAt))).first;
        reader = await manager.openActive();
      }
    } catch (_) {
      pack = null;
      reader = null;
    }
    if (isClosed) {
      await reader?.close();
      return;
    }
    final old = state.offlineReader;
    if (reader == null) {
      emit(state.copyWith(clearOffline: true));
    } else {
      emit(state.copyWith(offlinePack: pack, offlineReader: reader));
    }
    if (old != null && !identical(old, reader)) {
      try {
        await old.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() async {
    _areaTimer?.cancel();
    _areaQuery?.cancel();
    final reader = state.offlineReader;
    await super.close();
    try {
      await reader?.close();
    } catch (_) {}
  }

  /// Hay de donde sacar el pavimento por tramo (no con datos de ejemplo).
  bool get pavementSupported => segmentsRepository is SegmentPavementSource;

  /// Prende o apaga la capa de pavimento: la primera vez la pide al servidor
  /// (o la toma del telefono sin conexion).
  Future<void> togglePavement() async {
    if (state.pavementOn) {
      emit(state.copyWith(pavementOn: false));
      return;
    }
    emit(state.copyWith(pavementOn: true));
    if (state.pavement == null ||
        state.pavementStatus == PavementStatus.failure) {
      await loadPavement();
    }
  }

  Future<void> loadPavement() async {
    final source = segmentsRepository;
    if (source is! SegmentPavementSource) {
      emit(
        state.copyWith(
          pavementOn: false,
          pavementStatus: PavementStatus.unavailable,
        ),
      );
      return;
    }
    emit(state.copyWith(pavementStatus: PavementStatus.loading));
    try {
      final layer = await (source as SegmentPavementSource).pavement();
      if (isClosed) return;
      emit(
        state.copyWith(pavement: layer, pavementStatus: PavementStatus.ready),
      );
    } on MapException catch (e) {
      if (isClosed) return;
      final denied =
          e.error == MapError.permissionDenied ||
          e.error == MapError.notAvailable;
      emit(
        state.copyWith(
          pavementOn: false,
          pavementStatus: denied
              ? PavementStatus.unavailable
              : PavementStatus.failure,
        ),
      );
    }
  }

  /// Vuelve a pedir la pestana abierta (reintento o jalar para actualizar). Por
  /// zona, vuelve a pedir la zona sin quitar lo que se ve.
  Future<void> refresh() => _loadLayer(state.layer, showLoading: true);

  Future<void> selectLayer(MapLayer layer) async {
    if (layer == state.layer) return;
    // Una zona que estaba por pedirse ya no hace falta en otra pestana.
    _areaTimer?.cancel();
    final byArea = _byArea(layer);
    final known = byArea || state.pinsByLayer.containsKey(layer);
    emit(
      state.copyWith(
        layer: layer,
        byArea: byArea,
        status: known ? MapStatus.ready : MapStatus.loading,
        categories: const {},
        clearStatusFilter: true,
        clearGroupFilter: true,
        clearSelection: true,
        clearSegmentSelection: true,
        clearPickedPoint: true,
        clearError: true,
        clearAreaError: true,
        areaLoading: false,
        areaTruncated: byArea && _loadedTruncated,
        areaZoomedOut: byArea && _viewport != null && _zoomedOut,
      ),
    );
    if (byArea) {
      await _loadArea();
    } else if (!known) {
      await _loadLayer(layer, showLoading: false);
    }
  }

  Future<void> _loadLayer(MapLayer layer, {required bool showLoading}) async {
    if (_byArea(layer)) return _loadArea(force: true);
    if (showLoading && layer == state.layer) {
      emit(state.copyWith(status: MapStatus.loading, clearError: true));
    }
    try {
      final pins = await repository.pins(layer);
      if (isClosed) return;
      final all = {...state.pinsByLayer, layer: pins};
      // Lo que llega marcado como guardado viene del telefono, no del servidor.
      final saved = {...state.savedAt}..remove(layer);
      if (pins case PinListing(:final cachedAt?)) saved[layer] = cachedAt;
      emit(
        state.layer == layer
            ? state.copyWith(
                pinsByLayer: all,
                savedAt: saved,
                status: MapStatus.ready,
                clearError: true,
              )
            : state.copyWith(pinsByLayer: all, savedAt: saved),
      );
    } on MapException catch (e) {
      if (isClosed || state.layer != layer) return;
      emit(state.copyWith(status: MapStatus.failure, error: e.error));
    }
  }

  bool get _zoomedOut => _viewportZoom < areaMinZoom;

  /// Lo que se ve del mapa cambio (lo llama la pantalla al mover la camara, en
  /// cada cuadro si hace falta). Si la pestana se pide por zona, se pide la
  /// nueva cuando el mapa deja de moverse por [areaDelay].
  void viewportChanged(GeoBounds visible, double zoom) {
    if (isClosed || !visible.isValid || !zoom.isFinite) return;
    _viewport = visible;
    _viewportZoom = zoom;
    if (!state.byArea) return;
    _areaTimer?.cancel();
    _areaTimer = Timer(areaDelay, () {
      if (!isClosed) unawaited(_loadArea());
    });
  }

  void _cancelArea() {
    _areaTimer?.cancel();
    _areaQuery?.cancel();
    _areaQuery = null;
  }

  /// Trae los activos de la zona que se ve (agrandada por [areaMargin]) o, con
  /// [around], los de ese rectangulo aunque no se vea (para los cercanos). Si la
  /// zona ya esta cargada completa no se vuelve a pedir, salvo con [force].
  Future<void> _loadArea({bool force = false, GeoBounds? around}) async {
    const layer = MapLayer.inventory;
    final source = repository;
    if (source is! AreaPinsSource) return;
    final view = _viewport;
    if (around == null) {
      if (view == null) return; // El mapa aun no dice que se ve.
      if (_zoomedOut) {
        _cancelArea();
        _loadedArea = null;
        _loadedTruncated = false;
        // Lejos no se dibuja lo de la ultima zona: seria una parte cualquiera.
        emit(
          state.copyWith(
            pinsByLayer: {...state.pinsByLayer, layer: const []},
            savedAt: {...state.savedAt}..remove(layer),
            status: state.layer == layer ? MapStatus.ready : null,
            clearError: state.layer == layer,
            areaZoomedOut: true,
            areaLoading: false,
            areaTruncated: false,
            clearAreaError: true,
          ),
        );
        return;
      }
      final loaded = _loadedArea;
      if (!force &&
          loaded != null &&
          !_loadedTruncated &&
          loaded.covers(view) &&
          state.pinsByLayer.containsKey(layer)) {
        if (state.areaZoomedOut) emit(state.copyWith(areaZoomedOut: false));
        return;
      }
    }
    final area = around ?? view!.expanded(areaMargin);
    _cancelArea();
    final cancel = MapQueryCancel();
    _areaQuery = cancel;
    emit(
      state.copyWith(
        areaLoading: true,
        areaZoomedOut: around == null ? false : null,
        clearAreaError: true,
      ),
    );
    try {
      final found = await (source as AreaPinsSource).pinsIn(
        layer,
        area,
        cancel: cancel,
      );
      if (isClosed || !identical(_areaQuery, cancel)) return;
      _areaQuery = null;
      _loadedArea = area;
      _loadedTruncated = found.truncated;
      final pins = mergeAreaPins(
        previous: state.pinsByLayer[layer] ?? const [],
        fresh: found.pins,
        area: area,
        visible: _viewport ?? area,
        truncated: found.truncated,
      );
      final saved = {...state.savedAt}..remove(layer);
      if (found.cachedAt case final at?) saved[layer] = at;
      final current = state.layer == layer;
      emit(
        state.copyWith(
          pinsByLayer: {...state.pinsByLayer, layer: pins},
          savedAt: saved,
          status: current ? MapStatus.ready : null,
          clearError: current,
          areaLoading: false,
          areaTruncated: found.truncated,
          clearAreaError: true,
        ),
      );
    } on MapQueryCancelled {
      // Otra zona la reemplazo.
    } on MapException catch (e) {
      if (isClosed || !identical(_areaQuery, cancel)) return;
      _areaQuery = null;
      _loadedArea = null;
      final current = state.layer == layer;
      // Sin permiso o sin mapa publicado no hay zona que valga: la pestana
      // entera lo dice. Un corte o un error del servidor deja lo que ya se ve.
      if (current &&
          (e.error == MapError.permissionDenied ||
              e.error == MapError.notAvailable)) {
        emit(
          state.copyWith(
            status: MapStatus.failure,
            error: e.error,
            areaLoading: false,
          ),
        );
        return;
      }
      emit(state.copyWith(areaLoading: false, areaError: e.error));
    }
  }

  void toggleCategory(String category) {
    final next = {...state.categories};
    if (!next.add(category)) next.remove(category);
    emit(state.copyWith(categories: next, clearSelection: true));
  }

  void setStatusFilter(PinStatus? status) => emit(
    status == null
        ? state.copyWith(clearStatusFilter: true, clearSelection: true)
        : state.copyWith(statusFilter: status, clearSelection: true),
  );

  void setOperatingFilter(OperatingState? value) => emit(
    value == null
        ? state.copyWith(clearOperatingFilter: true, clearSelection: true)
        : state.copyWith(operatingFilter: value, clearSelection: true),
  );

  /// Solo un grupo (subsistema) a la vez; null = todos.
  void setGroupFilter(String? group) => emit(
    group == null
        ? state.copyWith(clearGroupFilter: true, clearSelection: true)
        : state.copyWith(groupFilter: group, clearSelection: true),
  );

  void clearFilters() => emit(
    state.copyWith(
      categories: const {},
      clearStatusFilter: true,
      clearOperatingFilter: true,
      clearGroupFilter: true,
      clearSelection: true,
    ),
  );

  /// Elegir un pin suelta el tramo elegido: la ficha de abajo es de uno solo.
  void selectPin(String? id) => emit(
    id == null
        ? state.copyWith(clearSelection: true)
        : state.copyWith(
            selectedId: id,
            clearSegmentSelection: true,
            clearPickedPoint: true,
          ),
  );

  /// Elige un punto del mapa (manteniendo presionado): suelta lo seleccionado,
  /// porque la ficha de abajo es de una sola cosa.
  void pickPoint(GeoPoint point) => emit(
    state.copyWith(
      pickedPoint: point,
      clearSelection: true,
      clearSegmentSelection: true,
    ),
  );

  void clearPickedPoint() => emit(state.copyWith(clearPickedPoint: true));

  /// Trae los tramos de la carretera. Es un extra del mapa: si no se pueden
  /// traer (sin permiso, no publicados, error) el mapa sigue con sus pines.
  Future<void> loadSegments() async {
    final repo = segmentsRepository;
    if (repo == null) return;
    try {
      final segments = await repo.segments();
      if (isClosed) return;
      final savedAt = segments is SegmentListing ? segments.cachedAt : null;
      emit(
        state.copyWith(
          segments: [
            for (final s in segments)
              if (s.isDrawable) s,
          ],
          segmentsSavedAt: savedAt,
          clearSegmentsSavedAt: savedAt == null,
          clearSegmentSelection: true,
        ),
      );
    } on MapException {
      // Sin tramos: se dibujan solo los pines.
    }
  }

  /// Elegir un tramo (o null para soltarlo) suelta el pin elegido.
  void selectSegment(String? id) => emit(
    id == null
        ? state.copyWith(clearSegmentSelection: true)
        : state.copyWith(selectedSegmentId: id, clearSelection: true),
  );

  void setRadius(double meters) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(nearbyRadiusMeters: meters),
        // Los del servidor eran del radio anterior.
        clearServerNearby: true,
      ),
    );
    unawaited(loadServerNearby());
  }

  /// Pide al servidor los activos cercanos a la ultima ubicacion. Sin conexion
  /// (o si el servidor no los da) quedan los calculados en el telefono.
  Future<void> loadServerNearby() async {
    final source = repository;
    final here = state.location;
    if (source is! NearbyAssetsSource || here == null) return;
    final radius = state.settings.nearbyRadiusMeters;
    try {
      final found = await (source as NearbyAssetsSource).nearbyAssets(
        here.position,
        radius,
      );
      // Si mientras tanto cambio la ubicacion o el radio, ya no sirve.
      if (isClosed ||
          state.location != here ||
          state.settings.nearbyRadiusMeters != radius) {
        return;
      }
      emit(state.copyWith(serverNearby: found));
    } on MapException {
      if (isClosed) return;
      emit(state.copyWith(clearServerNearby: true));
    }
  }

  /// Busca la ubicacion del usuario y pide centrar el mapa en ella. Tambien
  /// trae el inventario, que es de donde salen los cercanos sin conexion (por
  /// zona: solo los de alrededor). Con [silent] (al abrir el mapa) un fallo no
  /// muestra aviso: el usuario no pidio ubicarse y puede hacerlo con el boton.
  Future<void> locate({bool silent = false}) async {
    emit(state.copyWith(locate: LocateStatus.locating));
    final inventoryByArea = _byArea(MapLayer.inventory);
    if (!state.inventoryLoaded && !inventoryByArea) {
      // Sin esperarlo: los cercanos aparecen cuando llegue.
      _loadLayer(MapLayer.inventory, showLoading: false);
    }
    try {
      final here = await locationSource.current();
      if (isClosed) return;
      emit(
        state.copyWith(
          location: here,
          locate: LocateStatus.ready,
          focusTick: state.focusTick + 1,
          // Los del servidor eran de la ubicacion anterior.
          clearServerNearby: true,
        ),
      );
      unawaited(loadServerNearby());
      // Con la pestana del inventario abierta, la zona sale de centrar el mapa.
      if (inventoryByArea &&
          !state.inventoryLoaded &&
          state.layer != MapLayer.inventory) {
        unawaited(
          _loadArea(
            around: GeoBounds.around(
              here.position,
              math.max(_aroundMeters, state.settings.nearbyRadiusMeters),
            ),
          ),
        );
      }
    } on LocationException catch (e) {
      if (isClosed) return;
      if (silent) {
        emit(state.copyWith(locate: LocateStatus.idle));
        return;
      }
      emit(
        state.copyWith(
          locate: switch (e.failure) {
            LocationFailure.serviceDisabled => LocateStatus.serviceDisabled,
            LocationFailure.permissionDenied => LocateStatus.permissionDenied,
            LocationFailure.permissionDeniedForever =>
              LocateStatus.permissionDeniedForever,
            LocationFailure.unavailable => LocateStatus.unavailable,
          },
        ),
      );
    }
  }

  /// Abre los ajustes cuando el problema solo se arregla ahi. La razon la da
  /// quien mostro el aviso: para entonces el estado ya se limpio.
  Future<void> openSettings(LocationFailure reason) =>
      locationSource.openSettings(reason);

  /// Quita el aviso de ubicacion una vez que el usuario lo vio.
  void dismissLocateMessage() {
    if (state.locate == LocateStatus.locating ||
        state.locate == LocateStatus.ready ||
        state.locate == LocateStatus.idle) {
      return;
    }
    emit(state.copyWith(locate: LocateStatus.idle));
  }
}
