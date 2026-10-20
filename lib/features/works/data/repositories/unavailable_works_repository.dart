import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';

/// Mientras el backend no publique los endpoints de obras, la pantalla dice que
/// no estan disponibles en lugar de inventar datos. Con `SAMPLE_WORKS=true` se
/// usa `SampleWorksRepository`.
class UnavailableWorksRepository implements WorksRepository {
  const UnavailableWorksRepository();

  static const _error = WorksException(WorksError.notAvailable);

  @override
  Future<List<PublicWork>> list() => Future.error(_error);

  @override
  Future<PublicWork> get(String id) => Future.error(_error);
}
