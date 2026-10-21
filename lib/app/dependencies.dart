import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_source.dart';
import '../core/device/device_info_source.dart';
import '../core/device/device_unlock.dart';
import '../core/files/file_source.dart';
import '../core/files/local_file_store.dart';
import '../core/offline/offline_database.dart';
import '../core/offline/operation_queue.dart';
import '../core/offline/sync_cubit.dart';
import '../core/offline/sync_engine.dart';
import '../core/pdf/pdf_renderer.dart';
import '../core/permissions/permission_keys.dart';
import 'feature_flags.dart';
import 'sync_revalidation.dart';
import '../core/offline/unavailable_remote.dart';
import '../core/session/session_scope.dart';
import '../core/time/concession_zone.dart';
import '../core/time/concession_zone_source.dart';
import '../core/ui/capped_download.dart';
import '../core/ui/logo_store.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/entities/auth_entities.dart';
import '../features/auth/data/repositories/credential_vault.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/branding/data/repositories/branding_repository_impl.dart';
import '../features/branding/domain/entities/concession_branding.dart';
import '../features/branding/domain/repositories/branding_repository.dart';
import '../features/documents/data/cache/documents_cache.dart';
import '../features/documents/data/repositories/cached_documents_repository.dart';
import '../features/documents/data/repositories/documents_repository_impl.dart';
import '../features/documents/data/repositories/sample_documents_repository.dart';
import '../features/documents/data/repositories/unavailable_documents_repository.dart';
import '../features/documents/data/sync/documents_sync_remote.dart';
import '../features/documents/domain/entities/document_access.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../features/accidents/data/repositories/sample_accidents_repository.dart';
import '../features/accidents/data/repositories/unavailable_accidents_repository.dart';
import '../features/accidents/domain/repositories/accidents_repository.dart';
import '../core/push/api_push.dart';
import '../core/push/push_registrar.dart';
import 'composition/composed_dashboard_repository.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/inspections/data/repositories/sample_inspections_repository.dart';
import '../features/inspections/data/repositories/unavailable_inspections_repository.dart';
import '../features/inspections/domain/repositories/inspections_repository.dart';
import '../features/inventory/data/repositories/sample_inventory_repository.dart';
import '../features/inventory/data/repositories/unavailable_inventory_repository.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/maintenance/data/repositories/sample_maintenance_repository.dart';
import 'composition/maintenance_reports_repository.dart';
import '../features/alerts/data/repositories/sample_alerts_repository.dart';
import '../features/alerts/data/repositories/unavailable_alerts_repository.dart';
import '../features/alerts/domain/repositories/alerts_repository.dart';
import '../features/works/data/repositories/sample_works_repository.dart';
import '../features/works/data/repositories/unavailable_works_repository.dart';
import '../features/works/domain/repositories/works_repository.dart';
import '../features/reports/domain/repositories/reports_repository.dart';
import '../features/maintenance/data/repositories/unavailable_maintenance_repository.dart';
import '../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../features/map/data/cache/map_pins_cache.dart';
import '../features/map/data/location/geolocator_location_source.dart';
import '../features/map/data/packs/file_map_pack_manager.dart';
import '../features/map/data/packs/map_pack_remote.dart';
import '../features/map/data/packs/unavailable_map_pack_manager.dart';
import '../features/map/data/location/unavailable_location_source.dart';
import '../features/map/data/repositories/cached_map_repository.dart';
import '../features/map/data/repositories/cached_road_segments_repository.dart';
import '../features/map/data/repositories/near_me_sample_road_segments_repository.dart';
import '../features/map/data/repositories/sample_road_segments_repository.dart';
import '../features/map/data/repositories/unavailable_road_segments_repository.dart';
import '../features/map/data/repositories/near_me_road.dart';
import '../features/map/data/repositories/near_me_sample_map_repository.dart';
import '../features/map/data/repositories/osrm_road_finder.dart';
import '../features/map/data/repositories/sample_map_repository.dart';
import '../features/map/data/repositories/unavailable_map_repository.dart';
import '../features/map/domain/entities/geo_point.dart';
import '../features/map/domain/entities/map_settings.dart';
import '../features/map/domain/repositories/location_source.dart';
import '../features/map/domain/repositories/map_pack_manager.dart';
import '../features/map/domain/repositories/map_repository.dart';
import '../features/map/domain/repositories/road_segments_repository.dart';
import '../features/map/presentation/tiles/map_tile_source.dart';
import '../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../features/tickets/data/repositories/sample_tickets_repository.dart';
import '../features/tickets/data/repositories/unavailable_tickets_repository.dart';
import '../features/tickets/domain/repositories/tickets_repository.dart';
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

