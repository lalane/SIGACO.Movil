import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance.dart';
import '../maintenance_labels.dart';

/// El panel lateral de indicadores del menu (mockup): titulo, buscador y la
/// lista de indicadores; cada uno abre sus mantenimientos.
class IndicatorsPanel extends StatefulWidget {
  const IndicatorsPanel({super.key});

  @override
  State<IndicatorsPanel> createState() => _IndicatorsPanelState();
}

class _IndicatorsPanelState extends State<IndicatorsPanel> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AppLocalizations l10n, MaintenanceIndicator i) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return indicatorCode(i).toLowerCase().contains(q) ||
        indicatorLabel(l10n, i).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final shown = [
      for (final i in MaintenanceIndicator.values)
        if (_matches(l10n, i)) i,
    ];
    return Drawer(
      key: const Key('indicators-panel'),
      backgroundColor: moduleSurface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(16), r.s(16), r.s(12)),
              child: Row(
                children: [
                  Container(
                    width: r.s(48),
                    height: r.s(48),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(r.s(14)),
                    ),
                    child: Icon(
                      Icons.construction,
                      color: p.accentOnDark,
                      size: r.s(26),
                    ),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.indicatorsPanelTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: r.s(22),
                          ),
                        ),
                        Text(
                          l10n.indicatorsPanelSubtitle,
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.s(16)),
              child: TextField(
                key: const Key('indicators-search'),
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.indicatorsSearchHint,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(r.s(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: r.s(8)),
            Expanded(
              child: shown.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(r.s(20)),
                      child: Text(
                        l10n.indicatorsNoMatch,
                        key: const Key('indicators-no-match'),
                        style: TextStyle(color: moduleMuted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final i in shown)
                          ListTile(
                            key: Key('panel-indicator-${i.name}'),
                            leading: Container(
                              width: r.s(44),
                              height: r.s(44),
                              decoration: BoxDecoration(
                                color: p.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(r.s(12)),
                              ),
                              child: Icon(
                                indicatorIcon(i),
                                color: p.accentOnDark,
                                size: r.s(24),
                              ),
                            ),
                            title: Text(
                              indicatorCode(i),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              indicatorLabel(l10n, i),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: moduleMuted,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push('/maintenance/${i.name}');
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
