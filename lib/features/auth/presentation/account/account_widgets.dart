import 'package:flutter/material.dart';

import '../../../../core/branding/sigaco_wordmark.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';

/// El marco de las pantallas de la cuenta: cabecera con el nombre de SIGACO y
/// el titulo de la pantalla, y el contenido debajo.
class AccountScaffold extends StatelessWidget {
  const AccountScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: p.gradientTop),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(8), r.s(4), r.s(16), r.s(16)),
                child: Row(
                  children: [
                    BackButton(color: p.textOnTop),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SigacoWordmark(fontSize: r.s(26)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                color: p.textOnTop.withValues(alpha: 0.8),
                                fontSize: r.s(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Filas de solo lectura: icono, nombre y valor alineado a la derecha.
class AccountInfoRows extends StatelessWidget {
  const AccountInfoRows({super.key, required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Column(
      children: [
        for (final (icon, label, value) in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: r.s(10)),
            // La etiqueta mide lo que necesita, hasta la mitad de la fila: con
            // texto grande se parte en dos lineas en vez de empujar el valor
            // fuera de la pantalla. El valor ocupa el resto, alineado a la derecha.
            child: LayoutBuilder(
              builder: (context, box) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: p.hint, size: r.s(20)),
                  SizedBox(width: r.s(12)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
                    child: Text(
                      label,
                      style: TextStyle(color: p.hint, fontSize: r.s(14)),
                    ),
                  ),
                  SizedBox(width: r.s(16)),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: p.textOnBottom,
                        fontSize: r.s(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AccountSectionTitle extends StatelessWidget {
  const AccountSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(8)),
      child: Text(
        text,
        style: TextStyle(
          color: p.textOnBottom,
          fontSize: r.s(15),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AccountActionTile extends StatelessWidget {
  const AccountActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Sustituye a la flecha (por ejemplo, un interruptor).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(r.s(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(16)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(r.s(14)),
          child: Row(
            children: [
              Icon(icon, color: p.accentOnDark, size: r.s(24)),
              SizedBox(width: r.s(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.s(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: r.s(12),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF94A3B8),
                    size: r.s(24),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
