import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_pills.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/indicator_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../bloc/report_cubit.dart';
import '../reports_labels.dart';
import '../widgets/report_line_card.dart';

/// El reporte de un indicador: periodo, boton para generarlo y el resultado
/// (resumen, importes y los mantenimientos que lo forman).
class ReportPage extends StatelessWidget {
  const ReportPage({super.key, this.sampleData = false});

  /// Los mantenimientos son de ejemplo: se avisa para que nadie los tome por
  /// reales.
  final bool sampleData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final cubit = context.read<ReportCubit>();
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) => Column(
            children: [
              SigacoModuleHeader(
                transparent: true,
                title:
                    '${reportIndicatorCode(cubit.indicator)} · ${reportIndicatorLabel(l10n, cubit.indicator)}',
                subtitle: l10n.repReportSubtitle,
                actions: [
                  ModuleHeaderAction(
                    key: const Key('report-download'),
                    icon: Icons.download,
                    tooltip: l10n.ticketActionDownload,
                    onPressed: state.report == null
                        ? null
                        : () => showActionSoon(context),
                  ),
                ],
              ),
              if (sampleData)
                Container(
                  key: const Key('report-sample-banner'),
                  width: double.infinity,
                  color: StatusColors.attended.withValues(alpha: 0.25),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.s(16),
                    vertical: r.s(6),
                  ),
                  child: Text(
                    l10n.repSampleBanner,
                    style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                  ),
                ),
              _PeriodRow(state: state),
              SizedBox(height: r.s(12)),
              Expanded(
                child: ModuleListSheet(
                  body: _body(context, state),
                  buttonKey: const Key('report-generate'),
                  buttonLabel: state.report == null
                      ? l10n.repGenerate
                      : l10n.repRegenerate,
                  onButton: state.status == ReportStatus.generating
                      ? null
                      : cubit.generate,
                  buttonIcon: Icons.assessment_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ReportState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ReportCubit>();
    switch (state.status) {
      case ReportStatus.generating:
        return const Center(
          key: Key('report-loading'),
          child: CircularProgressIndicator(),
        );
      case ReportStatus.failure:
        return _ErrorView(
          error: state.error ?? ReportError.server,
          onRetry: cubit.generate,
        );
      case ReportStatus.idle:
        return KeyedSubtree(
          key: const Key('report-idle'),
          child: ModuleStateView(
            icon: Icons.assessment_outlined,
            body: l10n.repNotGenerated,
          ),
        );
      case ReportStatus.ready:
        return _Result(report: state.report!, stale: state.stale);
    }
  }
}

/// Desde y hasta, en dos campos blancos.
class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.state});

  final ReportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<ReportCubit>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
      child: Row(
        children: [
          Expanded(
            child: ModuleDatePill(
              key: const Key('report-from'),
              tooltip: l10n.repFrom,
              hint: '${l10n.repFrom}: ${l10n.repDateHint}',
              day: state.from,
              onTap: () async {
                final day = await ModuleDatePill.pick(context, state.from);
                if (day != null) cubit.setFrom(day);
              },
              onClear: () => cubit.setFrom(null),
              clearKey: const Key('report-from-clear'),
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            child: ModuleDatePill(
              key: const Key('report-to'),
              tooltip: l10n.repTo,
              hint: '${l10n.repTo}: ${l10n.repDateHint}',
              day: state.to,
              onTap: () async {
                final day = await ModuleDatePill.pick(context, state.to);
                if (day != null) cubit.setTo(day);
              },
              onClear: () => cubit.setTo(null),
              clearKey: const Key('report-to-clear'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.report, required this.stale});

  final IndicatorReport report;
  final bool stale;

  String _period(BuildContext context, AppLocalizations l10n) {
    final from = report.from;
    final to = report.to;
    if (from != null && to != null) {
      return l10n.repPeriodRange(
        formatCalendarDay(context, from),
        formatCalendarDay(context, to),
      );
    }
    if (from != null) {
      return l10n.repPeriodFrom(formatCalendarDay(context, from));
    }
    if (to != null) return l10n.repPeriodUntil(formatCalendarDay(context, to));
    return l10n.repPeriodAll;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      key: const Key('report-result'),
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Responsive.formMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stale)
                  Padding(
                    padding: EdgeInsets.only(bottom: r.s(12)),
                    child: Text(
                      l10n.repStale,
                      key: const Key('report-stale'),
                      style: TextStyle(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                        fontSize: r.s(14),
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.s(20)),
                  decoration: BoxDecoration(
                    color: moduleSurface,
                    borderRadius: BorderRadius.circular(r.s(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.repSummaryTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.s(20),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: r.s(4)),
                      Text(
                        _period(context, l10n),
                        key: const Key('report-period'),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                      Text(
                        l10n.repGeneratedAt(
                          moduleDate(report.generatedAt, zone),
                        ),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
                      ),
                      SizedBox(height: r.s(16)),
                      Row(
                        children: [
                          _Count(
                            key: const Key('report-count-all'),
                            value: report.total,
                            label: l10n.repTotal,
                            color: Colors.white,
                          ),
                          for (final s in ReportLineStatus.values)
                            _Count(
                              key: Key('report-count-${s.name}'),
                              value: report.count(s),
                              label: switch (s) {
                                ReportLineStatus.open => l10n.repStatusOpen,
                                ReportLineStatus.inProgress =>
                                  l10n.repStatusInProgress,
                                ReportLineStatus.closed => l10n.repStatusClosed,
                              },
                              color: reportStatusColor(s),
                            ),
                        ],
                      ),
                      SizedBox(height: r.s(20)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.repExecution,
                              style: TextStyle(
                                color: moduleMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: r.s(15),
                              ),
                            ),
                          ),
                          Text(
                            percent(report.execution),
                            key: const Key('report-execution'),
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
                          value: report.execution,
                          minHeight: r.s(10),
                          color: StatusColors.closed,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: r.s(16)),
                      Row(
                        children: [
                          _Amount(
                            key: const Key('report-programmed'),
                            label: l10n.repProgrammedAmount,
                            value: money(locale, report.programmedAmount),
                          ),
                          _Amount(
                            key: const Key('report-executed'),
                            label: l10n.repExecutedAmount,
                            value: money(locale, report.executedAmount),
                            color: context.palette.accent,
                          ),
                          _Amount(
                            key: const Key('report-pending'),
                            label: l10n.repPendingAmount,
                            value: money(locale, report.pendingAmount),
                            color: StatusColors.attended,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.s(24)),
                Text(
                  l10n.repOrdersTitle,
                  style: TextStyle(
                    color: moduleSurface,
                    fontSize: r.s(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: r.s(12)),
                if (report.lines.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: r.s(16)),
                    child: Text(
                      l10n.repEmpty,
                      key: const Key('report-empty'),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                else
                  for (final o in report.lines)
                    ReportLineCard(
                      line: o,
                      zone: zone,
                      onTap: () => context.push(
                        '/maintenance/${o.indicator.name}/${o.id}',
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: r.s(26),
              fontWeight: FontWeight.w800,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(color: moduleMuted, fontSize: r.s(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    super.key,
    required this.label,
    required this.value,
    this.color = Colors.white,
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
                fontSize: r.s(18),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(color: moduleMuted, fontSize: r.s(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final ReportError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, body, retry) = switch (error) {
      ReportError.notAvailable => (
        Icons.assessment_outlined,
        l10n.repUnavailableTitle,
        l10n.repUnavailableBody,
        false,
      ),
      ReportError.permissionDenied => (
        Icons.lock_outline,
        l10n.repNoPermissionTitle,
        l10n.repNoPermissionBody,
        false,
      ),
      ReportError.network || ReportError.server => (
        Icons.cloud_off_outlined,
        l10n.repErrorTitle,
        l10n.repErrorBody,
        true,
      ),
    };
    return KeyedSubtree(
      key: Key('report-state-${error.name}'),
      child: ModuleStateView(
        icon: icon,
        title: title,
        body: body,
        retryLabel: retry ? l10n.repRetry : null,
        onRetry: onRetry,
        retryKey: const Key('report-retry'),
      ),
    );
  }
}
