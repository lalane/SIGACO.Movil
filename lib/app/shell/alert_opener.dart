import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/bloc/alerts_cubit.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import 'alert_routes.dart';

/// `/alerts/:id`: el destino de tocar una notificacion. Con la sesion ya abierta
/// busca la alerta, la marca como leida y lleva directo al registro al que
/// apunta; si no apunta a nada o no se encuentra, deja en la lista de alertas.
/// Nunca manda a la web: el aviso se resuelve dentro de la app.
class AlertOpener extends StatefulWidget {
  const AlertOpener({super.key, required this.alertId});

  final String alertId;

  @override
  State<AlertOpener> createState() => _AlertOpenerState();
}

class _AlertOpenerState extends State<AlertOpener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final cubit = context.read<AlertsCubit>();
    final menu = context.read<NavigationBloc>().state.menu;
    final router = GoRouter.of(context);
    // La alerta puede no estar todavia (se abrio la app desde la notificacion).
    if (cubit.state.byId(widget.alertId) == null) await cubit.refresh();
    if (!mounted) return;
    final alert = cubit.state.byId(widget.alertId);
    final route = alert == null ? null : alertRoute(alert, menu);
    if (alert != null) cubit.markRead(alert.id);
    // Se reemplaza esta pantalla de paso: atras vuelve a donde estaba.
    router.pushReplacement(route ?? '/alerts');
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(key: Key('alert-opening'), child: CircularProgressIndicator()),
  );
}
