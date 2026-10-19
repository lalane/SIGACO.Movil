import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/ui/module_format.dart';
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

/// Una cantidad con separador de miles y, si la tiene, su parte decimal
/// (`350`, `1,200.5`), segun el idioma.
String quantity(String locale, double value) =>
    NumberFormat('#,##0.##', moduleNumberLocale(locale)).format(value);

/// Un importe en pesos sin centavos (`$28,000`).
String money(String locale, double value) => NumberFormat.currency(
  locale: moduleNumberLocale(locale),
  symbol: r'$',
  decimalDigits: 0,
).format(value);

/// Un importe con centavos (`100,000.00`).
String moneyExact(String locale, double value) =>
    NumberFormat('#,##0.00', moduleNumberLocale(locale)).format(value);

/// El avance como porcentaje entero (`64%`).
String percent(double progress) => '${(progress * 100).round()}%';
