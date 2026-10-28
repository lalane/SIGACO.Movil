import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/auth_error_text.dart';
import 'package:sigaco_movil/l10n/app_localizations.dart';
import 'package:sigaco_movil/l10n/app_localizations_es.dart';
import 'package:sigaco_movil/l10n/app_localizations_pt.dart';

/// Lo que ve la persona cuando el acceso falla (APP-MOB-01): cada error tiene su
/// mensaje en los dos idiomas y ninguno promete lo que no es.
void main() {
  final idiomas = <String, AppLocalizations>{
    'es': AppLocalizationsEs(),
    'pt': AppLocalizationsPt(),
  };

  for (final MapEntry(key: lang, value: l10n) in idiomas.entries) {
    group('mensajes en $lang', () {
      test('todos los errores tienen texto', () {
        for (final e in AuthError.values) {
          expect(authErrorText(l10n, e).trim(), isNotEmpty, reason: e.name);
        }
      });

      test('los que la persona resuelve de forma distinta no se confunden', () {
        String t(AuthError e) => authErrorText(l10n, e);
        expect(t(AuthError.invalidCredentials), isNot(t(AuthError.network)));
        expect(t(AuthError.invalidCredentials), isNot(t(AuthError.mfaInvalid)));
        expect(t(AuthError.accountBlocked), isNot(t(AuthError.server)));
        expect(t(AuthError.sessionExpired), isNot(t(AuthError.network)));
      });

      test('no muestran datos tecnicos ni contrasenas', () {
        for (final e in AuthError.values) {
          final text = authErrorText(l10n, e).toLowerCase();
          expect(text, isNot(contains('exception')), reason: e.name);
          expect(text, isNot(contains('null')), reason: e.name);
          expect(text, isNot(contains('http')), reason: e.name);
        }
      });
    });
  }

  test('el mensaje cambia con el idioma', () {
    for (final e in AuthError.values) {
      expect(
        authErrorText(idiomas['es']!, e),
        isNot(authErrorText(idiomas['pt']!, e)),
        reason: e.name,
      );
    }
  });
}
