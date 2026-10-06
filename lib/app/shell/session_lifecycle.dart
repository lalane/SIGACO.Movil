import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/session/session_scope.dart';
import '../../core/settings/settings_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/session/session_timeout_cubit.dart';
import '../../features/branding/presentation/bloc/branding_cubit.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../l10n/app_localizations.dart';
import 'connection_banner.dart';

/// Reacciona a la sesion en toda la app:
///  - al iniciar sesion o cambiar de concesion carga el menu de esa concesion;
///  - al cerrar sesion o cambiar de concesion descarta lo del ambiente anterior;
///  - al volver a la app con la sesion abierta vuelve a consultar los accesos;
///  - avisa antes de que el servidor cierre la sesion por inactividad.
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
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _probe?.cancel();
    super.dispose();
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

  /// Al volver a la app con la sesion abierta se vuelven a consultar los accesos:
  /// un administrador pudo cambiarlos mientras estaba en segundo plano (M02-02-04).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastStep == AuthStep.signedIn) {
      context.read<NavigationBloc>().add(const NavigationRefreshed());
    }
  }

  void _onAuthChanged(BuildContext context, AuthState s) {
    final navigation = context.read<NavigationBloc>();
    final branding = context.read<BrandingCubit>();
    final timeout = context.read<SessionTimeoutCubit>();
    final concessionChanged =
        _lastConcession != null &&
        s.activeConcessionId != null &&
        s.activeConcessionId != _lastConcession;

    if (s.step == AuthStep.signedIn) {
      if (concessionChanged) widget.scope.clear();
      if (_lastStep != AuthStep.signedIn || concessionChanged) {
        navigation.add(const NavigationRequested());
        // Los colores y el logo son de la concesion activa (MAR-08, MAR-09).
        final id = s.activeConcessionId;
        if (id != null) {
          branding.load(id);
        } else {
          branding.clear();
        }
      }
      timeout.start(Duration(minutes: s.idleTimeoutMinutes));
    } else if (s.step == AuthStep.signedOut) {
      navigation.add(const NavigationCleared());
      branding.clear();
      timeout.stop();
      widget.scope.clear();
    }
    _lastStep = s.step;
    _lastConcession = s.activeConcessionId;
  }

  bool get _onSignedInRoute {
    try {
      final path = widget.router.routerDelegate.currentConfiguration.uri.path;
      return path == '/home' || path.startsWith('/account');
    } catch (_) {
      // El router aun no tiene ruta (arranque) o ya se libero.
      return false;
    }
  }

  /// Cierra el dialogo una sola vez: si ya se cerro, no toca la pantalla de abajo.
  void _closeDialog(BuildContext ctx) {
    final route = ModalRoute.of(ctx);
    if (route != null && route.isActive) {
      Navigator.of(ctx).removeRoute(route);
    }
  }

  Future<void> _showExpiring() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    // El router puede seguir cambiando de pantalla (justo despues de iniciar
    // sesion): un dialogo abierto antes se perderia al reemplazarse la ruta.
    for (var i = 0; i < 30 && !_onSignedInRoute; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) {
        _dialogOpen = false;
        return;
      }
    }
    // Margen para que termine la transicion de pantalla: al reemplazarse la
    // ruta de login, un dialogo abierto encima se descartaria.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) {
      _dialogOpen = false;
      return;
    }
    final context = widget.router.routerDelegate.navigatorKey.currentContext;
    if (context == null ||
        !context.mounted ||
        !context.read<SessionTimeoutCubit>().state.warning) {
      _dialogOpen = false;
      return;
    }
    final l10n = AppLocalizations.of(context);
    final timeout = context.read<SessionTimeoutCubit>();
    final auth = context.read<AuthBloc>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: timeout,
        child: BlocConsumer<SessionTimeoutCubit, SessionTimeoutState>(
          listenWhen: (a, b) => a.warning && !b.warning,
          listener: (ctx, _) => _closeDialog(ctx),
          builder: (ctx, state) => AlertDialog(
            title: Text(l10n.sessionExpiringTitle),
            content: Text(l10n.sessionExpiringBody(state.secondsLeft ?? 0)),
            actions: [
              TextButton(
                onPressed: () {
                  _closeDialog(ctx);
                  auth.add(const AuthLogoutRequested());
                },
                child: Text(l10n.signOut),
              ),
              FilledButton(
                onPressed: () {
                  _closeDialog(ctx);
                  timeout.keepAlive();
                },
                child: Text(l10n.sessionContinue),
              ),
            ],
          ),
        ),
      ),
    );
    _dialogOpen = false;
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
          listener: (context, s) =>
              context.read<SettingsCubit>().setBrandAvailable(s.seed != null),
        ),
        // Al volver la conexion se actualizan los accesos; sin ella se sondea.
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listenWhen: (a, b) => a.online != b.online,
          listener: (context, s) {
            _onConnectionChanged(context, s);
            if (s.online && _lastStep == AuthStep.signedIn) {
              context.read<NavigationBloc>().add(
                const NavigationRefreshed(gap: Duration.zero),
              );
            }
          },
        ),
        BlocListener<SessionTimeoutCubit, SessionTimeoutState>(
          listener: (context, s) {
            if (s.expired) {
              context.read<AuthBloc>().add(const AuthSessionExpired());
            } else if (s.warning) {
              _showExpiring();
            }
          },
        ),
      ],
      child: ConnectionBannerHost(child: widget.child),
    );
  }
}
