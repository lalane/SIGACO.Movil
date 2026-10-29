import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/responsive/responsive.dart';
import '../../features/alerts/presentation/bloc/alerts_cubit.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/navigation/domain/entities/mobile_module.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../../l10n/app_localizations.dart';

/// El carrusel de resumen del menu (mockup): una tarjeta por modulo que la
/// persona puede ver, con lo abierto a la vista y una linea de contexto. Sale
/// del mismo resumen del panel; lo que no se pudo armar se ve como "—" en vez de
/// desaparecer.
class HomeSummary extends StatefulWidget {
  const HomeSummary({super.key});

  @override
  State<HomeSummary> createState() => _HomeSummaryState();
}

class _HomeSummaryState extends State<HomeSummary> {
  DashboardSummary? _summary;
  PageController? _pages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = context.read<DashboardRepository>();
    try {
      final summary = await repository.load();
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // Sin resumen las tarjetas muestran "—": el menu sigue igual.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final menu = context.select((NavigationBloc b) => b.state.menu);
    final unread = context.select((AlertsCubit c) => c.state.unread);
    final summary = _summary;
    const none = '—';
    final tickets = summary?.tickets;
    final accidents = summary?.accidents;
    final cards = <Widget>[
      if (MobileModule.tickets.isAvailableIn(menu))
        _SummaryCard(
          key: const Key('home-summary-tickets'),
          value: tickets?.open.toString() ?? none,
          label: l10n.homeSummaryTickets,
          caption: tickets == null
              ? null
              : tickets.overdue > 0
              ? l10n.homeSummaryOverdue(tickets.overdue)
              : l10n.homeSummaryOnTime,
          color: (tickets?.overdue ?? 0) > 0
              ? const Color(0xFFEF4444)
              : const Color(0xFF22C55E),
        ),
      if (MobileModule.inventory.isAvailableIn(menu))
        _SummaryCard(
          key: const Key('home-summary-assets'),
          value: summary?.inventory?.total.toString() ?? none,
          label: l10n.homeSummaryAssets,
          color: const Color(0xFF38BDF8),
        ),
      if (MobileModule.accidents.isAvailableIn(menu))
        _SummaryCard(
          key: const Key('home-summary-accidents'),
          value: accidents?.recent.toString() ?? none,
          label: l10n.homeSummaryAccidents,
          caption: accidents == null
              ? null
              : l10n.homeSummaryInProgress(accidents.inFollowUp),
          color: const Color(0xFFF87171),
        ),
      // Las alertas no dependen del resumen: son las que siguen sin leer.
      if (MobileModule.alerts.isAvailableIn(menu))
        _SummaryCard(
          key: const Key('home-summary-alerts'),
          value: '$unread',
          label: l10n.homeSummaryAlerts,
          caption: unread > 0
              ? l10n.homeSummaryUnread(unread)
              : l10n.homeSummaryOnTime,
          color: unread > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    // Con texto grande las tarjetas crecen: la franja no se queda corta.
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    // Carrusel: se desliza de lado y se detiene en cada tarjeta, todas del mismo
    // tamano; las de los lados asoman.
    final pages = _pages ??= PageController(
      viewportFraction: 0.44,
      initialPage: (cards.length - 1) ~/ 2,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(24)),
      child: SizedBox(
        height: r.s(118) * textScale,
        child: PageView.builder(
          key: const Key('home-summary'),
          controller: pages,
          padEnds: true,
          itemCount: cards.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(6)),
            child: cards[i],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.caption,
  });

  final String value;
  final String label;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.s(18)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: r.s(30),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF1E293B),
              fontSize: r.s(13),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: r.s(11),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
