import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_nav.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../maintenance_labels.dart';

/// "Seleccione un indicador" (mockup nuevo): la puerta de entrada de
/// mantenimiento. Cada indicador abre sus propios mantenimientos. Solo se ven
/// los indicadores que la persona tiene asignados en la concesion
/// (`/api/maintenance/navigation`).
class MaintenanceIndicatorsPage extends StatefulWidget {
  const MaintenanceIndicatorsPage({super.key});

  @override
  State<MaintenanceIndicatorsPage> createState() =>
      _MaintenanceIndicatorsPageState();
}

class _MaintenanceIndicatorsPageState extends State<MaintenanceIndicatorsPage> {
  late Future<List<MaintenanceIndicator>> _indicators;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _indicators = context.read<MaintenanceRepository>().visibleIndicators();

  Widget _message(String text, {VoidCallback? onRetry}) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.all(r.s(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            key: const Key('maintenance-indicators-message'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: r.s(15)),
          ),
          if (onRetry != null) ...[
            SizedBox(height: r.s(12)),
            TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Scaffold(
      backgroundColor: moduleSurface,
      bottomNavigationBar: const SigacoModuleNav(
        current: ModuleTab.maintenance,
      ),
      body: Column(
        children: [
          SigacoModuleHeader(title: l10n.maintIndicatorsTitle),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: FutureBuilder<List<MaintenanceIndicator>>(
                  future: _indicators,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _message(
                        l10n.maintIndicatorsFailed,
                        onRetry: () => setState(_load),
                      );
                    }
                    final indicators = snapshot.data ?? const [];
                    if (indicators.isEmpty) {
                      return _message(l10n.maintIndicatorsNone);
                    }
                    return ListView(
                      key: const Key('maintenance-indicators'),
                      padding: EdgeInsets.fromLTRB(
                        r.s(16),
                        r.s(20),
                        r.s(16),
                        r.s(16),
                      ),
                      children: [
                        for (final i in indicators)
                          InkWell(
                            key: Key('indicator-${i.name}'),
                            borderRadius: BorderRadius.circular(r.s(24)),
                            onTap: () => context.push('/maintenance/${i.name}'),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.s(20),
                                vertical: r.s(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: r.s(54),
                                    height: r.s(54),
                                    decoration: BoxDecoration(
                                      color: p.accent.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(
                                        r.s(14),
                                      ),
                                    ),
                                    child: Icon(
                                      indicatorIcon(i),
                                      color: p.accentOnDark,
                                      size: r.s(28),
                                    ),
                                  ),
                                  SizedBox(width: r.s(16)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          indicatorCode(i),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: r.s(20),
                                          ),
                                        ),
                                        Text(
                                          indicatorLabel(l10n, i),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: r.s(15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: moduleMuted),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
