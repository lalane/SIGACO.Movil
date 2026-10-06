import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_source.dart';
import '../core/device/device_info_source.dart';
import '../core/session/session_scope.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/credential_vault.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/branding/data/repositories/branding_repository_impl.dart';
import '../features/branding/domain/entities/concession_branding.dart';
import '../features/branding/domain/repositories/branding_repository.dart';
import '../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../features/navigation/domain/repositories/navigation_repository.dart';

/// Sin marca propia: se usan los colores de SIGACO.
class _NoBranding implements BrandingRepository {
  const _NoBranding();

  @override
  Future<ConcessionBranding?> load(String concessionId) async => null;
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
    SessionScope? sessionScope,
    this.accessRefreshGap = const Duration(seconds: 30),
    this.connectivity = const AlwaysOnlineSource(),
    this.serverReachable = const Stream<bool>.empty(),
    this.deviceInfo = const NoDeviceInfo(),
  }) : brandingRepository = brandingRepository ?? const _NoBranding(),
       sessionScope = sessionScope ?? SessionScope();

  final SharedPreferences prefs;
  final AuthRepository authRepository;
  final CredentialStore credentialStore;
  final NavigationRepository navigationRepository;
  final BrandingRepository brandingRepository;

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
    return AppDependencies(
      prefs: prefs,
      authRepository: AuthRepositoryImpl(api),
      credentialStore: CredentialVault(
        const FlutterSecureStorage(),
        prefs,
        LocalAuthentication(),
      ),
      navigationRepository: NavigationRepositoryImpl(api),
      connectivity: ConnectivityPlusSource(),
      serverReachable: api.reachability,
      deviceInfo: DeviceInfoPlusSource(),
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
