import '../../domain/entities/pending_definition.dart';
import '../../domain/repositories/definitions_repository.dart';

/// Sin servidor configurado (pruebas y arranque sin API): todo falla como sin red.
class UnavailableDefinitionsRepository implements DefinitionsRepository {
  const UnavailableDefinitionsRepository();

  @override
  Future<DefinitionPage> list({String? mobileModule}) =>
      Future.error(const DefinitionsException(DefinitionsError.network));

  @override
  Future<DefinitionDetail> get(String code) =>
      Future.error(const DefinitionsException(DefinitionsError.network));

  @override
  Future<DefinitionDetail> answer(
    String code,
    DefinitionAnswerKind kind, {
    String? text,
  }) => Future.error(const DefinitionsException(DefinitionsError.network));
}
