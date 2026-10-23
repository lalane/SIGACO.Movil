import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/device/device_registrar.dart';
import '../../core/push/push_registrar.dart';
import '../composition/map_base_source.dart';
import '../../core/session/session_scope.dart';
import '../../core/offline/operation.dart';
import '../../core/offline/sync_cubit.dart';
import '../../core/settings/settings_cubit.dart';
import '../../core/time/concession_zone_cubit.dart';
import '../../core/time/concession_zone_source.dart';
import '../../features/alerts/presentation/bloc/alerts_cubit.dart';
import '../../features/auth/domain/entities/auth_entities.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/session/session_lock_cubit.dart';
import '../../features/branding/presentation/bloc/branding_cubit.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import 'connection_banner.dart';
import 'session_lock_overlay.dart';

/// Reacciona a la sesion en toda la app:
///  - al iniciar sesion o cambiar de concesion carga el menu de esa concesion;
///  - al cerrar sesion o cambiar de concesion descarta lo del ambiente anterior;
///  - al volver a la app con la sesion abierta vuelve a consultar los accesos;
///  - bloquea la app tras los minutos de inactividad (se abre con el telefono) y
///    pide entrar de nuevo cuando vence la sesion movil (RN-M01-37).
class SessionLifecycle extends StatefulWidget {
  const SessionLifecycle({
    super.key,
    required this.child,
    required this.router,
    required this.scope,
  });

  final Widget child;
  final GoRouter router;
  final SessionScope scope;

  @override
  State<SessionLifecycle> createState() => _SessionLifecycleState();
}

