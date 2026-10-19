import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../map_labels.dart';

/// Los botones cuadrados de la izquierda del mapa: uno por capa (tickets,
/// inventario, mantenimiento y obras). La capa abierta va en el color de accion.
class MapLayerButtons extends StatelessWidget {
  const MapLayerButtons({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final MapLayer current;
  final ValueChanged<MapLayer> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final size = r.s(44);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final layer in MapLayer.values) ...[
          Semantics(
            button: true,
            selected: layer == current,
            label: layerLabel(l10n, layer),
            child: Tooltip(
              message: layerLabel(l10n, layer),
              child: Material(
                color: layer == current ? p.accent : p.gradientTop,
                elevation: 2,
                borderRadius: BorderRadius.circular(r.s(12)),
                child: InkWell(
                  key: Key('map-tab-${layer.name}'),
                  borderRadius: BorderRadius.circular(r.s(12)),
                  onTap: () => onSelect(layer),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      layerIcon(layer),
                      size: r.s(22),
                      color: layer == current ? p.onAccent : p.textOnTop,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (layer != MapLayer.values.last) SizedBox(height: r.s(8)),
        ],
      ],
    );
  }
}
