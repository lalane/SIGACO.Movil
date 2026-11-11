import '../entities/pending_definition.dart';

/// Por que no se pudo leer o responder una definicion.
enum DefinitionsError {
  /// Sin conexion o sin respuesta del servidor.
  network,

  /// El perfil no puede hacer eso (p. ej. aceptar sin administrar).
  permissionDenied,

  /// La definicion ya no existe.
  notFound,

  /// Esta retirada: ya no se contesta.
  retired,

  /// Falta el texto o no es valido.
  validation,

  /// Error del servidor.
  server,
}

class DefinitionsException implements Exception {
  const DefinitionsException(this.error, [this.message]);

  final DefinitionsError error;

  /// El texto del servidor, si lo trae.
  final String? message;

  @override
  String toString() => 'DefinitionsException($error)';
}

/// Las definiciones pendientes de SIGACO (son del sistema, no de la concesion).
/// Lanza [DefinitionsException].
abstract interface class DefinitionsRepository {
  /// Sin las retiradas. [mobileModule] deja las de un modulo de la app.
  Future<DefinitionPage> list({String? mobileModule});

  Future<DefinitionDetail> get(String code);

  Future<DefinitionDetail> answer(
    String code,
    DefinitionAnswerKind kind, {
    String? text,
  });
}
