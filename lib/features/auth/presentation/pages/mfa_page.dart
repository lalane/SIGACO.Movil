import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Segundo paso del login: codigo de la app autenticadora.
/// Provisional: aspecto pendiente de diseno.
class MfaPage extends StatefulWidget {
  const MfaPage({super.key});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final _code = TextEditingController();

  /// Se entra con un codigo de recuperacion en vez del de la app (DEV-BACK-132).
  bool _recovery = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => StepScaffold(
        title: l10n.mfaTitle,
        subtitle: l10n.mfaSubtitle,
        children: [
          AppTextField(
            key: ValueKey(_recovery),
            controller: _code,
            hint: _recovery ? l10n.mfaRecoveryCodeHint : l10n.mfaCode,
            keyboardType: _recovery
                ? TextInputType.visiblePassword
                : TextInputType.number,
            autofillHints: _recovery ? null : const [AutofillHints.oneTimeCode],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            ErrorBanner(authErrorText(l10n, state.error!)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l10n.mfaVerify,
            busy: state.busy,
            onPressed: () =>
                context.read<AuthBloc>().add(AuthMfaSubmitted(_code.text)),
          ),
          TextButton(
            key: const Key('mfa-toggle-recovery'),
            onPressed: () => setState(() {
              _recovery = !_recovery;
              _code.clear();
            }),
            child: Text(
              _recovery ? l10n.mfaUseAppCode : l10n.mfaUseRecoveryCode,
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
