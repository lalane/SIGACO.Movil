import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/geo_point.dart';
import '../map_labels.dart';

/// El punto que la persona eligio en el mapa (manteniendo presionado): sus
/// coordenadas y lo que se puede hacer ahi.
class PickedPointCard extends StatelessWidget {
  const PickedPointCard({
    super.key,
    required this.point,
    required this.onClose,
    required this.onNavigate,
    this.onCreate,
  });

  final GeoPoint point;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  /// Levantar un registro aqui; null si el usuario no puede crearlos.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Card(
      key: const Key('map-picked'),
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
                const Icon(Icons.place),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Text(
                    l10n.mapPickedTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('map-picked-close'),
                  tooltip: l10n.mapPickedClose,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: r.s(4)),
            Text(
              '${moduleDms(point.latitude, latitude: true)}  '
              '${moduleDms(point.longitude, latitude: false)}',
              key: const Key('map-picked-coords'),
            ),
            SizedBox(height: r.s(12)),
            Wrap(
              spacing: r.s(8),
              runSpacing: r.s(8),
              children: [
                if (onCreate != null)
                  FilledButton.icon(
                    key: const Key('map-picked-create'),
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(l10n.mapCreateRecord),
                  ),
                OutlinedButton.icon(
                  key: const Key('map-picked-navigate'),
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined),
                  label: Text(l10n.mapNavigate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
