import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

/// Cuantas fotos admite el registro (las del mockup).
const accidentPhotoSlots = 3;

/// Tope de vehiculos o de victimas por accidente en el formulario.
const accidentMaxParties = 20;

/// Lo que falta o esta mal al guardar. La gravedad del accidente ya no se
/// captura: es la de su victima mas grave (BBP §7.8).
enum NewAccidentIssue { title, type, vehicle, victim }

/// Una victima mientras se captura: la gravedad es obligatoria porque de ella
/// sale la del accidente; el sexo es opcional.
class VictimDraft extends Equatable {
  const VictimDraft({this.sex, this.severity});

  final VictimSex? sex;
  final AccidentSeverity? severity;

  VictimDraft copyWith({VictimSex? sex, AccidentSeverity? severity}) =>
      VictimDraft(sex: sex ?? this.sex, severity: severity ?? this.severity);

  @override
  List<Object?> get props => [sex, severity];
}

class NewAccidentState extends Equatable {
  const NewAccidentState({
    this.title = '',
    this.type,
    this.kmLabel = '',
    this.description = '',
    this.photos = const [null, null, null],
    this.zone,
    this.weather,
    this.pavementCondition,
    this.layout,
    this.pavementType,
    this.signageCondition,
    this.cause,
    this.place,
    this.vehicles = const [],
    this.victims = const [],
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.failed = false,
  });

  final String title;
  final AccidentType? type;
  final String kmLabel;
  final String description;
  final List<String?> photos;
  final AccidentZone? zone;
  final AccidentWeather? weather;
  final RoadCondition? pavementCondition;
  final RoadLayout? layout;
  final PavementType? pavementType;
  final RoadCondition? signageCondition;
  final AccidentCause? cause;
  final AccidentPlace? place;

  /// Un renglon por vehiculo; null = aun sin elegir el tipo.
  final List<VehicleType?> vehicles;
  final List<VictimDraft> victims;
  final bool saving;
  final bool saved;

  /// Se activa al intentar guardar: antes no se regana por un campo vacio.
  final bool showIssues;
  final bool failed;

  /// La del accidente: la de su victima mas grave; sin victimas, ileso.
  AccidentSeverity get severity => AccidentVictim.worst([
    for (final v in victims)
      if (v.severity != null) AccidentVictim(severity: v.severity!),
  ]);

  List<NewAccidentIssue> get issues => [
    if (title.trim().isEmpty) NewAccidentIssue.title,
    if (type == null) NewAccidentIssue.type,
    if (vehicles.any((v) => v == null)) NewAccidentIssue.vehicle,
    if (victims.any((v) => v.severity == null)) NewAccidentIssue.victim,
  ];

