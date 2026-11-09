import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'follow_up_cubit.dart';

enum NewTicketIssue { title, category, description, kmEnd, direction, offRoad }

/// Las fallas de la Matriz que la persona puede usar: las de sus indicadores.
/// Null si no se sabe (todas).
typedef AllowedIndicators = Future<Set<String>?> Function();

class NewTicketState extends Equatable {
  const NewTicketState({
    this.failures = const [],
    this.indicator,
    this.group,
    this.categories = const [],
    this.categoriesLoaded = false,
    this.title = '',
    this.category,
    this.priority = TicketPriority.medium,
    this.kmLabel = '',
    this.description = '',
    this.photos = const [null, null, null],
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
    this.warning,
    this.placement,
    this.kmEndLabel = '',
    this.direction,
  });

  /// El km final, si la falla ocupa un tramo.
  final String kmEndLabel;

  /// El sentido que eligio la persona (solo se pide donde el trazo es compartido).
  final String? direction;

  /// El punto cae donde los dos sentidos comparten trazo: hay que elegir.
  bool get needsDirection =>
      placement?.status == TicketPlacementStatus.onRoad &&
      placement!.directionAmbiguous;

  /// Donde cae el punto sobre la carretera; null si no hay punto o aun no se sabe.
  final TicketPlacement? placement;

  /// Las fallas de la Matriz; vacio, el formulario usa la lista plana.
  final List<TicketFailure> failures;
  final String? indicator;
  final String? group;

  final List<String> categories;
  final bool categoriesLoaded;
  final String title;
  final String? category;
  final TicketPriority priority;
  final String kmLabel;
  final String description;
  final List<String?> photos;
  final bool saving;
  final bool saved;
  final bool showIssues;
  final bool failed;

  /// Se guardo, pero faltó parte (por ejemplo las fotos); lo que dijo el servidor.
  final String? warning;

  bool get usesMatrix => failures.isNotEmpty;

  /// Los indicadores con fallas, en el orden de la Matriz.
  List<String> get indicators =>
      {for (final f in failures) f.subsystemCode}.toList();

  List<String> get groups => {
    for (final f in failures)
      if (f.subsystemCode == indicator) f.group,
  }.toList();

  List<TicketFailure> get groupFailures => [
    for (final f in failures)
      if (f.subsystemCode == indicator && f.group == group) f,
  ];

  /// La falla elegida (la categoria es su codigo).
  TicketFailure? get failure {
    for (final f in failures) {
      if (f.code == category) return f;
    }
    return null;
  }

  List<NewTicketIssue> get issues => [
    if (title.trim().isEmpty) NewTicketIssue.title,
    if (category == null) NewTicketIssue.category,
    if (description.trim().isEmpty) NewTicketIssue.description,
    if (_kmEndInvalid) NewTicketIssue.kmEnd,
    if (needsDirection && direction == null) NewTicketIssue.direction,
    if (placement?.status == TicketPlacementStatus.offRoad)
      NewTicketIssue.offRoad,
  ];

  /// El km final va con el inicial y no puede ser menor.
  bool get _kmEndInvalid {
    if (kmEndLabel.trim().isEmpty) return false;
    final end = parseKm(kmEndLabel);
    final start = parseKm(kmLabel);
    return end == null || start == null || end < start;
  }

  NewTicketState copyWith({
    List<TicketFailure>? failures,
    String? indicator,
    String? group,
    bool clearSelection = false,
    bool clearCategory = false,
    List<String>? categories,
    bool? categoriesLoaded,
    String? title,
    String? category,
    TicketPriority? priority,
    String? kmLabel,
    String? description,
    List<String?>? photos,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
    String? warning,
    TicketPlacement? placement,
    String? kmEndLabel,
    String? direction,
  }) => NewTicketState(
    failures: failures ?? this.failures,
    indicator: clearSelection ? indicator : (indicator ?? this.indicator),
    group: clearSelection ? group : (group ?? this.group),
    categories: categories ?? this.categories,
    categoriesLoaded: categoriesLoaded ?? this.categoriesLoaded,
    title: title ?? this.title,
    category: clearCategory ? category : (category ?? this.category),
    priority: priority ?? this.priority,
    kmLabel: kmLabel ?? this.kmLabel,
    description: description ?? this.description,
    photos: photos ?? this.photos,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    failed: failed ?? this.failed,
    warning: warning ?? this.warning,
    placement: placement ?? this.placement,
    kmEndLabel: kmEndLabel ?? this.kmEndLabel,
    direction: direction ?? this.direction,
  );

  @override
  List<Object?> get props => [
    failures,
    indicator,
    group,
    categories,
    categoriesLoaded,
    title,
    category,
    priority,
    kmLabel,
    description,
    photos,
    saving,
    saved,
    showIssues,
    failed,
    warning,
    placement,
    kmEndLabel,
    direction,
  ];
}

