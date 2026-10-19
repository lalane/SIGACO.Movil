import 'package:flutter/material.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../domain/entities/pin_cluster.dart';
import '../map_labels.dart';

/// Un grupo de pines: circulo con la cuenta, del color del estado mas grave.
/// Tocarlo acerca el mapa a los pines que contiene.
class PinClusterMarker extends StatelessWidget {
  const PinClusterMarker({
    super.key,
    required this.cluster,
    required this.onTap,
  });

  final PinCluster cluster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = pinColor(p, cluster.status);
    return Semantics(
      button: true,
      label: '${cluster.count}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${cluster.count}',
              style: TextStyle(
                color: SigacoPalette.readableOn(color),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
