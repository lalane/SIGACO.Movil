import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/sigaco_palette.dart';
import '../../../core/theme/status_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/map_pin.dart';
import '../domain/entities/road_segment.dart';

String layerLabel(AppLocalizations l10n, MapLayer layer) => switch (layer) {
  MapLayer.tickets => l10n.mapTabTickets,
  MapLayer.inventory => l10n.mapTabInventory,
  MapLayer.maintenance => l10n.mapTabMaintenance,
  MapLayer.works => l10n.mapTabWorks,
};

IconData layerIcon(MapLayer layer) => switch (layer) {
  MapLayer.tickets => Icons.confirmation_number_outlined,
  MapLayer.inventory => Icons.inventory_2_outlined,
  MapLayer.maintenance => Icons.build_outlined,
  MapLayer.works => Icons.construction_outlined,
};

String statusLabel(AppLocalizations l10n, PinStatus status) => switch (status) {
  PinStatus.normal => l10n.mapStatusNormal,
  PinStatus.attention => l10n.mapStatusAttention,
  PinStatus.critical => l10n.mapStatusCritical,
};

/// El color de un pin: los de estatus son del sistema (COL-05); lo normal usa
/// el color de accion de la concesion.
Color pinColor(SigacoPalette p, PinStatus status) => switch (status) {
  PinStatus.normal => p.accent,
  PinStatus.attention => StatusColors.attended,
  PinStatus.critical => StatusColors.open,
};

String directionLabel(AppLocalizations l10n, TravelDirection direction) =>
    switch (direction) {
      TravelDirection.increasing => l10n.mapDirectionIncreasing,
      TravelDirection.decreasing => l10n.mapDirectionDecreasing,
    };

/// El color de la linea de un tramo, segun su sentido. No usa los colores de
/// estatus (rojo y ambar son de los pines) ni el de la concesion (el de los
/// pines normales): la carretera es el fondo sobre el que se leen los pines.
Color segmentColor(TravelDirection direction) => switch (direction) {
  TravelDirection.increasing => const Color(0xFF1D4ED8),
  TravelDirection.decreasing => const Color(0xFF6D28D9),
};

/// Distancia legible: metros hasta 1 km y kilometros con un decimal despues.
String distanceLabel(AppLocalizations l10n, double meters) {
  if (meters < 1000) return l10n.mapDistanceMeters(meters.round().toString());
  return l10n.mapDistanceKm((meters / 1000).toStringAsFixed(1));
}

/// Un tamano legible: B, KB, MB o GB con un decimal, con el separador del
/// idioma.
String formatBytes(String locale, int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  return '${NumberFormat('0.#', locale).format(value)} ${units[i]}';
}

/// El color de las tarjetas del tema es una veladura translucida: sirve sobre el
/// fondo de la pantalla, pero sobre el mapa deja ver las calles y el texto no
/// se lee. Esto es el mismo color, ya mezclado con el fondo, y opaco.
Color solidCard(SigacoPalette p) => Color.alphaBlend(p.card, p.gradientBottom);
