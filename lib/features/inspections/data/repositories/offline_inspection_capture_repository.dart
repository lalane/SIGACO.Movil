import '../../../../core/files/local_file_store.dart';
import '../../../../core/ids/client_id.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/operation_queue.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/inspection_capture.dart';
import '../../domain/repositories/inspection_capture_repository.dart';
import '../../domain/repositories/inspections_repository.dart';
import 'api_inspection_capture_repository.dart';

/// La captura que no se pierde sin red (HU-08-17, RB-08-17 a RB-08-19): si no
/// hay conexion, el borrador, las fotos, la finalizacion y los hallazgos quedan
/// en la cola con su clave y salen por `/api/sync/operations` al volver la red.
/// La ficha se sigue viendo con lo ultimo que bajo (cache) mas lo capturado.
/// Supuesto S-INS-17: un borrador por inspeccion en la cola (el ultimo manda);
/// las fotos suben antes de la captura para que finalizar no falle por ellas.
class OfflineInspectionCaptureRepository
    implements InspectionCaptureRepository, ScopeBound {
  OfflineInspectionCaptureRepository(
    this._online,
    this._queue, {
    this.files,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ApiInspectionCaptureRepository _online;
  final OperationQueue _queue;

  /// Donde se copian las fotos que esperan red; sin el, se dejan donde estan.
  final LocalFileStore? files;
  final DateTime Function() _clock;
  OfflineScope? _scope;

  /// Nombres con que el servidor conoce estas operaciones (`SyncEntities`).
  static const inspectionEntity = 'INSPECTION';
  static const findingEntity = 'INSPECTION_FINDING';

  /// Claves locales del payload (empiezan con `_`: no viajan en el lote).
  static const photosKey = '_photos';
  static const latKey = '_lat';
  static const lngKey = '_lng';
  static const atKey = '_at';

  @override
  bool get available => true;

  @override
  Future<void> bind(OfflineScope? scope) async => _scope = scope;

  @override
  Future<void> clear() async {}

  @override
  Future<InspectionCaptureView> capture(String id) async =>
      _withPending(await _online.capture(id));

  /// Lo que espera red sobre lo ultimo que dijo el servidor: respuestas, fotos,
  /// finalizacion y hallazgos de la cola.
  Future<InspectionCaptureView> _withPending(InspectionCaptureView view) async {
    final scope = _scope;
    if (scope == null) return view;
    final ops = await _queue.list(
      scope,
      statuses: {
        OperationStatus.pending,
        OperationStatus.sending,
        OperationStatus.rejected,
        OperationStatus.conflict,
      },
    );
    final mine = [
      for (final o in ops)
        if (o.recordId == view.id &&
            (o.entity == inspectionEntity || o.entity == findingEntity))
          o,
    ];
    if (mine.isEmpty) return view;
    var answers = view.answers;
    var status = view.serverStatus;
    final evidences = [...view.evidences];
    final findings = [...view.findings];
    for (final o in mine) {
      if (o.entity == inspectionEntity) {
        final a = o.payload['answers'];
        if (a is Map<String, dynamic>) answers = a;
        if (o.payload['finalize'] is Map) status = 'ATENDIDA';
        for (final p in _photos(o)) {
          evidences.add(
            CaptureEvidence(
              id: '${p['clientUuid']}',
              fileName: '${p['path']}'.split(RegExp(r'[\\/]')).last,
              fieldKey: p['fieldKey'] as String?,
              latitude: (p['latitude'] as num?)?.toDouble(),
              longitude: (p['longitude'] as num?)?.toDouble(),
              localPath: '${p['path']}',
            ),
          );
        }
      } else {
        findings.add(
          CaptureFinding(
            id: o.id,
            description: '${o.payload['description'] ?? ''}',
            severity: '${o.payload['severity'] ?? ''}',
            status: 'ABIERTO',
            failureCode: o.payload['failureTypeCode'] as String?,
            pending: true,
          ),
        );
      }
    }
    return view
        .copyWith(
          answers: answers,
          evidences: evidences,
          findings: findings,
          pendingSync: true,
          serverStatus: status,
        )
        .recomputed();
  }

  static List<Map<String, Object?>> _photos(PendingOperation o) => [
    for (final p in (o.payload[photosKey] as List?) ?? const [])
      if (p is Map) p.cast<String, Object?>(),
  ];

  @override
  Future<InspectionCaptureView> start(String id, int rowVersion) =>
      _online.start(id, rowVersion);

  @override
  Future<InspectionCaptureView> save(
    InspectionCaptureView view,
    Map<String, dynamic> answers,
  ) async {
    try {
      if (!view.pendingSync) return await _online.save(view, answers);
    } on InspectionsException catch (e) {
      if (e.error != InspectionsError.network || _scope == null) rethrow;
    }
    // Sin red (o con algo ya en la cola, para no adelantarse a ello): a la cola.
    await _upsert(view, answers: answers);
    return _withPending(view);
  }

  @override
  Future<InspectionCaptureView> finalize(
    InspectionCaptureView view, {
    FindingPosition? position,
    String? justification,
    required DateTime executedAt,
  }) async {
    // Lo que falta se dice en el telefono, con o sin red (Resumen y finalizar).
    final issues = view
        .recomputed()
        .missing
        .where((m) => !m.path.startsWith('findings.') || !view.pendingSync)
        .toList();
    if (issues.isNotEmpty) throw InspectionIncompleteException(issues);
    try {
      if (!view.pendingSync) {
        return await _online.finalize(
          view,
          position: position,
          justification: justification,
          executedAt: executedAt,
        );
      }
    } on InspectionsException catch (e) {
      if (e.error != InspectionsError.network || _scope == null) rethrow;
    }
    await _upsert(
      view,
      answers: view.answers,
      finalize: ApiInspectionCaptureRepository.finalizeBody(
        position,
        justification,
        executedAt,
        null,
      ),
    );
    return _withPending(view);
  }

  @override
  Future<InspectionCaptureView> addPhoto(
    InspectionCaptureView view,
    String path, {
    String? fieldKey,
    FindingPosition? position,
    required DateTime capturedAt,
  }) async {
    try {
      if (!view.pendingSync) {
        return await _online.addPhoto(
          view,
          path,
          fieldKey: fieldKey,
          position: position,
          capturedAt: capturedAt,
        );
      }
    } on InspectionsException catch (e) {
      if (e.error != InspectionsError.network || _scope == null) rethrow;
    }
    final kept = await _keep(path);
    await _upsert(
      view,
      answers: view.answers,
      photo: {
        'path': kept,
        'fieldKey': fieldKey,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'clientUuid': newClientId(),
      },
    );
    return _withPending(view);
  }

  @override
  Future<InspectionCaptureView> addFinding(
    InspectionCaptureView view, {
    required String description,
    String? failureCode,
    String? severity,
    String? parameter,
    List<String> photoPaths = const [],
    FindingPosition? position,
    required DateTime capturedAt,
  }) async {
    try {
      if (!view.pendingSync) {
        return await _online.addFinding(
          view,
          description: description,
          failureCode: failureCode,
          severity: severity,
          parameter: parameter,
          photoPaths: photoPaths,
          position: position,
          capturedAt: capturedAt,
        );
      }
    } on InspectionsException catch (e) {
      if (e.error != InspectionsError.network || _scope == null) rethrow;
    }
    final key = newClientId();
    final photos = [for (final p in photoPaths) await _keep(p)];
    await _queue.enqueue(
      _scope!,
      entity: findingEntity,
      kind: OperationKind.insert,
      recordId: view.id,
      key: key,
      capturedAt: capturedAt.toUtc(),
      payload: {
        ...ApiInspectionCaptureRepository.findingBody(
          description: description,
          failureCode: failureCode,
          // Sin falla ni severidad, el servidor exige una: la app propone MEDIA.
          severity: severity ?? (failureCode == null ? 'MEDIA' : null),
          parameter: parameter,
          position: position,
          clientUuid: key,
        ),
        if (photos.isNotEmpty) photosKey: photos,
        latKey: position?.latitude,
        lngKey: position?.longitude,
        atKey: capturedAt.toUtc().toIso8601String(),
      },
    );
    return _withPending(view);
  }

  @override
  Future<List<FailureChoice>> failures(String typeId) =>
      _online.failures(typeId);

  @override
  Future<InspectionCaptureView> accept(InspectionCaptureView view) =>
      _online.accept(view);

  @override
  Future<InspectionCaptureView> reject(
    InspectionCaptureView view,
    String reason,
  ) => _online.reject(view, reason);

  /// Una sola captura por inspeccion en la cola: se reemplaza la que espera
  /// (conservando su version de partida y sus fotos) por la nueva.
  Future<void> _upsert(
    InspectionCaptureView view, {
    required Map<String, dynamic> answers,
    Map<String, Object?>? finalize,
    Map<String, Object?>? photo,
  }) async {
    final scope = _scope!;
    final waiting = [
      for (final o in await _queue.list(
        scope,
        statuses: {OperationStatus.pending},
      ))
        if (o.entity == inspectionEntity && o.recordId == view.id) o,
    ];
    final photos = [for (final o in waiting) ..._photos(o), ?photo];
    final keepFinalize =
        finalize ??
        [
          for (final o in waiting) o.payload['finalize'],
        ].whereType<Map>().firstOrNull;
    final baseVersion = waiting.isNotEmpty
        ? waiting.first.baseVersion ?? view.rowVersion
        : view.rowVersion;
    for (final o in waiting) {
      await _queue.discard(o.id);
    }
    await _queue.enqueue(
      scope,
      entity: inspectionEntity,
      kind: OperationKind.update,
      recordId: view.id,
      baseVersion: baseVersion,
      capturedAt: _clock().toUtc(),
      payload: {
        'answers': answers,
        'finalize': ?keepFinalize,
        if (photos.isNotEmpty) photosKey: photos,
      },
    );
  }

  /// Copia la foto a un lugar que no se borra antes de que suba.
  Future<String> _keep(String path) async {
    final store = files;
    if (store == null) return path;
    try {
      return await store.keep(path, name: path.split(RegExp(r'[\\/]')).last);
    } catch (_) {
      return path;
    }
  }
}
