import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/repositories/asset_capture_repository.dart';

/// Huecos para fotos del alta (los mismos que el ticket).
const assetPhotoSlots = 3;

enum NewAssetLoad { loading, ready, failure }

/// Lo que falta o sobra fuera de los campos de la ficha.
enum NewAssetIssue {
  /// No se eligio el tipo.
  type,

  /// Sin km y sin un punto que sirva de ubicacion.
  location,

  /// El km no se entiende.
  km,

  /// El tipo se ubica por rango y falta el km final, o es menor que el inicial.
  kmEnd,

  /// Aqui los dos sentidos comparten trazo: hay que elegir.
  direction,
}

/// Como va la lectura del GPS.
enum GpsStatus { idle, reading, ready, unavailable }

class NewAssetState extends Equatable {
  const NewAssetState({
    this.typesStatus = NewAssetLoad.loading,
    this.types = const [],
    this.typesError,
    this.type,
    this.templateStatus = NewAssetLoad.ready,
    this.template,
    this.templateError,
    this.catalogs = const {},
    this.values = const {},
    this.gps = GpsStatus.idle,
    this.position,
    this.placement,
    this.kmLabel = '',
    this.kmEndLabel = '',
    this.direction,
    this.description = '',
    this.notes = '',
    this.photos = const [null, null, null],
    this.saving = false,
    this.showIssues = false,
    this.result,
    this.failure,
  });

  final NewAssetLoad typesStatus;
  final List<AssetTypeOption> types;
  final AssetCaptureError? typesError;

  /// El tipo elegido.
  final AssetTypeOption? type;
  final NewAssetLoad templateStatus;

  /// La ficha vigente del tipo: de ella sale el formulario.
  final AssetTemplate? template;
  final AssetCaptureError? templateError;
  final Map<String, List<CatalogOption>> catalogs;

  /// Lo capturado por campo: texto (texto y numeros, como se escriben), bool,
  /// [DateTime] o el codigo de catalogo.
  final Map<String, Object?> values;
  final GpsStatus gps;
  final AssetPosition? position;

  /// Donde cae el punto sobre la carretera; null si aun no se sabe.
  final RoadPlacement? placement;

  /// Km, km final y sentido: los llena la ubicacion y la persona los corrige.
  final String kmLabel;
  final String kmEndLabel;
  final String? direction;
  final String description;
  final String notes;
  final List<String?> photos;
  final bool saving;
  final bool showIssues;

  /// Lo que paso al guardar; null mientras no se guarda.
  final CapturedAsset? result;

  /// Por que no se pudo guardar (la persona puede corregir y reintentar).
  final AssetCaptureException? failure;

  bool get saved => result != null;

  /// El punto del GPS sirve de ubicacion para este tipo.
  bool get pointLocates => position != null && (type?.acceptsPoint ?? true);

  bool get needsDirection =>
      placement?.status == RoadPlacementStatus.onRoad &&
      placement!.directionAmbiguous;

  /// Los campos de la ficha que se capturan, en orden.
  List<AttributeDefinition> get fields => template?.attributes ?? const [];

  /// Lo que no sirve de cada campo de la ficha (clave -> problema).
  Map<String, AttributeIssue> get attributeIssues => {
    for (final f in fields) f.key: ?f.check(values[f.key]),
  };

  List<NewAssetIssue> get issues {
    final km = parseKm(kmLabel);
    final kmEnd = parseKm(kmEndLabel);
    return [
      if (type == null) NewAssetIssue.type,
      if (kmLabel.trim().isNotEmpty && km == null) NewAssetIssue.km,
      if (km == null && kmLabel.trim().isEmpty && !pointLocates)
        NewAssetIssue.location,
      if (_kmEndInvalid(km, kmEnd)) NewAssetIssue.kmEnd,
      if (needsDirection && direction == null) NewAssetIssue.direction,
    ];
  }

  bool _kmEndInvalid(double? km, double? kmEnd) {
    final typed = kmEndLabel.trim().isNotEmpty;
    if (typed) return kmEnd == null || km == null || kmEnd < km;
    return (type?.requiresKmEnd ?? false) && km != null;
  }

  /// Todo listo para guardar.
  bool get isValid =>
      issues.isEmpty && attributeIssues.isEmpty && template != null;

