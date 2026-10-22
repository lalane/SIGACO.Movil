import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';

/// Mientras el backend no publique los endpoints de inspecciones, la pantalla
/// dice que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_INSPECTIONS=true` se usa `SampleInspectionsRepository`.
class UnavailableInspectionsRepository implements InspectionsRepository {
  const UnavailableInspectionsRepository();

  static const _error = InspectionsException(InspectionsError.notAvailable);

  @override
  Future<List<Inspection>> list() => Future.error(_error);

  @override
  Future<Inspection> get(String id) => Future.error(_error);

  @override
  Future<Inspection> saveAnswers(String id, Map<String, CheckResult> answers) =>
      Future.error(_error);

  @override
  Future<List<InspectionTemplate>> templates() => Future.error(_error);

  @override
  Future<Inspection> create(NewInspection draft) => Future.error(_error);

  @override
  Future<Inspection> addFinding(String id, InspectionFinding finding) =>
      Future.error(_error);

  @override
  Future<Inspection> complete(String id, Map<String, CheckResult> answers) =>
      Future.error(_error);
}
