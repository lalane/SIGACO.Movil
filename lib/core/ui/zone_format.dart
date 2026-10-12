import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../time/concession_zone.dart';

/// Una fecha UTC en la zona de la concesion (RN-04); sin zona, la del telefono.
String formatInZone(BuildContext context, DateTime utc, ConcessionZone? zone) =>
    DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).add_Hm().format(inConcessionZone(utc, zone));

/// Solo el dia, en la zona de la concesion.
String formatDayInZone(
  BuildContext context,
  DateTime utc,
  ConcessionZone? zone,
) => DateFormat.yMd(
  Localizations.localeOf(context).toString(),
).format(inConcessionZone(utc, zone));

/// Un dia de calendario tal cual (por ejemplo el elegido en un filtro), sin
/// convertirlo a ninguna zona.
String formatCalendarDay(BuildContext context, DateTime day) =>
    DateFormat.yMd(Localizations.localeOf(context).toString()).format(day);
