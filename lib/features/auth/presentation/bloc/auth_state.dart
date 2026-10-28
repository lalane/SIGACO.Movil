import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_entities.dart';

/// Pasos del flujo de acceso. El backend indica cuales siguen pendientes.
enum AuthStep {
  signedOut,
  mfa,
  mfaEnroll,
  mfaCodes,
  changePassword,
  concession,
  signedIn,
}

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.concessions = const [],
    this.activeConcessionId,
    this.idleTimeoutMinutes = 10,
    this.mfaRequired = false,
    this.mfaEnrollmentRequired = false,
    this.passwordChangeRequired = false,
    this.busy = false,
    this.error,
    this.errorDetails = const [],
    this.sessionExpired = false,
    this.offerBiometric = false,
    this.mfaEnrollment,
    this.recoveryCodes = const [],
    this.recoverySent = false,
    this.passwordResetDone = false,
    this.mfaActive = false,
    this.rememberedEmail,
    this.rememberedPassword,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
  });

  final CurrentUser? user;
  final List<ConcessionSummary> concessions;
  final String? activeConcessionId;
  final int idleTimeoutMinutes;
  final bool mfaRequired;
  final bool mfaEnrollmentRequired;
  final bool passwordChangeRequired;

  /// Hay una operacion en curso.
  final bool busy;
  final AuthError? error;

  /// Los motivos que dio el servidor para `error` (por ejemplo, por que no
  /// acepto la contrasena nueva); vacio si no dio ninguno.
  final List<String> errorDetails;

  /// La sesion termino por el servidor; el login lo muestra.
  final bool sessionExpired;

  /// Hay que ofrecer activar biometria (primer acceso con contrasena).
  final bool offerBiometric;
  final MfaEnrollment? mfaEnrollment;

  /// Codigos de recuperacion recien entregados: se muestran una sola vez y la
  /// persona confirma que los guardo antes de seguir.
  final List<String> recoveryCodes;
  final bool recoverySent;

  /// El usuario definio una nueva contrasena en el navegador y regreso a la app.
  final bool passwordResetDone;

  /// Un administrador activo la verificacion en dos pasos de esta cuenta. El
  /// servidor no lo informa en el perfil: se deduce del acceso (pidio el codigo
  /// o el enrolamiento).
  final bool mfaActive;
  final String? rememberedEmail;

  /// Solo existe en el estado sin sesion, para rellenar el formulario; al
  /// iniciar sesion se descarta. Nunca se registra (ver `toString`).
  final String? rememberedPassword;
  final bool biometricAvailable;
  final bool biometricEnabled;

  /// Nombre de la concesion activa (el contexto que refleja la cabecera).
  String? get activeConcessionName {
    for (final c in concessions) {
      if (c.id == activeConcessionId) return c.name;
    }
    return null;
  }

  /// Paso actual, derivado de lo que el backend dejo pendiente.
  AuthStep get step {
    if (user == null) return AuthStep.signedOut;
    if (mfaRequired) return AuthStep.mfa;
    if (mfaEnrollmentRequired) return AuthStep.mfaEnroll;
    if (recoveryCodes.isNotEmpty) return AuthStep.mfaCodes;
    if (passwordChangeRequired) return AuthStep.changePassword;
    if (activeConcessionId == null && concessions.length > 1) {
      return AuthStep.concession;
    }
    return AuthStep.signedIn;
  }

  AuthState copyWith({
    CurrentUser? user,
    List<ConcessionSummary>? concessions,
    String? activeConcessionId,
    bool clearActiveConcession = false,
    int? idleTimeoutMinutes,
    bool? mfaRequired,
    bool? mfaEnrollmentRequired,
    bool? passwordChangeRequired,
    bool? busy,
    AuthError? error,
    List<String>? errorDetails,
    bool clearError = false,
    bool? sessionExpired,
    bool? offerBiometric,
    MfaEnrollment? mfaEnrollment,
    List<String>? recoveryCodes,
    bool? recoverySent,
    bool? passwordResetDone,
    bool? mfaActive,
    String? rememberedEmail,
    String? rememberedPassword,
    bool clearRememberedPassword = false,
    bool? biometricAvailable,
    bool? biometricEnabled,
  }) => AuthState(
    user: user ?? this.user,
    concessions: concessions ?? this.concessions,
    activeConcessionId: clearActiveConcession
        ? null
        : (activeConcessionId ?? this.activeConcessionId),
    idleTimeoutMinutes: idleTimeoutMinutes ?? this.idleTimeoutMinutes,
    mfaRequired: mfaRequired ?? this.mfaRequired,
    mfaEnrollmentRequired: mfaEnrollmentRequired ?? this.mfaEnrollmentRequired,
    passwordChangeRequired:
        passwordChangeRequired ?? this.passwordChangeRequired,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    errorDetails: clearError
        ? const []
        : (errorDetails ?? (error != null ? const [] : this.errorDetails)),
    sessionExpired: sessionExpired ?? this.sessionExpired,
    offerBiometric: offerBiometric ?? this.offerBiometric,
    mfaEnrollment: mfaEnrollment ?? this.mfaEnrollment,
    recoveryCodes: recoveryCodes ?? this.recoveryCodes,
    recoverySent: recoverySent ?? this.recoverySent,
    passwordResetDone: passwordResetDone ?? this.passwordResetDone,
    mfaActive: mfaActive ?? this.mfaActive,
    rememberedEmail: rememberedEmail ?? this.rememberedEmail,
    rememberedPassword: clearRememberedPassword
        ? null
        : (rememberedPassword ?? this.rememberedPassword),
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
  );

  @override
  List<Object?> get props => [
    user,
    concessions,
    activeConcessionId,
    idleTimeoutMinutes,
    mfaRequired,
    mfaEnrollmentRequired,
    passwordChangeRequired,
    busy,
    error,
    errorDetails,
    sessionExpired,
    offerBiometric,
    mfaEnrollment,
    recoveryCodes,
    recoverySent,
    passwordResetDone,
    mfaActive,
    rememberedEmail,
    rememberedPassword,
    biometricAvailable,
    biometricEnabled,
  ];

  /// Sin secretos: el observador registra los estados.
  @override
  String toString() =>
      'AuthState(step: ${step.name}, busy: $busy, error: ${error?.name})';
}
