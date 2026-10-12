import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import '../document_labels.dart';

/// Estado de firma de la version vigente: un punto de color y el texto, para que
/// no dependa solo del color.
class SignatureBadge extends StatelessWidget {
  const SignatureBadge({super.key, required this.signature});

  final DocumentSignature signature;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final color = signatureColor(signature) ?? p.hint;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(8), vertical: r.s(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(r.s(20)),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: r.s(7),
            height: r.s(7),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: r.s(5)),
          Flexible(
            child: Text(
              signatureLabel(AppLocalizations.of(context), signature),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textOnBottom,
                fontSize: r.s(11),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
