import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sigaco_movil/core/device/device_unlock.dart';
import 'package:sigaco_movil/core/files/file_source.dart';
import 'package:sigaco_movil/core/files/local_file_store.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/pdf/pdf_renderer.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/time/concession_zone.dart';
import 'package:sigaco_movil/core/time/concession_zone_source.dart';
import 'package:sigaco_movil/core/ui/logo_store.dart';
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

/// Lo que el servidor confirma al revalidar la sesion (todo vigente por omision).
SessionRevalidation fakeRevalidation({
  List<String> permissions = const [],
  String status = 'ACTIVO',
  bool mfaPending = false,
  bool forcePasswordChange = false,
  DateTime? expiresAt,
  DateTime? serverTime,
}) => SessionRevalidation(
  accountStatus: status,
  expiresAt: expiresAt ?? DateTime.utc(2030),
  idleTimeoutMinutes: 10,
  serverTime: serverTime ?? DateTime.utc(2026, 10, 21, 12),
  mfaPending: mfaPending,
  forcePasswordChange: forcePasswordChange,
  permissions: permissions,
);

LoginOutcome outcome({
  bool mfa = false,
  bool enroll = false,
  bool force = false,
  String? active,
  int concessions = 1,
  int idleMinutes = 10,
}) => LoginOutcome(
  user: testUser,
  concessions: [
    for (var i = 0; i < concessions; i++)
      ConcessionSummary(id: 'c$i', code: 'C$i', name: 'Concesion $i'),
  ],
  activeConcessionId: active,
  idleTimeoutMinutes: idleMinutes,
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

/// Menu con los modulos dados. Como el backend real, trae el permiso de Ver de
/// los modulos de consulta (Inventario y Documentos), salvo que se indique otra
/// lista en [permissions].
NavigationMenu menuWith(List<String> codes, {List<String>? permissions}) =>
    NavigationMenu(
      modules: [for (final c in codes) NavigationItem(code: c, name: c)],
      permissions:
          permissions ??
          [
            if (codes.contains('INVENTARIO')) PermissionKeys.inventoryView,
            if (codes.contains('DOCUMENTOS')) PermissionKeys.documentsView,
          ],
    );

/// Marca por concesion (`brands['c0']`); sin entrada, la concesion no tiene marca.
class FakeBrandingRepository implements BrandingRepository {
  FakeBrandingRepository([Map<String, ConcessionBranding>? brands])
    : brands = brands ?? {};

  final Map<String, ConcessionBranding> brands;
  final loads = <String>[];

  /// Si se define, cada carga espera este tiempo (para probar respuestas tardias).
  Duration? delay;

  /// Simula un fallo del repositorio.
  bool failing = false;

  @override
  Future<ConcessionBranding?> load(String concessionId) async {
    loads.add(concessionId);
    if (delay != null) await Future<void>.delayed(delay!);
    if (failing) throw StateError('sin conexion');
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

/// El desbloqueo del telefono: disponible o no, y si la persona lo logra.
class FakeDeviceUnlock implements DeviceUnlock {
  FakeDeviceUnlock({this.available = true, this.result = true});

  bool available;
  bool result;
  int attempts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    attempts++;
    return result;
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
  DateTime? sessionExpiresAt;

  @override
  Duration serverClockOffset = Duration.zero;

  /// Lo que responde la revalidacion; si se define [revalidationFailure], falla.
  SessionRevalidation revalidation = fakeRevalidation();
  AuthError? revalidationFailure;

  @override
  Future<SessionRevalidation> revalidateSession() async {
    calls.add('revalidate');
    if (revalidationFailure != null) throw AuthException(revalidationFailure!);
    sessionExpiresAt = revalidation.expiresAt;
    serverClockOffset = revalidation.serverTime.difference(
      DateTime.now().toUtc(),
    );
    return revalidation;
  }

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

  /// El ultimo codigo de verificacion enviado (de la app o de recuperacion).
  String? lastMfaCode;

  @override
  Future<void> verifyMfa(String code) async {
    calls.add('verifyMfa');
    lastMfaCode = code;
  }

  /// Si se define, generar la clave de enrolamiento falla.
  AuthError? enrollmentFailure;

  @override
  Future<MfaEnrollment> startMfaEnrollment() async {
    if (enrollmentFailure != null) throw AuthException(enrollmentFailure!);
    return const MfaEnrollment(secret: 'SECRET', otpAuthUri: 'otpauth://x');
  }

  /// Si se define, confirmar el codigo de enrolamiento falla.
  AuthError? activationFailure;

  /// Los codigos de recuperacion que el servidor entrega al activar o regenerar.
  List<String> recoveryCodes = const ['AAAA-1111-BBBB', 'CCCC-2222-DDDD'];
  AuthError? regenerationFailure;

  @override
  Future<List<String>> activateMfa(String code) async {
    calls.add('activateMfa');
    if (activationFailure != null) throw AuthException(activationFailure!);
    return recoveryCodes;
  }

  @override
  Future<List<String>> regenerateRecoveryCodes(String code) async {
    calls.add('regenerate:$code');
    if (regenerationFailure != null) throw AuthException(regenerationFailure!);
    return recoveryCodes;
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

/// Un PNG valido de 1 x 1.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Un SVG de 100 x 40: a 34 de alto mide 85 de ancho.
const tinySvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 40">'
    '<rect width="100" height="40" fill="#0EA5E9"/></svg>';

/// Logos de prueba, sin red ni disco: un PNG o un SVG segun la URL. Guarda lo
/// que se pidio. Con [failing] no entrega nada (sin conexion y sin copia).
class FakeLogoStore implements LogoStore {
  FakeLogoStore({this.failing = false});

  bool failing;
  final asked = <(String url, int version)>[];

  @override
  Future<Uint8List?> bytesFor(String url, {int version = 0}) async {
    asked.add((url, version));
    if (failing) return null;
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg')
        ? Uint8List.fromList(utf8.encode(tinySvg))
        : tinyPng;
  }
}

/// Cola de sincronizacion de pruebas: guarda el estado que se le da y registra
/// lo que la app le pide, sin base local ni red.
class FakeSyncCubit extends Cubit<SyncState> implements SyncCubit {
  FakeSyncCubit([SyncState? initial]) : super(initial ?? const SyncState());

  final calls = <String>[];
  final conflicts = <String, SyncConflict>{};

  @override
  Duration get resumeGap => Duration.zero;

  @override
  Future<void> Function(PendingOperation operation)? get onDiscarded => null;

  @override
  OfflineScope? get scope => state.scope;

  void show(SyncState next) => emit(next);

  @override
  Future<void> setScope(OfflineScope? scope) async {
    calls.add('scope:${scope?.userId}/${scope?.concessionId}');
    emit(scope == null ? const SyncState() : state.copyWith(scope: scope));
  }

  @override
  void setOnline(bool online) => calls.add('online:$online');

  /// Lo que se guardo en la cola con [enqueue], en orden.
  final enqueued = <PendingOperation>[];

  /// Si es true, [enqueue] no guarda nada (sin sesion o sin base local).
  bool failEnqueue = false;

  @override
  Future<PendingOperation?> enqueue({
    required String entity,
    required OperationKind kind,
    required Map<String, Object?> payload,
    String? recordId,
    int? baseVersion,
    DateTime? capturedAt,
  }) async {
    if (failEnqueue || state.scope == null) return null;
    final op = fakeOperation(
      'q${enqueued.length + 1}',
      entity: entity,
      kind: kind,
      payload: payload,
      scope: state.scope!,
      baseVersion: baseVersion,
      recordId: recordId,
    );
    enqueued.add(op);
    calls.add('enqueue:$entity');
    emit(state.copyWith(items: [...state.items, op]));
    return op;
  }

  @override
  Future<void> onResume() async => calls.add('resume');

  @override
  Future<void> syncNow({Duration minGap = Duration.zero}) async =>
      calls.add('syncNow');

  @override
  Future<SyncConflict?> conflictOf(String operationId) async =>
      conflicts[operationId];

  @override
  Future<void> retry(String operationId, {int? baseVersion}) async =>
      calls.add('retry:$operationId:$baseVersion');

  @override
  Future<bool> discard(String operationId) async {
    calls.add('discard:$operationId');
    emit(
      state.copyWith(
        items: [
          for (final o in state.items)
            if (o.id != operationId) o,
        ],
      ),
    );
    return true;
  }
}

/// Una operacion pendiente de prueba.
PendingOperation fakeOperation(
  String id, {
  OperationStatus status = OperationStatus.pending,
  String entity = 'documento',
  String? name,
  String? error,
  OperationKind kind = OperationKind.insert,
  OfflineScope scope = const OfflineScope(userId: 'u1', concessionId: 'c0'),
  DateTime? capturedAt,
  int attempts = 0,
  int? baseVersion,
  String? recordId,
  Map<String, Object?>? payload,
}) {
  final at = capturedAt ?? DateTime.utc(2026, 10, 12, 15, 30);
  return PendingOperation(
    id: id,
    scope: scope,
    entity: entity,
    kind: kind,
    payload: payload ?? {'name': ?name},
    status: status,
    createdAt: at,
    capturedAt: at,
    updatedAt: at,
    attempts: attempts,
    lastError: error,
    recordId: recordId ?? (kind == OperationKind.insert ? null : 'rec-1'),
    baseVersion: baseVersion ?? (kind == OperationKind.insert ? null : 1),
  );
}

/// Selector de archivos de pruebas: devuelve lo que se le prepare.
class FakeFileSource implements FileSource {
  FakeFileSource({List<SelectedFile>? files, this.photo})
    : files = files ?? <SelectedFile>[];

  /// Lo que devolvera el selector la proxima vez (y siempre).
  List<SelectedFile> files;
  SelectedFile? photo;
  int picks = 0;
  int photos = 0;

  @override
  Future<List<SelectedFile>> pickFiles() async {
    picks++;
    return files;
  }

  @override
  Future<SelectedFile?> takePhoto() async {
    photos++;
    return photo;
  }
}

/// Guarda los archivos en memoria (solo anota rutas) y puede fallar con algunos.
class MemoryFileStore implements LocalFileStore {
  final kept = <String, String>{};
  final removed = <String>[];

  /// Nombres de archivo que no se pueden guardar (disco lleno, por ejemplo).
  final failNames = <String>{};

  @override
  Future<String> keep(String sourcePath, {required String name}) async {
    if (failNames.contains(name)) {
      throw const FileSystemException('sin espacio');
    }
    final path = '/kept/${kept.length + 1}/$name';
    kept[path] = sourcePath;
    return path;
  }

  @override
  Future<void> remove(String path) async {
    kept.remove(path);
    removed.add(path);
  }
}

/// Visor de PDF de pruebas: un documento con las paginas que se le pidan y una
/// imagen de 1x1 por pagina.
class FakePdfRenderer implements PdfRenderer {
  FakePdfRenderer({this.pages = 3, this.failOpen = false, this.failPage});

  final int pages;
  final bool failOpen;

  /// Pagina (desde 0) que no se puede dibujar.
  final int? failPage;

  int opened = 0;
  int closed = 0;
  final rendered = <(int, int)>[];

  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<PdfDocumentHandle> open(Uint8List bytes) async {
    if (failOpen) throw StateError('PDF danado');
    opened++;
    return PdfDocumentHandle('pdf-$opened', [
      for (var i = 0; i < pages; i++) const PdfPageSize(595, 842),
    ]);
  }

  @override
  Future<Uint8List> renderPage(
    PdfDocumentHandle document,
    int index, {
    required int width,
  }) async {
    if (index == failPage) throw StateError('pagina danada');
    rendered.add((index, width));
    return _png;
  }

  @override
  Future<void> close(PdfDocumentHandle document) async => closed++;
}

/// La zona horaria que el servidor publica para toda concesion (por omision,
/// la de Sao Paulo). Sin una zona, la app no deja crear registros (RN-13).
class FixedZoneSource implements ConcessionZoneSource {
  FixedZoneSource([this.id = 'America/Sao_Paulo']);

  final String id;

  @override
  Future<ConcessionZone?> load(String concessionId) async =>
      ConcessionZone.tryParse(id);
}
