import 'package:flutter/widgets.dart';

import 'brand_colors.dart';

/// Wordmark "SIGACO": SIG en [sigColor] y ACO en verde de marca.
class SigacoWordmark extends StatelessWidget {
  const SigacoWordmark({
    super.key,
    this.fontSize = 56,
    this.sigColor = BrandColors.white,
    this.acoColor = BrandColors.green,
    this.stacked = false,
  });

  /// Version para fondo claro: SIG en azul de marca.
  const SigacoWordmark.onLight({
    super.key,
    this.fontSize = 56,
    this.stacked = false,
  }) : sigColor = BrandColors.navy,
       acoColor = BrandColors.green;

  final double fontSize;
  final Color sigColor;
  final Color acoColor;

  /// SIG sobre ACO, para espacios cuadrados (icono de la app).
  final bool stacked;

  TextStyle _style(Color color) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontVariations: const [FontVariation('wght', 800)],
    fontSize: fontSize,
    height: stacked ? 0.95 : 1,
    letterSpacing: -fontSize * 0.02,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SIG',
            style: _style(sigColor),
            textScaler: TextScaler.noScaling,
          ),
          Text(
            'ACO',
            style: _style(acoColor),
            textScaler: TextScaler.noScaling,
          ),
        ],
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'SIG', style: _style(sigColor)),
          TextSpan(text: 'ACO', style: _style(acoColor)),
        ],
      ),
      semanticsLabel: 'SIGACO',
      textScaler: TextScaler.noScaling,
    );
  }
}
