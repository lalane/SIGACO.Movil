import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';
import '../../domain/entities/segment_pavement.dart';
import '../map_labels.dart';

/// La ficha corta del tramo elegido: su codigo, hacia donde corre y que
/// kilometros cubre.
class SegmentDetailCard extends StatelessWidget {
  const SegmentDetailCard({
    super.key,
    required this.segment,
    required this.onClose,
    this.layer,
    this.pinCount,
    this.pavement,
  });

  final RoadSegment segment;
  final VoidCallback onClose;

  /// La pestana abierta y cuantos de sus elementos estan en este tramo.
  final MapLayer? layer;
  final int? pinCount;

  /// Con la capa de pavimento prendida: el indicador del tramo (HU-MOB-10-01).
  final PavementLayer? pavement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final measured = pavement?.segments[segment.id];
    final color = pavement != null
        ? pavementColor(measured?.level)
        : segmentColor(segment.direction);
    final from = segment.startKmLabel;
    final to = segment.endKmLabel;
    return Card(
      key: const Key('map-segment-detail'),
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
                    Icons.timeline,
                    size: r.s(18),
                    color: SigacoPalette.readableOn(color),
                  ),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Text(
                    l10n.mapSegmentTitle(segment.code),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('map-segment-close'),
                  tooltip: l10n.mapDetailClose,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (segment.name != null) ...[
              SizedBox(height: r.s(4)),
              Text(segment.name!),
            ],
            SizedBox(height: r.s(8)),
            Wrap(
              spacing: r.s(8),
              runSpacing: r.s(4),
              children: [
                Chip(
                  avatar: CircleAvatar(radius: 6, backgroundColor: color),
                  label: Text(directionLabel(l10n, segment.direction)),
                  visualDensity: VisualDensity.compact,
                ),
                if (from != null && to != null)
                  Chip(
                    label: Text(l10n.mapSegmentRange(from, to)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (pavement != null)
                  Chip(
                    key: const Key('map-segment-pavement'),
                    avatar: CircleAvatar(
                      radius: 6,
                      backgroundColor: pavementColor(measured?.level),
                    ),
                    label: Text(
                      measured?.average == null
                          ? '${pavement!.label}: ${pavementLevelLabel(l10n, null)}'
                          : l10n.mapPavementSegment(
                              pavement!.label,
                              measured!.average!.toStringAsFixed(2),
                              pavement!.unit,
                              pavementLevelLabel(l10n, measured.level),
                              '${measured.coveragePercent}',
                            ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                if (layer != null && pinCount != null)
                  Chip(
                    key: const Key('map-segment-count'),
                    avatar: Icon(layerIcon(layer!), size: 16),
                    label: Text(
                      l10n.mapSegmentLayerCount(
                        layerLabel(l10n, layer!),
                        pinCount!,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
