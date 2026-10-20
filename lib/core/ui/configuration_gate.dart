import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../theme/sigaco_palette.dart';
import '../time/concession_zone_cubit.dart';
import 'module_header.dart';
import 'module_style.dart';
import 'module_widgets.dart';

/// Deja pasar a [child] solo si la app ya tiene la configuracion de la
/// concesion con su zona horaria (DTF Configuracion, RN-13): sin ella la hora de
/// lo que se captura no se podria dar, asi que no se permite crear registros y
/// se pide conectarse y sincronizar.
class ConfigurationGate extends StatelessWidget {
  const ConfigurationGate({
    super.key,
    required this.title,
    required this.child,
    required this.onSync,
  });

  /// El titulo de la pantalla que se bloquea (se ve en la cabecera).
  final String title;
  final Widget child;

  /// Vuelve a pedir la configuracion al servidor (lo compone `app/`, que sabe
  /// de la sesion y de la concesion activa).
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final zone = context.select((ConcessionZoneCubit c) => c.state);
    if (zone != null) return child;
    return _Blocked(title: title, onSync: onSync);
  }
}

class _Blocked extends StatefulWidget {
  const _Blocked({required this.title, required this.onSync});

  final String title;
  final Future<void> Function() onSync;

  @override
  State<_Blocked> createState() => _BlockedState();
}

class _BlockedState extends State<_Blocked> {
  bool _syncing = false;

  Future<void> _retry() async {
    setState(() => _syncing = true);
    try {
      await widget.onSync();
    } catch (_) {
      // Sin red sigue bloqueado: la persona puede volver a intentar.
    }
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.gradientTop,
      body: Column(
        children: [
          SigacoModuleHeader(title: widget.title),
          Expanded(
            child: Container(
              color: moduleSheet,
              child: KeyedSubtree(
                key: const Key('configuration-gate'),
                child: ModuleStateView(
                  icon: Icons.cloud_sync_outlined,
                  title: l10n.cfgGateTitle,
                  body: l10n.cfgGateBody,
                  retryLabel: _syncing ? null : l10n.cfgGateRetry,
                  onRetry: _syncing ? null : _retry,
                  retryKey: const Key('configuration-gate-retry'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
