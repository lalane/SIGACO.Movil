import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/inventory_asset.dart';

String conditionLabel(AppLocalizations l10n, AssetCondition c) => switch (c) {
  AssetCondition.good => l10n.invConditionGood,
  AssetCondition.regular => l10n.invConditionRegular,
  AssetCondition.poor => l10n.invConditionPoor,
};

String conditionStatLabel(AppLocalizations l10n, AssetCondition c) =>
    switch (c) {
      AssetCondition.good => l10n.invStatGood,
      AssetCondition.regular => l10n.invStatRegular,
      AssetCondition.poor => l10n.invStatPoor,
    };

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color conditionColor(AssetCondition c) => switch (c) {
  AssetCondition.good => StatusColors.closed,
  AssetCondition.regular => StatusColors.attended,
  AssetCondition.poor => StatusColors.open,
};
