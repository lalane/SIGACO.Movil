import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../map_labels.dart';

/// La ficha corta del pin elegido: que es, donde esta, que tan lejos queda y
/// cuanta atencion pide. Crear un ticket, una inspeccion o un mantenimiento
/// desde aqui llegara cuando esos modulos existan en la app.
class PinDetailCard extends StatelessWidget {
  const PinDetailCard({
    super.key,
    required this.pin,
    required this.onClose,
    this.distanceMeters,
  });

  final MapPin pin;
  final VoidCallback onClose;

  /// Distancia a la ubicacion del usuario, si se conoce.
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final color = pinColor(p, pin.status);
    return Card(
      key: const Key('map-detail'),
      color: solidCard(p),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(r.s(16), r.s(12), r.s(8), r.s(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: r.s(16),
                  backgroundColor: color,
                  child: Icon(
                    layerIcon(pin.layer),
                    size: r.s(18),
                    color: SigacoPalette.readableOn(color),
                  ),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Text(
                    pin.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('map-detail-close'),
                  tooltip: l10n.mapDetailClose,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (pin.subtitle != null) ...[
              SizedBox(height: r.s(4)),
              Text(pin.subtitle!),
            ],
            SizedBox(height: r.s(8)),
            Wrap(
              spacing: r.s(8),
              runSpacing: r.s(4),
              children: [
                Chip(
                  avatar: CircleAvatar(radius: 6, backgroundColor: color),
                  label: Text(statusLabel(l10n, pin.status)),
                  visualDensity: VisualDensity.compact,
                ),
                if (pin.category != null)
                  Chip(
                    label: Text(pin.category!),
                    visualDensity: VisualDensity.compact,
                  ),
                if (pin.kmLabel != null)
                  Chip(
                    label: Text('${l10n.mapDetailReference}: ${pin.kmLabel}'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (pin.segmentCode != null)
                  Chip(
                    key: const Key('map-detail-segment'),
                    avatar: Icon(
                      Icons.timeline,
                      size: 16,
                      color: segmentColor(
                        pin.direction ?? TravelDirection.increasing,
                      ),
                    ),
                    label: Text(
                      [
                        l10n.mapSegmentTitle(pin.segmentCode!),
                        if (pin.direction != null)
                          directionLabel(l10n, pin.direction!),
                      ].join(' · '),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                if (distanceMeters != null)
                  Chip(
                    key: const Key('map-detail-distance'),
                    avatar: const Icon(Icons.near_me_outlined, size: 16),
                    label: Text(
                      l10n.mapDetailDistance(
                        distanceLabel(l10n, distanceMeters!),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(height: r.s(8)),
            Text(
              l10n.mapActionsSoon,
              style: TextStyle(color: p.hint, fontSize: r.s(12)),
            ),
          ],
        ),
      ),
    );
  }
}
