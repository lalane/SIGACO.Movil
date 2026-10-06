import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/status_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../l10n/app_localizations.dart';

/// Texto oscuro sobre los colores de estatus (ambar y verde): se lee igual en
/// cualquier concesion y en cualquier modo, porque no son colores de marca.
const _onStatus = Color(0xFF1E293B);

/// Aviso discreto y persistente de «Sin conexion» sobre todas las pantallas con
/// sesion abierta (MQ-MOB-10). No cambia la estructura de las pantallas: solo
/// empuja el contenido hacia abajo mientras se muestra.
class ConnectionBannerHost extends StatelessWidget {
  const ConnectionBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select(
      (AuthBloc b) => b.state.step == AuthStep.signedIn,
    );
    final connection = context.watch<ConnectivityCubit>().state;
    final show = signedIn && (!connection.online || connection.justReconnected);
    return Column(
      children: [
        if (show) ConnectionBanner(state: connection),
        Expanded(
          // La barra del aviso ya cubre la zona de la barra de estado.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: show,
            child: child,
          ),
        ),
      ],
    );
  }
}

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.state});

  final ConnectivityState state;

  String _since(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final format = sameDay
        ? DateFormat.Hm(locale)
        : DateFormat.Md(locale).add_Hm();
    return format.format(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final offline = !state.online;
    final last = state.lastContactAt;
    final text = !offline
        ? l10n.connectionRestored
        : last == null
        ? l10n.connectionOffline
        : l10n.connectionOfflineSince(_since(context, last));
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        key: Key(offline ? 'connection-offline' : 'connection-restored'),
        color: offline ? StatusColors.attended : StatusColors.closed,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.s(16),
              vertical: r.s(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  offline
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  size: r.s(16),
                  color: _onStatus,
                ),
                SizedBox(width: r.s(8)),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _onStatus,
                      fontSize: r.s(12.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
