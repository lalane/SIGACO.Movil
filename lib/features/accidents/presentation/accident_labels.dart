import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/accident.dart';
import 'bloc/accidents_cubit.dart';

String typeLabel(AppLocalizations l10n, AccidentType t) => switch (t) {
  AccidentType.collision => l10n.accidentTypeCollision,
  AccidentType.rollover => l10n.accidentTypeRollover,
  AccidentType.fire => l10n.accidentTypeFire,
};

String filterLabel(AppLocalizations l10n, AccidentFilter f) => switch (f) {
  AccidentFilter.all => l10n.accidentsFilterAll,
  AccidentFilter.collision => l10n.accidentTypeCollision,
  AccidentFilter.rollover => l10n.accidentTypeRollover,
  AccidentFilter.fire => l10n.accidentTypeFire,
};

String severityLabel(AppLocalizations l10n, AccidentSeverity s) => switch (s) {
  AccidentSeverity.low => l10n.accidentSeverityLow,
  AccidentSeverity.medium => l10n.accidentSeverityMedium,
  AccidentSeverity.high => l10n.accidentSeverityHigh,
};

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color severityColor(AccidentSeverity s) => switch (s) {
  AccidentSeverity.low => StatusColors.closed,
  AccidentSeverity.medium => StatusColors.attended,
  AccidentSeverity.high => StatusColors.open,
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
  AccidentFilter.fire => StatusColors.closed,
};
