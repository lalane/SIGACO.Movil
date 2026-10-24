import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/device/device_info_source.dart';
import '../core/device/device_registrar.dart';
import '../core/demo/demo_mode.dart';
import '../features/map/presentation/map_camera.dart';
import 'composition/map_base_source.dart';
import '../core/device/device_unlock.dart';
import '../core/files/file_source.dart';
import '../core/pdf/pdf_renderer.dart';
import '../core/push/push_registrar.dart';
import '../core/time/concession_zone_source.dart';
import '../core/files/local_file_store.dart';
import '../core/settings/settings_cubit.dart';
import '../core/theme/app_theme.dart';
import '../core/time/concession_zone_cubit.dart';
import '../core/ui/logo_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/session/session_lock_cubit.dart';
import '../features/branding/presentation/bloc/branding_cubit.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../features/map/domain/entities/map_settings.dart';
import '../features/map/domain/repositories/location_source.dart';
import '../features/map/domain/repositories/map_pack_manager.dart';
import '../features/map/domain/repositories/map_repository.dart';
import '../features/map/domain/repositories/road_segments_repository.dart';
import '../features/map/presentation/tiles/map_tile_source.dart';
import '../features/alerts/presentation/bloc/alerts_cubit.dart';
import '../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../features/accidents/domain/repositories/accidents_repository.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/inspections/domain/repositories/inspections_repository.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../features/reports/domain/repositories/reports_repository.dart';
import '../features/works/domain/repositories/works_repository.dart';
import '../features/tickets/domain/repositories/tickets_repository.dart';
import '../l10n/app_localizations.dart';
import 'dependencies.dart';
import 'feature_flags.dart';
import 'router.dart';
import 'shell/session_lifecycle.dart';

class SigacoApp extends StatefulWidget {
  const SigacoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SigacoApp> createState() => _SigacoAppState();
}

class _SigacoAppState extends State<SigacoApp> {
  late final SettingsCubit _settings = SettingsCubit(widget.dependencies.prefs);
  late final AuthBloc _auth = AuthBloc(
    widget.dependencies.authRepository,
    widget.dependencies.credentialStore,
    beforeLogout: widget.dependencies.pushRegistrar.retire,
  )..add(const AuthStarted());
  late final NavigationBloc _navigation = NavigationBloc(
    widget.dependencies.navigationRepository,
    minRefreshGap: widget.dependencies.accessRefreshGap,
    // Una accion negada espera poco; nunca mas que el tiempo por volver a la app.
    deniedRefreshGap:
        widget.dependencies.accessRefreshGap < const Duration(seconds: 5)
        ? widget.dependencies.accessRefreshGap
        : const Duration(seconds: 5),
  );
  late final SessionLockCubit _lock = SessionLockCubit(
    widget.dependencies.authRepository,
  );
  late final AlertsCubit _alerts = AlertsCubit(
    widget.dependencies.alertsRepository,
  );
  late final BrandingCubit _branding = BrandingCubit(
    widget.dependencies.brandingRepository,
    minRefreshGap: widget.dependencies.brandingRefreshGap,
  );
  late final ConnectivityCubit _connectivity = ConnectivityCubit(
    widget.dependencies.connectivity,
    widget.dependencies.serverReachable,
  );
  late final ConcessionZoneCubit _zone = ConcessionZoneCubit();
  late final GoRouter _router = createRouter(
    _auth,
    sampleMap: widget.dependencies.sampleMap,
    sampleTickets: widget.dependencies.sampleTickets,
    sampleAccidents: widget.dependencies.sampleAccidents,
    sampleMaintenance: widget.dependencies.sampleMaintenance,
    sampleInventory: widget.dependencies.sampleInventory,
    sampleWorks: widget.dependencies.sampleWorks,
    sampleInspections: widget.dependencies.sampleInspections,
    sampleAlerts: widget.dependencies.sampleAlerts,
  );