/// El formulario de un ticket nuevo.
class NewTicketCubit extends Cubit<NewTicketState> {
  NewTicketCubit(
    this._repository, {
    DateTime Function()? clock,
    this.location,
    String Function()? clientIdGenerator,
    this.allowedIndicators,
    this.asset,
  }) : _clock = clock ?? DateTime.now,
       super(
         NewTicketState(
           // El cadenamiento ya conocido se rellena solo (FRM-02): el del punto
           // o el del activo.
           kmLabel: location?.kmLabel ?? asset?.kmLabel ?? '',
           kmEndLabel: location?.kmLabel == null ? asset?.kmEndLabel ?? '' : '',
         ),
       ) {
    _clientId = (clientIdGenerator ?? newClientId)();
    // La hora del registro es la de abrir el formulario, en UTC.
    _capturedAt = _clock().toUtc();
  }

  final TicketsRepository _repository;
  final DateTime Function() _clock;

  /// Los indicadores asignados: solo sus fallas se ofrecen.
  final AllowedIndicators? allowedIndicators;
  late final DateTime _capturedAt;
  late final String _clientId;

  /// Donde se levanta el ticket, si viene del mapa o de un activo.
  final TicketLocation? location;

  /// El activo, si se levanta desde su ficha (puede no tener punto).
  final TicketAssetRef? asset;

  /// Identificador unico de este registro (`cliente_uuid`).
  String get clientId => _clientId;

  /// Cuando se abrio el formulario, en UTC.
  DateTime get capturedAt => _capturedAt;

  /// Un punto del mapa o del GPS (no un activo) tiene que caer sobre la
  /// carretera: se ubica para llenar el km y avisar antes de guardar.
  Future<void> _place() async {
    final at = location;
    final source = _repository;
    if (at == null || at.assetId != null || source is! TicketPlacementSource) {
      return;
    }
    final placement = await (source as TicketPlacementSource).place(
      at.longitude,
      at.latitude,
    );
    if (isClosed) return;
    final km = placement.status == TicketPlacementStatus.onRoad
        ? kmLabel(placement.km, null)
        : null;
    // El km que ya escribio la persona se respeta.
    final typed = state.kmLabel.trim();
    final keep = typed.isNotEmpty && typed != (at.kmLabel ?? '').trim();
    emit(
      state.copyWith(
        placement: placement,
        kmLabel: km != null && !keep ? km : null,
      ),
    );
  }

  Future<void> load() async {
    unawaited(_place());
    var failures = const <TicketFailure>[];
    final source = _repository;
    if (source is TicketFailureSource) {
      try {
        failures = await (source as TicketFailureSource).failures();
        final allowed = await allowedIndicators?.call();
        if (allowed != null) {
          failures = [
            for (final f in failures)
              if (allowed.contains(f.subsystemCode)) f,
          ];
        }
      } catch (_) {
        // Sin el catalogo de fallas queda la lista plana.
        failures = const [];
      }
    }
    // Desde la ficha de un activo se propone su indicador, si es de los que la
    // persona puede usar.
    final wanted = asset?.subsystemCode?.toUpperCase();
    final indicator = state.indicator != null || wanted == null
        ? null
        : failures
              .where((f) => f.subsystemCode.toUpperCase() == wanted)
              .firstOrNull
              ?.subsystemCode;
    try {
      final categories = await _repository.categories();
      if (isClosed) return;
      emit(
        state.copyWith(
          failures: failures,
          categories: categories,
          categoriesLoaded: true,
          indicator: indicator,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          failures: failures,
          categoriesLoaded: true,
          indicator: indicator,
        ),
      );
    }
  }

  /// Al cambiar de indicador se vuelve a elegir subclasificacion y falla.
  void setIndicator(String v) => emit(
    state.copyWith(indicator: v, clearSelection: true, clearCategory: true),
  );

  void setGroup(String v) => emit(
    state.copyWith(
      indicator: state.indicator,
      group: v,
      clearSelection: true,
      clearCategory: true,
    ),
  );

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setCategory(String v) => emit(state.copyWith(category: v));

  void setPriority(TicketPriority v) => emit(state.copyWith(priority: v));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setKmEnd(String v) => emit(state.copyWith(kmEndLabel: v));

  void setDirection(String v) => emit(state.copyWith(direction: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  void setPhoto(int slot, String? path) {
    final photos = [...state.photos];
    if (slot >= 0 && slot < ticketPhotoSlots) photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  Future<void> save() async {
    if (state.saving) return;
    if (state.issues.isNotEmpty) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, failed: false));
    try {
      await _repository.create(
        NewTicket(
          title: state.title.trim(),
          category: state.category!,
          priority: state.priority,
          kmLabel: state.kmLabel.trim().isEmpty ? null : state.kmLabel.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          photoPaths: [for (final p in state.photos) ?p],
          capturedAt: _capturedAt,
          deviceClockAt: _clock().toUtc(),
          location: location,
          assetId: asset?.id,
          clientId: _clientId,
          fixedAttention: state.failure != null,
          kmEndLabel: state.kmEndLabel.trim().isEmpty
              ? null
              : state.kmEndLabel.trim(),
          direction: state.needsDirection
              ? state.direction
              : state.placement?.status == TicketPlacementStatus.onRoad
              ? state.placement!.direction
              : null,
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } on TicketPartiallySavedException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true, warning: e.reason));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, failed: true));
    }
  }
}
