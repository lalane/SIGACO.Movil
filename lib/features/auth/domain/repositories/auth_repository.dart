import '../entities/auth_entities.dart';

/// Acceso a la API de autenticacion. Las implementaciones lanzan [AuthException].
abstract interface class AuthRepository {
  /// Emite cuando el servidor cierra la sesion (vencida, revocada, 401).
  Stream<void> get sessionExpired;

  /// Emite cuando el servidor exige un paso a mitad de sesion (MFA, cambio de
  /// contrasena, elegir concesion).
  Stream<SessionRequirement> get sessionRequirements;

  /// Ultima respuesta del servidor con sesion abierta; base del aviso de
  /// inactividad (el servidor la mide por peticion).
  DateTime? get lastActivityAt;

  /// Perfil propio. Tambien sirve para mantener viva la sesion.
  Future<MyProfile> getProfile();

  Future<LoginOutcome> login(String email, String password);

  Future<void> verifyMfa(String code);

  Future<MfaEnrollment> startMfaEnrollment();

  Future<void> activateMfa(String code);

  Future<void> changePassword({
    required String current,
    required String next,
    required String confirm,
  });

  Future<void> selectConcession(String concessionId);

  /// El servidor responde igual exista o no la cuenta; los fallos no se propagan.
  Future<void> requestPasswordRecovery(String email);

  Future<void> logout();
}
