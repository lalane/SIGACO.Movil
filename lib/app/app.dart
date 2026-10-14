import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/device/device_info_source.dart';
import '../core/files/file_source.dart';
import '../core/pdf/pdf_renderer.dart';
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
import '../features/auth/presentation/session/session_timeout_cubit.dart';
import '../features/branding/presentation/bloc/branding_cubit.dart';
import '../features/documents/domain/repositories/documents_repository.dart';
import '../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../l10n/app_localizations.dart';
import 'dependencies.dart';
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
  late final SessionTimeoutCubit _timeout = SessionTimeoutCubit(
    widget.dependencies.authRepository,
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
  late final GoRouter _router = createRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _settings.close();
    _auth.close();
    _navigation.close();
    _timeout.close();
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _settings),
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _navigation),
          BlocProvider.value(value: _timeout),
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
