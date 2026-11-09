import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/credential_store.dart';
import '../features/auth/presentation/account/account_cubit.dart';
import '../features/auth/presentation/account/account_page.dart';
import '../features/auth/presentation/account/account_settings_page.dart';
import '../features/auth/presentation/account/account_mfa_page.dart';
import '../features/auth/presentation/account/account_password_page.dart';
import '../features/auth/presentation/account/mfa_setup_cubit.dart';
import '../features/auth/presentation/account/change_password_cubit.dart';
import '../features/auth/presentation/account/password_rules_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/concession_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/mfa_enroll_page.dart';
import '../features/auth/presentation/pages/mfa_page.dart';
import '../features/auth/presentation/pages/mfa_recovery_codes_page.dart';
import '../features/auth/presentation/pages/recovery_page.dart';
import '../features/documents/domain/entities/document_access.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../core/files/file_source.dart';
import '../l10n/app_localizations.dart';
import '../core/files/local_file_store.dart';
import '../core/offline/sync_cubit.dart';
import '../core/time/concession_zone_cubit.dart';
import '../core/ui/configuration_gate.dart';
import 'shell/record_routes.dart';
import 'shell/zone_refresh.dart';
import '../features/documents/presentation/bloc/document_detail_cubit.dart';
import '../features/documents/presentation/bloc/document_preview_cubit.dart';
import '../features/documents/presentation/bloc/document_upload_cubit.dart';
import '../features/documents/presentation/pages/document_preview_page.dart';
import '../features/documents/presentation/pages/document_upload_page.dart';
import '../features/documents/presentation/bloc/documents_cubit.dart';
import '../features/documents/presentation/pages/document_detail_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/map/domain/entities/geo_point.dart';
import '../features/map/domain/entities/map_pin.dart';
import '../features/map/domain/entities/map_settings.dart';
import '../features/map/domain/repositories/location_source.dart';
import '../features/map/domain/repositories/map_pack_manager.dart';
import '../features/map/domain/repositories/map_repository.dart';
import '../features/map/domain/repositories/road_segments_repository.dart';
import '../features/map/presentation/bloc/map_packs_cubit.dart';
import '../features/map/presentation/pages/map_packs_page.dart';
import '../features/map/presentation/bloc/map_cubit.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../core/demo/demo_mode.dart';
import '../features/map/presentation/map_camera.dart';
import '../features/map/presentation/tiles/map_tile_source.dart';
import '../features/map/presentation/map_record_actions.dart';
import '../features/alerts/presentation/pages/alerts_page.dart';
import '../features/navigation/domain/entities/mobile_module.dart';
import 'shell/alert_opener.dart';
import 'shell/alert_routes.dart';
import '../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../features/accidents/domain/repositories/accidents_repository.dart';
import '../features/accidents/presentation/bloc/accident_detail_cubit.dart';
import '../features/accidents/presentation/bloc/accidents_cubit.dart';
import '../features/accidents/presentation/bloc/new_accident_cubit.dart';
import '../features/accidents/presentation/pages/accident_detail_page.dart';
import '../features/accidents/presentation/pages/accidents_page.dart';
import '../features/accidents/presentation/pages/new_accident_page.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/inspections/domain/repositories/inspections_repository.dart';
import '../features/inspections/presentation/bloc/inspection_detail_cubit.dart';
import '../features/inspections/presentation/bloc/new_inspection_cubit.dart';
import '../features/inspections/presentation/pages/new_inspection_page.dart';
import 'composition/location_finding_position_source.dart';
import '../features/inspections/presentation/bloc/inspections_cubit.dart';
import '../features/inspections/presentation/pages/inspection_detail_page.dart';
import '../features/inspections/presentation/pages/inspections_page.dart';
import '../core/permissions/permission_keys.dart';
import '../core/scan/qr_scanner.dart';
import '../features/inventory/domain/repositories/asset_capture_repository.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/inventory/presentation/bloc/asset_qr_cubit.dart';
import '../features/inventory/presentation/bloc/inventory_cubit.dart';
import '../features/inventory/presentation/bloc/inventory_detail_cubit.dart';
import '../features/inventory/presentation/bloc/new_asset_cubit.dart';
import '../features/inventory/presentation/pages/asset_qr_page.dart';
import '../features/inventory/presentation/pages/inventory_detail_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/inventory/presentation/pages/new_asset_page.dart';
import '../features/inventory/presentation/widgets/asset_history_view.dart';
import 'composition/location_asset_position_source.dart';
import '../features/maintenance/domain/entities/maintenance.dart';
import '../features/reports/domain/entities/indicator_report.dart';
import '../features/reports/domain/repositories/reports_repository.dart';
import '../features/works/domain/repositories/works_repository.dart';
import '../features/works/presentation/bloc/work_detail_cubit.dart';
import '../features/works/presentation/bloc/works_cubit.dart';
import '../features/works/presentation/pages/work_detail_page.dart';
import '../features/works/presentation/pages/works_page.dart';
import '../features/reports/presentation/bloc/report_cubit.dart';
import '../features/reports/presentation/pages/report_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/maintenance/domain/repositories/maintenance_repository.dart';
import '../features/maintenance/presentation/bloc/maintenance_cubit.dart';
import '../features/maintenance/presentation/bloc/maintenance_detail_cubit.dart';
import '../features/maintenance/presentation/bloc/maintenance_progress_cubit.dart';
import '../features/maintenance/presentation/pages/maintenance_detail_page.dart';
import '../features/maintenance/presentation/pages/maintenance_indicators_page.dart';
import '../features/maintenance/presentation/pages/maintenance_page.dart';
import '../features/maintenance/presentation/pages/maintenance_progress_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/tickets/domain/repositories/tickets_repository.dart';
import '../features/tickets/presentation/bloc/follow_up_cubit.dart';
import '../features/tickets/presentation/bloc/new_ticket_cubit.dart';
import '../features/tickets/presentation/bloc/ticket_detail_cubit.dart';
import '../features/tickets/presentation/bloc/tickets_cubit.dart';
import '../features/tickets/presentation/pages/follow_up_page.dart';
import '../features/tickets/presentation/pages/new_ticket_page.dart';
import '../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../features/tickets/presentation/pages/tickets_page.dart';
import '../features/sync/presentation/conflict_page.dart';
import '../features/sync/presentation/sync_page.dart';
import 'shell/home_page.dart';

