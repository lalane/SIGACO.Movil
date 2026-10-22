import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/accident.dart';
import 'bloc/accidents_cubit.dart';

String typeLabel(AppLocalizations l10n, AccidentType t) => switch (t) {
  AccidentType.collision => l10n.accidentTypeCollision,
  AccidentType.rollover => l10n.accidentTypeRollover,
  AccidentType.runOver => l10n.accidentTypeRunOver,
  AccidentType.fire => l10n.accidentTypeFire,
  AccidentType.other => l10n.accidentTypeOther,
};

String filterLabel(AppLocalizations l10n, AccidentFilter f) => switch (f) {
  AccidentFilter.all => l10n.accidentsFilterAll,
  AccidentFilter.collision => l10n.accidentTypeCollision,
  AccidentFilter.rollover => l10n.accidentTypeRollover,
  AccidentFilter.runOver => l10n.accidentTypeRunOver,
  AccidentFilter.fire => l10n.accidentTypeFire,
  AccidentFilter.other => l10n.accidentTypeOther,
};

String severityLabel(AppLocalizations l10n, AccidentSeverity s) => switch (s) {
  AccidentSeverity.unharmed => l10n.accidentSeverityUnharmed,
  AccidentSeverity.minor => l10n.accidentSeverityMinor,
  AccidentSeverity.serious => l10n.accidentSeveritySerious,
  AccidentSeverity.fatal => l10n.accidentSeverityFatal,
};

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color severityColor(AccidentSeverity s) => switch (s) {
  AccidentSeverity.unharmed => StatusColors.closed,
  AccidentSeverity.minor => StatusColors.attended,
  AccidentSeverity.serious => StatusColors.open,
  AccidentSeverity.fatal => StatusColors.open,
};

String statusLabel(AppLocalizations l10n, AccidentStatus s) => switch (s) {
  AccidentStatus.registered => l10n.accidentStatusRegistered,
  AccidentStatus.inProgress => l10n.accidentStatusInProgress,
  AccidentStatus.closed => l10n.accidentStatusClosed,
};

Color statusColor(AccidentStatus s) => switch (s) {
  AccidentStatus.registered => StatusColors.open,
  AccidentStatus.inProgress => StatusColors.attended,
  AccidentStatus.closed => StatusColors.closed,
};

/// El color del resumen y de la insignia de cada pestana de tipo.
Color filterColor(AccidentFilter f) => switch (f) {
  AccidentFilter.all => Colors.white,
  AccidentFilter.collision => StatusColors.open,
  AccidentFilter.rollover => StatusColors.attended,
  AccidentFilter.runOver => const Color(0xFF94A3B8),
  AccidentFilter.fire => StatusColors.closed,
  AccidentFilter.other => const Color(0xFF64748B),
};

String zoneLabel(AppLocalizations l10n, AccidentZone z) => switch (z) {
  AccidentZone.rural => l10n.accidentZoneRural,
  AccidentZone.suburban => l10n.accidentZoneSuburban,
  AccidentZone.urban => l10n.accidentZoneUrban,
};

String weatherLabel(AppLocalizations l10n, AccidentWeather w) => switch (w) {
  AccidentWeather.wind => l10n.accidentWeatherWind,
  AccidentWeather.rain => l10n.accidentWeatherRain,
  AccidentWeather.fog => l10n.accidentWeatherFog,
  AccidentWeather.normal => l10n.accidentWeatherNormal,
};

String conditionLabel(AppLocalizations l10n, RoadCondition c) => switch (c) {
  RoadCondition.good => l10n.accidentConditionGood,
  RoadCondition.fair => l10n.accidentConditionFair,
  RoadCondition.poor => l10n.accidentConditionPoor,
};

String layoutLabel(AppLocalizations l10n, RoadLayout x) => switch (x) {
  RoadLayout.straight => l10n.accidentLayoutStraight,
  RoadLayout.verticalCurve => l10n.accidentLayoutVerticalCurve,
  RoadLayout.horizontalCurve => l10n.accidentLayoutHorizontalCurve,
};

String pavementTypeLabel(AppLocalizations l10n, PavementType p) => switch (p) {
  PavementType.rigid => l10n.accidentPavementRigid,
  PavementType.flexible => l10n.accidentPavementFlexible,
};

String causeLabel(AppLocalizations l10n, AccidentCause c) => switch (c) {
  AccidentCause.speeding => l10n.accidentCauseSpeeding,
  AccidentCause.laneInvasion => l10n.accidentCauseLaneInvasion,
  AccidentCause.other => l10n.accidentCauseOther,
};

String placeLabel(AppLocalizations l10n, AccidentPlace p) => switch (p) {
  AccidentPlace.pavement => l10n.accidentPlacePavement,
  AccidentPlace.signage => l10n.accidentPlaceSignage,
  AccidentPlace.tollBooth => l10n.accidentPlaceTollBooth,
  AccidentPlace.other => l10n.accidentPlaceOther,
};

String vehicleLabel(AppLocalizations l10n, VehicleType v) => switch (v) {
  VehicleType.vehicle => l10n.accidentVehicleCar,
  VehicleType.motorcycle => l10n.accidentVehicleMotorcycle,
  VehicleType.livestock => l10n.accidentVehicleLivestock,
  VehicleType.fixedObject => l10n.accidentVehicleFixedObject,
};

String sexLabel(AppLocalizations l10n, VictimSex s) => switch (s) {
  VictimSex.female => l10n.accidentSexFemale,
  VictimSex.male => l10n.accidentSexMale,
  VictimSex.unspecified => l10n.accidentSexUnspecified,
};