  NewAssetState copyWith({
    NewAssetLoad? typesStatus,
    List<AssetTypeOption>? types,
    AssetCaptureError? typesError,
    AssetTypeOption? type,
    NewAssetLoad? templateStatus,
    AssetTemplate? template,
    bool clearTemplate = false,
    AssetCaptureError? templateError,
    bool clearTemplateError = false,
    Map<String, List<CatalogOption>>? catalogs,
    Map<String, Object?>? values,
    GpsStatus? gps,
    AssetPosition? position,
    RoadPlacement? placement,
    String? kmLabel,
    String? kmEndLabel,
    String? direction,
    String? description,
    String? notes,
    List<String?>? photos,
    bool? saving,
    bool? showIssues,
    CapturedAsset? result,
    AssetCaptureException? failure,
    bool clearFailure = false,
  }) => NewAssetState(
    typesStatus: typesStatus ?? this.typesStatus,
    types: types ?? this.types,
    typesError: typesError ?? this.typesError,
    type: type ?? this.type,
    templateStatus: templateStatus ?? this.templateStatus,
    template: clearTemplate ? null : (template ?? this.template),
    templateError: clearTemplateError
        ? null
        : (templateError ?? this.templateError),
    catalogs: catalogs ?? this.catalogs,
    values: values ?? this.values,
    gps: gps ?? this.gps,
    position: position ?? this.position,
    placement: placement ?? this.placement,
    kmLabel: kmLabel ?? this.kmLabel,
    kmEndLabel: kmEndLabel ?? this.kmEndLabel,
    direction: direction ?? this.direction,
    description: description ?? this.description,
    notes: notes ?? this.notes,
    photos: photos ?? this.photos,
    saving: saving ?? this.saving,
    showIssues: showIssues ?? this.showIssues,
    result: result ?? this.result,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [
    typesStatus,
    types,
    typesError,
    type,
    templateStatus,
    template,
    templateError,
    catalogs,
    values,
    gps,
    position,
    placement,
    kmLabel,
    kmEndLabel,
    direction,
    description,
    notes,
    photos,
    saving,
    showIssues,
    result,
    failure,
  ];
}

/// El alta de un activo en campo: elegir el tipo, llenar la ficha vigente (el
/// formulario se arma solo), ubicarlo con el GPS y tomar fotos. Nace
/// "Pendiente de validacion"; sin red queda en la cola del telefono.
class NewAssetCubit extends Cubit<NewAssetState> {
  NewAssetCubit(
    this._repository, {
    AssetPositionSource positionSource = const NoAssetPositionSource(),
    DateTime Function()? clock,
    String Function()? clientIdGenerator,
    this.language = 'es',
  }) : _positions = positionSource,
       _clock = clock ?? DateTime.now,
       super(const NewAssetState()) {
    _clientId = (clientIdGenerator ?? newClientId)();
    // La hora del alta es la de abrir el formulario, en UTC.
    _capturedAt = _clock().toUtc();
  }

  final AssetCaptureRepository _repository;
  final AssetPositionSource _positions;
  final DateTime Function() _clock;

  /// `es` o `pt`: el nombre del tipo que se guarda con lo que espera en la cola.
  final String language;
  late final String _clientId;
  late final DateTime _capturedAt;

  /// La ultima ficha pedida: si la persona cambia de tipo mientras llega una,
  /// la vieja se descarta.
  int _templateRequest = 0;

  String get clientId => _clientId;
  DateTime get capturedAt => _capturedAt;

  Future<void> load() async {
    unawaited(readPosition());
    await loadTypes();
  }

