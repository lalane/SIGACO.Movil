import 'package:equatable/equatable.dart';

class ConcessionSummary extends Equatable {
  const ConcessionSummary({
    required this.id,
    required this.code,
    required this.name,
    this.logoUrl,
  });

  final String id;
  final String code;
  final String name;

  /// Ruta del logo de la concesion en el servidor (se baja con la sesion). Null
  /// si no tiene ni usa el de SIGACO.
  final String? logoUrl;

  @override
  List<Object?> get props => [id, code, name, logoUrl];
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
    this.teamName,
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

  /// El equipo (team) de la empresa al que pertenece, en la concesion activa.
  final String? teamName;

  @override
  List<Object?> get props => [
    id,
    username,
    fullName,
    email,
    organizationArea,
    jobTitle,
    companyName,
    teamName,
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
    this.profiles = const [],
  });

  /// Nulo si el servidor no lo informo (versiones anteriores del backend).
  final MfaStatus? mfa;

  final CurrentUser user;
  final ConcessionSummary? activeConcession;
  final ProfileSummary? profile;

  /// Todos los perfiles de la persona en la concesion: el servidor le da un
  /// perfil distinto a cada modulo. Vacio si el servidor solo informa uno
  /// ([profile]).
  final List<ProfileSummary> profiles;
  final List<RoadSummary> roads;
  final List<ConcessionSummary> availableConcessions;

  /// Los nombres de sus perfiles, sin repetir y separados por coma; el unico si
  /// solo tiene uno.
  String profileLabel(String languageCode) {
    final all = profiles.isNotEmpty ? profiles : [?profile];
    return {for (final p in all) p.localizedName(languageCode)}.join(', ');
  }

  @override
  List<Object?> get props => [
    user,
    activeConcession,
    profile,
    profiles,
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
  const AuthException(this.error, {this.details = const []});

  final AuthError error;

  /// Lo que el servidor dijo que esta mal (por ejemplo por que rechazo una
  /// contrasena nueva). Texto para la persona, nunca datos tecnicos.
  final List<String> details;

  @override
  String toString() => 'AuthException(${error.name})';
}

/// Cada regla que puede exigir la contrasena nueva.
enum PasswordRuleKind { length, uppercase, lowercase, digit, special }

/// Lo que se exige al elegir contrasena (Configuracion > Seguridad). El servidor
/// es quien valida: esto solo permite mostrarlo antes de escribir y marcar lo que
/// ya se cumple.
class PasswordRules extends Equatable {
  const PasswordRules({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireDigit = true,
    this.requireSpecial = true,
  });

  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecial;

  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _lower = RegExp(r'\p{Ll}', unicode: true);
  static final _digit = RegExp(r'\p{Nd}', unicode: true);
  // Como el servidor: lo que no es letra, digito ni espacio.
  static final _special = RegExp(r'[^\p{L}\p{Nd}\s]', unicode: true);

  /// Las que se exigen, en el orden en que se muestran.
  List<PasswordRuleKind> get required => [
    PasswordRuleKind.length,
    if (requireUppercase) PasswordRuleKind.uppercase,
    if (requireLowercase) PasswordRuleKind.lowercase,
    if (requireDigit) PasswordRuleKind.digit,
    if (requireSpecial) PasswordRuleKind.special,
  ];

  bool isMet(PasswordRuleKind kind, String password) => switch (kind) {
    PasswordRuleKind.length => password.length >= minLength,
    PasswordRuleKind.uppercase => _upper.hasMatch(password),
    PasswordRuleKind.lowercase => _lower.hasMatch(password),
    PasswordRuleKind.digit => _digit.hasMatch(password),
    PasswordRuleKind.special => _special.hasMatch(password),
  };

  bool isSatisfiedBy(String password) =>
      required.every((k) => isMet(k, password));

  @override
  List<Object?> get props => [
    minLength,
    requireUppercase,
    requireLowercase,
    requireDigit,
    requireSpecial,
  ];
}
