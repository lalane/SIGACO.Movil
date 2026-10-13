import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_source.dart';
import '../core/device/device_info_source.dart';
import '../core/files/file_source.dart';
import '../core/files/local_file_store.dart';
import '../core/offline/offline_database.dart';
import '../core/offline/operation_queue.dart';
import '../core/offline/sync_cubit.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/unavailable_remote.dart';
import '../core/session/session_scope.dart';
import '../core/ui/logo_store.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/credential_vault.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/branding/data/repositories/branding_repository_impl.dart';
import '../features/branding/domain/entities/concession_branding.dart';
import '../features/branding/domain/repositories/branding_repository.dart';
import '../features/documents/data/repositories/documents_repository_impl.dart';
import '../features/documents/data/repositories/sample_documents_repository.dart';
import '../features/documents/data/repositories/unavailable_documents_repository.dart';
import '../features/documents/domain/entities/document_access.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../features/navigation/domain/entities/navigation_entities.dart';
import '../features/navigation/domain/repositories/navigation_repository.dart';

/// Sin marca propia: se usan los colores de SIGACO.
class _NoBranding implements BrandingRepository {
  const _NoBranding();

  @override
  Future<ConcessionBranding?> load(String concessionId) async => null;
}

/// Solo para la prueba con documentos de ejemplo (`SAMPLE_DOCUMENTS`): suma el
/// modulo y sus permisos al menu que entrega el servidor.
class _WithSampleDocuments implements NavigationRepository {
  const _WithSampleDocuments(this._inner);

  final NavigationRepository _inner;

  @override
  Stream<void> get accessDenied => _inner.accessDenied;

  @override
  Future<NavigationMenu> load() async {
    final menu = await _inner.load();
    if (menu.has('DOCUMENTOS')) return menu;
    return NavigationMenu(
      modules: [
        ...menu.modules,
        const NavigationItem(code: 'DOCUMENTOS', name: 'Gestor documental'),
      ],
      permissions: [
        ...menu.permissions,
        DocumentAccess.viewKey,
        DocumentAccess.uploadKey,
        DocumentAccess.signKey,
      ],
    );
  }
}

/// Raiz de composicion: aqui se crean las implementaciones concretas.
/// Las pruebas pasan sus propios fakes por el constructor.
class AppDependencies {
  AppDependencies({
    required this.prefs,
    required this.authRepository,
    required this.credentialStore,
    required this.navigationRepository,
    BrandingRepository? brandingRepository,
    DocumentsRepository? documentsRepository,
    SessionScope? sessionScope,
    this.accessRefreshGap = const Duration(seconds: 30),
    this.connectivity = const AlwaysOnlineSource(),
    this.serverReachable = const Stream<bool>.empty(),
    this.deviceInfo = const NoDeviceInfo(),
    this.logoStore = const DownloadLogoStore(),
    this.fileSource = const NoFileSource(),
    LocalFileStore? fileStore,
    this.brandingRefreshGap = const Duration(minutes: 1),
    SyncCubit? sync,
  }) : brandingRepository = brandingRepository ?? const _NoBranding(),
       fileStore = fileStore ?? DiskLocalFileStore(),
       documentsRepository =
           documentsRepository ?? const UnavailableDocumentsRepository(),
       sessionScope = sessionScope ?? SessionScope(),
       sync = sync ?? SyncCubit.disabled();

  final SharedPreferences prefs;
  final AuthRepository authRepository;
  final CredentialStore credentialStore;
  final NavigationRepository navigationRepository;
  final BrandingRepository brandingRepository;

  /// De donde salen los archivos que se cargan (selector y camara).
  final FileSource fileSource;

  /// Donde se guardan los archivos de lo capturado sin conexion.
  final LocalFileStore fileStore;

  /// Gestor documental (M03). Hasta que el backend publique sus endpoints, no
  /// hay datos: la pantalla ofrece reintentar.
  final DocumentsRepository documentsRepository;

