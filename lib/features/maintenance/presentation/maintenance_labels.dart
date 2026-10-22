import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
export '../../../core/ui/module_format.dart'
    show quantity, money, moneyExact, percent;
import '../../../l10n/app_localizations.dart';
import '../domain/entities/maintenance.dart';

/// La sigla del indicador, tal como la usa el negocio.
String indicatorCode(MaintenanceIndicator i) => i.name.toUpperCase();

String indicatorLabel(AppLocalizations l10n, MaintenanceIndicator i) =>
    switch (i) {
      MaintenanceIndicator.sgp => l10n.maintIndSgp,
      MaintenanceIndicator.sgs => l10n.maintIndSgs,
      MaintenanceIndicator.sgoae => l10n.maintIndSgoae,
      MaintenanceIndicator.sgoac => l10n.maintIndSgoac,
      MaintenanceIndicator.sgits => l10n.maintIndSgits,
      MaintenanceIndicator.conservacion => l10n.maintIndConservacion,
      MaintenanceIndicator.sgsei => l10n.maintIndSgsei,
      MaintenanceIndicator.sgost => l10n.maintIndSgost,
      MaintenanceIndicator.sgf => l10n.maintIndSgf,
      MaintenanceIndicator.sgtec => l10n.maintIndSgtec,
      MaintenanceIndicator.sge => l10n.maintIndSge,
    };

IconData indicatorIcon(MaintenanceIndicator i) => switch (i) {
  MaintenanceIndicator.sgp => Icons.add_road,
  MaintenanceIndicator.sgs => Icons.traffic,
  MaintenanceIndicator.sgoae => Icons.account_balance,
  MaintenanceIndicator.sgoac => Icons.directions_car,
  MaintenanceIndicator.sgits => Icons.cell_tower,
  MaintenanceIndicator.conservacion => Icons.construction,
  MaintenanceIndicator.sgsei => Icons.bolt,
  MaintenanceIndicator.sgost => Icons.stream,
  MaintenanceIndicator.sgf => Icons.landscape,
  MaintenanceIndicator.sgtec => Icons.architecture,
  MaintenanceIndicator.sge => Icons.apartment,
};

String statusLabel(AppLocalizations l10n, MaintenanceStatus s) => switch (s) {
  MaintenanceStatus.open => l10n.maintStatusOpen,
  MaintenanceStatus.inProgress => l10n.maintStatusInProgress,
  MaintenanceStatus.closed => l10n.maintStatusClosed,
};

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color statusColor(MaintenanceStatus s) => switch (s) {
  MaintenanceStatus.open => StatusColors.open,
  MaintenanceStatus.inProgress => StatusColors.attended,
  MaintenanceStatus.closed => StatusColors.closed,
};

String statLabel(AppLocalizations l10n, MaintenanceStatus s) => switch (s) {
  MaintenanceStatus.open => l10n.maintStatOpen,
  MaintenanceStatus.inProgress => l10n.maintStatInProgress,
  MaintenanceStatus.closed => l10n.maintStatClosed,
};
