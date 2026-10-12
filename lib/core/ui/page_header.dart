import 'package:flutter/material.dart';

import '../branding/sigaco_wordmark.dart';
import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';

/// Cabecera de las pantallas internas: atras, marca SIGACO y el titulo de la
/// pantalla. Los modulos la comparten en lugar de armar cada uno la suya.
class SigacoPageHeader extends StatelessWidget {
  const SigacoPageHeader({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      width: double.infinity,
      color: p.gradientTop,
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
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}