/// Donde esta el telefono, para repartir los pines de ejemplo. Sin ubicacion
/// (permiso negado, GPS apagado, sin senal) devuelve null.
Future<GeoPoint?> _phonePosition() async {
  try {
    final here = await const GeolocatorLocationSource(
      timeLimit: Duration(seconds: 8),
    ).current();
    return here.position;
  } catch (_) {
    return null;
  }
}

/// Solo para la prueba con el mapa de ejemplo (`SAMPLE_MAP`): suma el modulo de
/// inventario y su permiso de Ver al menu que entrega el servidor, que es lo
/// que habilita la tarjeta Mapa.
class _WithSampleMap implements NavigationRepository {
  const _WithSampleMap(this._inner);

  final NavigationRepository _inner;

  @override
  Stream<void> get accessDenied => _inner.accessDenied;

  @override
  Future<NavigationMenu> load() async {
    final menu = await _inner.load();
    return NavigationMenu(
      modules: [
        ...menu.modules,
        if (!menu.has('INVENTARIO'))
          const NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
      ],
      permissions: [
        ...menu.permissions,
        if (!menu.permissions.contains(PermissionKeys.inventoryView))
          PermissionKeys.inventoryView,
      ],
    );
  }
}

/// Solo para las pruebas con datos de ejemplo (`SAMPLE_TICKETS`,
/// `SAMPLE_ACCIDENTS`, `SAMPLE_MAINTENANCE`): suma los modulos al menu que
/// entrega el servidor, que es lo que habilita sus tarjetas.
class _WithSampleModules implements NavigationRepository {
  const _WithSampleModules(this._inner, this._extra);

  final NavigationRepository _inner;
  final List<NavigationItem> _extra;

  @override
  Stream<void> get accessDenied => _inner.accessDenied;

  @override
  Future<NavigationMenu> load() async {
    final menu = await _inner.load();
    return NavigationMenu(
      modules: [
        ...menu.modules,
        for (final item in _extra)
          if (!menu.has(item.code) &&
              !item.submodules.any((s) => menu.has(s.code)))
            item,
      ],
      permissions: menu.permissions,
    );
  }
}

/// Solo para las pruebas con datos de ejemplo: si el servidor no publica la
/// zona horaria de la concesion, usa la de Sao Paulo.
class _WithSampleZone implements ConcessionZoneSource {
  const _WithSampleZone(this._inner);

  final ConcessionZoneSource _inner;

