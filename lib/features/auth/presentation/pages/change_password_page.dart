import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/password_rules_list.dart';

/// Cambio obligatorio de contrasena. Provisional: aspecto pendiente de diseno.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => StepScaffold(
        title: l10n.changePasswordTitle,
        subtitle: l10n.changePasswordSubtitle,
        children: [
          AppTextField(
            controller: _current,
            hint: l10n.currentPassword,
            obscure: true,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _next,
            hint: l10n.newPassword,
            obscure: true,
          ),
          PasswordRulesList(controller: _next),
          const SizedBox(height: 14),
          AppTextField(
            controller: _confirm,
            hint: l10n.confirmPassword,
            obscure: true,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            ErrorBanner(
              authErrorMessage(l10n, state.error!, state.errorDetails),
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l10n.changePasswordAction,
            busy: state.busy,
            onPressed: () => context.read<AuthBloc>().add(
              AuthPasswordChangeSubmitted(
                current: _current.text,
                next: _next.text,
                confirm: _confirm.text,
              ),
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
