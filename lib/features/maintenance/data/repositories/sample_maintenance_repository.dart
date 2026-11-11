import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Mantenimientos de ejemplo para ver el modulo mientras el backend no publica
/// los suyos. Hay varios para senalizacion, pavimentos y edificaciones y uno o
/// ninguno para el resto. No son mantenimientos reales.
class SampleMaintenanceRepository implements MaintenanceRepository {
  SampleMaintenanceRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) {
    _orders = _seed((clock ?? DateTime.now)().toUtc());
  }

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  late final List<MaintenanceOrder> _orders;

  static List<MaintenanceOrder> _seed(DateTime now) {
    DateTime day(int offset) =>
        DateTime.utc(now.year, now.month, now.day).add(Duration(days: offset));
    MaintenanceOrder o(
      String id,
      MaintenanceIndicator indicator,
      String title,
      String activity,
      MaintenanceStatus status, {
      required double total,
      required double done,
      String unit = 'PZA',
      double unitCost = 35,
      double? programmed,
      double? executed,
      int start = -10,
      int end = -3,
      String kmStart = '016 + 100',
      String kmEnd = '016 + 900',
      String direction = 'Decreciente',
      String sense = 'Este',
    }) => MaintenanceOrder(
      id: id,
      indicator: indicator,
      title: title,
      activity: activity,
      status: status,
      totalVolume: total,
      executedVolume: done,
      unit: unit,
      unitCost: unitCost,
      programmedAmount: programmed ?? total * unitCost,
      executedAmount: executed ?? done * unitCost,
      startDate: day(start),
      endDate: day(end),
      kmStart: kmStart,
      kmEnd: kmEnd,
      direction: direction,
      sense: sense,
    );
    const sgs = MaintenanceIndicator.sgs;
    const sgp = MaintenanceIndicator.sgp;
    const sge = MaintenanceIndicator.sge;
    return [
      o(
        'M-210',
        sgs,
        'Túnel Norte - Portal Norte',
        'Revisión de luminarias LED',
        MaintenanceStatus.open,
        total: 350,
        done: 224,
        programmed: 100000,
        executed: 64000,
        start: -9,
        end: -3,
      ),
      o(
        'M-211',
        sgs,
        'Túnel Sur - Portal Sur',
        'Limpieza y verificación de cámaras CCTV',
        MaintenanceStatus.closed,
        total: 350,
        done: 350,
        start: -20,
        end: -4,
        kmStart: '017 + 200',
        kmEnd: '017 + 900',
      ),
      o(
        'M-212',
        sgs,
        'Túnel Sur - Portal Sur',
        'Reposición de señales verticales',
        MaintenanceStatus.inProgress,
        total: 120,
        done: 48,
        start: -6,
        end: 8,
        kmStart: '018 + 000',
        kmEnd: '019 + 500',
      ),
      o(
        'M-213',
        sgs,
        'Acceso Poniente',
        'Pintura de balizamiento horizontal',
        MaintenanceStatus.open,
        total: 8000,
        done: 0,
        unit: 'M2',
        unitCost: 12,
        start: 2,
        end: 15,
        kmStart: '020 + 000',
        kmEnd: '023 + 400',
        direction: 'Creciente',
        sense: 'Oeste',
      ),
      o(
        'M-301',
        sgp,
        'Tramo 381BMG0160',
        'Bacheo superficial',
        MaintenanceStatus.inProgress,
        total: 1200,
        done: 780,
        unit: 'M2',
        unitCost: 85,
        start: -12,
        end: 6,
        kmStart: '146 + 900',
        kmEnd: '148 + 400',
      ),
      o(
        'M-302',
        sgp,
        'Tramo 381BMG0170',
        'Sellado de grietas',
        MaintenanceStatus.open,
        total: 4500,
        done: 0,
        unit: 'M',
        unitCost: 9,
        start: 1,
        end: 20,
        kmStart: '150 + 000',
        kmEnd: '155 + 900',
      ),
      o(
        'M-303',
        sgp,
        'Tramo 381BMG0160',
        'Fresado y reposición de carpeta',
        MaintenanceStatus.closed,
        total: 2500,
        done: 2500,
        unit: 'M2',
        unitCost: 140,
        start: -40,
        end: -15,
      ),
      o(
        'M-401',
        sge,
        'Caseta de peaje Valadares',
        'Impermeabilización de azotea',
        MaintenanceStatus.inProgress,
        total: 600,
        done: 210,
        unit: 'M2',
        unitCost: 210,
        start: -5,
        end: 12,
        kmStart: '149 + 500',
        kmEnd: '149 + 500',
      ),
      o(
        'M-402',
        sge,
        'Base de operaciones',
        'Mantenimiento de aire acondicionado',
        MaintenanceStatus.open,
        total: 14,
        done: 0,
        unitCost: 1800,
        start: 3,
        end: 9,
        kmStart: '151 + 000',
        kmEnd: '151 + 000',
      ),
      o(
        'M-501',
        MaintenanceIndicator.sgits,
        'Pórtico ITS km 150',
        'Calibración de sensores',
        MaintenanceStatus.open,
        total: 6,
        done: 2,
        unitCost: 4200,
        start: -2,
        end: 5,
        kmStart: '150 + 000',
        kmEnd: '150 + 000',
      ),
      o(
        'M-301',
        MaintenanceIndicator.sgoae,
        'Puente río Doce km 149',
        'Limpieza y sellado de juntas',
        MaintenanceStatus.inProgress,
        total: 24,
        done: 10,
        unitCost: 2600,
        start: -8,
        end: 5,
        kmStart: '149 + 400',
        kmEnd: '149 + 640',
      ),
      o(
        'M-401',
        MaintenanceIndicator.sgoac,
        'Alcantarillas km 151–152',
        'Desobstrucción de drenajes',
        MaintenanceStatus.closed,
        total: 14,
        done: 14,
        unitCost: 1400,
        start: -20,
        end: -6,
        kmStart: '151 + 000',
        kmEnd: '152 + 000',
      ),
      o(
        'M-701',
        MaintenanceIndicator.conservacion,
        'Calzada norte km 148',
        'Sellado de grietas',
        MaintenanceStatus.inProgress,
        total: 2400,
        done: 1500,
        unit: 'ML',
        unitCost: 12,
        start: -12,
        end: 4,
        kmStart: '148 + 000',
        kmEnd: '149 + 200',
      ),
      o(
        'M-801',
        MaintenanceIndicator.sgsei,
        'Alumbrado enlace km 150',
        'Reposición de luminarias',
        MaintenanceStatus.open,
        total: 40,
        done: 8,
        unitCost: 950,
        start: -4,
        end: 6,
        kmStart: '150 + 000',
        kmEnd: '150 + 800',
      ),
      o(
        'M-901',
        MaintenanceIndicator.sgost,
        'Túnel Sur - ventilación',
        'Mantenimiento de ventiladores',
        MaintenanceStatus.closed,
        total: 6,
        done: 6,
        unitCost: 7800,
        start: -25,
        end: -8,
        kmStart: '153 + 100',
        kmEnd: '153 + 100',
      ),
      o(
        'M-601',
        MaintenanceIndicator.sgf,
        'Faixa de domínio lado izquierdo',
        'Roza y limpieza de vegetación',
        MaintenanceStatus.closed,
        total: 18000,
        done: 18000,
        unit: 'M2',
        unitCost: 3,
        start: -30,
        end: -10,
        kmStart: '152 + 000',
        kmEnd: '154 + 000',
      ),
    ];
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<MaintenanceOrder>> list(MaintenanceIndicator indicator) async {
    await _wait();
    return [
      for (final o in _orders)
        if (o.indicator == indicator) o,
    ];
  }

  @override
  Future<MaintenanceOrder> get(String id) async {
    await _wait();
    return _orders.firstWhere(
      (o) => o.id == id,
      orElse: () => throw const MaintenanceException(MaintenanceError.notFound),
    );
  }

  /// Los ejemplos no guardan nada: devuelve la orden como esta.
  @override
  Future<MaintenanceOrder> addProgress(
    String id, {
    double? executedVolume,
    double? percent,
    String? notes,
    List<String> photoPaths = const [],
    DateTime? at,
    String? clientId,
  }) => get(id);

  @override
  Future<List<MaintenanceIndicator>> visibleIndicators() async =>
      MaintenanceIndicator.values;

  /// Los datos de ejemplo no inventan conteos de tickets ni evaluaciones.
  @override
  Future<MaintenanceIndicatorSummary?> summary(
    MaintenanceIndicator indicator, {
    DateTime? from,
    DateTime? to,
  }) async => null;
}
