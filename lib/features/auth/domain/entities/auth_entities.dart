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
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? organizationArea;

  @override
  List<Object?> get props => [id, username, fullName, email, organizationArea];
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
  });

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
  ];
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
  });

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
