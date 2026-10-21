import 'package:equatable/equatable.dart';

class ConcessionSummary extends Equatable {
  const ConcessionSummary({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

class CurrentUser extends Equatable {
  const CurrentUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.organizationArea,
    this.jobTitle,
    this.companyName,
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? organizationArea;

  /// Cargo y empresa de la persona (DEV-MOB-041); el servidor los trae nulos si
  /// no se capturaron.
  final String? jobTitle;
  final String? companyName;

  @override
  List<Object?> get props => [
    id,
    username,
    fullName,
    email,
    organizationArea,
    jobTitle,
    companyName,
  ];
}

/// Resultado del login: la sesion y los pasos que el backend deja pendientes.
class LoginOutcome extends Equatable {
  const LoginOutcome({
    required this.user,
    required this.concessions,
    required this.activeConcessionId,
    required this.idleTimeoutMinutes,
    required this.mfaRequired,
    required this.mfaEnrollmentRequired,
    required this.forcePasswordChange,
    this.expiresAt,
  });

  /// Hasta cuando vale la sesion. En la app movil vale hasta ese momento, con o
  /// sin conexion (RN-M01-37); pasado, hay que volver a entrar con conexion.
  final DateTime? expiresAt;

  final CurrentUser user;
  final List<ConcessionSummary> concessions;
  final String? activeConcessionId;
  final int idleTimeoutMinutes;
  final bool mfaRequired;
  final bool mfaEnrollmentRequired;
  final bool forcePasswordChange;

  @override
  List<Object?> get props => [
    user,
    concessions,
    activeConcessionId,
    idleTimeoutMinutes,
    mfaRequired,
    mfaEnrollmentRequired,
    forcePasswordChange,
    expiresAt,
  ];
}

/// Lo que el servidor confirma al recuperar la conexion (POST
/// /api/auth/session/revalidate, HU-M01-08-04): la cuenta, el vencimiento de la
/// sesion y los permisos vigentes.
class SessionRevalidation extends Equatable {
  const SessionRevalidation({
    required this.accountStatus,
    required this.expiresAt,
    required this.idleTimeoutMinutes,
    required this.serverTime,
    this.activeConcessionId,
    this.mfaPending = false,
    this.forcePasswordChange = false,
    this.permissions = const [],
    this.modules = const [],
    this.hasMenu = false,
  });

  /// ACTIVO, BLOQUEADO o INACTIVO. Con las dos ultimas el servidor ya revoco la
  /// sesion (responde 401), pero se comprueba igual.
  final String accountStatus;
  final DateTime expiresAt;
  final int idleTimeoutMinutes;

  /// Hora del servidor: sirve para medir cuanto se adelanta o atrasa el reloj
  /// del telefono (RN-15).
  final DateTime serverTime;
  final String? activeConcessionId;
  final bool mfaPending;
  final bool forcePasswordChange;
  final List<String> permissions;
  final List<String> modules;

  /// El servidor mando el menu y los permisos (si no, no hay con que comparar).
  final bool hasMenu;

  bool get isActive => accountStatus.toUpperCase() == 'ACTIVO';

  /// La sesion no puede seguir sin que la persona haga otro paso.
  bool get needsStep => mfaPending || forcePasswordChange;

  @override
  List<Object?> get props => [
    accountStatus,
    expiresAt,
    idleTimeoutMinutes,
    serverTime,
    activeConcessionId,
    mfaPending,
    forcePasswordChange,
    permissions,
    modules,
    hasMenu,
  ];
}

/// Estado de la verificacion en dos pasos de la cuenta, tal como lo informa el
/// servidor en GET /api/auth/me (DEV-MOB-052).
class MfaStatus extends Equatable {
  const MfaStatus({
    required this.required,
    required this.active,
    this.recoveryCodesRemaining = 0,
  });

  /// El servidor exige la verificacion a esta cuenta.
  final bool required;

  /// Ya esta enrolada y activa.
  final bool active;

  /// Codigos de recuperacion sin usar.
  final int recoveryCodesRemaining;

  @override
  List<Object?> get props => [required, active, recoveryCodesRemaining];
}

class MfaEnrollment extends Equatable {
  const MfaEnrollment({required this.secret, required this.otpAuthUri});

  final String secret;
  final String otpAuthUri;

  @override
  List<Object?> get props => [secret, otpAuthUri];
}

class ProfileSummary extends Equatable {
  const ProfileSummary({required this.code, required this.nameEs, this.namePt});

  final String code;
  final String nameEs;
  final String? namePt;

  String localizedName(String languageCode) =>
      languageCode == 'pt' && (namePt?.isNotEmpty ?? false) ? namePt! : nameEs;

  @override
  List<Object?> get props => [code, nameEs, namePt];
}

class RoadSummary extends Equatable {
  const RoadSummary({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

/// Perfil propio: la cuenta y el contexto de la sesion (FEAT-M01-03).
class MyProfile extends Equatable {
  const MyProfile({
    required this.user,
    required this.activeConcession,
    required this.profile,
    required this.roads,
    required this.availableConcessions,
    this.mfa,
  });

  /// Nulo si el servidor no lo informo (versiones anteriores del backend).
  final MfaStatus? mfa;

  final CurrentUser user;
  final ConcessionSummary? activeConcession;
  final ProfileSummary? profile;
  final List<RoadSummary> roads;
  final List<ConcessionSummary> availableConcessions;

  @override
  List<Object?> get props => [
    user,
    activeConcession,
    profile,
    roads,
    availableConcessions,
    mfa,
  ];
}

/// Paso que el servidor exige a mitad de sesion (403 con codigo estable).
enum SessionRequirement { mfa, mfaEnrollment, passwordChange, concession }

/// Motivos de fallo del acceso, independientes del transporte (HTTP).
enum AuthError {
  invalidCredentials,
  accountBlocked,
  network,
  server,
  sessionExpired,
  mfaInvalid,
  validation,
  passwordMismatch,
  biometricNotConfigured,
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  @override
  String toString() => 'AuthException(${error.name})';
}
