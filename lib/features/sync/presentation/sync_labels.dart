import 'package:flutter/material.dart';

import '../../../core/offline/operation.dart';
import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Nombre legible del tipo de registro (`sync.operacion.entidad`).
String entityLabel(AppLocalizations l10n, String entity) =>
    switch (entity.toLowerCase()) {
      'documento' => l10n.syncEntityDocument,
      'documento_firma' => l10n.syncEntitySignature,
      'ticket' ||
      'ticket_seguimiento' ||
      'ticket_follow_up' => l10n.syncEntityTicket,
      'maintenance_progress' => l10n.syncEntityMaintenanceProgress,
      'inspeccion' => l10n.syncEntityInspection,
      'evento' => l10n.syncEntityEvent,
      'activo' => l10n.syncEntityAsset,
      'levantamiento' => l10n.syncEntitySurvey,
      'media' => l10n.syncEntityMedia,
      _ => l10n.syncEntityOther,
    };

String kindLabel(AppLocalizations l10n, OperationKind kind) => switch (kind) {
  OperationKind.insert => l10n.syncKindInsert,
  OperationKind.update => l10n.syncKindUpdate,
  OperationKind.delete => l10n.syncKindDelete,
};

String statusLabel(AppLocalizations l10n, OperationStatus status) =>
    switch (status) {
      OperationStatus.pending => l10n.syncStatusPending,
      OperationStatus.sending => l10n.syncStatusSending,
      OperationStatus.rejected => l10n.syncStatusRejected,
      OperationStatus.conflict => l10n.syncStatusConflict,
      // Las aceptadas no se listan; por completitud.
      OperationStatus.accepted => l10n.syncAllDone,
    };

Color statusColor(OperationStatus status) => switch (status) {
  OperationStatus.rejected => StatusColors.open,
  OperationStatus.conflict || OperationStatus.pending => StatusColors.attended,
  OperationStatus.sending || OperationStatus.accepted => StatusColors.closed,
};

/// Un nombre para reconocer la operacion: el del documento, archivo, titulo...
String? operationName(PendingOperation op) {
  for (final key in const ['name', 'nombre', 'filename', 'title', 'titulo']) {
    final v = op.payload[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// Un valor de un registro, legible: texto, numero, o lo anidado en una linea.
String displayValue(Object? value) {
  if (value == null) return '—';
  if (value is Map || value is List) {
    return value.toString();
  }
  return '$value';
}