String _routeFor(AuthStep step) => switch (step) {
  AuthStep.signedOut => '/login',
  AuthStep.mfa => '/mfa',
  AuthStep.mfaEnroll => '/mfa-enroll',
  AuthStep.mfaCodes => '/mfa-codes',
  AuthStep.changePassword => '/change-password',
  AuthStep.concession => '/concession',
  AuthStep.signedIn => '/home',
};

/// Avisa al router cuando cambia el paso del acceso.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream
        .map((s) => s.step)
        .distinct()
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthStep> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Lo que el usuario puede hacer en el gestor documental, segun los permisos
/// de su sesion; se recalcula si el menu cambia mientras la pantalla esta abierta.
DocumentAccess _documentAccess(BuildContext context) =>
    DocumentAccess.fromPermissions(
      context.select((NavigationBloc b) => b.state.menu.permissions),
    );

/// Lo que el mapa puede abrir y crear en otros modulos, segun el menu del
/// usuario: abrir la ficha de un elemento en su modulo y levantar un ticket en
/// un lugar (DTF M10, HU-MOB-10-03 y HU-MOB-10-04).
MapRecordActions _mapActions(BuildContext context) {
  final menu = context.read<NavigationBloc>().state.menu;
  bool has(MobileModule m) => m.isAvailableIn(menu);
  return MapRecordActions(
    openRoute: (pin) => switch (pin.layer) {
      MapLayer.inventory =>
        has(MobileModule.inventory) ? '/inventory/${pin.id}' : null,
      MapLayer.tickets =>
        has(MobileModule.tickets) ? '/tickets/${pin.id}' : null,
      MapLayer.works => has(MobileModule.works) ? '/works/${pin.id}' : null,
      MapLayer.maintenance =>
        has(MobileModule.maintenance) ? '/maintenance' : null,
    },
    onCreate: has(MobileModule.tickets)
        ? (target) async {
            await context.push<Object?>(ticketNewRoute(target));
          }
        : null,
  );
}

