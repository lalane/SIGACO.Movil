import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Los codigos de recuperacion de la verificacion en dos pasos. El servidor los
/// muestra una sola vez: la persona debe guardarlos y confirmarlo para seguir.
class RecoveryCodesView extends StatelessWidget {
  const RecoveryCodesView({
    super.key,
    required this.codes,
    required this.onSaved,
  });

  final List<String> codes;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('recovery-codes'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.fieldFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              for (final code in codes)
                SelectableText(
                  code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: p.textOnTop,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('recovery-copy'),
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l10n.mfaRecoveryCopy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: codes.join('\n')));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.mfaRecoveryCopied)));
            }
          },
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          key: const Key('recovery-saved'),
          label: l10n.mfaRecoverySaved,
          onPressed: onSaved,
        ),
      ],
    );
  }
}
