import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../map_labels.dart';

/// Superficie oscura de las hojas y tarjetas del mockup nuevo.
const mapSheetColor = Color(0xFF1E293B);

/// La hoja de abajo del mapa: cuantos elementos hay con los filtros puestos y,
/// al abrirla, la lista para elegir uno y "Refinar busqueda".
class MapResultsSheet extends StatefulWidget {
  const MapResultsSheet({
    super.key,
    required this.pins,
    required this.onPick,
    required this.onRefine,
  });

  final List<MapPin> pins;
  final ValueChanged<MapPin> onPick;
  final VoidCallback onRefine;

  @override
  State<MapResultsSheet> createState() => _MapResultsSheetState();
}

class _MapResultsSheetState extends State<MapResultsSheet> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final itemHeight = r.s(64);
    final maxList = MediaQuery.sizeOf(context).height * 0.3;
    final listHeight = math.min(widget.pins.length * itemHeight, maxList);
    final radius = Radius.circular(r.s(24));
    return Material(
      key: const Key('map-results'),
      color: _open ? mapSheetColor : p.gradientTop,
      borderRadius: BorderRadius.vertical(top: radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              key: const Key('map-results-toggle'),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(16), r.s(12)),
                child: Column(
                  children: [
                    Container(
                      width: r.s(36),
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: r.s(10)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.mapResultsFound(widget.pins.length),
                            key: const Key('map-results-count'),
                            style: TextStyle(
                              color: p.textOnTop,
                              fontSize: r.s(16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          _open
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: p.textOnTop.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open) ...[
            if (widget.pins.isNotEmpty)
              SizedBox(
                height: listHeight,
                child: ListView.builder(
                  itemExtent: itemHeight,
                  itemCount: widget.pins.length,
                  itemBuilder: (context, i) {
                    final pin = widget.pins[i];
                    return _ResultTile(
                      pin: pin,
                      onTap: () {
                        setState(() => _open = false);
                        widget.onPick(pin);
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(8), r.s(16), r.s(16)),
              child: FilledButton(
                key: const Key('map-refine'),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(r.s(48)),
                  shape: const StadiumBorder(),
                ),
                onPressed: widget.onRefine,
                child: Text(l10n.mapRefine),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.pin, required this.onTap});

  final MapPin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final color = pinColor(p, pin.status);
    final detail = [
      if (pin.kmLabel != null) pin.kmLabel!,
      if (pin.category != null) pin.category!,
    ].join(' · ');
    return InkWell(
      key: Key('map-result-${pin.id}'),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.s(20)),
        child: Row(
          children: [
            Icon(layerIcon(pin.layer), color: color, size: r.s(26)),
            SizedBox(width: r.s(14)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textOnTop,
                      fontWeight: FontWeight.w700,
                      fontSize: r.s(14),
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textOnTop.withValues(alpha: 0.65),
                        fontSize: r.s(12),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: p.textOnTop.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