  @override
  Future<ConcessionZone?> load(String concessionId) async =>
      await _inner.load(concessionId) ??
      ConcessionZone.tryParse('America/Sao_Paulo');
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
    this.mapRepository = const UnavailableMapRepository(),
    this.roadSegmentsRepository = const UnavailableRoadSegmentsRepository(),
    this.locationSource = const UnavailableLocationSource(),
    this.mapTileSource = const NoTileSource(),
    this.sampleMap = false,
    this.ticketsRepository = const UnavailableTicketsRepository(),
    this.sampleTickets = false,
    this.accidentsRepository = const UnavailableAccidentsRepository(),
    this.sampleAccidents = false,
    this.maintenanceRepository = const UnavailableMaintenanceRepository(),
    this.sampleMaintenance = false,
    this.inventoryRepository = const UnavailableInventoryRepository(),
    this.sampleInventory = false,
    this.worksRepository = const UnavailableWorksRepository(),
    this.sampleWorks = false,
    this.alertsRepository = const UnavailableAlertsRepository(),
    this.sampleAlerts = false,
    this.inspectionsRepository = const UnavailableInspectionsRepository(),
    this.sampleInspections = false,
    ReportsRepository? reportsRepository,
    DashboardRepository? dashboardRepository,
    PushRegistrar? pushRegistrar,
    this.features = const FeatureFlags(),
    this.mapSettings = const MapSettings(),
    this.mapPacks = const UnavailableMapPackManager(),
    SessionScope? sessionScope,
    this.accessRefreshGap = const Duration(seconds: 30),
    this.connectivity = const AlwaysOnlineSource(),
    this.serverReachable = const Stream<bool>.empty(),
    this.deviceInfo = const NoDeviceInfo(),
    this.deviceUnlock = const NoDeviceUnlock(),
    this.logoStore = const DownloadLogoStore(),
    this.fileSource = const NoFileSource(),
    this.pdfRenderer = const NoPdfRenderer(),
    this.zoneSource = const NoConcessionZoneSource(),
    LocalFileStore? fileStore,
    this.brandingRefreshGap = const Duration(minutes: 1),
    SyncCubit? sync,
  }) : brandingRepository = brandingRepository ?? const _NoBranding(),
       reportsRepository =
           reportsRepository ??
           MaintenanceReportsRepository(maintenanceRepository),
       pushRegistrar = pushRegistrar ?? PushRegistrar(prefs: prefs),
       dashboardRepository =
           dashboardRepository ??
           ComposedDashboardRepository(
             tickets: ticketsRepository,
             accidents: accidentsRepository,
             maintenance: maintenanceRepository,
             inventory: inventoryRepository,
           ),
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

  /// Dibuja las paginas de los PDF en la vista previa.
  final PdfRenderer pdfRenderer;

  /// De donde sale la zona horaria de la concesion cuando la marca no la trae.
  final ConcessionZoneSource zoneSource;

  /// Donde se guardan los archivos de lo capturado sin conexion.
  final LocalFileStore fileStore;

  /// Gestor documental (M03). Hasta que el backend publique sus endpoints, no
  /// hay datos: la pantalla ofrece reintentar.
  final DocumentsRepository documentsRepository;

  /// Pines del mapa. Hasta que el backend publique sus endpoints no hay datos
  /// (el mapa lo dice); con `SAMPLE_MAP=true` son de ejemplo.
  final MapRepository mapRepository;
  final RoadSegmentsRepository roadSegmentsRepository;

  /// La ubicacion del telefono, para "ubicarme" y los activos cercanos.
  final LocationSource locationSource;

  /// De donde salen las teselas del mapa base; sin proveedor, solo pines.
  final MapTileSource mapTileSource;

  /// El mapa muestra datos de ejemplo y lo avisa.
  final bool sampleMap;

  /// Tickets (APP-MOB-03). Hasta que el backend publique sus endpoints no hay
  /// datos (la pantalla lo dice); con `SAMPLE_TICKETS=true` son de ejemplo.
  final TicketsRepository ticketsRepository;

  /// Los tickets son de ejemplo y se avisa.
  final bool sampleTickets;

  /// Accidentes (APP-MOB-05, pendiente de homologacion). Igual que los tickets.
  final AccidentsRepository accidentsRepository;
  final bool sampleAccidents;

  /// Mantenimiento (APP-MOB-07). Igual que los tickets.
  final MaintenanceRepository maintenanceRepository;
  final bool sampleMaintenance;

  /// Inventario (APP-MOB-06). Igual que los tickets.
  final InventoryRepository inventoryRepository;
  final bool sampleInventory;

  /// Obras (APP-MOB-09). Igual que los tickets.
  final WorksRepository worksRepository;
  final bool sampleWorks;
  final AlertsRepository alertsRepository;
  final bool sampleAlerts;

  /// Inspecciones (APP-MOB-08). Igual que los tickets.
  final InspectionsRepository inspectionsRepository;
  final bool sampleInspections;

  /// Indicadores y reportes (APP-MOB-02). Sin un servicio propio se arman con
  /// los mantenimientos del indicador.
  final ReportsRepository reportsRepository;

  /// Dashboard (APP-MOB-04). Sin un servicio propio se arma con lo que
  /// consultan los demas modulos.
  final DashboardRepository dashboardRepository;

  /// Registra el token push de este telefono en la concesion activa si su
  /// canal push esta activo (RN-19). Sin Firebase ni servicio en el servidor no
  /// hace nada.
  final PushRegistrar pushRegistrar;

  /// Lo que existe en el codigo pero no se ofrece en el menu.
  final FeatureFlags features;

  /// Radio de cercanos, precision minima del GPS y agrupacion de pines.
  final MapSettings mapSettings;

  /// Paquetes de mapa para trabajar sin conexion.
  final MapPackManager mapPacks;

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
  final DeviceUnlock deviceUnlock;

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
    final fileStore = DiskLocalFileStore();
    final scope = SessionScope();
    // Los paquetes de mapa son de la persona y la concesion activas.
    final mapPacks = FileMapPackManager(remote: ApiMapPackRemote(api));
    scope.register(mapPacks);
    // Los pines ya consultados quedan para ver el mapa sin conexion; son de la
    // persona y concesion activas.
    final mapPinsCache = FileMapPinsCache();
    scope.register(mapPinsCache);
    // Con el mapa de ejemplo cerca del telefono, los pines y los tramos caen sobre
    // la misma calle real (se busca una sola vez).
    final nearMeRoad = NearMeRoad(
      anchor: _phonePosition,
      finder: OsrmRoadFinder().find,
    );
    NavigationRepository navigation = NavigationRepositoryImpl(api);
    if (AppConfig.sampleDocuments) {
      navigation = _WithSampleDocuments(navigation);
    }
    if (AppConfig.sampleMap) {
      navigation = _WithSampleMap(navigation);
    }
    navigation = _WithSampleModules(navigation, [
      if (AppConfig.sampleTickets)
        const NavigationItem(code: 'TICKETS', name: 'Tickets'),
      if (AppConfig.sampleAccidents)
        const NavigationItem(
          code: 'ANTT',
          name: 'ANTT',
          submodules: [
            NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes'),
          ],
        ),
      if (AppConfig.sampleMaintenance)
        const NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
      if (AppConfig.sampleInventory)
        const NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
      if (AppConfig.sampleWorks)
        const NavigationItem(code: 'OBRAS', name: 'Obras'),
      if (AppConfig.sampleAlerts)
        const NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
      if (AppConfig.sampleInspections)
        const NavigationItem(code: 'INSPECCIONES', name: 'Inspecciones'),
      // El dashboard resume los modulos: con ejemplos, el panel tambien existe.
      if (AppConfig.sampleTickets || AppConfig.sampleMaintenance)
        const NavigationItem(code: 'PANEL', name: 'Panel'),
      // Los reportes salen de los mantenimientos: con ejemplos, tambien.
      if (AppConfig.sampleMaintenance)
        const NavigationItem(code: 'REPORTES', name: 'Reportes'),
    ]);
    final DocumentsRepository documents;
    final SyncRemote remote;
    if (AppConfig.sampleDocuments) {
      // Con datos de ejemplo no hay servidor al que enviar: todo se queda en la
      // cola.
      documents = SampleDocumentsRepository();
      remote = const UnavailableSyncRemote();
    } else {
      final server = DocumentsRepositoryImpl(
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
      );
      // Lo ya consultado queda en el telefono para verlo sin conexion; es de la
      // persona y concesion activas y se descarta al cambiar o cerrar sesion.
      final cache = FileDocumentsCache();
      scope
        ..register(server)
        ..register(cache);
      documents = CachedDocumentsRepository(server, cache);
      // Los documentos y las firmas capturados salen por /api/uploads y
      // /api/documents.
      remote = DocumentsSyncRemote(api, server, fileStore);
    }
    final authRepository = AuthRepositoryImpl(api);
    final engine = SyncEngine(
      queue,
      remote,
      preflight: SyncRevalidation(
        // La sesion y los permisos vigentes los confirma el servidor. Con los
        // documentos de ejemplo el menu agrega permisos que el servidor no
        // conoce: se suman para no rechazar lo capturado en esa prueba.
        revalidate: () async {
          final session = await authRepository.revalidateSession();
          if (!AppConfig.sampleDocuments) return session;
          final menu = await navigation.load();
          return SessionRevalidation(
            accountStatus: session.accountStatus,
            expiresAt: session.expiresAt,
            idleTimeoutMinutes: session.idleTimeoutMinutes,
            serverTime: session.serverTime,
            activeConcessionId: session.activeConcessionId,
            mfaPending: session.mfaPending,
            forcePasswordChange: session.forcePasswordChange,
            permissions: {...session.permissions, ...menu.permissions}.toList(),
            modules: session.modules,
          );
        },
        queue: queue,
        requiredPermissions: const {
          'documento': [
            PermissionKeys.documentsView,
            PermissionKeys.documentsUpload,
          ],
          'documento_firma': [
            PermissionKeys.documentsView,
            PermissionKeys.documentsSign,
          ],
        },
      ).call,
    );
    return AppDependencies(
      sync: SyncCubit(
        queue,
        engine,
        // Lo que la persona descarta no debe dejar su archivo en el telefono.
        onDiscarded: (operation) async {
          final path = operation.payload['localPath'];
          if (path is String) await fileStore.remove(path);
        },
      ),
      sessionScope: scope,
      prefs: prefs,
      authRepository: authRepository,
      credentialStore: CredentialVault(
        const FlutterSecureStorage(),
        prefs,
        LocalAuthentication(),
      ),
      navigationRepository: navigation,
      documentsRepository: documents,
      mapRepository: !AppConfig.sampleMap
          ? CachedMapRepository(const UnavailableMapRepository(), mapPinsCache)
          : AppConfig.sampleMapNearMe
          ? NearMeSampleMapRepository(road: nearMeRoad)
          : SampleMapRepository(),
      roadSegmentsRepository: !AppConfig.sampleMap
          ? CachedRoadSegmentsRepository(
              const UnavailableRoadSegmentsRepository(),
              mapPinsCache,
            )
          : AppConfig.sampleMapNearMe
          ? NearMeSampleRoadSegmentsRepository(road: nearMeRoad)
          : SampleRoadSegmentsRepository(),
      locationSource: const GeolocatorLocationSource(),
      mapTileSource: AppConfig.mapTileUrl.isEmpty
          ? const NoTileSource()
          : const UrlTemplateTileSource(
              urlTemplate: AppConfig.mapTileUrl,
              attributionText: AppConfig.mapTileAttribution,
              attributionLink: AppConfig.mapTileAttributionUrl,
            ),
      sampleMap: AppConfig.sampleMap,
      ticketsRepository: AppConfig.sampleTickets
          ? SampleTicketsRepository()
          : const UnavailableTicketsRepository(),
      sampleTickets: AppConfig.sampleTickets,
      accidentsRepository: AppConfig.sampleAccidents
          ? SampleAccidentsRepository()
          : const UnavailableAccidentsRepository(),
      sampleAccidents: AppConfig.sampleAccidents,
      maintenanceRepository: AppConfig.sampleMaintenance
          ? SampleMaintenanceRepository()
          : const UnavailableMaintenanceRepository(),
      sampleMaintenance: AppConfig.sampleMaintenance,
      inventoryRepository: AppConfig.sampleInventory
          ? SampleInventoryRepository()
          : const UnavailableInventoryRepository(),
      sampleInventory: AppConfig.sampleInventory,
      // El token push se registra en `/api/auth/me/devices` solo si el canal
      // push de la concesion esta encendido. Falta la fuente del token
      // (Firebase): sin ella no se registra nada.
      pushRegistrar: PushRegistrar(
        prefs: prefs,
        channels: ApiPushChannelSource(api),
        remote: ApiPushRemote(api),
      ),
      worksRepository: AppConfig.sampleWorks
          ? SampleWorksRepository()
          : const UnavailableWorksRepository(),
      sampleWorks: AppConfig.sampleWorks,
      alertsRepository: AppConfig.sampleAlerts
          ? SampleAlertsRepository()
          : const UnavailableAlertsRepository(),
      sampleAlerts: AppConfig.sampleAlerts,
      inspectionsRepository: AppConfig.sampleInspections
          ? SampleInspectionsRepository()
          : const UnavailableInspectionsRepository(),
      sampleInspections: AppConfig.sampleInspections,
      features: const FeatureFlags(documents: AppConfig.documentsModule),
      mapPacks: mapPacks,
      connectivity: ConnectivityPlusSource(),
      serverReachable: api.reachability,
      deviceInfo: DeviceInfoPlusSource(),
      deviceUnlock: LocalAuthDeviceUnlock(LocalAuthentication()),
      // Los logos de la propia API piden sesion; los de otro servidor (marca de
      // prueba) se bajan tal cual.
      logoStore: DiskLogoStore(
        download: (url) => url.startsWith(api.baseUrl)
            ? api.downloadFile(url)
            : downloadCapped(url),
      ),
      fileSource: PlatformFileSource(),
      pdfRenderer: PlatformPdfRenderer(),
      // Con datos de ejemplo no hay servidor que publique la zona: se usa la
      // de Brasil para poder probar los formularios (RN-13 los bloquea sin zona).
      zoneSource:
          (AppConfig.sampleTickets ||
              AppConfig.sampleAccidents ||
              AppConfig.sampleInspections)
          ? _WithSampleZone(ApiConcessionZoneSource(api))
          : ApiConcessionZoneSource(api),
      fileStore: fileStore,
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
