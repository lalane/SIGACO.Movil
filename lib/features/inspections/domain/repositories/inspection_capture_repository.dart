import '../entities/inspection.dart';
import '../entities/inspection_capture.dart';
import 'inspections_repository.dart';

/// Faltan datos para finalizar: lo que dijo el telefono o el servidor.
class InspectionIncompleteException extends InspectionsException {
  const InspectionIncompleteException(this.issues)
    : super(InspectionsError.incomplete);

  final List<CaptureIssue> issues;

  /// El servidor pide justificar la ubicacion (fuera de la tolerancia).
  CaptureIssue? get location =>
      issues.where((i) => i.path == 'locationJustification').firstOrNull;
}

/// Captura de una inspeccion con su plantilla (M08, APP-MOB-08): ver, guardar
/// borrador, fotos por campo, hallazgos con falla y finalizar; aceptar o
/// rechazar la asignada. Lanza [InspectionsException].
abstract interface class InspectionCaptureRepository {
  /// Hay servidor de verdad (sin el, la ficha usa el checklist de antes).
  bool get available;

  Future<InspectionCaptureView> capture(String id);

  Future<InspectionCaptureView> start(String id, int rowVersion);

  /// Guarda el borrador; sin red queda en la cola y se ve igual en el telefono.
  Future<InspectionCaptureView> save(
    InspectionCaptureView view,
    Map<String, dynamic> answers,
  );

  /// Valida en el telefono y finaliza; sin red queda en la cola (no genera
  /// ticket hasta sincronizarse).
  Future<InspectionCaptureView> finalize(
    InspectionCaptureView view, {
    FindingPosition? position,
    String? justification,
    required DateTime executedAt,
  });

  /// Foto de un campo de evidencia (o general si [fieldKey] es null).
  Future<InspectionCaptureView> addPhoto(
    InspectionCaptureView view,
    String path, {
    String? fieldKey,
    FindingPosition? position,
    required DateTime capturedAt,
  });

  /// Hallazgo con su falla (o severidad) y sus fotos.
  Future<InspectionCaptureView> addFinding(
    InspectionCaptureView view, {
    required String description,
    String? failureCode,
    String? severity,
    String? parameter,
    List<String> photoPaths,
    FindingPosition? position,
    required DateTime capturedAt,
  });

  Future<List<FailureChoice>> failures(String typeId);

  Future<InspectionCaptureView> accept(InspectionCaptureView view);

  Future<InspectionCaptureView> reject(
    InspectionCaptureView view,
    String reason,
  );
}

/// Sin servidor (datos de ejemplo): la ficha usa el checklist de antes.
class UnavailableInspectionCapture implements InspectionCaptureRepository {
  const UnavailableInspectionCapture();

  static const _error = InspectionsException(InspectionsError.notAvailable);

  @override
  bool get available => false;
  @override
  Future<InspectionCaptureView> capture(String id) => Future.error(_error);
  @override
  Future<InspectionCaptureView> start(String id, int rowVersion) =>
      Future.error(_error);
  @override
  Future<InspectionCaptureView> save(
    InspectionCaptureView view,
    Map<String, dynamic> answers,
  ) => Future.error(_error);
  @override
  Future<InspectionCaptureView> finalize(
    InspectionCaptureView view, {
    FindingPosition? position,
    String? justification,
    required DateTime executedAt,
  }) => Future.error(_error);
  @override
  Future<InspectionCaptureView> addPhoto(
    InspectionCaptureView view,
    String path, {
    String? fieldKey,
    FindingPosition? position,
    required DateTime capturedAt,
  }) => Future.error(_error);
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
  }) => Future.error(_error);
  @override
  Future<List<FailureChoice>> failures(String typeId) async => const [];
  @override
  Future<InspectionCaptureView> accept(InspectionCaptureView view) =>
      Future.error(_error);
  @override
  Future<InspectionCaptureView> reject(
    InspectionCaptureView view,
    String reason,
  ) => Future.error(_error);
}
