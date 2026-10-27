import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/map_pack.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/map_settings.dart';
import '../../domain/entities/nearby_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_source.dart';
import '../../domain/repositories/map_pack_manager.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/repositories/road_segments_repository.dart';

enum MapStatus { loading, ready, failure }

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
    this.pickedPoint,
    this.selectedId,
    this.settings = const MapSettings(),
    this.location,
    this.locate = LocateStatus.idle,
    this.focusTick = 0,
    this.offlinePack,
    this.offlineReader,
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

  List<MapPin> get layerPins => pinsByLayer[layer] ?? const [];

  /// Cuando se guardaron los pines de la pestana abierta, si son del telefono.
  DateTime? get layerSavedAt => savedAt[layer];

  /// Categorias de la pestana, en orden, para el filtro.
  List<String> get availableCategories {
    final set = <String>{
      for (final p in layerPins)
        if (p.category != null) p.category!,
    };
    return set.toList()..sort();
  }

  int get activeFilterCount =>
      categories.length +
      (statusFilter == null ? 0 : 1) +
      (operatingFilter == null ? 0 : 1);

  /// Si la pestana abierta tiene equipos con estado operativo (para mostrar su
  /// filtro solo donde aplica).
  bool get hasOperatingStates => layerPins.any((p) => p.operatingState != null);

  /// Lo que se dibuja: la pestana con sus filtros.
  List<MapPin> get visiblePins => [
    for (final p in layerPins)
      if ((categories.isEmpty ||
              (p.category != null && categories.contains(p.category))) &&
          (statusFilter == null || p.status == statusFilter) &&
          (operatingFilter == null || p.operatingState == operatingFilter))
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

  /// Los activos de inventario cercanos a la ultima ubicacion, con el radio
  /// elegido. Son lo que se elige para levantar un ticket, una inspeccion o un
  /// mantenimiento, y se calculan en el telefono (con y sin conexion igual).
  List<NearbyPin> get nearby {
    final here = location;
    if (here == null) return const [];
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
    pickedPoint: clearPickedPoint ? null : (pickedPoint ?? this.pickedPoint),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    settings: settings ?? this.settings,
    location: location ?? this.location,
    locate: locate ?? this.locate,
    focusTick: focusTick ?? this.focusTick,
    offlinePack: clearOffline ? null : (offlinePack ?? this.offlinePack),
    offlineReader: clearOffline ? null : (offlineReader ?? this.offlineReader),
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
    pickedPoint,
    selectedId,
    settings,
    location,
    locate,
    focusTick,
    offlinePack,
    offlineReader,
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
  }) : super(MapState(settings: settings));

  final MapRepository repository;
  final LocationSource locationSource;

  /// Paquetes de mapa sin conexion; sin esto el mapa solo usa el de en linea.
  final MapPackManager? packs;

  /// Los tramos de la carretera; sin esto el mapa solo dibuja pines.
  final RoadSegmentsRepository? segmentsRepository;

  /// Carga la pestana abierta y el paquete de mapa sin conexion, si hay.
  Future<void> load() async {
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
    final reader = state.offlineReader;
    await super.close();
    try {
      await reader?.close();
    } catch (_) {}
  }

  /// Vuelve a pedir la pestana abierta (reintento o jalar para actualizar).
  Future<void> refresh() => _loadLayer(state.layer, showLoading: true);

  Future<void> selectLayer(MapLayer layer) async {
    if (layer == state.layer) return;
    final known = state.pinsByLayer.containsKey(layer);
    emit(
      state.copyWith(
        layer: layer,
        status: known ? MapStatus.ready : MapStatus.loading,
        categories: const {},
        clearStatusFilter: true,
        clearSelection: true,
        clearSegmentSelection: true,
        clearPickedPoint: true,
        clearError: true,
      ),
    );
    if (!known) await _loadLayer(layer, showLoading: false);
  }

  Future<void> _loadLayer(MapLayer layer, {required bool showLoading}) async {
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

  void clearFilters() => emit(
    state.copyWith(
      categories: const {},
      clearStatusFilter: true,
      clearOperatingFilter: true,
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

  void setRadius(double meters) => emit(
    state.copyWith(
      settings: state.settings.copyWith(nearbyRadiusMeters: meters),
    ),
  );

  /// Busca la ubicacion del usuario y pide centrar el mapa en ella. Tambien
  /// trae el inventario, que es de donde salen los cercanos. Con [silent] (al
  /// abrir el mapa) un fallo no muestra aviso: el usuario no pidio ubicarse y
  /// puede hacerlo con el boton.
  Future<void> locate({bool silent = false}) async {
    emit(state.copyWith(locate: LocateStatus.locating));
    if (!state.inventoryLoaded) {
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
        ),
      );
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
