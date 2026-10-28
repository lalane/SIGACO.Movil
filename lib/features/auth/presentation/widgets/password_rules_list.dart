import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_entities.dart';
import '../account/password_rules_cubit.dart';

/// Lo que debe cumplir la contrasena nueva, con una marca en lo que ya cumple
/// mientras la persona escribe. No decide nada: el servidor valida al enviar.
class PasswordRulesList extends StatelessWidget {
  const PasswordRulesList({super.key, required this.controller});

  /// El campo de la contrasena nueva.
  final TextEditingController controller;

  static String label(
    AppLocalizations l10n,
    PasswordRules rules,
    PasswordRuleKind kind,
  ) => switch (kind) {
    PasswordRuleKind.length => l10n.passwordRuleLength(rules.minLength),
    PasswordRuleKind.uppercase => l10n.passwordRuleUppercase,
    PasswordRuleKind.lowercase => l10n.passwordRuleLowercase,
    PasswordRuleKind.digit => l10n.passwordRuleDigit,
    PasswordRuleKind.special => l10n.passwordRuleSpecial,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordRulesCubit, PasswordRules?>(
      builder: (context, rules) {
        if (rules == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final p = context.palette;
        final r = context.responsive;
        return Padding(
          key: const Key('password-rules'),
          padding: EdgeInsets.only(top: r.s(10)),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.passwordRulesTitle,
                  style: TextStyle(color: p.hint, fontSize: r.s(13)),
                ),
                SizedBox(height: r.s(6)),
                for (final kind in rules.required)
                  _Rule(
                    key: Key('password-rule-${kind.name}'),
                    text: label(l10n, rules, kind),
                    met: rules.isMet(kind, controller.text),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({super.key, required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.s(2)),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: r.s(16),
            color: met ? StatusColors.closed : p.hint,
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: met ? p.textOnBottom : p.hint,
                fontSize: r.s(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
