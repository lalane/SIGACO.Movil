import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../time/concession_zone.dart';

/// El idioma con el que se escriben las cifras. El espanol de la app es el de
/// Mexico (coma para los miles, punto para los decimales, como en el mockup),
/// no el de Espana.
String moduleNumberLocale(String locale) =>
    locale.startsWith('es') ? 'es_MX' : locale;

/// `15-08-2026 08:45` en la zona de la concesion.
String moduleDate(DateTime utc, ConcessionZone? zone) =>
    DateFormat('dd-MM-yyyy HH:mm').format(inConcessionZone(utc, zone));

/// Solo el dia, `15/08/2026`, en la zona de la concesion.
String moduleDay(DateTime utc, ConcessionZone? zone) =>
    DateFormat('dd/MM/yyyy').format(inConcessionZone(utc, zone));

/// `15 de octubre de 2026 · 09:15` en la zona de la concesion.
String moduleLongDate(
  BuildContext context,
  DateTime utc,
  ConcessionZone? zone,
) {
  final local = inConcessionZone(utc, zone);
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.yMMMMd(locale).format(local)} · '
      '${DateFormat.Hm(locale).format(local)}';
}

/// Una coordenada en grados, minutos y segundos (`18°50'46.20"S`).
String moduleDms(double value, {required bool latitude}) {
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
