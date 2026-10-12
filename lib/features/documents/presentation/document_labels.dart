import 'package:flutter/material.dart';

import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/document.dart';

String viewLabel(AppLocalizations l10n, DocumentView view) => switch (view) {
  DocumentView.all => l10n.docsViewAll,
  DocumentView.recent => l10n.docsViewRecent,
  DocumentView.favorites => l10n.docsViewFavorites,
  DocumentView.mine => l10n.docsViewMine,
};

String signatureLabel(AppLocalizations l10n, DocumentSignature s) =>
    switch (s) {
      DocumentSignature.unsigned => l10n.docsSignatureUnsigned,
      DocumentSignature.pending => l10n.docsSignaturePending,
      DocumentSignature.validated => l10n.docsSignatureValidated,
    };

/// Los colores de estatus son del sistema (COL-05): sin firma queda neutro.
Color? signatureColor(DocumentSignature s) => switch (s) {
  DocumentSignature.unsigned => null,
  DocumentSignature.pending => StatusColors.attended,
  DocumentSignature.validated => StatusColors.closed,
};

IconData fileIcon(String format) => switch (format) {
  'pdf' => Icons.picture_as_pdf_outlined,
  'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
  'doc' || 'docx' => Icons.description_outlined,
  'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
  'ppt' || 'pptx' => Icons.slideshow_outlined,
  'dwg' || 'dxf' => Icons.architecture_outlined,
  _ => Icons.insert_drive_file_outlined,
};

/// `480 KB`, `2,4 MB`: un decimal solo cuando hace falta.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 100 || value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
