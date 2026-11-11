import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/status_colors.dart';
import '../../../core/time/concession_zone.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/ticket.dart';
import '../domain/entities/ticket_supervision.dart';
import 'bloc/tickets_cubit.dart';

String statusLabel(AppLocalizations l10n, TicketStatus s) => switch (s) {
  TicketStatus.open => l10n.ticketStatusOpen,
  TicketStatus.attended => l10n.ticketStatusAttended,
};

/// Los colores de estatus son del sistema y la concesion no los cambia.
Color statusColor(TicketStatus s) => switch (s) {
  TicketStatus.open => StatusColors.open,
  TicketStatus.attended => StatusColors.attended,
};

String filterLabel(AppLocalizations l10n, TicketFilter f) => switch (f) {
  TicketFilter.all => l10n.ticketsFilterAll,
  TicketFilter.unvalidated => l10n.ticketsFilterUnvalidated,
  TicketFilter.open => l10n.ticketsFilterOpen,
  TicketFilter.attended => l10n.ticketsFilterAttended,
  TicketFilter.closed => l10n.ticketsFilterClosed,
  TicketFilter.cancelled => l10n.ticketsFilterCancelled,
};

/// Los cinco estados del DTF M11 v0.3.
String stageLabel(AppLocalizations l10n, TicketStage s) => switch (s) {
  TicketStage.unvalidated => l10n.ticketStageUnvalidated,
  TicketStage.open => l10n.ticketStatusOpen,
  TicketStage.attended => l10n.ticketStatusAttended,
  TicketStage.closed => l10n.ticketStageClosed,
  TicketStage.cancelled => l10n.ticketStageCancelled,
};

/// Como en la web: lo que falta atender en rojo, lo atendido en ambar, lo
/// cerrado en verde; lo cancelado en gris, porque ya no cuenta (RB-11-16).
Color stageColor(TicketStage s) => switch (s) {
  TicketStage.unvalidated || TicketStage.open => StatusColors.open,
  TicketStage.attended => StatusColors.attended,
  TicketStage.closed => StatusColors.closed,
  TicketStage.cancelled => StatusColors.cancelled,
};

String assetConditionLabel(AppLocalizations l10n, TicketAssetCondition c) =>
    switch (c) {
      TicketAssetCondition.unchanged => l10n.ticketConditionUnchanged,
      TicketAssetCondition.good => l10n.ticketConditionGood,
      TicketAssetCondition.fair => l10n.ticketConditionFair,
      TicketAssetCondition.poor => l10n.ticketConditionPoor,
      TicketAssetCondition.veryPoor => l10n.ticketConditionVeryPoor,
    };

/// La condicion que llego del servidor, legible; el codigo si no se conoce.
String assetConditionCodeLabel(AppLocalizations l10n, String code) {
  for (final c in TicketAssetCondition.values) {
    if (c.code == code) return assetConditionLabel(l10n, c);
  }
  return code;
}

String cancelReasonLabel(AppLocalizations l10n, TicketCancelReason r) =>
    switch (r) {
      TicketCancelReason.duplicate => l10n.ticketCancelDuplicate,
      TicketCancelReason.improper => l10n.ticketCancelImproper,
      TicketCancelReason.other => l10n.ticketCancelOther,
    };

/// El motivo de cancelacion que llego del servidor, legible.
String cancelReasonCodeLabel(AppLocalizations l10n, String code) {
  for (final r in TicketCancelReason.values) {
    if (r.code == code) return cancelReasonLabel(l10n, r);
  }
  return code;
}

/// Cuanto falta (o cuanto se paso) del vencimiento: horas hasta dos dias y
/// dias despues.
String dueValue(AppLocalizations l10n, Duration remaining) {
  final abs = remaining.abs();
  if (abs.inHours < 48) return l10n.ticketDueHours(abs.inHours);
  return l10n.ticketDueDays(abs.inDays);
}

/// `15-08-2026 08:45` en la zona de la concesion.
String ticketDate(DateTime utc, ConcessionZone? zone) =>
    DateFormat('dd-MM-yyyy HH:mm').format(inConcessionZone(utc, zone));

/// `15 de octubre de 2026 · 09:15` en la zona de la concesion.
String ticketLongDate(
  BuildContext context,
  DateTime utc,
  ConcessionZone? zone,
) {
  final local = inConcessionZone(utc, zone);
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.yMMMMd(locale).format(local)} · '
      '${DateFormat.Hm(locale).format(local)}';
}

/// La hora como `15:46` a partir de los minutos desde la medianoche.
String minutesLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Una coordenada en grados, minutos y segundos (`18°50'46.20"S`).
String dms(double value, {required bool latitude}) {
  final hemisphere = latitude
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'W');
  final abs = value.abs();
  final degrees = abs.floor();
  final minutesFull = (abs - degrees) * 60;
  final minutes = minutesFull.floor();
  final seconds = (minutesFull - minutes) * 60;
  return '$degrees°$minutes\'${seconds.toStringAsFixed(2)}"$hemisphere';
}

String ticketPriorityLabel(AppLocalizations l10n, TicketPriority p) =>
    switch (p) {
      TicketPriority.low => l10n.ticketPriorityLow,
      TicketPriority.medium => l10n.ticketPriorityMedium,
      TicketPriority.high => l10n.ticketPriorityHigh,
      TicketPriority.critical => l10n.ticketPriorityCritical,
    };
