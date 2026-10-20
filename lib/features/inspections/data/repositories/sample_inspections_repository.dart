import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';

/// Inspecciones de ejemplo sobre activos del inventario de ejemplo, para ver el
/// modulo mientras el backend no publica las suyas. Viven en memoria: llenar o
/// terminar una las cambia hasta que se cierra la app. No son inspecciones
/// reales.
class SampleInspectionsRepository implements InspectionsRepository {
  SampleInspectionsRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) : _clock = clock ?? DateTime.now {
    _items = _seed(_clock().toUtc());
  }

  final DateTime Function() _clock;

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;

  late List<Inspection> _items;

  static List<ChecklistItem> _checklist(
    String prefix,
    List<(String, bool)> items, {
    int ok = 0,
    int findings = 0,
  }) => [
    for (var i = 0; i < items.length; i++)
      ChecklistItem(
        id: '$prefix-${i + 1}',
        text: items[i].$1,
        critical: items[i].$2,
        result: i < ok
            ? CheckResult.ok
            : i < ok + findings
            ? CheckResult.finding
            : CheckResult.pending,
      ),
  ];

  static List<Inspection> _seed(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));
    Inspection inspection(
      String id,
      String title,
      String type,
      InspectionStatus status, {
      required String assetId,
      required String assetName,
      required String km,
      required String segment,
      required List<ChecklistItem> checklist,
      int scheduled = 0,
      int? completed,
      String direction = 'Creciente',
      String assignee = 'Ana Herrera',
    }) => Inspection(
      id: id,
      title: title,
      type: type,
      status: status,
      checklist: checklist,
      scheduledAt: day(scheduled),
      completedAt: completed == null ? null : day(completed),
      assignee: assignee,
      assetId: assetId,
      assetName: assetName,
      kmLabel: km,
      segmentCode: segment,
      direction: direction,
    );
    const signs = [
      ('Visibilidad de la señal', true),
      ('Estado del soporte y la fijación', false),
      ('Retrorreflectividad', false),
    ];
    const guardrail = [
      ('Continuidad de la defensa', true),
      ('Anclajes y tornillería', false),
      ('Deformaciones por impacto', true),
      ('Terminales de extremo', false),
    ];
    const lighting = [
      ('Funcionamiento de la luminaria', false),
      ('Estado del poste y la base', true),
      ('Cableado expuesto', true),
    ];
    const bridge = [
      ('Juntas de dilatación', false),
      ('Fisuras en la superestructura', true),
      ('Estado de los apoyos', true),
    ];
    const drainage = [
      ('Obstrucciones en el conducto', false),
      ('Erosión en la salida', false),
    ];
    return [
      inspection(
        'I-501',
        'Inspección de señal SV-114',
        'Señalización',
        InspectionStatus.pending,
        assetId: 'A-002',
        assetName: 'Señal vertical SV-114',
        km: 'KM 148+000',
        segment: '381BMG0160',
        direction: 'Decreciente',
        scheduled: 1,
        checklist: _checklist('I-501', signs),
      ),
      inspection(
        'I-502',
        'Revisión de defensa metálica',
        'Barreras',
        InspectionStatus.inProgress,
        assetId: 'A-008',
        assetName: 'Defensa metálica',
        km: 'KM 155+400',
        segment: '381BMG0170',
        direction: 'Decreciente',
        scheduled: 0,
        checklist: _checklist('I-502', guardrail, ok: 1, findings: 1),
      ),
      inspection(
        'I-503',
        'Inspección de poste P-310',
        'Iluminación',
        InspectionStatus.pending,
        assetId: 'A-005',
        assetName: 'Poste de iluminación P-310',
        km: 'KM 150+350',
        segment: '381BMG0160',
        direction: 'Decreciente',
        scheduled: 0,
        assignee: 'Luis Prado',
        checklist: _checklist('I-503', lighting),
      ),
      inspection(
        'I-504',
        'Revisión del puente sobre arroyo',
        'Obras de arte',
        InspectionStatus.attended,
        assetId: 'A-006',
        assetName: 'OAE puente sobre arroyo',
        km: 'KM 152+100',
        segment: '381BMG0170',
        scheduled: -3,
        completed: -2,
        checklist: _checklist('I-504', bridge, ok: 2, findings: 1),
      ),
      inspection(
        'I-505',
        'Inspección de alcantarilla AL-07',
        'Drenaje',
        InspectionStatus.closed,
        assetId: 'A-012',
        assetName: 'Alcantarilla AL-07',
        km: 'KM 163+200',
        segment: '381BMG0200',
        direction: 'Decreciente',
        scheduled: -10,
        completed: -9,
        checklist: _checklist('I-505', drainage, ok: 2),
      ),
      inspection(
        'I-506',
        'Revisión de barrera New Jersey',
        'Barreras',
        InspectionStatus.cancelled,
        assetId: 'A-003',
        assetName: 'Barrera New Jersey',
        km: 'KM 149+400',
        segment: '381BMG0160',
        scheduled: -5,
        checklist: _checklist('I-506', guardrail),
      ),
    ];
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  int _indexOf(String id) {
    final i = _items.indexWhere((x) => x.id == id);
    if (i < 0) throw const InspectionsException(InspectionsError.notFound);
    return i;
  }

  @override
  Future<List<Inspection>> list() async {
    await _wait();
    return [..._items];
  }

  @override
  Future<Inspection> get(String id) async {
    await _wait();
    return _items[_indexOf(id)];
  }

  @override
  Future<Inspection> saveAnswers(
    String id,
    Map<String, CheckResult> answers,
  ) async {
    await _wait();
    final i = _indexOf(id);
    final current = _items[i];
    if (!current.editable) {
      throw const InspectionsException(InspectionsError.notEditable);
    }
    var next = current.withAnswers(answers);
    // En cuanto hay una respuesta, ya esta en proceso.
    if (next.answered > 0 && next.status == InspectionStatus.pending) {
      next = next.copyWith(status: InspectionStatus.inProgress);
    }
    return _items[i] = next;
  }

  @override
  Future<Inspection> complete(
    String id,
    Map<String, CheckResult> answers,
  ) async {
    await _wait();
    final i = _indexOf(id);
    final current = _items[i];
    if (!current.editable) {
      throw const InspectionsException(InspectionsError.notEditable);
    }
    final filled = current.withAnswers(answers);
    if (!filled.complete) {
      throw const InspectionsException(InspectionsError.incomplete);
    }
    return _items[i] = filled.copyWith(
      status: InspectionStatus.attended,
      completedAt: _clock().toUtc(),
    );
  }
}