  NewAccidentState copyWith({
    String? title,
    AccidentType? type,
    String? kmLabel,
    String? description,
    List<String?>? photos,
    AccidentZone? zone,
    AccidentWeather? weather,
    RoadCondition? pavementCondition,
    RoadLayout? layout,
    PavementType? pavementType,
    RoadCondition? signageCondition,
    AccidentCause? cause,
    AccidentPlace? place,
    List<VehicleType?>? vehicles,
    List<VictimDraft>? victims,
    bool? saving,
    bool? saved,
    bool? showIssues,
    bool? failed,
  }) => NewAccidentState(
    title: title ?? this.title,
    type: type ?? this.type,
    kmLabel: kmLabel ?? this.kmLabel,
    description: description ?? this.description,
    photos: photos ?? this.photos,
    zone: zone ?? this.zone,
    weather: weather ?? this.weather,
    pavementCondition: pavementCondition ?? this.pavementCondition,
    layout: layout ?? this.layout,
    pavementType: pavementType ?? this.pavementType,
    signageCondition: signageCondition ?? this.signageCondition,
    cause: cause ?? this.cause,
    place: place ?? this.place,
    vehicles: vehicles ?? this.vehicles,
    victims: victims ?? this.victims,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [
    title,
    type,
    kmLabel,
    description,
    photos,
    zone,
    weather,
    pavementCondition,
    layout,
    pavementType,
    signageCondition,
    cause,
    place,
    vehicles,
    victims,
    saving,
    saved,
    showIssues,
    failed,
  ];
}

/// El formulario de un accidente nuevo.
class NewAccidentCubit extends Cubit<NewAccidentState> {
  NewAccidentCubit(
    this._repository, {
    DateTime Function()? clock,
    String Function()? clientIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       super(const NewAccidentState()) {
    _clientId = (clientIdGenerator ?? newClientId)();
    // La hora del registro es la de abrir el formulario, en UTC.
    _capturedAt = _clock().toUtc();
  }

  final AccidentsRepository _repository;
  final DateTime Function() _clock;
  late final DateTime _capturedAt;
  late final String _clientId;

  /// Identificador unico de este registro (`cliente_uuid`).
  String get clientId => _clientId;

  /// Cuando se abrio el formulario, en UTC.
  DateTime get capturedAt => _capturedAt;

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setType(AccidentType v) => emit(state.copyWith(type: v));

  void setKm(String v) => emit(state.copyWith(kmLabel: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  void setZone(AccidentZone v) => emit(state.copyWith(zone: v));

  void setWeather(AccidentWeather v) => emit(state.copyWith(weather: v));

  void setPavementCondition(RoadCondition v) =>
      emit(state.copyWith(pavementCondition: v));

  void setLayout(RoadLayout v) => emit(state.copyWith(layout: v));

  void setPavementType(PavementType v) => emit(state.copyWith(pavementType: v));

  void setSignageCondition(RoadCondition v) =>
      emit(state.copyWith(signageCondition: v));

  void setCause(AccidentCause v) => emit(state.copyWith(cause: v));

  void setPlace(AccidentPlace v) => emit(state.copyWith(place: v));

  void setPhoto(int slot, String? path) {
    if (slot < 0 || slot >= accidentPhotoSlots) return;
    final photos = [...state.photos];
    photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  /// La cantidad de vehiculos decide cuantos renglones se piden (BBP §7.8); al
  /// bajarla se conservan los primeros.
  void setVehicleCount(int n) {
    final count = n.clamp(0, accidentMaxParties);
    final vehicles = [...state.vehicles];
    while (vehicles.length > count) {
      vehicles.removeLast();
    }
    while (vehicles.length < count) {
      vehicles.add(null);
    }
    emit(state.copyWith(vehicles: vehicles));
  }

  void setVehicleType(int index, VehicleType type) {
    if (index < 0 || index >= state.vehicles.length) return;
    final vehicles = [...state.vehicles];
    vehicles[index] = type;
    emit(state.copyWith(vehicles: vehicles));
  }

  /// Igual que los vehiculos: la cantidad de victimas decide los renglones.
  void setVictimCount(int n) {
    final count = n.clamp(0, accidentMaxParties);
    final victims = [...state.victims];
    while (victims.length > count) {
      victims.removeLast();
    }
    while (victims.length < count) {
      victims.add(const VictimDraft());
    }
    emit(state.copyWith(victims: victims));
  }

  void setVictimSex(int index, VictimSex sex) {
    if (index < 0 || index >= state.victims.length) return;
    final victims = [...state.victims];
    victims[index] = victims[index].copyWith(sex: sex);
    emit(state.copyWith(victims: victims));
  }

  void setVictimSeverity(int index, AccidentSeverity severity) {
    if (index < 0 || index >= state.victims.length) return;
    final victims = [...state.victims];
    victims[index] = victims[index].copyWith(severity: severity);
    emit(state.copyWith(victims: victims));
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
        NewAccident(
          title: state.title.trim(),
          type: state.type!,
          severity: state.severity,
          kmLabel: state.kmLabel.trim().isEmpty ? null : state.kmLabel.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          photoPaths: [for (final p in state.photos) ?p],
          capturedAt: _capturedAt,
          deviceClockAt: _clock().toUtc(),
          clientId: _clientId,
          zone: state.zone,
          weather: state.weather,
          pavementCondition: state.pavementCondition,
          layout: state.layout,
          pavementType: state.pavementType,
          signageCondition: state.signageCondition,
          cause: state.cause,
          place: state.place,
          vehicles: [for (final v in state.vehicles) AccidentVehicle(type: v!)],
          victims: [
            for (final v in state.victims)
              AccidentVictim(severity: v.severity!, sex: v.sex),
          ],
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, failed: true));
    }
  }
}
