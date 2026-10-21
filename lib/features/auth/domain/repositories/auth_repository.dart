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

  /// Hasta cuando vale la sesion segun el servidor; nulo si aun no se conoce.
  DateTime? get sessionExpiresAt;

  /// Cuanto se adelanta (positivo) o atrasa el servidor respecto del reloj del
  /// telefono, medido en la ultima revalidacion; cero si aun no se midio.
  Duration get serverClockOffset;

  /// Revalida la sesion, la cuenta y los permisos vigentes antes de sincronizar.
  /// Si el servidor ya revoco la sesion, lanza [AuthException] con
  /// [AuthError.sessionExpired].
  Future<SessionRevalidation> revalidateSession();

  /// Perfil propio. Tambien sirve para mantener viva la sesion.
  Future<MyProfile> getProfile();

  Future<LoginOutcome> login(String email, String password);

  Future<void> verifyMfa(String code);

  Future<MfaEnrollment> startMfaEnrollment();

  /// Confirma el enrolamiento con el primer codigo. Devuelve los codigos de
  /// recuperacion, que el servidor muestra solo esta vez.
  Future<List<String>> activateMfa(String code);

  /// Genera codigos de recuperacion nuevos (los anteriores dejan de servir);
  /// pide un codigo vigente de la app autenticadora.
  Future<List<String>> regenerateRecoveryCodes(String code);

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