/// Lo que la ficha del activo abre en otros modulos, segun el menu del usuario:
/// la ficha de cada registro de su historia operativa y el alta de ticket con
/// el activo elegido. Con datos de ejemplo los registros no existen en sus
/// modulos: solo se listan.
AssetRecordActions _assetActions(BuildContext context, {required bool sample}) {
  final menu = context.read<NavigationBloc>().state.menu;
  bool has(MobileModule m) => m.isAvailableIn(menu);
  final tickets = has(MobileModule.tickets);
  final inspections = has(MobileModule.inspections);
  final maintenance = has(MobileModule.maintenance);
  return AssetRecordActions(
    openRoute: sample
        ? null
        : (entry) {
            final id = Uri.encodeComponent(entry.id);
            return switch (entry.kind) {
              AssetHistoryKind.tickets => tickets ? '/tickets/$id' : null,
              AssetHistoryKind.inspections =>
                inspections ? '/inspections/$id' : null,
              // El mantenimiento se abre dentro de su indicador.
              AssetHistoryKind.maintenances when maintenance =>
                switch (MaintenanceIndicator.values
                    .where((i) => i.name == entry.subsystemCode?.toLowerCase())
                    .firstOrNull) {
                  final indicator? => '/maintenance/${indicator.name}/$id',
                  null => null,
                },
              AssetHistoryKind.maintenances => null,
            };
          },
    newTicketRoute: tickets ? ticketNewRouteForAsset : null,
  );
}

/// `?lat=&lon=` de la ruta del mapa (donde esta el elemento que se abre); null
/// si no vienen o no son numeros.
GeoPoint? _queryPoint(Map<String, String> query) {
  final lat = double.tryParse(query['lat'] ?? '');
  final lon = double.tryParse(query['lon'] ?? '');
  return lat == null || lon == null ? null : GeoPoint(lat, lon);
}

/// El perfil puede dar de alta activos (cualquiera de los permisos que acepta
/// el servidor); se recalcula si el menu cambia con la pantalla abierta.
bool _canCreateAssets(BuildContext context) {
  final permissions = context.select(
    (NavigationBloc b) => b.state.menu.permissions,
  );
  return PermissionKeys.inventoryCreate.any(permissions.contains);
}

