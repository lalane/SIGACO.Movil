import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/app_alert.dart';

String alertSeverityLabel(AppLocalizations l10n, AlertSeverity s) =>
    switch (s) {
      AlertSeverity.info => l10n.alertsSeverityInfo,
      AlertSeverity.warning => l10n.alertsSeverityWarning,
      AlertSeverity.critical => l10n.alertsSeverityCritical,
    };

/// Los colores de estatus son del sistema y la concesion no los cambia: lo
/// urgente es rojo, lo que pide atencion ambar y lo informativo, un gris neutro.
Color alertSeverityColor(AlertSeverity s) => switch (s) {
  AlertSeverity.info => const Color(0xFF94A3B8),
  AlertSeverity.warning => StatusColors.attended,
  AlertSeverity.critical => StatusColors.open,
};

IconData alertSeverityIcon(AlertSeverity s) => switch (s) {
  AlertSeverity.info => Icons.info_outline,
  AlertSeverity.warning => Icons.warning_amber_outlined,
  AlertSeverity.critical => Icons.error_outline,
};
