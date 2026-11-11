import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/pending_definition.dart';
import '../domain/repositories/definitions_repository.dart';

String definitionStatusLabel(AppLocalizations l10n, DefinitionStatus s) =>
    switch (s) {
      DefinitionStatus.open => l10n.defStatusOpen,
      DefinitionStatus.answered => l10n.defStatusAnswered,
      DefinitionStatus.accepted => l10n.defStatusAccepted,
      DefinitionStatus.changeRequested => l10n.defStatusChangeRequested,
      DefinitionStatus.retired => l10n.defStatusRetired,
    };

/// Abierta en ambar (espera respuesta), aceptada en verde, cambio en rojo.
Color definitionStatusColor(DefinitionStatus s) => switch (s) {
  DefinitionStatus.open => StatusColors.attended,
  DefinitionStatus.answered => const Color(0xFF3B82F6),
  DefinitionStatus.accepted => const Color(0xFF22C55E),
  DefinitionStatus.changeRequested => StatusColors.open,
  DefinitionStatus.retired => const Color(0xFF94A3B8),
};

String definitionPriorityLabel(AppLocalizations l10n, DefinitionPriority p) =>
    switch (p) {
      DefinitionPriority.high => l10n.defPriorityHigh,
      DefinitionPriority.medium => l10n.defPriorityMedium,
      DefinitionPriority.low => l10n.defPriorityLow,
    };

String definitionKindLabel(AppLocalizations l10n, String kind) =>
    switch (kind) {
      'ACUERDO' => l10n.defKindAgree,
      'CAMBIO' => l10n.defKindChange,
      'COMENTARIO' => l10n.defKindComment,
      'REAPERTURA' => l10n.defKindReopen,
      'SUPUESTO_ACTUALIZADO' => l10n.defKindUpdated,
      'RETIRADA' => l10n.defKindRetired,
      'REINCORPORADA' => l10n.defKindRestored,
      _ => kind,
    };

String definitionsErrorMessage(AppLocalizations l10n, DefinitionsError e) =>
    switch (e) {
      DefinitionsError.network => l10n.defErrorNetwork,
      DefinitionsError.permissionDenied => l10n.defErrorPermission,
      DefinitionsError.notFound => l10n.defErrorNotFound,
      DefinitionsError.retired => l10n.defErrorRetired,
      DefinitionsError.validation => l10n.defTextRequired,
      DefinitionsError.server => l10n.defErrorServer,
    };
