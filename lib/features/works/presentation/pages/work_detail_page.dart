import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/public_work.dart';
import '../../domain/repositories/works_repository.dart';
import '../bloc/work_detail_cubit.dart';
import '../widgets/work_widgets.dart';
import '../works_labels.dart';

/// La ficha de una obra: avance fisico contra programado, importes y datos.
class WorkDetailPage extends StatelessWidget {
  const WorkDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<WorkDetailCubit, WorkDetailState>(
      builder: (context, state) {
        final work = state.work;
        if (work != null) return _Detail(work: work);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.workDetailTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == WorkDetailStatus.failure
                      ? WorksStateView(
                          error: state.error ?? WorksError.server,
                          onRetry: context.read<WorkDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('work-detail-loading'),
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
  const _Detail({required this.work});

  final PublicWork work;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final locale = Localizations.localeOf(context).toString();
    const none = '—';
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
                  key: const Key('work-detail'),
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        child: Row(
                          children: [
                            const ModuleBackPill(key: Key('work-detail-back')),
                            const Spacer(),
                            ModuleStatusPill(
                              key: const Key('work-detail-status'),
                              label: workStatusLabel(l10n, work.status),
                              color: workStatusColor(work.status),
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
                            work.name,
                            key: const Key('work-detail-title'),
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
                          if (work.description != null) ...[
                            SizedBox(height: r.s(10)),
                            Text(
                              work.description!,
                              style: TextStyle(
                                color: moduleMuted,
                                fontSize: r.s(16),
                              ),
                            ),
                          ],
                          SizedBox(height: r.s(20)),
                          _ProgressRow(
                            label: l10n.workPhysical,
                            value: percent(work.physicalProgress),
                            valueKey: const Key('work-detail-physical'),
                          ),
                          SizedBox(height: r.s(8)),
                          WorkProgressBar(
                            physical: work.physicalProgress,
                            programmed: work.programmedProgress,
                          ),
                          SizedBox(height: r.s(12)),
                          _ProgressRow(
                            label: l10n.workProgrammed,
                            value: percent(work.programmedProgress),
                            valueKey: const Key('work-detail-programmed'),
                          ),
                          SizedBox(height: r.s(10)),
                          Text(
                            work.lag > 0
                                ? l10n.workLag(percent(work.lag))
                                : l10n.workOnTrack,
                            key: const Key('work-detail-lag'),
                            style: TextStyle(
                              color: workStatusColor(
                                work.lag > 0
                                    ? WorkStatus.delayed
                                    : WorkStatus.finished,
                              ),
                              fontWeight: FontWeight.w800,
                              fontSize: r.s(15),
                            ),
                          ),
                          if (work.budget != null) ...[
                            SizedBox(height: r.s(24)),
                            Row(
                              children: [
                                _Amount(
                                  key: const Key('work-detail-budget'),
                                  label: l10n.workBudget,
                                  value: money(locale, work.budget!),
                                  color: Colors.white,
                                ),
                                _Amount(
                                  key: const Key('work-detail-executed'),
                                  label: l10n.workExecutedAmount,
                                  value: money(
                                    locale,
                                    work.executedAmount ?? 0,
                                  ),
                                  color: p.accent,
                                ),
                                _Amount(
                                  key: const Key('work-detail-pending'),
                                  label: l10n.workPendingAmount,
                                  value: money(locale, work.pendingAmount ?? 0),
                                  color: workStatusColor(WorkStatus.inProgress),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(28)),
                    Text(
                      l10n.workDetailsTitle,
                      style: TextStyle(
                        color: const Color(0xFF9AA3C7),
                        fontSize: r.s(16),
                      ),
                    ),
                    SizedBox(height: r.s(14)),
                    KeyedSubtree(
                      key: const Key('work-info'),
                      child: ModuleInfoGrid(
                        items: [
                          ModuleInfo(
                            Icons.business_outlined,
                            l10n.workContractor,
                            work.contractor ?? none,
                          ),
                          ModuleInfo(
                            Icons.fact_check,
                            l10n.workSegment,
                            work.segmentCode ?? none,
                          ),
                          ModuleInfo(
                            Icons.route,
                            l10n.workKmStart,
                            work.kmStart ?? none,
                          ),
                          ModuleInfo(
                            Icons.route,
                            l10n.workKmEnd,
                            work.kmEnd ?? none,
                          ),
                          ModuleInfo(
                            Icons.explore,
                            l10n.workDirection,
                            work.direction ?? none,
                          ),
                          ModuleInfo(
                            Icons.calendar_today_outlined,
                            l10n.workStartDate,
                            work.startDate == null
                                ? none
                                : moduleCalendarDay(work.startDate!),
                          ),
                          ModuleInfo(
                            Icons.event_available_outlined,
                            l10n.workEndDate,
                            work.endDate == null
                                ? none
                                : moduleCalendarDay(work.endDate!),
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
                key: const Key('work-action-map'),
                icon: Icons.map_outlined,
                tooltip: l10n.workViewOnMap,
                onTap: () {
                  if (!work.hasLocation) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.workNoLocation)),
                      );
                    return;
                  }
                  context.push(
                    Uri(
                      path: '/map',
                      queryParameters: {'layer': 'works', 'pin': work.id},
                    ).toString(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: moduleMuted,
              fontWeight: FontWeight.w700,
              fontSize: r.s(15),
            ),
          ),
        ),
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: r.s(18),
          ),
        ),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: r.s(20),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
            ),
          ),
        ],
      ),
    );
  }
}
