import 'package:flutter/material.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../domain/entities/map_pin.dart';
import '../map_labels.dart';

/// El circulo de un pin: color por estatus, icono por pestana. Seleccionado se
/// agranda y lleva un anillo, para encontrarlo entre los demas.
class MapPinMarker extends StatelessWidget {
  const MapPinMarker({
    super.key,
    required this.pin,
    required this.selected,
    required this.onTap,
  });

  final MapPin pin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = pinColor(p, pin.status);
    final onColor = SigacoPalette.readableOn(color);
    return Semantics(
      button: true,
      label: pin.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: selected ? 44 : 34,
            height: selected ? 44 : 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.white70,
                width: selected ? 3 : 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              layerIcon(pin.layer),
              color: onColor,
              size: selected ? 24 : 18,
            ),
          ),
        ),
      ),
    );
  }
}
