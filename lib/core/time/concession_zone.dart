import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Zona horaria de la concesion (DTF Configuracion, D3 y RN-04): las fechas se
/// guardan y viajan en UTC y se muestran en esta zona, no en la del telefono.
class ConcessionZone {
  ConcessionZone._(this.id, this._location);

  /// Identificador IANA, por ejemplo `America/Sao_Paulo`.
  final String id;
  final tz.Location _location;

  static var _ready = false;

  /// La zona de [id]; null si falta o no es un identificador IANA conocido.
  static ConcessionZone? tryParse(String? id) {
    final clean = id?.trim();
    if (clean == null || clean.isEmpty) return null;
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    try {
      return ConcessionZone._(clean, tz.getLocation(clean));
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  /// El instante [utc] expresado en la zona de la concesion. El resultado es un
  /// `DateTime` cuyos campos (hora, dia...) son los de la zona, listo para
  /// `DateFormat`.
  DateTime fromUtc(DateTime utc) => tz.TZDateTime.from(utc.toUtc(), _location);

  /// Desfase de la zona respecto de UTC en el instante [at] (cambia con el
  /// horario de verano).
  Duration offsetAt(DateTime at) =>
      _location.timeZone(at.toUtc().millisecondsSinceEpoch).offset;

  /// `UTC-03:00`, `UTC+05:30`, `UTC+00:00`.
  String offsetLabelAt(DateTime at) {
    final minutes = offsetAt(at).inMinutes;
    final sign = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$h:$m';
  }
}

/// El instante UTC [utc] en la zona de la concesion. Mientras la concesion no
/// tenga zona (o aun no se conozca), se usa la del telefono como respaldo
/// temporal: nunca se muestra UTC tal cual.
DateTime inConcessionZone(DateTime utc, ConcessionZone? zone) =>
    zone?.fromUtc(utc) ?? utc.toLocal();
