import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/device/device_unlock.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/session/session_lock_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Pantalla de bloqueo por inactividad (RN-M01-37). Cubre la app sin cerrar la
/// sesion ni llamar al servidor: se abre con la huella, el rostro o el codigo del
/// telefono. Si el telefono no puede confirmarlo, solo queda cerrar sesion.
class SessionLockOverlay extends StatefulWidget {
  const SessionLockOverlay({super.key, required this.idleMinutes});

  final int idleMinutes;

  @override
  State<SessionLockOverlay> createState() => _SessionLockOverlayState();
}

class _SessionLockOverlayState extends State<SessionLockOverlay> {
  bool _busy = false;
  bool? _available;

  @override
  void initState() {
    super.initState();
    // Se pide la confirmacion al aparecer, sin esperar un toque.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    final unlock = context.read<DeviceUnlock>();
    final lock = context.read<SessionLockCubit>();
    final reason = AppLocalizations.of(context).sessionUnlockReason;
    setState(() => _busy = true);
    final available = await unlock.isAvailable();
    final ok = available && await unlock.authenticate(reason);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _available = available;
    });
    if (ok) lock.unlock();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      key: const Key('session-lock'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.sessionLockedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  _available == false
                      ? l10n.sessionUnlockUnavailable
                      : l10n.sessionLockedBody(widget.idleMinutes),
                  key: const Key('session-lock-body'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                if (_available != false)
                  FilledButton.icon(
                    key: const Key('session-unlock'),
                    onPressed: _busy ? null : _unlock,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.sessionUnlock),
                  ),
                const SizedBox(height: 10),
                TextButton(
                  key: const Key('session-lock-signout'),
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  child: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