  Future<void> loadTypes() async {
    emit(state.copyWith(typesStatus: NewAssetLoad.loading));
    try {
      final types = await _repository.types();
      if (isClosed) return;
      emit(state.copyWith(typesStatus: NewAssetLoad.ready, types: types));
    } on AssetCaptureException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(typesStatus: NewAssetLoad.failure, typesError: e.error),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          typesStatus: NewAssetLoad.failure,
          typesError: AssetCaptureError.server,
        ),
      );
    }
  }

  /// Lee el GPS y ubica el punto sobre la carretera: llena km y sentido, salvo
  /// lo que la persona ya escribio.
  Future<void> readPosition() async {
    if (state.gps == GpsStatus.reading) return;
    emit(state.copyWith(gps: GpsStatus.reading));
    final here = await _positions.current();
    if (isClosed) return;
    if (here == null) {
      emit(state.copyWith(gps: GpsStatus.unavailable));
      return;
    }
    emit(state.copyWith(gps: GpsStatus.ready, position: here));
    final placement = await _repository.locate(here.longitude, here.latitude);
    if (isClosed) return;
    final onRoad = placement.status == RoadPlacementStatus.onRoad;
    final km = onRoad ? kmLabel(placement.km, null) : null;
    final direction = onRoad && !placement.directionAmbiguous
        ? placement.direction
        : null;
    // Lo que escribio la persona se respeta; lo que lleno una lectura anterior
    // se pone al dia.
    final typedKm = state.kmLabel.trim();
    final fillKm =
        km != null && (typedKm.isEmpty || typedKm == _filledKm?.trim());
    final fillDirection =
        direction != null &&
        (state.direction == null || state.direction == _filledDirection);
    if (fillKm) _filledKm = km;
    if (fillDirection) _filledDirection = direction;
    emit(
      state.copyWith(
        placement: placement,
        kmLabel: fillKm ? km : null,
        direction: fillDirection ? direction : null,
      ),
    );
  }

  /// Lo que lleno la ultima lectura del GPS (para no pisar lo que se escribio).
  String? _filledKm;
  String? _filledDirection;

  Future<void> chooseType(AssetTypeOption type) async {
    if (type == state.type && state.template != null) return;
    final request = ++_templateRequest;
    emit(
      state.copyWith(
        type: type,
        templateStatus: NewAssetLoad.loading,
        clearTemplate: true,
        clearTemplateError: true,
        showIssues: false,
      ),
    );
    try {
      final template = await _repository.template(type.code);
      final catalogs = state.catalogs.isNotEmpty || !_usesCatalogs(template)
          ? state.catalogs
          : await _repository.catalogs();
      if (isClosed || request != _templateRequest) return;
      // Lo ya capturado se conserva en los campos que siguen existiendo.
      final keys = {for (final f in template.attributes) f.key};
      emit(
        state.copyWith(
          templateStatus: NewAssetLoad.ready,
          template: template,
          catalogs: catalogs,
          values: {
            for (final e in state.values.entries)
              if (keys.contains(e.key)) e.key: e.value,
          },
        ),
      );
    } on AssetCaptureException catch (e) {
      if (isClosed || request != _templateRequest) return;
      emit(
        state.copyWith(
          templateStatus: NewAssetLoad.failure,
          templateError: e.error,
        ),
      );
    } catch (_) {
      if (isClosed || request != _templateRequest) return;
      emit(
        state.copyWith(
          templateStatus: NewAssetLoad.failure,
          templateError: AssetCaptureError.server,
        ),
      );
    }
  }

  static bool _usesCatalogs(AssetTemplate t) =>
      t.attributes.any((a) => a.type == AttributeType.catalog);

  /// Vuelve a pedir la ficha del tipo elegido.
  Future<void> retryTemplate() async {
    final type = state.type;
    if (type == null) return;
    _templateRequest++;
    emit(state.copyWith(clearTemplate: true));
    await chooseType(type);
  }

  void setValue(String key, Object? value) =>
      emit(state.copyWith(values: {...state.values, key: value}));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setKmEnd(String v) => emit(state.copyWith(kmEndLabel: v));

  void setDirection(String v) => emit(state.copyWith(direction: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  void setNotes(String v) => emit(state.copyWith(notes: v));

  void setPhoto(int slot, String? path) {
    final photos = [...state.photos];
    if (slot >= 0 && slot < assetPhotoSlots) photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  Future<void> save() async {
    if (state.saving || state.saved) return;
    final type = state.type;
    final template = state.template;
    if (!state.isValid || type == null || template == null) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, clearFailure: true));
    final km = parseKm(state.kmLabel);
    final kmEnd = parseKm(state.kmEndLabel);
    final placement = state.placement;
    try {
      final result = await _repository.create(
        NewAsset(
          clientId: _clientId,
          typeCode: type.code,
          typeLabel: type.label(language),
          capturedAt: _capturedAt,
          roadId: placement?.status == RoadPlacementStatus.onRoad
              ? placement!.roadId
              : null,
          kmStart: km,
          kmEnd: kmEnd,
          direction: state.direction,
          position: state.position,
          sendPoint: type.acceptsPoint,
          attributes: {
            for (final f in template.attributes)
              f.key: ?f.toServer(state.values[f.key]),
          },
          description: state.description,
          notes: state.notes,
          photoPaths: [for (final p in state.photos) ?p],
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, result: result));
    } on AssetCaptureException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, failure: e));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          saving: false,
          failure: const AssetCaptureException(AssetCaptureError.server),
        ),
      );
    }
  }
}
