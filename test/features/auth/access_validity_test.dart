import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';
import 'package:sigaco_movil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/presentation/auth_error_text.dart';
import 'package:sigaco_movil/l10n/app_localizations_es.dart';
import 'package:sigaco_movil/l10n/app_localizations_pt.dart';

import '../../support/fake_api.dart';

/// Vencimiento del acceso (acuerdo A8 del 05/11/2026) y varios equipos por
/// usuario (A2): lo que la app recibe del login y del perfil propio.
void main() {
  group('acceso vencido', () {
    late FakeApi api;
    late AuthRepositoryImpl repo;

    setUp(() {
      api = FakeApi();
      repo = AuthRepositoryImpl(api.client());
    });

    test('el login rechazado por vencimiento no se confunde con credenciales malas', () async {
      api.on(
        'POST /api/auth/login',
        const FakeReply(401, {
          'code': 'AUTH_ACCESS_EXPIRED',
          'title': 'Tu acceso a SIGACO venció el 31/12/2028. Pide a tu administrador que lo renueve.',
        }),
      );
      await expectLater(
        repo.login('joao@nova.local', 'Clave.Segura.2026!'),
        throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.accessExpired)),
      );
    });

    test('el mensaje pide renovar el acceso, en los dos idiomas', () {
      final es = authErrorText(AppLocalizationsEs(), AuthError.accessExpired);
      final pt = authErrorText(AppLocalizationsPt(), AuthError.accessExpired);
      expect(es, contains('venció'));
      expect(pt, contains('venceu'));
      expect(es, isNot(authErrorText(AppLocalizationsEs(), AuthError.invalidCredentials)));
    });
  });

  test('el perfil propio trae sus equipos y la vigencia del acceso', () {
    final user = userFromJson({
      'id': 'u1',
      'username': 'lider',
      'fullName': 'Lider Campo',
      'email': 'lider@nova.local',
      'teamName': 'Cuadrilla 01, Pavimentos',
      'accessValidUntil': '2028-12-31',
    });
    expect(user.teamName, 'Cuadrilla 01, Pavimentos');
    expect(user.accessValidUntil, '2028-12-31');
    expect(userFromJson({'id': 'u2'}).accessValidUntil, isNull);
  });
}
