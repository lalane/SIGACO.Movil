import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/auth/data/mappers/auth_mappers.dart';

/// La respuesta de POST /api/auth/session/revalidate (HU-M01-08-04, RN-M01-38).
void main() {
  Map<String, dynamic> json({String status = 'ACTIVO', Object? navigation}) => {
    'sessionId': 's1',
    'clientType': 'MOBILE',
    'accountStatus': status,
    'forcePasswordChange': false,
    'mfaPending': false,
    'expiresAt': '2026-10-22T04:00:00Z',
    'idleTimeoutMinutes': 10,
    'activeConcessionId': 'c1',
    'serverTime': '2026-10-21T18:00:00Z',
    'navigation': navigation,
  };

  test('lee la cuenta, el vencimiento y los permisos vigentes', () {
    final r = sessionRevalidationFromJson(
      json(
        navigation: {
          'modules': [
            {'code': 'TICKETS', 'name': 'Tickets'},
            {'code': 'DOCUMENTOS', 'name': 'Gestor documental'},
          ],
          'permissions': ['DOCUMENTOS:LEER', 'DOCUMENTOS:FIRMAR'],
        },
      ),
    );

    expect(r.isActive, isTrue);
    expect(r.needsStep, isFalse);
    expect(r.expiresAt, DateTime.utc(2026, 10, 22, 4));
    expect(r.serverTime, DateTime.utc(2026, 10, 21, 18));
    expect(r.activeConcessionId, 'c1');
    expect(r.modules, ['TICKETS', 'DOCUMENTOS']);
    expect(r.permissions, ['DOCUMENTOS:LEER', 'DOCUMENTOS:FIRMAR']);
  });

  test('sin menu no hay permisos (el servidor puede no mandarlo)', () {
    final r = sessionRevalidationFromJson(json());

    expect(r.permissions, isEmpty);
    expect(r.modules, isEmpty);
  });

  test('una cuenta bloqueada o inactiva no esta activa', () {
    expect(
      sessionRevalidationFromJson(json(status: 'BLOQUEADO')).isActive,
      isFalse,
    );
    expect(
      sessionRevalidationFromJson(json(status: 'INACTIVO')).isActive,
      isFalse,
    );
    expect(
      sessionRevalidationFromJson(json(status: 'activo')).isActive,
      isTrue,
    );
  });

  test('un paso pendiente (MFA o cambio de contrasena) impide seguir', () {
    final mfa = sessionRevalidationFromJson({...json(), 'mfaPending': true});
    final password = sessionRevalidationFromJson({
      ...json(),
      'forcePasswordChange': true,
    });

    expect(mfa.needsStep, isTrue);
    expect(password.needsStep, isTrue);
  });

  test('el login informa hasta cuando vale la sesion', () {
    final (outcome, token) = loginFromJson({
      'accessToken': 't',
      'expiresAt': '2026-10-22T04:00:00Z',
      'idleTimeoutMinutes': 10,
      'user': {
        'id': 'u1',
        'username': 'a',
        'fullName': 'A',
        'email': 'a@x.com',
      },
      'concessions': [],
    });

    expect(token, 't');
    expect(outcome.expiresAt, DateTime.utc(2026, 10, 22, 4));
  });

  test('un vencimiento ilegible se trata como desconocido', () {
    final (outcome, _) = loginFromJson({
      'accessToken': 't',
      'expiresAt': 'pronto',
      'user': {
        'id': 'u1',
        'username': 'a',
        'fullName': 'A',
        'email': 'a@x.com',
      },
      'concessions': [],
    });

    expect(outcome.expiresAt, isNull);
  });
}
