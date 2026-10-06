import '../../../l10n/app_localizations.dart';
import '../domain/entities/auth_entities.dart';

String authErrorText(AppLocalizations l10n, AuthError e) => switch (e) {
  AuthError.invalidCredentials => l10n.errInvalidCredentials,
  AuthError.accountBlocked => l10n.errAccountBlocked,
  AuthError.network => l10n.errNetwork,
  AuthError.server => l10n.errServer,
  AuthError.sessionExpired => l10n.errSessionExpired,
  AuthError.mfaInvalid => l10n.mfaCodeInvalid,
  AuthError.validation => l10n.errServer,
  AuthError.passwordMismatch => l10n.passwordMismatch,
  AuthError.biometricNotConfigured => l10n.biometricNoCredentials,
};
