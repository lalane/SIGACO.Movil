import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

/// Accidentes de ejemplo sobre la BR-381, para ver el modulo mientras el
/// backend no publica los suyos. Viven en memoria: registrar uno los cambia
/// hasta que se cierra la app. No son accidentes reales.
class SampleAccidentsRepository implements AccidentsRepository {
  SampleAccidentsRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) : _clock = clock ?? DateTime.now {
    _accidents = _seed(_clock().toUtc());
  }

  final DateTime Function() _clock;

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  late List<Accident> _accidents;
  var _next = 100;

  static const _concession = 'NOVA 361';

  static List<Accident> _seed(DateTime now) {
    Accident a(
      String code,
      String title,
      AccidentType type,
      AccidentSeverity severity,
      AccidentStatus status, {
      required Duration age,
      required String km,
      String? description,
      String author = 'Ana Herrera',
    }) => Accident(
      id: 'A-$code',
      code: code,
      title: title,
      type: type,
      severity: severity,
      status: status,
      createdAt: now.subtract(age),
      description: description,
      authorName: author,
      authorProfile: 'Supervisor',
      company: 'TEKIA',
      concessionName: _concession,
      kmLabel: km,
      latitude: -18.8461,
      longitude: -41.9807,
      carriageway: 'B',
    );
    return [
      a(
        '0035',
        'Choque entre camión y automóvil km 513+615',
        AccidentType.collision,
        AccidentSeverity.medium,
        AccidentStatus.inProgress,
        age: const Duration(hours: 20),
        km: 'KM 513+615',
        description:
            'Colisión trasera con un carril cerrado. Se atendió con grúa y balizamiento.',
      ),
      a(
        '0036',
        'Volcamiento de camión de carga km 147+200',
        AccidentType.rollover,
        AccidentSeverity.high,
        AccidentStatus.registered,
        age: const Duration(hours: 6),
        km: 'KM 147+200',
        description:
            'Camión volcado sobre el acotamiento; hay derrame de carga.',
      ),
      a(
        '0037',
        'Incendio de vehículo km 150+300',
        AccidentType.fire,
        AccidentSeverity.high,
        AccidentStatus.inProgress,
        age: const Duration(days: 1),
        km: 'KM 150+300',
        author: 'Luis Prado',
      ),
      a(
        '0038',
        'Choque múltiple en el túnel norte',
        AccidentType.collision,
        AccidentSeverity.high,
        AccidentStatus.closed,
        age: const Duration(days: 4),
        km: 'KM 152+500',
        author: 'Luis Prado',
      ),
      a(
        '0039',
        'Volcamiento de automóvil km 153+600',
        AccidentType.rollover,
        AccidentSeverity.medium,
        AccidentStatus.closed,
        age: const Duration(days: 6),
        km: 'KM 153+600',
      ),
      a(
        '0040',
        'Choque contra la defensa km 148+000',
        AccidentType.collision,
        AccidentSeverity.low,
        AccidentStatus.closed,
        age: const Duration(days: 9),
        km: 'KM 148+000',
      ),
      a(
        '0041',
        'Incendio en el acotamiento km 151+000',
        AccidentType.fire,
        AccidentSeverity.low,
        AccidentStatus.closed,
        age: const Duration(days: 12),
        km: 'KM 151+000',
        author: 'Luis Prado',
      ),
      a(
        '0042',
        'Volcamiento de motocicleta km 154+100',
        AccidentType.rollover,
        AccidentSeverity.medium,
        AccidentStatus.inProgress,
        age: const Duration(days: 2),
        km: 'KM 154+100',
      ),
    ];
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<Accident>> list() async {
    await _wait();
    return List.unmodifiable(_accidents);
  }

  @override
  Future<Accident> get(String id) async {
    await _wait();
    return _accidents.firstWhere(
      (a) => a.id == id,
      orElse: () => throw const AccidentsException(AccidentsError.notFound),
    );
  }

  @override
  Future<Accident> create(NewAccident draft) async {
    await _wait();
    final n = _next++;
    final created = Accident(
      id: 'A-$n',
      code: n.toString().padLeft(4, '0'),
      title: draft.title,
      type: draft.type,
      severity: draft.severity,
      status: AccidentStatus.registered,
      createdAt: draft.capturedAt ?? _clock().toUtc(),
      description: draft.description,
      authorName: 'Usuario de ejemplo',
      authorProfile: 'Supervisor',
      company: 'TEKIA',
      concessionName: _concession,
      kmLabel: draft.kmLabel,
      photoPaths: draft.photoPaths,
    );
    _accidents = [created, ..._accidents];
    return created;
  }
}
