import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';

/// Los cuatro valores de la marca (Seguro, Confiable, Colaborativo, Eficiente).
class LoginValuesRow extends StatelessWidget {
  const LoginValuesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    Widget item(IconData icon, String label) => Expanded(
      child: Column(
        children: [
          SizedBox(
            height: r.s(34),
            child: Center(
              child: Icon(icon, color: p.accentOnBottom, size: r.s(28)),
            ),
          ),
          SizedBox(height: r.s(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: p.textOnBottom,
                fontSize: r.s(12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return Row(
      children: [
        item(Icons.verified_user, l10n.valueSecure),
        item(Icons.handshake_outlined, l10n.valueReliable),
        item(Icons.groups, l10n.valueCollaborative),
        item(Icons.speed, l10n.valueEfficient),
      ],
    );
  }
}

/// Pie del login: version, contacto y logo de TEKIA.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Medidas tomadas del mock: texto de ~8 dp y logo de ~30 dp de ancho.
    final small = TextStyle(
      fontSize: r.s(8.5),
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.versionLabel(version),
              style: small.copyWith(color: p.hint),
            ),
            Text(
              l10n.contactAdmin,
              style: small.copyWith(color: p.accentOnBottom),
            ),
          ],
        ),
        SizedBox(width: r.s(12)),
        Container(
          width: 1,
          height: r.s(20),
          color: p.hint.withValues(alpha: 0.45),
        ),
        SizedBox(width: r.s(12)),
        // Misma composicion en ambos modos: el tamano no cambia al alternar.
        Image.asset(
          isDark
              ? 'assets/branding/tekia_white.png'
              : 'assets/branding/tekia_dark.png',
          width: r.s(30),
        ),
      ],
    );
  }
}