  /// Limpiadores de datos locales de la concesion activa (RN-CTX-02).
  final SessionScope sessionScope;

  /// Tiempo minimo entre consultas de accesos al volver a la app; las pruebas
  /// lo ponen en cero.
  final Duration accessRefreshGap;

  /// Red del telefono y respuestas del servidor: de ahi sale «sin conexion».
  final ConnectivitySource connectivity;
  final Stream<bool> serverReachable;

  /// Datos del telefono que se muestran en la cuenta.
  final DeviceInfoSource deviceInfo;

  /// De donde salen los logos de la concesion (en la app, guardados en disco).
  final LogoStore logoStore;

  /// Tiempo minimo entre consultas de la marca al volver a la app; las pruebas
  /// lo ponen en cero.
  final Duration brandingRefreshGap;

  /// Cola local de operaciones sin conexion y su sincronizacion. Sin base local
  /// (pruebas) esta deshabilitada y no hace nada.
  final SyncCubit sync;

  static Future<AppDependencies> create() async {
    final prefs = await SharedPreferences.getInstance();
    String? userAgent;
    try {
      final info = await PackageInfo.fromPlatform();
      userAgent = 'SIGACO-Movil/${info.version}+${info.buildNumber} (Android)';
    } catch (_) {
      userAgent = null;
    }
    final api = ApiClient(userAgent: userAgent);
    final queue = OperationQueue(await OfflineDatabase.open());
    // Lo aceptado hace mas de una semana ya no le sirve a nadie.
    await queue.purgeAccepted();
    // Hasta que el backend publique los endpoints, nada sale de la cola.
    final engine = SyncEngine(queue, const UnavailableSyncRemote());
    return AppDependencies(
      sync: SyncCubit(queue, engine),
      prefs: prefs,
      authRepository: AuthRepositoryImpl(api),
      credentialStore: CredentialVault(
        const FlutterSecureStorage(),
        prefs,
        LocalAuthentication(),
      ),
      navigationRepository: AppConfig.sampleDocuments
          ? _WithSampleDocuments(NavigationRepositoryImpl(api))
          : NavigationRepositoryImpl(api),
      documentsRepository: AppConfig.sampleDocuments
          ? SampleDocumentsRepository()
          : DocumentsRepositoryImpl(
              api,
              // Etiquetas de tipo y categoria en el idioma elegido (o el del
              // telefono si no eligio ninguno).
              language: () {
                final saved = prefs.getString('app_locale');
                if (saved == 'es' || saved == 'pt') return saved!;
                return PlatformDispatcher.instance.locale.languageCode == 'pt'
                    ? 'pt'
                    : 'es';
              },
            ),
      connectivity: ConnectivityPlusSource(),
      serverReachable: api.reachability,
      deviceInfo: DeviceInfoPlusSource(),
      logoStore: DiskLogoStore(),
      fileSource: PlatformFileSource(),
      fileStore: DiskLocalFileStore(),
      brandingRepository: BrandingRepositoryImpl(
        api,
        prefs,
        fallback: _demoBranding(),
      ),
    );
  }

  /// Marca de prueba definida con `--dart-define` (ver `AppConfig`).
  static ConcessionBranding? _demoBranding() {
    if (AppConfig.demoBrandPrimary.isEmpty) return null;
    String? opt(String v) => v.isEmpty ? null : v;
    return ConcessionBranding(
      version: 1,
      primary: AppConfig.demoBrandPrimary,
      secondary: opt(AppConfig.demoBrandSecondary),
      headerStart: opt(AppConfig.demoBrandHeaderStart),
      headerEnd: opt(AppConfig.demoBrandHeaderEnd),
      logoLightUrl: opt(AppConfig.demoBrandLogoLight),
      logoDarkUrl: opt(AppConfig.demoBrandLogoDark),
    );
  }
}
