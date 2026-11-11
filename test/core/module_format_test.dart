import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/time/concession_zone.dart';
import 'package:sigaco_movil/core/ui/module_format.dart';

/// Fechas con hora y fechas sin hora: un instante se ve en la zona de la
/// concesion; una fecha sin hora (programada, instalacion) es el mismo dia en
/// cualquier zona.
void main() {
  final saoPaulo = ConcessionZone.tryParse('America/Sao_Paulo');

  test('una fecha sin hora no se corre al dia anterior en Brasil', () {
    // Asi llega `2026-11-10` del servidor: medianoche UTC.
    final day = DateTime.utc(2026, 11, 10);
    expect(moduleCalendarDay(day), '10/11/2026');
    // Llevada por la zona caeria el 9 (el error que se corrigio).
    expect(moduleDay(day, saoPaulo), '09/11/2026');
  });

  test('un instante se ve en la zona de la concesion', () {
    final instant = DateTime.utc(2026, 11, 11, 1, 30);
    expect(moduleDay(instant, saoPaulo), '10/11/2026');
  });
}