  @override
  void dispose() {
    _router.dispose();
    _settings.close();
    _auth.close();
    _navigation.close();
    _lock.close();
    _alerts.close();
    _branding.close();
    _connectivity.close();
    _zone.close();
    widget.dependencies.sync.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        RepositoryProvider<CredentialStore>.value(
          value: widget.dependencies.credentialStore,
        ),
        RepositoryProvider<DeviceUnlock>.value(
          value: widget.dependencies.deviceUnlock,
        ),
        RepositoryProvider<DeviceInfoSource>.value(
          value: widget.dependencies.deviceInfo,
        ),
        RepositoryProvider<LogoStore>.value(
          value: widget.dependencies.logoStore,
        ),
        RepositoryProvider<FileSource>.value(
          value: widget.dependencies.fileSource,
        ),
        RepositoryProvider<ConcessionZoneSource>.value(
          value: widget.dependencies.zoneSource,
        ),
        RepositoryProvider<PdfRenderer>.value(
          value: widget.dependencies.pdfRenderer,
        ),
        RepositoryProvider<LocalFileStore>.value(
          value: widget.dependencies.fileStore,
        ),
        RepositoryProvider<DocumentsRepository>.value(
          value: widget.dependencies.documentsRepository,
        ),
        RepositoryProvider<MapRepository>.value(
          value: widget.dependencies.mapRepository,
        ),
        RepositoryProvider<RoadSegmentsRepository>.value(
          value: widget.dependencies.roadSegmentsRepository,
        ),
        RepositoryProvider<LocationSource>.value(
          value: widget.dependencies.locationSource,
        ),
        RepositoryProvider<MapTileSource>.value(
          value: widget.dependencies.mapTileSource,
        ),
        RepositoryProvider<MapPackManager>.value(
          value: widget.dependencies.mapPacks,
        ),
        RepositoryProvider<FeatureFlags>.value(
          value: widget.dependencies.features,
        ),
        RepositoryProvider<AccidentsRepository>.value(
          value: widget.dependencies.accidentsRepository,
        ),
        RepositoryProvider<MaintenanceRepository>.value(
          value: widget.dependencies.maintenanceRepository,
        ),
        RepositoryProvider<InventoryRepository>.value(
          value: widget.dependencies.inventoryRepository,
        ),
        RepositoryProvider<WorksRepository>.value(
          value: widget.dependencies.worksRepository,
        ),
        RepositoryProvider<InspectionsRepository>.value(
          value: widget.dependencies.inspectionsRepository,
        ),
        RepositoryProvider<PushRegistrar>.value(
          value: widget.dependencies.pushRegistrar,
        ),
        RepositoryProvider<DeviceRegistrar>.value(
          value: widget.dependencies.deviceRegistrar,
        ),
        RepositoryProvider<MapBaseLoader>.value(
          value: widget.dependencies.mapBaseLoader,
        ),
        RepositoryProvider<MapEngine>.value(
          value: widget.dependencies.mapEngine,
        ),
        RepositoryProvider<DemoMode>.value(value: widget.dependencies.demoMode),
        RepositoryProvider<DashboardRepository>.value(
          value: widget.dependencies.dashboardRepository,
        ),
        RepositoryProvider<ReportsRepository>.value(
          value: widget.dependencies.reportsRepository,
        ),
        RepositoryProvider<TicketsRepository>.value(
          value: widget.dependencies.ticketsRepository,
        ),
        RepositoryProvider<MapSettings>.value(
          value: widget.dependencies.mapSettings,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _settings),
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _navigation),
          BlocProvider.value(value: _lock),
          BlocProvider.value(value: _alerts),
          BlocProvider.value(value: _branding),
          BlocProvider.value(value: _connectivity),
          BlocProvider.value(value: _zone),
          BlocProvider.value(value: widget.dependencies.sync),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) => BlocBuilder<BrandingCubit, BrandingState>(
            builder: (context, branding) => MaterialApp.router(
              title: 'SIGACO',
              debugShowCheckedModeBanner: false,
              // Con una concesion activa y su marca valida, sus colores;
              // antes de iniciar sesion, o si el usuario lo elige, los de SIGACO.
              theme: AppTheme.forAppearance(
                settings.appearance,
                brand: settings.colorOrigin == ColorOrigin.concession
                    ? branding.seed
                    : null,
              ),
              themeMode: ThemeMode.light,
              locale: settings.locale,
              supportedLocales: SettingsCubit.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (device, supported) {
                for (final s in supported) {
                  if (s.languageCode == device?.languageCode) return s;
                }
                return const Locale('es');
              },
              routerConfig: _router,
              builder: (context, child) => SessionLifecycle(
                router: _router,
                scope: widget.dependencies.sessionScope,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