GoRouter createRouter(
  AuthBloc auth, {
  bool sampleMap = false,
  bool sampleTickets = false,
  bool sampleAccidents = false,
  bool sampleMaintenance = false,
  bool sampleInventory = false,
  bool sampleWorks = false,
  bool sampleInspections = false,
  bool sampleAlerts = false,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final step = auth.state.step;
      final loc = state.matchedLocation;
      if (step == AuthStep.signedOut) {
        return (loc == '/login' || loc == '/recovery' || loc == '/splash')
            ? null
            : '/login';
      }
      if (step == AuthStep.signedIn) {
        return (loc == '/home' ||
                loc.startsWith('/account') ||
                loc.startsWith('/sync') ||
                loc.startsWith('/map') ||
                loc.startsWith('/tickets') ||
                loc.startsWith('/accidents') ||
                loc.startsWith('/maintenance') ||
                loc.startsWith('/inventory') ||
                loc.startsWith('/reports') ||
                loc.startsWith('/dashboard') ||
                loc.startsWith('/works') ||
                loc.startsWith('/alerts') ||
                loc.startsWith('/inspections') ||
                loc.startsWith('/documents'))
            ? null
            : '/home';
      }
      final target = _routeFor(step);
      return loc == target ? null : target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/login',
        // `sigaco://app/login?reset=ok`: regreso del navegador tras restablecer.
        builder: (_, state) => LoginPage(
          passwordResetReturned: state.uri.queryParameters['reset'] == 'ok',
        ),
      ),
      GoRoute(path: '/recovery', builder: (_, _) => const RecoveryPage()),
      GoRoute(path: '/mfa', builder: (_, _) => const MfaPage()),
      GoRoute(path: '/mfa-enroll', builder: (_, _) => const MfaEnrollPage()),
      GoRoute(
        path: '/mfa-codes',
        builder: (_, _) => const MfaRecoveryCodesPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, _) => BlocProvider(
          create: (_) =>
              PasswordRulesCubit(context.read<AuthRepository>())..load(),
          child: const ChangePasswordPage(),
        ),
      ),
      GoRoute(path: '/concession', builder: (_, _) => const ConcessionPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/documents',
        builder: (context, _) => BlocProvider(
          create: (_) => DocumentsCubit(context.read<DocumentsRepository>()),
          child: Builder(
            builder: (context) =>
                DocumentsPage(access: _documentAccess(context)),
          ),
        ),
        routes: [
          // Antes que ':id', o "upload" se tomaria por un documento.
          GoRoute(
            path: 'upload',
            builder: (context, _) => BlocProvider(
              create: (_) => DocumentUploadCubit(
                repository: context.read<DocumentsRepository>(),
                sync: context.read<SyncCubit>(),
                files: context.read<FileSource>(),
                store: context.read<LocalFileStore>(),
              ),
              child: Builder(
                builder: (context) =>
                    DocumentUploadPage(access: _documentAccess(context)),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => DocumentDetailCubit(
                context.read<DocumentsRepository>(),
                state.pathParameters['id']!,
                sync: context.read<SyncCubit>(),
              ),
              child: Builder(
                builder: (context) =>
                    DocumentDetailPage(access: _documentAccess(context)),
              ),
            ),
            routes: [
              GoRoute(
                path: 'preview',
                builder: (context, state) => BlocProvider(
                  create: (_) => DocumentPreviewCubit(
                    context.read<DocumentsRepository>(),
                    state.pathParameters['id']!,
                  ),
                  child: Builder(
                    builder: (context) =>
                        DocumentPreviewPage(access: _documentAccess(context)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => BlocProvider(
          create: (_) => MapCubit(
            repository: context.read<MapRepository>(),
            locationSource: context.read<LocationSource>(),
            packs: context.read<MapPackManager>(),
            segmentsRepository: context.read<RoadSegmentsRepository>(),
            settings: context.read<MapSettings>(),
          ),
          child: MapPage(
            tileSource: context.read<MapTileSource>(),
            sampleData: sampleMap || context.read<DemoMode>().on,
            initialLayer: MapLayer.values
                .where((l) => l.name == state.uri.queryParameters['layer'])
                .firstOrNull,
            initialPinId: state.uri.queryParameters['pin'],
            initialPosition: _queryPoint(state.uri.queryParameters),
            actions: _mapActions(context),
            engine: context.read<MapEngine>(),
          ),
        ),
        routes: [
          GoRoute(
            path: 'packs',
            builder: (context, _) => BlocProvider(
              create: (_) => MapPacksCubit(context.read<MapPackManager>()),
              child: const MapPacksPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, _) => BlocProvider(
          create: (_) => TicketsCubit(context.read<TicketsRepository>()),
          child: TicketsPage(
            sampleData: sampleTickets || context.read<DemoMode>().on,
          ),
        ),
        routes: [
          // Antes que ':id', o "new" se tomaria por un ticket.
          GoRoute(
            path: 'new',
            builder: (context, state) => BlocProvider(
              create: (_) => NewTicketCubit(
                context.read<TicketsRepository>(),
                // Si viene del mapa o de un activo, ya trae donde se levanta.
                location: parseTicketLocation(state.uri.queryParameters),
                // Desde la ficha de un activo puede venir solo el activo.
                asset: parseTicketAsset(state.uri.queryParameters),
                // Solo las fallas de los indicadores asignados (reunion 05/11).
                allowedIndicators: () async {
                  try {
                    final mine = await context
                        .read<MaintenanceRepository>()
                        .visibleIndicators();
                    return {for (final i in mine) i.name.toUpperCase()};
                  } catch (_) {
                    return null;
                  }
                },
              )..load(),
              child: ConfigurationGate(
                title: AppLocalizations.of(context).newTicketTitle,
                child: NewTicketPage(
                  minAccuracyMeters: context
                      .read<MapSettings>()
                      .minAccuracyMeters,
                ),
                onSync: () => refreshConcessionZone(context),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => TicketDetailCubit(
                context.read<TicketsRepository>(),
                state.pathParameters['id']!,
              )..load(),
              child: const TicketDetailPage(),
            ),
            routes: [
              GoRoute(
                path: 'follow-up',
                builder: (context, state) => BlocProvider(
                  create: (_) => FollowUpCubit(
                    context.read<TicketsRepository>(),
                    state.pathParameters['id']!,
                    zone: context.read<ConcessionZoneCubit>().state,
                  ),
                  child: const FollowUpPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/accidents',
        builder: (context, _) => BlocProvider(
          create: (_) => AccidentsCubit(context.read<AccidentsRepository>()),
          child: AccidentsPage(
            sampleData: sampleAccidents || context.read<DemoMode>().on,
          ),
        ),
        routes: [
          // Antes que ':id', o "new" se tomaria por un accidente.
          GoRoute(
            path: 'new',
            builder: (context, _) => BlocProvider(
              create: (_) =>
                  NewAccidentCubit(context.read<AccidentsRepository>()),
              child: ConfigurationGate(
                title: AppLocalizations.of(context).newAccidentTitle,
                child: const NewAccidentPage(),
                onSync: () => refreshConcessionZone(context),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => AccidentDetailCubit(
                context.read<AccidentsRepository>(),
                state.pathParameters['id']!,
              )..load(),
              child: const AccidentDetailPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/maintenance',
        builder: (_, _) => const MaintenanceIndicatorsPage(),
        routes: [
          GoRoute(
            path: ':indicator',
            // Un indicador que no existe vuelve a la lista de indicadores.
            redirect: (_, state) =>
                MaintenanceIndicator.values.any(
                  (i) => i.name == state.pathParameters['indicator'],
                )
                ? null
                : '/maintenance',
            builder: (context, state) => BlocProvider(
              create: (_) => MaintenanceCubit(
                context.read<MaintenanceRepository>(),
                MaintenanceIndicator.values.byName(
                  state.pathParameters['indicator']!,
                ),
              ),
              child: MaintenancePage(
                indicator: MaintenanceIndicator.values.byName(
                  state.pathParameters['indicator']!,
                ),
                sampleData: sampleMaintenance || context.read<DemoMode>().on,
              ),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BlocProvider(
                  create: (_) => MaintenanceDetailCubit(
                    context.read<MaintenanceRepository>(),
                    state.pathParameters['id']!,
                  )..load(),
                  child: const MaintenanceDetailPage(),
                ),
                routes: [
                  // El avance abre desde la ficha, que pasa la orden: de ella
                  // salen el avance de partida y la unidad del volumen.
                  GoRoute(
                    path: 'progress',
                    builder: (context, state) {
                      final order = state.extra is MaintenanceOrder
                          ? state.extra! as MaintenanceOrder
                          : null;
                      return BlocProvider(
                        create: (_) => MaintenanceProgressCubit(
                          context.read<MaintenanceRepository>(),
                          state.pathParameters['id']!,
                          totalVolume: order?.totalVolume,
                          executedVolume: order?.executedVolume,
                        ),
                        child: MaintenanceProgressPage(unit: order?.unit),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, _) {
          final menu = context.read<NavigationBloc>().state.menu;
          return AlertsPage(
            sampleData: sampleAlerts || context.read<DemoMode>().on,
            routeFor: (alert) => alertRoute(alert, menu),
          );
        },
        routes: [
          // El destino de tocar una notificacion: abre el registro de la alerta.
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AlertOpener(alertId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/works',
        builder: (context, _) => BlocProvider(
          create: (_) => WorksCubit(context.read<WorksRepository>()),
          child: WorksPage(
            sampleData: sampleWorks || context.read<DemoMode>().on,
          ),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => WorkDetailCubit(
                context.read<WorksRepository>(),
                state.pathParameters['id']!,
              )..load(),
              child: const WorkDetailPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/inspections',
        builder: (context, _) => BlocProvider(
          create: (_) =>
              InspectionsCubit(context.read<InspectionsRepository>()),
          child: InspectionsPage(
            sampleData: sampleInspections || context.read<DemoMode>().on,
          ),
        ),
        routes: [
          // Antes que ':id', o "new" se tomaria por un monitoreo.
          GoRoute(
            path: 'new',
            builder: (context, _) => BlocProvider(
              create: (_) =>
                  NewInspectionCubit(context.read<InspectionsRepository>())
                    ..load(),
              child: ConfigurationGate(
                title: AppLocalizations.of(context).inspNew,
                child: const NewInspectionPage(),
                onSync: () => refreshConcessionZone(context),
              ),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => InspectionDetailCubit(
                context.read<InspectionsRepository>(),
                state.pathParameters['id']!,
                positionSource: LocationFindingPositionSource(
                  context.read<LocationSource>(),
                ),
              )..load(),
              child: const InspectionDetailPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, _) => BlocProvider(
          create: (_) => DashboardCubit(context.read<DashboardRepository>()),
          child: DashboardPage(
            sampleData:
                sampleTickets ||
                sampleAccidents ||
                sampleMaintenance ||
                sampleInventory ||
                context.read<DemoMode>().on,
          ),
        ),
      ),
      GoRoute(
        path: '/reports',
        builder: (_, _) => const ReportsPage(),
        routes: [
          GoRoute(
            path: ':indicator',
            // Un indicador que no existe vuelve a la lista de indicadores.
            redirect: (_, state) =>
                ReportIndicator.values.any(
                  (i) => i.name == state.pathParameters['indicator'],
                )
                ? null
                : '/reports',
            builder: (context, state) => BlocProvider(
              create: (_) => ReportCubit(
                context.read<ReportsRepository>(),
                ReportIndicator.values.byName(
                  state.pathParameters['indicator']!,
                ),
              ),
              child: ReportPage(
                sampleData: sampleMaintenance || context.read<DemoMode>().on,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, _) {
          final capture = context.read<AssetCaptureRepository>();
          return BlocProvider(
            create: (_) => InventoryCubit(
              context.read<InventoryRepository>(),
              // Las altas que siguen en el telefono tambien se ven.
              pending: capture is PendingAssetsSource
                  ? capture as PendingAssetsSource
                  : null,
            ),
            child: Builder(
              builder: (context) => InventoryPage(
                sampleData: sampleInventory || context.read<DemoMode>().on,
                canCreate: _canCreateAssets(context),
              ),
            ),
          );
        },
        routes: [
          // Antes que ':id', o "new" y "scan" se tomarian por un activo.
          GoRoute(
            path: 'new',
            builder: (context, _) => BlocProvider(
              create: (_) => NewAssetCubit(
                context.read<AssetCaptureRepository>(),
                positionSource: LocationAssetPositionSource(
                  context.read<LocationSource>(),
                ),
                language: Localizations.localeOf(context).languageCode,
              )..load(),
              child: ConfigurationGate(
                title: AppLocalizations.of(context).invNewTitle,
                child: NewAssetPage(
                  minAccuracyMeters: context
                      .read<MapSettings>()
                      .minAccuracyMeters,
                ),
                onSync: () => refreshConcessionZone(context),
              ),
            ),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, _) => BlocProvider(
              create: (_) => AssetQrCubit(context.read<InventoryRepository>()),
              child: AssetQrPage(scanner: context.read<QrScanner>()),
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => InventoryDetailCubit(
                context.read<InventoryRepository>(),
                state.pathParameters['id']!,
              )..load(),
              child: InventoryDetailPage(
                actions: _assetActions(
                  context,
                  sample: sampleInventory || context.read<DemoMode>().on,
                ),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/sync',
        builder: (_, _) => const SyncPage(),
        routes: [
          GoRoute(
            path: 'conflict/:id',
            builder: (_, state) =>
                ConflictPage(operationId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        builder: (context, _) => BlocProvider(
          create: (_) => AccountCubit(context.read<AuthRepository>())..load(),
          child: const AccountPage(),
        ),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, _) => BlocProvider(
              create: (_) =>
                  AccountCubit(context.read<AuthRepository>())..load(),
              child: const AccountSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'password',
            builder: (context, _) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ChangePasswordCubit(
                    context.read<AuthRepository>(),
                    context.read<CredentialStore>(),
                  ),
                ),
                BlocProvider(
                  create: (_) =>
                      PasswordRulesCubit(context.read<AuthRepository>())
                        ..load(),
                ),
              ],
              child: const AccountPasswordPage(),
            ),
          ),
          GoRoute(
            path: 'mfa',
            builder: (context, _) => BlocProvider(
              create: (_) =>
                  MfaSetupCubit(context.read<AuthRepository>())..loadStatus(),
              child: const AccountMfaPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
