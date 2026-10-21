import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../bloc/alerts_cubit.dart';
import '../widgets/alert_widgets.dart';

/// El centro de alertas: lo ultimo que paso, lo que sigue sin leer y, al tocar
/// una, el registro al que apunta. Es lo que TEKIA acepto en lugar de la
/// notificacion del sistema (20/10/2026): siempre que el aviso lleve directo al
/// registro dentro de la app.
class AlertsPage extends StatefulWidget {
  const AlertsPage({
    super.key,
    required this.routeFor,
    this.sampleData = false,
  });

  /// A donde lleva una alerta segun lo que la persona puede ver; nulo si solo
  /// informa. Lo compone la app (el modulo no conoce a los demas).
  final String? Function(AppAlert alert) routeFor;

  /// Las alertas son de ejemplo: se avisa para que nadie las tome por reales.
  final bool sampleData;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  void initState() {
    super.initState();
    // Al entrar se actualiza sin borrar lo que ya se ve.
    final cubit = context.read<AlertsCubit>();
    if (cubit.state.status == AlertsStatus.idle) {
      cubit.load();
    } else {
      cubit.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<AlertsCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<AlertsCubit, AlertsState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title: l10n.alertsTitle,
                subtitle: l10n.alertsSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('alerts-mark-all'),
                    icon: Icons.done_all,
                    tooltip: l10n.alertsMarkAll,
                    onPressed: state.unread == 0 ? null : cubit.markAllRead,
                  ),
                ],
              ),
              if (widget.sampleData)
                Container(
                  key: const Key('alerts-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.alertsSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              if (state.status == AlertsStatus.ready && state.alerts.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                  child: ModuleFilterChips<bool>(
                    keyPrefix: 'alerts',
                    selected: state.onlyUnread,
                    onSelect: cubit.setOnlyUnread,
                    chips: [
                      ModuleChip(
                        value: false,
                        id: 'all',
                        label: l10n.alertsFilterAll,
                        count: state.alerts.length,
                      ),
                      ModuleChip(
                        value: true,
                        id: 'unread',
                        label: l10n.alertsFilterUnread,
                        count: state.unread,
                        badge: StatusColors.open,
                      ),
                    ],
                  ),
                ),
              SizedBox(height: r.s(12)),
              Expanded(child: ModuleListSheet(body: _body(context, state))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AlertsState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<AlertsCubit>();
    switch (state.status) {
      case AlertsStatus.idle:
      case AlertsStatus.loading:
        return const Center(
          key: Key('alerts-loading'),
          child: CircularProgressIndicator(),
        );
      case AlertsStatus.failure:
        return AlertsStateView(
          error: state.error ?? AlertsError.server,
          onRetry: cubit.load,
        );
      case AlertsStatus.ready:
        final visible = state.visible;
        if (visible.isEmpty) {
          return AlertsStateView.empty(
            message: state.alerts.isEmpty
                ? l10n.alertsEmptyAll
                : l10n.alertsEmptyUnread,
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: ListView.builder(
            key: const Key('alerts-list'),
            padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final alert = visible[i];
              final route = widget.routeFor(alert);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Responsive.formMaxWidth,
                  ),
                  child: AlertCard(
                    alert: alert,
                    zone: zone,
                    opensRecord: route != null,
                    onTap: () {
                      cubit.markRead(alert.id);
                      if (route != null) context.push(route);
                    },
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}
