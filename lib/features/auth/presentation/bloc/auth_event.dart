import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_entities.dart';

/// Eventos del flujo de acceso. Los que llevan secretos los ocultan en
/// `toString` porque el observador de trazabilidad los registra.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga el correo recordado y la disponibilidad de biometria.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({
    required this.email,
    required this.password,
    this.remember = false,
  });

  final String email;
  final String password;

  /// Recordar correo y contrasena en el dispositivo (cifrados).
  final bool remember;

  @override
  List<Object?> get props => [email, remember];

  @override
  String toString() => 'AuthLoginSubmitted(email: $email, remember: $remember)';
}

class AuthBiometricLoginRequested extends AuthEvent {
  const AuthBiometricLoginRequested(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

class AuthMfaSubmitted extends AuthEvent {
  const AuthMfaSubmitted(this.code);

  final String code;

  @override
  String toString() => 'AuthMfaSubmitted()';
}

class AuthMfaEnrollmentRequested extends AuthEvent {
  const AuthMfaEnrollmentRequested();
}

/// La persona confirmo que guardo sus codigos de recuperacion.
class AuthRecoveryCodesAcknowledged extends AuthEvent {
  const AuthRecoveryCodesAcknowledged();
}

class AuthMfaActivationSubmitted extends AuthEvent {
  const AuthMfaActivationSubmitted(this.code);

  final String code;

  @override
  String toString() => 'AuthMfaActivationSubmitted()';
}

class AuthPasswordChangeSubmitted extends AuthEvent {
  const AuthPasswordChangeSubmitted({
    required this.current,
    required this.next,
    required this.confirm,
  });

  final String current;
  final String next;
  final String confirm;

  @override
  String toString() => 'AuthPasswordChangeSubmitted()';
}

class AuthConcessionSelected extends AuthEvent {
  const AuthConcessionSelected(this.concessionId);

  final String concessionId;

  @override
  List<Object?> get props => [concessionId];
}

class AuthRecoveryRequested extends AuthEvent {
  const AuthRecoveryRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Se abrio la pantalla de recuperacion: se descarta el resultado anterior.
class AuthRecoveryOpened extends AuthEvent {
  const AuthRecoveryOpened();
}

/// El usuario volvio del navegador tras definir su nueva contrasena (enlace
/// `sigaco://app/login?reset=ok`): lo guardado en el equipo ya no sirve.
class AuthPasswordResetReturned extends AuthEvent {
  const AuthPasswordResetReturned();
}

class AuthBiometricOfferAnswered extends AuthEvent {
  const AuthBiometricOfferAnswered({
    required this.accepted,
    required this.reason,
    this.persistDecline = true,
  });

  final bool accepted;
  final String reason;

  /// Un "Ahora no" explicito no se vuelve a ofrecer; cerrar el aviso sin
  /// elegir (por ejemplo con el boton atras) solo lo pospone.
  final bool persistDecline;

  @override
  List<Object?> get props => [accepted, reason, persistDecline];
}

/// El usuario apaga el acceso con biometria desde su cuenta.
class AuthBiometricDisabled extends AuthEvent {
  const AuthBiometricDisabled();
}

/// El usuario activa la biometria desde su cuenta, con la sesion abierta.
class AuthBiometricEnableRequested extends AuthEvent {
  const AuthBiometricEnableRequested(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// La contrasena cambio durante la sesion (cambio voluntario desde la cuenta):
/// la que guarda la app en memoria debe ser la nueva.
class AuthPasswordUpdated extends AuthEvent {
  const AuthPasswordUpdated(this.password);

  final String password;

  @override
  String toString() => 'AuthPasswordUpdated()';
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// El servidor exige un paso a mitad de sesion (MFA, contrasena, concesion).
class AuthRequirementReceived extends AuthEvent {
  const AuthRequirementReceived(this.requirement);

  final SessionRequirement requirement;

  @override
  List<Object?> get props => [requirement];
}

/// El servidor cerro la sesion (vencida o revocada).
class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
