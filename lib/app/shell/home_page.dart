import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/sigaco_wordmark.dart';
import '../../core/offline/sync_cubit.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/sigaco_palette.dart';
import '../../core/theme/status_colors.dart';
import '../../core/ui/access_state_view.dart';
import '../../features/alerts/presentation/bloc/alerts_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/branding/presentation/widgets/concession_logo.dart';
import '../../features/navigation/domain/entities/mobile_module.dart';
import '../../features/navigation/domain/entities/navigation_entities.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';
import '../feature_flags.dart';
import '../../l10n/app_localizations.dart';

/// Menu principal (diseno v2). Los modulos salen de `/api/context/navigation`:
/// solo aparece lo que el perfil, el acceso funcional y el cliente movil permiten.
/// Es parte del shell porque compone los modulos.
///
/// Responsivo (mismas piezas del mockup, recompuestas por ancho):
///  - compacta: barra inferior y 2 columnas;
///  - media: riel lateral y 3 columnas;
///  - expandida: riel lateral y 4 columnas.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // El estado con la oferta ya existe cuando esta pantalla aparece (el login
    // lo emite antes de navegar): un listener solo veria cambios posteriores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthBloc>().state.offerBiometric) {
        _askBiometric(context);
      }
    });
  }

  Future<void> _askBiometric(BuildContext context) async {
    if (_asking) return;
    _asking = true;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AuthBloc>();
    final accept = await showDialog<bool>(
      context: context,
      // Tocar fuera no debe contar como "Ahora no": ese rechazo es permanente.
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.biometricEnableTitle),
        content: Text(l10n.biometricEnableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.biometricNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.biometricEnable),
          ),
        ],
      ),
    );
    _asking = false;
    bloc.add(
      AuthBiometricOfferAnswered(
        accepted: accept == true,
        reason: l10n.biometricReason,
        // Sin elegir (boton atras): se pospone, no se rechaza para siempre.
        persistDecline: accept != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (a, b) => !a.offerBiometric && b.offerBiometric,
          listener: (context, _) => _askBiometric(context),
        ),
        // Si los accesos cambiaron durante la sesion, se avisa (M02-02-04).
        BlocListener<NavigationBloc, NavigationState>(
          listenWhen: (a, b) => b.accessChanges > a.accessChanges,
          listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).accessChangedNotice),
            ),
          ),
        ),
      ],
      child: Scaffold(
        extendBody: r.isCompact,
        body: Row(
          // El riel y el contenido ocupan toda la altura.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (r.useRail) const _SideRail(key: Key('home-rail')),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.gradientTop, p.menuBottom],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: r.homeMaxWidth),
                      child: Column(
                        children: [
                          const _Header(),
                          Expanded(
                            child: BlocBuilder<NavigationBloc, NavigationState>(
                              builder: (context, nav) => _Content(state: nav),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: r.isCompact
            ? const _BottomBar(key: Key('home-bottom-bar'))
            : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final name = context.select((AuthBloc b) => b.state.user?.fullName ?? '');
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(12), 0),
      child: Row(
        children: [
          // Ocupa el espacio sobrante; si el texto del sistema es grande, el
          // lema se reduce para no empujar los botones fuera de la pantalla.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo de la concesion activa arriba de SIGACO, en la variante
                // para fondo oscuro; sin logo no ocupa espacio.
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConcessionLogo(
                    height: r.s(34),
                    darkBackground: true,
                    // La variante reducida, si la concesion la tiene (US-07).
                    preferReduced: true,
                    semanticLabel: context.select(
                      (AuthBloc b) => b.state.activeConcessionName,
                    ),
                  ),
                ),
                SigacoWordmark(fontSize: r.s(30)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.appTaglineShort,
                    maxLines: 1,
                    style: TextStyle(
                      color: p.textOnTop.withValues(alpha: 0.8),
                      fontSize: r.s(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _AlertsBell(),
          SizedBox(width: r.s(4)),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/account'),
            child: CircleAvatar(
              radius: r.s(20),
              backgroundColor: p.accent,
              child: Text(
                _initials(name),
                style: TextStyle(
                  color: p.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: r.s(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    final letters = parts.take(2).map((s) => s[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

/// La campana de la cabecera: lleva a las alertas y cuenta las que siguen sin
/// leer. Siempre se ve: la bandeja de notificaciones es de la persona y no
/// depende de un modulo del menu.
class _AlertsBell extends StatelessWidget {
  const _AlertsBell();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final unread = context.select((AlertsCubit c) => c.state.unread);
    return IconButton(
      key: const Key('home-alerts-bell'),
      tooltip: l10n.navAlerts,
      onPressed: () => context.push('/alerts'),
      icon: Badge(
        key: const Key('bell-badge'),
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          Icons.notifications_none,
          color: p.textOnTop,
          size: r.s(26),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final NavigationState state;

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning;
    if (h < 19) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final name = context.select((AuthBloc b) => b.state.user?.fullName ?? '');
    final concession = context.select(
      (AuthBloc b) => b.state.activeConcessionName,
    );

    Widget body;
    switch (state.status) {
      case NavigationStatus.idle:
      case NavigationStatus.loading:
        body = Padding(
          padding: EdgeInsets.all(r.s(48)),
          child: const Center(child: CircularProgressIndicator()),
        );
      case NavigationStatus.failure:
        void retry() =>
            context.read<NavigationBloc>().add(const NavigationRequested());
        body = switch (state.error) {
          // El servidor dice que ya no hay nada que este usuario pueda ver.
          NavigationError.permissionDenied => AccessStateView(
            issue: AccessIssue.noPermission,
            title: l10n.accessNoPermissionTitle,
            message: l10n.accessNoPermissionBody,
            primaryLabel: l10n.retry,
            onPrimary: retry,
            secondaryLabel: l10n.signOut,
            onSecondary: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
          // No se pudieron comprobar los accesos (fallo del servidor).
          NavigationError.server => AccessStateView(
            issue: AccessIssue.authorizationError,
            title: l10n.accessErrorTitle,
            message: l10n.accessErrorBody,
            primaryLabel: l10n.retry,
            onPrimary: retry,
          ),
          // Sin conexion u otro fallo: solo se puede reintentar.
          _ => Padding(
            padding: EdgeInsets.all(r.s(32)),
            child: Column(
              children: [
                Text(
                  l10n.menuLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textOnBottom, fontSize: r.s(14)),
                ),
                TextButton(onPressed: retry, child: Text(l10n.retry)),
              ],
            ),
          ),
        };
      case NavigationStatus.ready:
        final flags = context.read<FeatureFlags>();
        final modules = [
          for (final m in MobileModule.availableIn(state.menu))
            // Las alertas no son una tarjeta: se ven en la campana de la cabecera.
            if (m != MobileModule.alerts &&
                (m != MobileModule.documents || flags.documents))
              m,
        ];
        body = modules.isEmpty
            ? AccessStateView(
                issue: AccessIssue.noPermission,
                title: l10n.accessNoPermissionTitle,
                message: l10n.menuEmpty,
                primaryLabel: l10n.retry,
                onPrimary: () => context.read<NavigationBloc>().add(
                  const NavigationRefreshed(gap: Duration.zero),
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: r.s(20)),
                child: _ModuleGrid(modules: modules),
              );
    }

    // Jalar hacia abajo vuelve a consultar los accesos (M01-05, M02-02-04).
    return RefreshIndicator(
      color: p.accentOnBottom,
      backgroundColor: p.card,
      onRefresh: () => _refreshAccess(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // En compacta la barra inferior flota sobre el contenido (extendBody).
        padding: EdgeInsets.only(bottom: r.isCompact ? 96 : r.s(32)),
        children: [
          const _SyncStrip(),
          Padding(
            padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(24)),
            child: Container(
              padding: EdgeInsets.all(r.s(20)),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(r.s(22)),
                border: Border.all(color: p.hint.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(l10n),
                          style: TextStyle(
                            color: p.textOnTop.withValues(alpha: 0.8),
                            fontSize: r.s(14),
                          ),
                        ),
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontVariations: const [FontVariation('wght', 800)],
                            fontSize: r.s(24),
                            color: p.textOnTop,
                          ),
                        ),
                        // La cabecera refleja el contexto activo (DTF, flujo de acceso, paso 10).
                        if (concession != null)
                          Padding(
                            padding: EdgeInsets.only(top: r.s(2)),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.apartment_outlined,
                                  size: r.s(15),
                                  color: p.textOnTop.withValues(alpha: 0.8),
                                ),
                                SizedBox(width: r.s(6)),
                                Flexible(
                                  child: Text(
                                    concession,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.textOnTop.withValues(alpha: 0.8),
                                      fontSize: r.s(13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: r.s(4)),
                        Text(
                          l10n.homeQuestion,
                          style: TextStyle(
                            color: p.accentOnDark,
                            fontSize: r.s(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              l10n.modulesTitle,
              style: TextStyle(
                color: p.textOnTop,
                fontSize: r.s(14),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: r.s(14)),
          body,
        ],
      ),
    );
  }

  /// Espera a que termine la consulta para cerrar el indicador; si no hay nada
  /// que consultar (cargando o sin sesion) no se queda esperando.
  Future<void> _refreshAccess(BuildContext context) async {
    final bloc = context.read<NavigationBloc>();
    final status = bloc.state.status;
    if (status == NavigationStatus.idle || status == NavigationStatus.loading) {
      return;
    }
    bloc.add(const NavigationRefreshed(gap: Duration.zero));
    await bloc.stream
        .firstWhere((s) => !s.refreshing)
        .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state);
  }
}

IconData _iconFor(MobileModule m) => switch (m) {
  MobileModule.map => Icons.map_outlined,
  MobileModule.dashboard => Icons.dashboard_outlined,
  MobileModule.accidents => Icons.warning_amber_rounded,
  MobileModule.maintenance => Icons.build_outlined,
  MobileModule.inventory => Icons.inventory_2_outlined,
  MobileModule.reports => Icons.description_outlined,
  MobileModule.tickets => Icons.confirmation_number_outlined,
  MobileModule.alerts => Icons.notifications_active_outlined,
  MobileModule.inspections => Icons.fact_check_outlined,
  MobileModule.works => Icons.engineering_outlined,
  MobileModule.documents => Icons.folder_open_outlined,
};

(String, String) _labelsFor(AppLocalizations l, MobileModule m) => switch (m) {
  MobileModule.map => (l.moduleMap, l.moduleMapSub),
  MobileModule.dashboard => (l.moduleDashboard, l.moduleDashboardSub),
  MobileModule.accidents => (l.moduleAccidents, l.moduleAccidentsSub),
  MobileModule.maintenance => (l.moduleMaintenance, l.moduleMaintenanceSub),
  MobileModule.inventory => (l.moduleInventory, l.moduleInventorySub),
  MobileModule.reports => (l.moduleReports, l.moduleReportsSub),
  MobileModule.tickets => (l.moduleTickets, l.moduleTicketsSub),
  MobileModule.alerts => (l.moduleAlerts, l.moduleAlertsSub),
  MobileModule.inspections => (l.moduleInspections, l.moduleInspectionsSub),
  MobileModule.works => (l.moduleWorks, l.moduleWorksSub),
  MobileModule.documents => (l.moduleDocuments, l.moduleDocumentsSub),
};

/// Abre el modulo; los que aun no existen avisan que estan en desarrollo.
void _open(BuildContext context, MobileModule module) {
  if (module == MobileModule.documents) {
    context.push('/documents');
    return;
  }
  if (module == MobileModule.map) {
    context.push('/map');
    return;
  }
  if (module == MobileModule.tickets) {
    context.push('/tickets');
    return;
  }
  if (module == MobileModule.accidents) {
    context.push('/accidents');
    return;
  }
  if (module == MobileModule.maintenance) {
    context.push('/maintenance');
    return;
  }
  if (module == MobileModule.inventory) {
    context.push('/inventory');
    return;
  }
  if (module == MobileModule.reports) {
    context.push('/reports');
    return;
  }
  if (module == MobileModule.dashboard) {
    context.push('/dashboard');
    return;
  }
  if (module == MobileModule.inspections) {
    context.push('/inspections');
    return;
  }
  if (module == MobileModule.works) {
    context.push('/works');
    return;
  }
  if (module == MobileModule.alerts) {
    context.push('/alerts');
    return;
  }
  _comingSoon(context);
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).moduleComingSoon)),
  );
}

/// Rejilla de modulos. La tarjeta conserva la proporcion del mockup (1,12 de
/// ancho por alto) y crece solo lo necesario si el texto del sistema es grande.
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.modules});

  final List<MobileModule> modules;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = r.moduleColumns;
        final gap = r.s(14);
        final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final content =
            r.s(16) * 2 +
            r.s(34) +
            r.s(8) +
            scaler.scale(r.s(16)) * 1.3 +
            _ModuleCard.subtitleHeight(r, scaler);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: math.max(cell / 1.12, content),
          ),
          children: [for (final m in modules) _ModuleCard(module: m)],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final MobileModule module;

  /// Altura de dos lineas de subtitulo: los titulos quedan alineados aunque
  /// un subtitulo ocupe una sola linea.
  static double subtitleHeight(Responsive r, TextScaler scaler) =>
      scaler.scale(r.s(12.5)) * 1.3 * 2;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final scaler = MediaQuery.textScalerOf(context);
    final (title, subtitle) = _labelsFor(AppLocalizations.of(context), module);
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(r.s(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(22)),
        onTap: () => _open(context, module),
        child: Padding(
          padding: EdgeInsets.all(r.s(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(module), color: p.accentIconOnLight, size: r.s(34)),
              const Spacer(),
              // Una sola linea: si el titulo no cabe, se reduce en vez de partirse.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: r.s(16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: subtitleHeight(r, scaler),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: r.s(12.5),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destinos de la navegacion principal (los mismos en barra y en riel).
class _NavEntry {
  const _NavEntry(
    this.icon,
    this.label,
    this.onTap, {
    this.selected = false,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Cuantas hay por atender (alertas sin leer); 0 no muestra nada.
  final int badge;
}

List<_NavEntry> _navEntries(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final menu = context.select((NavigationBloc b) => b.state.menu);
  final unreadAlerts = context.select((AlertsCubit c) => c.state.unread);
  return [
    _NavEntry(Icons.person, l10n.navProfile, () => context.push('/account')),
    if (MobileModule.tickets.isAvailableIn(menu))
      _NavEntry(
        Icons.receipt_long,
        l10n.navTickets,
        () => context.push('/tickets'),
      ),
    _NavEntry(Icons.home, l10n.navHome, () {}, selected: true),
    _NavEntry(
      Icons.notifications_none,
      l10n.navAlerts,
      () => context.push('/alerts'),
      badge: unreadAlerts,
    ),
    if (MobileModule.reports.isAvailableIn(menu))
      _NavEntry(
        Icons.bar_chart,
        l10n.navReports,
        () => context.push('/reports'),
      ),
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.entry, {required this.vertical});

  final _NavEntry entry;

  /// En el riel cada destino ocupa su propio renglon con mas aire.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final color = entry.selected ? p.accentOnDark : const Color(0xFF94A3B8);
    // Con poca altura (telefono en horizontal) el riel se compacta.
    final short = MediaQuery.sizeOf(context).height < 480;
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: r.s(vertical ? (short ? 6 : 14) : 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              key: Key('nav-badge-${entry.label}'),
              isLabelVisible: entry.badge > 0,
              label: Text(entry.badge > 99 ? '99+' : '${entry.badge}'),
              child: Icon(entry.icon, color: color, size: r.s(24)),
            ),
            SizedBox(height: r.s(2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                entry.label,
                maxLines: 1,
                style: TextStyle(fontSize: r.s(10.5), color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = _navEntries(context);
    return Container(
      color: context.palette.navBackground,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final e in entries)
              Expanded(child: _NavItem(e, vertical: false)),
          ],
        ),
      ),
    );
  }
}

/// Riel lateral para anchos medio y expandido: mismos destinos y colores que
/// la barra inferior.
class _SideRail extends StatelessWidget {
  const _SideRail({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final entries = _navEntries(context);
    return Container(
      width: r.railWidth,
      color: context.palette.navBackground,
      child: SafeArea(
        right: false,
        // Se desplaza si la ventana es mas baja que los destinos.
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: r.s(12)),
              for (final e in entries) _NavItem(e, vertical: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo capturado sin conexion que aun no llego al servidor (DEV-MOB-063): cuantas
/// operaciones esperan y cuantas piden una decision. Se toca para abrir el
/// centro de sincronizacion. Sin nada pendiente no ocupa espacio.
class _SyncStrip extends StatelessWidget {
  const _SyncStrip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final state = context.watch<SyncCubit>().state;
    if (!state.enabled || state.isEmpty) return const SizedBox.shrink();
    final attention = state.attention > 0;
    final text = attention
        ? l10n.syncStripAttention(state.attention)
        : l10n.syncStripPending(state.pending);
    final color = attention ? StatusColors.open : StatusColors.attended;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(12), r.s(20), 0),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(16)),
        child: InkWell(
          key: const Key('sync-strip'),
          borderRadius: BorderRadius.circular(r.s(16)),
          onTap: () => context.push('/sync'),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.s(14),
              vertical: r.s(12),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.s(16)),
              border: Border.all(color: color),
            ),
            child: Row(
              children: [
                state.running
                    ? SizedBox(
                        width: r.s(18),
                        height: r.s(18),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        attention ? Icons.error_outline : Icons.sync,
                        color: color,
                        size: r.s(20),
                      ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: p.textOnBottom,
                      fontSize: r.s(13.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: p.hint, size: r.s(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
