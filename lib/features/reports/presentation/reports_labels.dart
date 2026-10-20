import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/indicator_report.dart';

/// La sigla del indicador, tal como la usa el negocio.
String reportIndicatorCode(ReportIndicator i) => i.name.toUpperCase();

String reportIndicatorLabel(AppLocalizations l10n, ReportIndicator i) =>
    switch (i) {
      ReportIndicator.sgp => l10n.maintIndSgp,
      ReportIndicator.sgs => l10n.maintIndSgs,
      ReportIndicator.sgoae => l10n.maintIndSgoae,
      ReportIndicator.sgoac => l10n.maintIndSgoac,
      ReportIndicator.sgits => l10n.maintIndSgits,
      ReportIndicator.sgf => l10n.maintIndSgf,
      ReportIndicator.sgtec => l10n.maintIndSgtec,
      ReportIndicator.sge => l10n.maintIndSge,
    };

IconData reportIndicatorIcon(ReportIndicator i) => switch (i) {
  ReportIndicator.sgp => Icons.add_road,
  ReportIndicator.sgs => Icons.traffic,
  ReportIndicator.sgoae => Icons.account_balance,
  ReportIndicator.sgoac => Icons.directions_car,
  ReportIndicator.sgits => Icons.cell_tower,
  ReportIndicator.sgf => Icons.landscape,
  ReportIndicator.sgtec => Icons.architecture,
  ReportIndicator.sge => Icons.apartment,
};

String reportStatusLabel(AppLocalizations l10n, ReportLineStatus s) =>
    switch (s) {
      ReportLineStatus.open => l10n.repStatusOpen,
      ReportLineStatus.inProgress => l10n.repStatusInProgress,
      ReportLineStatus.closed => l10n.repStatusClosed,
    };

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color reportStatusColor(ReportLineStatus s) => switch (s) {
  ReportLineStatus.open => StatusColors.open,
  ReportLineStatus.inProgress => StatusColors.attended,
  ReportLineStatus.closed => StatusColors.closed,
};
