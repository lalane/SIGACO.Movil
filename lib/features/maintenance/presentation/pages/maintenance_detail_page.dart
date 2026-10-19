import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../bloc/maintenance_detail_cubit.dart';
import '../maintenance_labels.dart';
import '../widgets/maintenance_widgets.dart';

/// La ficha de un mantenimiento (mockup nuevo): avance, importes y los detalles
/// en dos columnas.
class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<MaintenanceDetailCubit, MaintenanceDetailState>(
      builder: (context, state) {
        final order = state.order;
        if (order != null) return _Detail(order: order);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.maintTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == MaintenanceDetailStatus.failure
                      ? MaintenanceStateView(
                          error: state.error ?? MaintenanceError.server,
                          onRetry: context.read<MaintenanceDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('maintenance-detail-loading'),
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.order});

  final MaintenanceOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final locale = Localizations.localeOf(context).toString();
    const none = '—';
    String? money0(double? v) => v == null ? null : money(locale, v);
    return Scaffold(
      backgroundColor: p.gradientTop,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: ListView(
                  key: const Key('maintenance-detail'),
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        child: Row(
                          children: [
                            const ModuleBackPill(
                              key: Key('maintenance-detail-back'),
                            ),
                            const Spacer(),
                            ModuleStatusPill(
                              key: const Key('maintenance-detail-status'),
                              label: statusLabel(l10n, order.status),
                              color: statusColor(order.status),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.s(24)),
                      decoration: BoxDecoration(
                        color: moduleSurface,
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.title,
                            key: const Key('maintenance-detail-title'),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PlusJakartaSans',
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                              fontSize: r.s(28),
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: r.s(10)),
                          Text(
                            l10n.maintActivity(order.activity),
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(16),
                            ),
                          ),
                          SizedBox(height: r.s(20)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.maintProjectProgress,
                                  style: TextStyle(
                                    color: moduleMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: r.s(15),
                                  ),
                                ),
                              ),
                              Text(
                                percent(order.progress),
                                key: const Key('maintenance-detail-progress'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.s(18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.s(8)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(r.s(6)),
                            child: LinearProgressIndicator(
                              value: order.progress,
                              minHeight: r.s(10),
                              color: StatusColors.closed,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: r.s(24)),
                          Row(
                            children: [
                              Expanded(
                                child: _Amount(
                                  label: l10n.maintExecutedAmount,
                                  value: money0(order.executedAmount) ?? none,
                                  color: p.accent,
                                  valueKey: const Key(
                                    'maintenance-executed-amount',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _Amount(
                                  label: l10n.maintPendingAmount,
                                  value: money0(order.pendingAmount) ?? none,
                                  color: StatusColors.attended,
                                  valueKey: const Key(
                                    'maintenance-pending-amount',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(28)),
                    Text(
                      l10n.maintDetailsTitle,
                      style: TextStyle(
                        color: const Color(0xFF9AA3C7),
                        fontSize: r.s(16),
                      ),
                    ),
                    SizedBox(height: r.s(14)),
                    KeyedSubtree(
                      key: const Key('maintenance-info'),
                      child: ModuleInfoGrid(
                        items: [
                          ModuleInfo(
                            Icons.route,
                            l10n.maintKmStart,
                            order.kmStart ?? none,
                          ),
                          ModuleInfo(
                            Icons.route,
                            l10n.maintKmEnd,
                            order.kmEnd ?? none,
                          ),
                          ModuleInfo(
                            Icons.fact_check,
                            l10n.maintDirection,
                            order.direction ?? none,
                          ),
                          ModuleInfo(
                            Icons.explore,
                            l10n.maintSense,
                            order.sense ?? none,
                          ),
                          ModuleInfo(
                            Icons.bar_chart,
                            l10n.maintVolumeTotal,
                            '${quantity(locale, order.totalVolume)} ${order.unit}',
                          ),
                          ModuleInfo(
                            Icons.bar_chart,
                            l10n.maintVolumeExecuted,
                            '${quantity(locale, order.executedVolume)} ${order.unit}',
                          ),
                          ModuleInfo(
                            Icons.attach_money,
                            l10n.maintUnitCost,
                            order.unitCost == null
                                ? none
                                : moneyExact(locale, order.unitCost!),
                          ),
                          ModuleInfo(
                            Icons.attach_money,
                            l10n.maintProgrammedAmount,
                            order.programmedAmount == null
                                ? none
                                : moneyExact(locale, order.programmedAmount!),
                          ),
                          ModuleInfo(
                            Icons.calendar_today_outlined,
                            l10n.maintStartDate,
                            order.startDate == null
                                ? none
                                : moduleDay(order.startDate!, zone),
                          ),
                          ModuleInfo(
                            Icons.calendar_today_outlined,
                            l10n.maintEndDate,
                            order.endDate == null
                                ? none
                                : moduleDay(order.endDate!, zone),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ModuleActionBar(
            actions: [
              ModuleActionButton(
                key: const Key('maintenance-action-download'),
                icon: Icons.download,
                tooltip: l10n.ticketActionDownload,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('maintenance-action-edit'),
                icon: Icons.edit,
                tooltip: l10n.ticketActionEdit,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('maintenance-action-add'),
                icon: Icons.add,
                tooltip: l10n.ticketActionFollowUp,
                onTap: () => showActionSoon(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    required this.color,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Color color;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: moduleMuted,
            fontWeight: FontWeight.w700,
            fontSize: r.s(15),
          ),
        ),
        SizedBox(height: r.s(6)),
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: r.s(24),
          ),
        ),
      ],
    );
  }
}