class _SessionLifecycleState extends State<SessionLifecycle>
    with WidgetsBindingObserver {
  AuthStep _lastStep = AuthStep.signedOut;
  String? _lastConcession;

  StreamSubscription<SessionRevalidation>? _revalidations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _revalidations = context.read<AuthRepository>().revalidations.listen(
      _onRevalidated,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revalidations?.cancel();
    _probe?.cancel();
    super.dispose();
  }

  /// El servidor confirmo la sesion con el menu y los permisos vigentes. Si ya no
  /// son los que muestra la app (un administrador quito o dio accesos mientras
  /// no habia red), se reconstruye la navegacion (HU-M01-08-04, CA-03).
  void _onRevalidated(SessionRevalidation r) {
    if (!mounted || !r.hasMenu || _lastStep != AuthStep.signedIn) return;
    final navigation = context.read<NavigationBloc>();
    final menu = navigation.state.menu;
    final shownModules = {for (final m in menu.modules) m.code};
    final changed =
        !setEquals(shownModules, r.modules.toSet()) ||
        !setEquals(menu.permissions.toSet(), r.permissions.toSet());
    if (changed) {
      navigation.add(const NavigationRefreshed(gap: Duration.zero));
    }
  }

  /// Al volver la conexion se confirma la sesion con el servidor, aunque no haya
  /// nada pendiente: una cuenta bloqueada o dada de baja se entera aqui (el 401
  /// devuelve al acceso). Sin red o con otro fallo, se reintenta la proxima vez.
  Future<void> _revalidate() async {
    try {
      await context.read<AuthRepository>().revalidateSession();
    } catch (_) {}
  }

  Timer? _probe;

  /// Sin conexion: cada tanto se vuelve a consultar el menu, que sirve de sonda
  /// para saber cuando el servidor responde otra vez.
  void _onConnectionChanged(BuildContext context, ConnectivityState s) {
    final navigation = context.read<NavigationBloc>();
    _probe?.cancel();
    _probe = null;
    if (!s.online) {
      _probe = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_lastStep == AuthStep.signedIn) {
          navigation.add(const NavigationRefreshed(gap: Duration.zero));
        }
      });
    }
  }

  /// Al volver a la app con la sesion abierta se vuelven a consultar los accesos
  /// (un administrador pudo cambiarlos mientras estaba en segundo plano,
  /// M02-02-04) y la version de la marca (US-18).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastStep == AuthStep.signedIn) {
      context.read<NavigationBloc>().add(const NavigationRefreshed());
      context.read<BrandingCubit>().refresh();
      // Lo capturado sin conexion se envia al volver a la app.
      context.read<SyncCubit>().onResume();
      // Las alertas que llegaron mientras tanto.
      context.read<AlertsCubit>().refresh();
    }
    if (state == AppLifecycleState.resumed) {
      // Mientras la app estuvo en segundo plano pudo pasar la inactividad o el
      // vencimiento de la sesion.
      context.read<SessionLockCubit>().check();
    }
  }

  void _onAuthChanged(BuildContext context, AuthState s) {
    final navigation = context.read<NavigationBloc>();
    final branding = context.read<BrandingCubit>();
    final lock = context.read<SessionLockCubit>();
    final sync = context.read<SyncCubit>();
    final alerts = context.read<AlertsCubit>();
    final concessionChanged =
        _lastConcession != null &&
        s.activeConcessionId != null &&
        s.activeConcessionId != _lastConcession;

    if (s.step == AuthStep.signedIn) {
      if (concessionChanged) widget.scope.clear();
      if (_lastStep != AuthStep.signedIn || concessionChanged) {
        navigation.add(const NavigationRequested());
        // Las alertas son de esta persona en esta concesion.
        alerts
          ..clear()
          ..load();
        // Los colores y el logo son de la concesion activa (MAR-08, MAR-09).
        final id = s.activeConcessionId;
        // La zona de la concesion anterior no vale para esta.
        context.read<ConcessionZoneCubit>().setFallback(null);
        if (id != null) {
          branding.load(id);
          _loadZone(id);
          _syncPush(id);
          _registerDevice(id);
          _loadMapBase(id);
        } else {
          branding.clear();
        }
      }
      // Lo local (cola de operaciones) es de esta persona en esta concesion.
      final userId = s.user?.id;
      final concession = s.activeConcessionId;
      if (userId != null && concession != null) {
        final offlineScope = OfflineScope(
          userId: userId,
          concessionId: concession,
        );
        // Los caches de documentos son de esta persona y concesion.
        widget.scope.bind(offlineScope);
        sync.setOnline(context.read<ConnectivityCubit>().state.online);
        sync.setScope(offlineScope);
      } else {
        widget.scope.bind(null);
        sync.setScope(null);
      }
      lock.start(Duration(minutes: s.idleTimeoutMinutes));
    } else if (s.step == AuthStep.signedOut) {
      navigation.add(const NavigationCleared());
      alerts.clear();
      branding.clear();
      context.read<ConcessionZoneCubit>().setFallback(null);
      context.read<PushRegistrar>().forget();
      context.read<DeviceRegistrar>().forget();
      context.read<MapBaseLoader>().reset();
      sync.setScope(null);
      lock.stop();
      widget.scope.clear();
      widget.scope.bind(null);
    }
    _lastStep = s.step;
    _lastConcession = s.activeConcessionId;
  }

  /// Registra el token push en la concesion activa si su canal esta activo
  /// (RN-19). Un fallo no estorba a la sesion: se reintenta al abrir la app.
  Future<void> _syncPush(String concessionId) async {
    final registrar = context.read<PushRegistrar>();
    await registrar.sync(concessionId);
  }

  /// Registra este telefono en el servidor para que el administrador vea la
  /// version de la app. Un fallo no estorba a la sesion. Borrar los datos locales
  /// cuando el administrador bloquea el telefono (`wipeData`) queda pendiente.
  Future<void> _registerDevice(String concessionId) async {
    await context.read<DeviceRegistrar>().register(concessionId);
  }

  /// El mapa base (proveedor de teselas) que el servidor indica para la
  /// concesion activa. Un fallo no estorba: se queda el de la compilacion.
  Future<void> _loadMapBase(String concessionId) async {
    await context.read<MapBaseLoader>().load(concessionId);
  }

  /// La zona horaria de la concesion segun el servidor, para cuando la marca no
  /// la trae (DEV-MOB-057, RN-04). Si el servidor no responde se usa la del
  /// telefono y se vuelve a intentar al recuperar la conexion.
  Future<void> _loadZone(String concessionId) async {
    final cubit = context.read<ConcessionZoneCubit>();
    final source = context.read<ConcessionZoneSource>();
    final zone = await source.load(concessionId);
    // La persona pudo cambiar de concesion o cerrar sesion mientras tanto.
    if (!mounted || _lastConcession != concessionId) return;
    if (zone != null) cubit.setFallback(zone);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) =>
              a.step != b.step || a.activeConcessionId != b.activeConcessionId,
          listener: _onAuthChanged,
        ),
        // Solo se ofrece elegir el origen de los colores si la concesion los trae.
        BlocListener<BrandingCubit, BrandingState>(
          listener: (context, s) {
            context.read<SettingsCubit>().setBrandAvailable(s.seed != null);
            // La zona horaria de la concesion para los demas modulos (RN-04).
            context.read<ConcessionZoneCubit>().set(s.zone);
          },
        ),
        // Al volver la conexion se actualizan los accesos; sin ella se sondea.
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listenWhen: (a, b) => a.online != b.online,
          listener: (context, s) {
            _onConnectionChanged(context, s);
            context.read<SyncCubit>().setOnline(s.online);
            if (s.online && _lastStep == AuthStep.signedIn) {
              _revalidate();
              context.read<AlertsCubit>().refresh();
              context.read<NavigationBloc>().add(
                const NavigationRefreshed(gap: Duration.zero),
              );
              // Un cambio de marca hecho en el portal mientras no habia red.
              context.read<BrandingCubit>().refresh(gap: Duration.zero);
              final id = _lastConcession;
              if (id != null &&
                  context.read<ConcessionZoneCubit>().state == null) {
                _loadZone(id);
              }
              // Lo que no se pudo registrar sin red (el registro repetido se omite).
              if (id != null) _registerDevice(id);
            }
          },
        ),
        BlocListener<SessionLockCubit, SessionLockState>(
          listenWhen: (a, b) => !a.expired && b.expired,
          // Vencio la sesion movil: se vuelve a entrar con conexion.
          listener: (context, s) =>
              context.read<AuthBloc>().add(const AuthSessionExpired()),
        ),
      ],
      // Cada toque cuenta como actividad; el bloqueo cubre toda la app.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => context.read<SessionLockCubit>().touch(),
        child: Stack(
          children: [
            ConnectionBannerHost(child: widget.child),
            BlocBuilder<SessionLockCubit, SessionLockState>(
              buildWhen: (a, b) => a.locked != b.locked,
              builder: (context, s) => s.locked
                  ? Positioned.fill(
                      child: SessionLockOverlay(
                        idleMinutes: context
                            .read<AuthBloc>()
                            .state
                            .idleTimeoutMinutes,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
