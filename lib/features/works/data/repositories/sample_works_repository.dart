import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';

/// Obras de ejemplo para ver el modulo mientras el backend no publica las
/// suyas. Las tres primeras tienen el mismo id, kilometro y posicion que las del
/// mapa de ejemplo, asi que "Ver en mapa" cae sobre el pin; las otras dos no
/// tienen ubicacion. No son obras reales.
class SampleWorksRepository implements WorksRepository {
  SampleWorksRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) : _clock = clock ?? DateTime.now;

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;
  final DateTime Function() _clock;

  List<PublicWork>? _works;

  List<PublicWork> _load() {
    final cached = _works;
    if (cached != null) return cached;
    final now = _clock().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));
    return _works = [
      PublicWork(
        id: 'O-031',
        name: 'Ampliación de acostamiento',
        status: WorkStatus.inProgress,
        physicalProgress: 0.35,
        programmedProgress: 0.40,
        description: 'Ampliación del acostamiento en ambos sentidos.',
        contractor: 'Consorcio Vale do Aço',
        budget: 4800000,
        executedAmount: 1680000,
        startDate: day(-90),
        endDate: day(120),
        kmStart: 'KM 149+000',
        kmEnd: 'KM 151+000',
        segmentCode: '381BMG0160',
        direction: 'Creciente',
        latitude: -18.862882,
        longitude: -41.987479,
      ),
      PublicWork(
        id: 'O-032',
        name: 'Refuerzo del puente',
        status: WorkStatus.delayed,
        physicalProgress: 0.80,
        programmedProgress: 0.95,
        description: 'Refuerzo de la superestructura de la obra de arte.',
        contractor: 'Estruturas Minas Ltda.',
        budget: 2300000,
        executedAmount: 1840000,
        startDate: day(-200),
        endDate: day(15),
        kmStart: 'KM 152+100',
        kmEnd: 'KM 152+300',
        segmentCode: '381BMG0170',
        direction: 'Decreciente',
        latitude: -18.886628,
        longitude: -42.000451,
      ),
      PublicWork(
        id: 'O-033',
        name: 'Estabilización de talud',
        status: WorkStatus.inProgress,
        physicalProgress: 0.50,
        programmedProgress: 0.48,
        contractor: 'Geotécnica Rio Doce',
        budget: 3100000,
        executedAmount: 1500000,
        startDate: day(-60),
        endDate: day(75),
        kmStart: 'KM 160+800',
        kmEnd: 'KM 161+200',
        segmentCode: '381BMG0190',
        direction: 'Creciente',
        latitude: -18.933409,
        longitude: -42.049109,
      ),
      PublicWork(
        id: 'O-034',
        name: 'Señalización horizontal',
        status: WorkStatus.finished,
        physicalProgress: 1,
        programmedProgress: 1,
        contractor: 'Sinalvias Brasil',
        budget: 950000,
        executedAmount: 940000,
        startDate: day(-150),
        endDate: day(-30),
        kmStart: 'KM 146+900',
        kmEnd: 'KM 155+900',
        segmentCode: '381BMG0160',
        direction: 'Creciente',
      ),
      PublicWork(
        id: 'O-035',
        name: 'Báscula de pesaje',
        status: WorkStatus.notStarted,
        physicalProgress: 0,
        programmedProgress: 0,
        contractor: 'Por contratar',
        budget: 5200000,
        executedAmount: 0,
        startDate: day(30),
        endDate: day(240),
        kmStart: 'KM 158+900',
        kmEnd: 'KM 159+200',
        segmentCode: '381BMG0190',
        direction: 'Creciente',
      ),
    ];
  }

  @override
  Future<List<PublicWork>> list() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return [..._load()];
  }

  @override
  Future<PublicWork> get(String id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    for (final w in _load()) {
      if (w.id == id) return w;
    }
    throw const WorksException(WorksError.notFound);
  }
}
