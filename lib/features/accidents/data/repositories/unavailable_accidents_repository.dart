import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';

/// Mientras el backend no publique los endpoints de accidentes, la pantalla dice
/// que no estan disponibles en lugar de inventar datos. Con
/// `SAMPLE_ACCIDENTS=true` se usa [SampleAccidentsRepository].
class UnavailableAccidentsRepository implements AccidentsRepository {
  const UnavailableAccidentsRepository();

  static const _error = AccidentsException(AccidentsError.notAvailable);

  @override
  Future<List<Accident>> list() => Future.error(_error);

  @override
  Future<Accident> get(String id) => Future.error(_error);

  @override
  Future<Accident> create(NewAccident draft) => Future.error(_error);
}
