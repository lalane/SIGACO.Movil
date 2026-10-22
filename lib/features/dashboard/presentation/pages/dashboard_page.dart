import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../bloc/dashboard_cubit.dart';

/// El resumen operativo (APP-MOB-04): un bloque por modulo con sus cifras, que
/// abre el modulo, y un acceso al mapa.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.sampleData = false});

  /// Los datos son de ejemplo: se avisa para que nadie los tome por reales.
  final bool sampleData;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: ModuleGradient(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final summary = state.summary;
            final zone = context.watch<ConcessionZoneCubit>().state;
            return Column(
              children: [
                SigacoModuleHeader(
                  transparent: true,
                  title: l10n.dashTitle,
                  subtitle: summary == null
                      ? l10n.dashSubtitle
                      : l10n.dashUpdated(moduleDate(summary.generatedAt, zone)),
                ),
                if (widget.sampleData)
                  Container(
                    key: const Key('dashboard-sample-banner'),
                    width: double.infinity,
                    color: StatusColors.attended.withValues(alpha: 0.25),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.s(16),
                      vertical: r.s(6),
                    ),
                    child: Text(
                      l10n.dashSampleBanner,
                      style: TextStyle(fontSize: r.s(12), color: p.textOnTop),
                    ),
                  ),
                SizedBox(height: r.s(12)),
                Expanded(
                  child: ModuleListSheet(
                    body: _body(context, state),
                    buttonKey: const Key('dashboard-map'),
                    buttonLabel: l10n.dashViewMap,
                    buttonIcon: Icons.map_outlined,
                    onButton: () => context.push('/map'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final cubit = context.read<DashboardCubit>();
    final summary = state.summary;
    if (state.status == DashboardStatus.loading) {
      return const Center(
        key: Key('dashboard-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (summary == null) {
      return KeyedSubtree(
        key: const Key('dashboard-error'),
        child: ModuleStateView(
          icon: Icons.cloud_off_outlined,
          title: l10n.dashErrorTitle,
          body: l10n.dashErrorBody,
          retryLabel: l10n.dashRetry,
          onRetry: cubit.load,
          retryKey: const Key('dashboard-retry'),
        ),
      );
    }
    if (summary.isEmpty &&
        summary.errors.values.every((e) => e == DashboardError.notAvailable)) {
      return KeyedSubtree(
        key: const Key('dashboard-unavailable'),
        child: ModuleStateView(
          icon: Icons.dashboard_outlined,
          title: l10n.dashUnavailableTitle,
          body: l10n.dashUnavailableBody,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        key: const Key('dashboard-list'),
        padding: EdgeInsets.fromLTRB(r.s(16), r.s(20), r.s(16), r.s(8)),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Responsive.formMaxWidth,
              ),
              child: Column(
                children: [
                  _compliance(context, summary),
                  _tickets(context, summary),
                  _accidents(context, summary),
                  _maintenance(context, summary),
                  _inventory(context, summary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compliance(BuildContext context, DashboardSummary s) =>
      _ComplianceCard(
        compliance: s.compliance,
        error: s.errors[DashboardSection.compliance],
        creators: s.tickets?.creators ?? const [],
      );

  Widget _tickets(BuildContext context, DashboardSummary s) {
    final l10n = AppLocalizations.of(context);
    final t = s.tickets;
    return _SectionCard(
      section: DashboardSection.tickets,
      icon: Icons.confirmation_number_outlined,
      title: l10n.dashTickets,
      route: '/tickets',
      error: s.errors[DashboardSection.tickets],
      figures: t == null
          ? const []
          : [
              _Figure('open', t.open, l10n.dashTicketsOpen, StatusColors.open),
              _Figure(
                'attended',
                t.attended,
                l10n.dashTicketsAttended,
                StatusColors.attended,
              ),
              _Figure(
                'overdue',
                t.overdue,
                l10n.dashTicketsOverdue,
                StatusColors.open,
              ),
            ],
    );
  }

  Widget _accidents(BuildContext context, DashboardSummary s) {
    final l10n = AppLocalizations.of(context);
    final a = s.accidents;
    return _SectionCard(
      section: DashboardSection.accidents,
      icon: Icons.warning_amber_rounded,
      title: l10n.dashAccidents,
      subtitle: l10n.dashAccidentsPeriod(AccidentsSummary.days),
      route: '/accidents',
      error: s.errors[DashboardSection.accidents],
      figures: a == null
          ? const []
          : [
              _Figure(
                'recent',
                a.recent,
                l10n.dashAccidentsTotal,
                Colors.white,
              ),
              _Figure(
                'severe',
                a.severe,
                l10n.dashAccidentsSevere,
                StatusColors.open,
              ),
              _Figure(
                'follow-up',
                a.inFollowUp,
                l10n.dashAccidentsOpen,
                StatusColors.attended,
              ),
            ],
    );
  }

  Widget _maintenance(BuildContext context, DashboardSummary s) {
    final l10n = AppLocalizations.of(context);
    final m = s.maintenance;
    final locale = Localizations.localeOf(context).toString();
    return _SectionCard(
      section: DashboardSection.maintenance,
      icon: Icons.build_outlined,
      title: l10n.dashMaintenance,
      subtitle: m == null
          ? null
          : l10n.dashMaintExecution('${(m.execution * 100).round()}%'),
      route: '/maintenance',
      error: s.errors[DashboardSection.maintenance],
      progress: m?.execution,
      figures: m == null
          ? const []
          : [
              _Figure('open', m.open, l10n.dashMaintOpen, StatusColors.open),
              _Figure(
                'in-progress',
                m.inProgress,
                l10n.dashMaintInProgress,
                StatusColors.attended,
              ),
              _Figure(
                'closed',
                m.closed,
                l10n.dashMaintClosed,
                StatusColors.closed,
              ),
            ],
      locale: locale,
    );
  }

  Widget _inventory(BuildContext context, DashboardSummary s) {
    final l10n = AppLocalizations.of(context);
    final i = s.inventory;
    return _SectionCard(
      section: DashboardSection.inventory,
      icon: Icons.inventory_2_outlined,
      title: l10n.dashInventory,
      subtitle: i == null ? null : l10n.dashInventoryTotal(i.total),
      route: '/inventory',
      error: s.errors[DashboardSection.inventory],
      figures: i == null
          ? const []
          : [
              _Figure('good', i.good, l10n.dashInvGood, StatusColors.closed),
              _Figure(
                'regular',
                i.regular,
                l10n.dashInvRegular,
                StatusColors.attended,
              ),
              _Figure('poor', i.poor, l10n.dashInvPoor, StatusColors.open),
            ],
    );
  }
}

Color _statusColor(IndicatorStatus s) => switch (s) {
  IndicatorStatus.good => StatusColors.closed,
  IndicatorStatus.intermediate => StatusColors.attended,
  IndicatorStatus.bad => StatusColors.open,
  IndicatorStatus.inProcess => const Color(0xFF94A3B8),
};

String _statusLabel(AppLocalizations l10n, IndicatorStatus s) => switch (s) {
  IndicatorStatus.good => l10n.dashStatusGood,
  IndicatorStatus.intermediate => l10n.dashStatusIntermediate,
  IndicatorStatus.bad => l10n.dashStatusBad,
  IndicatorStatus.inProcess => l10n.dashStatusInProcess,
};

/// El nombre de un indicador a partir de su codigo; uno que la app no conoce se
/// muestra tal cual, en mayusculas.
String _indicatorName(AppLocalizations l10n, String code) => switch (code) {
  'sgp' => l10n.maintIndSgp,
  'sgs' => l10n.maintIndSgs,
  'sgoae' => l10n.maintIndSgoae,
  'sgoac' => l10n.maintIndSgoac,
  'sgits' => l10n.maintIndSgits,
  'conservacion' => l10n.maintIndConservacion,
  'sge' => l10n.maintIndSge,
  'sgtec' => l10n.maintIndSgtec,
  'sgsei' => l10n.maintIndSgsei,
  'sgost' => l10n.maintIndSgost,
  'sgf' => l10n.maintIndSgf,
  _ => code.toUpperCase(),
};

/// Cumplimiento general y por indicador, y quienes mas tickets generaron (BBP
/// §7.8). Las cifras de cumplimiento las calcula el servidor.
class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.compliance,
    required this.error,
    required this.creators,
  });

  final ComplianceSummary? compliance;
  final DashboardError? error;
  final List<TicketCreator> creators;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final c = compliance;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('dashboard-compliance'),
          onTap: () => context.push('/reports'),
          child: Padding(
            padding: EdgeInsets.all(r.s(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: r.s(44),
                      height: r.s(44),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Icon(
                        Icons.speed_outlined,
                        color: p.accentOnDark,
                        size: r.s(24),
                      ),
                    ),
                    SizedBox(width: r.s(14)),
                    Expanded(
                      child: Text(
                        l10n.dashCompliance,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.s(19),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: moduleMuted),
                  ],
                ),
                SizedBox(height: r.s(16)),
                if (c == null)
                  Row(
                    key: const Key('dashboard-compliance-error'),
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: moduleMuted,
                        size: r.s(20),
                      ),
                      SizedBox(width: r.s(8)),
                      Expanded(
                        child: Text(
                          switch (error) {
                            DashboardError.permissionDenied =>
                              l10n.dashSectionNoPermission,
                            DashboardError.network ||
                            DashboardError.server => l10n.dashSectionError,
                            _ => l10n.dashComplianceUnavailable,
                          },
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(14),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${c.overall.round()}%',
                        key: const Key('dashboard-compliance-overall'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.s(40),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: r.s(12)),
                      Padding(
                        padding: EdgeInsets.only(bottom: r.s(4)),
                        child: ModuleStatusPill(
                          key: const Key('dashboard-compliance-status'),
                          label: _statusLabel(l10n, c.overallStatus),
                          color: _statusColor(c.overallStatus),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.s(8)),
                  Text(
                    l10n.dashComplianceMet(c.met, c.total),
                    key: const Key('dashboard-compliance-met'),
                    style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                  ),
                  SizedBox(height: r.s(14)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.s(8),
                    children: [
                      for (final s in IndicatorStatus.values)
                        Chip(
                          key: Key('dashboard-compliance-${s.name}'),
                          avatar: CircleAvatar(
                            backgroundColor: _statusColor(s),
                            radius: r.s(6),
                          ),
                          label: Text(
                            '${_statusLabel(l10n, s)}: ${c.count(s)}',
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          labelStyle: const TextStyle(color: Colors.white),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  if (c.ticketsBySubsystem.isNotEmpty) ...[
                    SizedBox(height: r.s(18)),
                    Text(
                      l10n.dashTicketsBySubsystem,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.s(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: r.s(8)),
                    for (final s in c.ticketsBySubsystem)
                      _BarRow(
                        key: Key('dashboard-subsystem-${s.code}'),
                        label: _indicatorName(l10n, s.code),
                        value: s.count,
                        max: c.ticketsBySubsystem.first.count,
                      ),
                  ],
                ],
                if (creators.isNotEmpty) ...[
                  SizedBox(height: r.s(18)),
                  Text(
                    l10n.dashTopCreators,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: r.s(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: r.s(8)),
                  for (var i = 0; i < creators.length; i++)
                    _BarRow(
                      key: Key('dashboard-creator-$i'),
                      label: creators[i].name,
                      value: creators[i].count,
                      max: creators.first.count,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una barra horizontal con su etiqueta y su cifra.
class _BarRow extends StatelessWidget {
  const _BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(6)),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
            ),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r.s(6)),
              child: LinearProgressIndicator(
                minHeight: r.s(10),
                value: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: p.accent,
              ),
            ),
          ),
          SizedBox(width: r.s(8)),
          Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: r.s(13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure {
  const _Figure(this.id, this.value, this.label, this.color);

  final String id;
  final int value;
  final String label;
  final Color color;
}

/// El bloque de un modulo: titulo, cifras (o por que no hay) y un toque abre el
/// modulo.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.icon,
    required this.title,
    required this.route,
    required this.figures,
    this.subtitle,
    this.error,
    this.progress,
    this.locale,
  });

  final DashboardSection section;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;
  final DashboardError? error;
  final List<_Figure> figures;

  /// Avance de 0 a 1 que se dibuja como barra debajo de las cifras.
  final double? progress;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final e = error;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(r.s(28)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('dashboard-${section.name}'),
          onTap: () => context.push(route),
          child: Padding(
            padding: EdgeInsets.all(r.s(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: r.s(44),
                      height: r.s(44),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(r.s(12)),
                      ),
                      child: Icon(icon, color: p.accentOnDark, size: r.s(24)),
                    ),
                    SizedBox(width: r.s(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.s(19),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              key: Key('dashboard-${section.name}-subtitle'),
                              style: TextStyle(
                                color: moduleMuted,
                                fontSize: r.s(13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: moduleMuted),
                  ],
                ),
                SizedBox(height: r.s(16)),
                if (e != null)
                  Row(
                    key: Key('dashboard-${section.name}-error'),
                    children: [
                      Icon(
                        e == DashboardError.permissionDenied
                            ? Icons.lock_outline
                            : Icons.info_outline,
                        color: moduleMuted,
                        size: r.s(20),
                      ),
                      SizedBox(width: r.s(8)),
                      Expanded(
                        child: Text(
                          switch (e) {
                            DashboardError.notAvailable =>
                              l10n.dashSectionUnavailable,
                            DashboardError.permissionDenied =>
                              l10n.dashSectionNoPermission,
                            DashboardError.network ||
                            DashboardError.server => l10n.dashSectionError,
                          },
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(14),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      for (final f in figures)
                        Expanded(
                          child: Column(
                            key: Key('dashboard-${section.name}-${f.id}'),
                            children: [
                              Text(
                                '${f.value}',
                                style: TextStyle(
                                  color: f.color,
                                  fontSize: r.s(28),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  f.label,
                                  style: TextStyle(
                                    color: moduleMuted,
                                    fontSize: r.s(13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    SizedBox(height: r.s(14)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(r.s(4)),
                      child: LinearProgressIndicator(
                        key: Key('dashboard-${section.name}-progress'),
                        value: progress,
                        minHeight: r.s(6),
                        color: p.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
