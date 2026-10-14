import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sigaco_movil/core/time/concession_zone.dart';
import 'package:sigaco_movil/core/time/concession_zone_cubit.dart';

/// Las fechas se guardan en UTC y se muestran en la zona de la concesion
/// (DTF Configuracion D3 y RN-04), no en la del telefono.
void main() {
  group('ConcessionZone.tryParse', () {
    test('reconoce un identificador IANA', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo');
      expect(zone, isNotNull);
      expect(zone!.id, 'America/Sao_Paulo');
    });

    test('ignora espacios alrededor', () {
      expect(
        ConcessionZone.tryParse('  America/Sao_Paulo ')?.id,
        'America/Sao_Paulo',
      );
    });

    test('devuelve null si falta, esta vacio o no existe', () {
      expect(ConcessionZone.tryParse(null), isNull);
      expect(ConcessionZone.tryParse(''), isNull);
      expect(ConcessionZone.tryParse('   '), isNull);
      expect(ConcessionZone.tryParse('Marte/Olympus'), isNull);
    });
  });

  group('fromUtc', () {
    test('Brasilia es UTC-3: 15:30 UTC son las 12:30', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo')!;
      final local = zone.fromUtc(DateTime.utc(2026, 10, 12, 15, 30));
      expect((local.year, local.month, local.day), (2026, 10, 12));
      expect((local.hour, local.minute), (12, 30));
    });

    test('cruza la medianoche hacia el dia anterior', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo')!;
      final local = zone.fromUtc(DateTime.utc(2026, 10, 12, 1, 15));
      expect((local.day, local.hour, local.minute), (11, 22, 15));
    });

    test('Manaus es UTC-4 y Acre UTC-5', () {
      final at = DateTime.utc(2026, 10, 12, 12);
      expect(ConcessionZone.tryParse('America/Manaus')!.fromUtc(at).hour, 8);
      expect(
        ConcessionZone.tryParse('America/Rio_Branco')!.fromUtc(at).hour,
        7,
      );
    });

    test('respeta el horario de verano de la zona', () {
      final zone = ConcessionZone.tryParse('Europe/Madrid')!;
      expect(zone.fromUtc(DateTime.utc(2026, 1, 15, 12)).hour, 13);
      expect(zone.fromUtc(DateTime.utc(2026, 7, 15, 12)).hour, 14);
    });

    test('da igual si el instante llega como UTC o como hora local', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo')!;
      final utc = DateTime.utc(2026, 10, 12, 15, 30);
      expect(zone.fromUtc(utc.toLocal()).hour, zone.fromUtc(utc).hour);
    });

    test('se puede dar formato con DateFormat', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo')!;
      final text = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(zone.fromUtc(DateTime.utc(2026, 10, 12, 15, 30)));
      expect(text, '2026-10-12 12:30');
    });
  });

  group('desfase', () {
    test('etiqueta con signo y minutos', () {
      final at = DateTime.utc(2026, 10, 12);
      expect(
        ConcessionZone.tryParse('America/Sao_Paulo')!.offsetLabelAt(at),
        'UTC-03:00',
      );
      expect(
        ConcessionZone.tryParse('Asia/Kolkata')!.offsetLabelAt(at),
        'UTC+05:30',
      );
      expect(ConcessionZone.tryParse('UTC')!.offsetLabelAt(at), 'UTC+00:00');
    });

    test('cambia con el horario de verano', () {
      final zone = ConcessionZone.tryParse('Europe/Madrid')!;
      expect(zone.offsetLabelAt(DateTime.utc(2026, 1, 15)), 'UTC+01:00');
      expect(zone.offsetLabelAt(DateTime.utc(2026, 7, 15)), 'UTC+02:00');
    });
  });

  group('inConcessionZone', () {
    test('con zona, usa la de la concesion', () {
      final zone = ConcessionZone.tryParse('America/Sao_Paulo');
      final out = inConcessionZone(DateTime.utc(2026, 10, 12, 15, 30), zone);
      expect(out.hour, 12);
    });

    test('sin zona usa la del telefono, nunca UTC tal cual', () {
      final utc = DateTime.utc(2026, 10, 12, 15, 30);
      final out = inConcessionZone(utc, null);
      expect(out, utc.toLocal());
      expect(out.isUtc, isFalse);
    });
  });

  group('ConcessionZoneCubit', () {
    test('empieza sin zona y emite cuando cambia', () async {
      final cubit = ConcessionZoneCubit();
      final seen = <String?>[];
      final sub = cubit.stream.listen((z) => seen.add(z?.id));
      expect(cubit.state, isNull);

      cubit.set(ConcessionZone.tryParse('America/Sao_Paulo'));
      cubit.set(ConcessionZone.tryParse('America/Sao_Paulo'));
      cubit.set(ConcessionZone.tryParse('America/Manaus'));
      cubit.set(null);
      await Future<void>.delayed(Duration.zero);

      expect(seen, ['America/Sao_Paulo', 'America/Manaus', null]);
      await sub.cancel();
      await cubit.close();
    });

    test('la zona de la marca manda sobre la del servidor', () async {
      final cubit = ConcessionZoneCubit();
      addTearDown(cubit.close);

      cubit.setFallback(ConcessionZone.tryParse('America/Manaus'));
      expect(cubit.state?.id, 'America/Manaus');

      cubit.set(ConcessionZone.tryParse('America/Sao_Paulo'));
      expect(cubit.state?.id, 'America/Sao_Paulo');

      // Una zona de respaldo nueva no pisa la de la marca.
      cubit.setFallback(ConcessionZone.tryParse('America/Bahia'));
      expect(cubit.state?.id, 'America/Sao_Paulo');
    });

    test('si la marca deja de traer zona, vuelve la del servidor', () async {
      final cubit = ConcessionZoneCubit();
      addTearDown(cubit.close);
      cubit.setFallback(ConcessionZone.tryParse('America/Manaus'));
      cubit.set(ConcessionZone.tryParse('America/Sao_Paulo'));

      cubit.set(null);

      expect(cubit.state?.id, 'America/Manaus');
    });

    test('sin ninguna fuente no hay zona (se usa la del telefono)', () async {
      final cubit = ConcessionZoneCubit();
      addTearDown(cubit.close);
      cubit.setFallback(ConcessionZone.tryParse('America/Manaus'));

      cubit.setFallback(null);

      expect(cubit.state, isNull);
    });
  });
}
