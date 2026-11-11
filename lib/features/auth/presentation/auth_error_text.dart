import '../../../l10n/app_localizations.dart';
import '../domain/entities/auth_entities.dart';

String authErrorText(AppLocalizations l10n, AuthError e) => switch (e) {
  AuthError.invalidCredentials => l10n.errInvalidCredentials,
  AuthError.accountBlocked => l10n.errAccountBlocked,
  AuthError.network => l10n.errNetwork,
  AuthError.server => l10n.errServer,
  AuthError.sessionExpired => l10n.errSessionExpired,
  AuthError.mfaInvalid => l10n.mfaCodeInvalid,
  AuthError.validation => l10n.errValidation,
  AuthError.passwordMismatch => l10n.passwordMismatch,
  AuthError.biometricNotConfigured => l10n.biometricNoCredentials,
  AuthError.accessExpired => l10n.errAccessExpired,
};

/// El mensaje a mostrar: si el servidor explico el motivo (por ejemplo por que no
/// acepto la contrasena nueva), se muestra eso; si no, el texto general.
String authErrorMessage(
  AppLocalizations l10n,
  AuthError e, [
  List<String> details = const [],
]) => e == AuthError.validation && details.isNotEmpty
    ? details.join('\n')
    : authErrorText(l10n, e);
