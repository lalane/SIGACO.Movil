import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/public_work.dart';

String workStatusLabel(AppLocalizations l10n, WorkStatus s) => switch (s) {
  WorkStatus.notStarted => l10n.workStatusNotStarted,
  WorkStatus.inProgress => l10n.workStatusInProgress,
  WorkStatus.delayed => l10n.workStatusDelayed,
  WorkStatus.finished => l10n.workStatusFinished,
};

String workStatLabel(AppLocalizations l10n, WorkStatus s) => switch (s) {
  WorkStatus.notStarted => l10n.workStatNotStarted,
  WorkStatus.inProgress => l10n.workStatInProgress,
  WorkStatus.delayed => l10n.workStatDelayed,
  WorkStatus.finished => l10n.workStatFinished,
};

/// Los colores de estatus son del sistema y la concesion no los cambia: lo
/// atrasado es rojo, lo que avanza ambar, lo terminado verde y lo que no ha
/// empezado, un gris neutro.
Color workStatusColor(WorkStatus s) => switch (s) {
  WorkStatus.notStarted => const Color(0xFF94A3B8),
  WorkStatus.inProgress => StatusColors.attended,
  WorkStatus.delayed => StatusColors.open,
  WorkStatus.finished => StatusColors.closed,
};
