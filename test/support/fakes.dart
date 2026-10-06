import 'dart:async';

import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/auth/domain/repositories/auth_repository.dart';
import 'package:sigaco_movil/features/auth/domain/repositories/credential_store.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/branding/domain/repositories/branding_repository.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/features/navigation/domain/repositories/navigation_repository.dart';

const testUser = CurrentUser(
  id: 'u1',
  username: 'jperez',
  fullName: 'Juan Perez',
  email: 'jperez@example.com',
);

LoginOutcome outcome({
  bool mfa = false,
  bool enroll = false,
  bool force = false,
  String? active,
  int concessions = 1,
}) => LoginOutcome(
  user: testUser,
  concessions: [
    for (var i = 0; i < concessions; i++)
      ConcessionSummary(id: 'c$i', code: 'C$i', name: 'Concesion $i'),
  ],
  activeConcessionId: active,
  idleTimeoutMinutes: 10,
  mfaRequired: mfa,
  mfaEnrollmentRequired: enroll,
  forcePasswordChange: force,
);

const testProfile = MyProfile(
  user: testUser,
  activeConcession: ConcessionSummary(
    id: 'c0',
    code: 'C0',
    name: 'Concesion 0',
  ),
  profile: ProfileSummary(
    code: 'MANTENIMIENTO',
    nameEs: 'Mantenimiento',
    namePt: 'Manutenção',
  ),
  roads: [RoadSummary(id: 'r1', code: 'R1', name: 'Carretera 1')],
  availableConcessions: [
    ConcessionSummary(id: 'c0', code: 'C0', name: 'Concesion 0'),
    ConcessionSummary(id: 'c1', code: 'C1', name: 'Concesion 1'),
  ],
);

NavigationMenu menuWith(List<String> codes) => NavigationMenu(
  modules: [for (final c in codes) NavigationItem(code: c, name: c)],
);

/// Marca por concesion (`brands['c0']`); sin entrada, la concesion no tiene marca.
class FakeBrandingRepository implements BrandingRepository {
  FakeBrandingRepository([Map<String, ConcessionBranding>? brands])
    : brands = brands ?? {};

  final Map<String, ConcessionBranding> brands;
  final loads = <String>[];

  /// Si se define, cada carga espera este tiempo (para probar respuestas tardias).
  Duration? delay;

  @override
  Future<ConcessionBranding?> load(String concessionId) async {
    loads.add(concessionId);
    if (delay != null) await Future<void>.delayed(delay!);
    return brands[concessionId];
  }
}

class FakeNavigationRepository implements NavigationRepository {
  FakeNavigationRepository({NavigationMenu? menu, this.failure})
    : menu = menu ?? menuWith(['PANEL', 'TICKETS', 'INVENTARIO']);

  NavigationMenu menu;
  NavigationError? failure;
  int loads = 0;

  /// Simula un 403 del servidor en una accion (los accesos pudieron cambiar).
  final denied = StreamController<void>.broadcast();

  @override
  Stream<void> get accessDenied => denied.stream;

  /// Si se define, cada carga espera este tiempo (para probar respuestas tardias).
  Duration? delay;

  @override
  Future<NavigationMenu> load() async {
    loads++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (failure != null) throw NavigationException(failure!);
    return menu;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({LoginOutcome? result, this.failure})
    : result = result ?? outcome(active: 'c0');

  LoginOutcome result;
  AuthError? failure;
  final expired = StreamController<void>.broadcast();
  final requirements = StreamController<SessionRequirement>.broadcast();
  DateTime? activity;
  MyProfile profile = testProfile;
  AuthError? profileFailure;
  final calls = <String>[];

  @override
  Stream<void> get sessionExpired => expired.stream;

  @override
  Stream<SessionRequirement> get sessionRequirements => requirements.stream;

  @override
  DateTime? get lastActivityAt => activity;

  @override
  Future<MyProfile> getProfile() async {
    calls.add('profile');
    if (profileFailure != null) throw AuthException(profileFailure!);
    activity = DateTime.now();
    return profile;
  }

  @override
  Future<LoginOutcome> login(String email, String password) async {
    calls.add('login');
    if (failure != null) throw AuthException(failure!);
    return result;
  }

  @override
  Future<void> verifyMfa(String code) async => calls.add('verifyMfa');

  /// Si se define, generar la clave de enrolamiento falla.
  AuthError? enrollmentFailure;

  @override
  Future<MfaEnrollment> startMfaEnrollment() async {
    if (enrollmentFailure != null) throw AuthException(enrollmentFailure!);
    return const MfaEnrollment(secret: 'SECRET', otpAuthUri: 'otpauth://x');
  }

  /// Si se define, confirmar el codigo de enrolamiento falla.
  AuthError? activationFailure;

  @override
  Future<void> activateMfa(String code) async {
    calls.add('activateMfa');
    if (activationFailure != null) throw AuthException(activationFailure!);
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
    required String confirm,
  }) async => calls.add('changePassword');

  @override
  Future<void> selectConcession(String concessionId) async =>
      calls.add('selectConcession');

  /// Si se define, la solicitud de recuperacion falla (por ejemplo sin red).
  AuthError? recoveryFailure;

  @override
  Future<void> requestPasswordRecovery(String email) async {
    calls.add('recovery');
    if (recoveryFailure != null) throw AuthException(recoveryFailure!);
  }

  @override
  Future<void> logout() async => calls.add('logout');
}

class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore({this.supportsBiometrics = true});

  final bool supportsBiometrics;
  bool _remember = false;
  bool _enabled = false;
  bool _declined = false;
  bool _passwordForgotten = false;

  /// Registro cifrado compartido por "recordar" y biometria.
  SavedCredentials? stored;

  @override
  bool get rememberEnabled => _remember;

  @override
  String? get rememberedEmail => _remember ? stored?.email : null;

  @override
  Future<String?> readRememberedPassword() async =>
      _remember && !_passwordForgotten ? stored?.password : null;

  @override
  Future<void> setRemembered({
    required bool remember,
    SavedCredentials? credentials,
  }) async {
    if (remember && credentials != null) {
      stored = credentials;
      _passwordForgotten = false;
      _remember = true;
    } else if (!remember) {
      _remember = false;
      if (!_enabled) stored = null;
    }
  }

  @override
  bool get biometricEnabled => _enabled;

  @override
  bool get biometricOfferDeclined => _declined;

  @override
  Future<void> declineBiometricOffer() async => _declined = true;
  @override
  Future<bool> deviceSupportsBiometrics() async => supportsBiometrics;

  @override
  Future<bool> enableBiometric(
    String reason,
    SavedCredentials credentials,
  ) async {
    stored = credentials;
    _passwordForgotten = false;
    _enabled = true;
    return true;
  }

  @override
  Future<void> refreshStoredPassword(String password) async {
    if ((_remember || _enabled) && stored != null) {
      stored = (email: stored!.email, password: password);
    }
  }

  @override
  Future<SavedCredentials?> readWithBiometric(String reason) async =>
      _enabled ? stored : null;

  @override
  Future<void> disableBiometric() async {
    _enabled = false;
    if (!_remember) stored = null;
  }

  @override
  Future<void> forgetPassword() async {
    _enabled = false;
    _declined = false;
    _passwordForgotten = true;
    if (!_remember) stored = null;
  }
}
