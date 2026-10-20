import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/inspection.dart';

String inspectionStatusLabel(AppLocalizations l10n, InspectionStatus s) =>
    switch (s) {
      InspectionStatus.pending => l10n.inspStatusPending,
      InspectionStatus.inProgress => l10n.inspStatusInProgress,
      InspectionStatus.attended => l10n.inspStatusAttended,
      InspectionStatus.closed => l10n.inspStatusClosed,
      InspectionStatus.cancelled => l10n.inspStatusCancelled,
    };

String inspectionStatLabel(AppLocalizations l10n, InspectionStatus s) =>
    switch (s) {
      InspectionStatus.pending => l10n.inspStatPending,
      InspectionStatus.inProgress => l10n.inspStatInProgress,
      InspectionStatus.attended => l10n.inspStatAttended,
      InspectionStatus.closed => l10n.inspStatClosed,
      InspectionStatus.cancelled => l10n.inspStatusCancelled,
    };

/// Los colores de estatus son del sistema y la concesion no los cambia: lo que
/// se esta haciendo o espera revision es ambar, lo cerrado verde, y lo que aun
/// no empieza o se cancelo, un gris neutro.
Color inspectionStatusColor(InspectionStatus s) => switch (s) {
  InspectionStatus.pending => const Color(0xFF94A3B8),
  InspectionStatus.inProgress => StatusColors.attended,
  InspectionStatus.attended => StatusColors.attended,
  InspectionStatus.closed => StatusColors.closed,
  InspectionStatus.cancelled => const Color(0xFF64748B),
};
