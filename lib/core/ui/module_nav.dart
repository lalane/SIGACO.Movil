import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';

/// Los cinco destinos de la barra inferior de las pantallas de modulo (mockup
/// nuevo): Mapa, Ticket, Menu, Inventario y Mantenimiento.
enum ModuleTab {
  map('/map', Icons.map_outlined),
  tickets('/tickets', Icons.receipt_long),
  home('/home', Icons.home_outlined),
  inventory('/inventory', Icons.checklist_rtl),
  maintenance('/maintenance', Icons.settings);

  const ModuleTab(this.route, this.icon);

  /// Ruta a la que lleva; sin ruta el modulo todavia no existe.
  final String? route;
  final IconData icon;
}

String _label(AppLocalizations l10n, ModuleTab tab) => switch (tab) {
  ModuleTab.map => l10n.navTabMap,
  ModuleTab.tickets => l10n.navTabTicket,
  ModuleTab.home => l10n.navTabMenu,
  ModuleTab.inventory => l10n.navTabInventory,
  ModuleTab.maintenance => l10n.navTabMaintenance,
};

/// Barra inferior de los modulos. Cambiar de destino reemplaza la pantalla (el
/// atras sigue llevando al menu); "Menu" vuelve al inicio.
class SigacoModuleNav extends StatelessWidget {
  const SigacoModuleNav({super.key, required this.current});

  final ModuleTab current;

  void _go(BuildContext context, ModuleTab tab) {
    if (tab == current) return;
    final route = tab.route;
    if (route == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).moduleComingSoon),
          ),
        );
      return;
    }
    if (tab == ModuleTab.home) {
      context.go(route);
    } else {
      context.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Container(
      key: const Key('module-nav'),
      color: p.navBackground,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final tab in ModuleTab.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: tab == current,
                  label: _label(l10n, tab),
                  child: InkWell(
                    key: Key('nav-tab-${tab.name}'),
                    onTap: () => _go(context, tab),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: r.s(10),
                        horizontal: r.s(2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: r.s(24),
                            color: tab == current
                                ? p.navSelected
                                : const Color(0xFF94A3B8),
                          ),
                          SizedBox(height: r.s(2)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _label(l10n, tab),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: r.s(11),
                                fontWeight: tab == current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: tab == current
                                    ? p.navSelected
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
