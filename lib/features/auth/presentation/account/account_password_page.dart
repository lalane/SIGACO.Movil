import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/password_rules_list.dart';
import 'change_password_cubit.dart';

/// Cambio voluntario de la propia contrasena (HU-M01-03-02).
class AccountPasswordPage extends StatefulWidget {
  const AccountPasswordPage({super.key});

  @override
  State<AccountPasswordPage> createState() => _AccountPasswordPageState();
}

class _AccountPasswordPageState extends State<AccountPasswordPage> {
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
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (a, b) => !a.success && b.success,
      listener: (context, state) {
        // La app conserva en memoria la contrasena de esta sesion: la nueva.
        context.read<AuthBloc>().add(AuthPasswordUpdated(_next.text));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
        context.pop();
      },
      builder: (context, state) => StepScaffold(
        title: l10n.changePasswordAction,
        subtitle: l10n.actionChangePasswordSub,
        showBack: true,
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
            ErrorBanner(authErrorMessage(l10n, state.error!, state.details)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l10n.changePasswordAction,
            busy: state.busy,
            onPressed: () => context.read<ChangePasswordCubit>().submit(
              current: _current.text,
              next: _next.text,
              confirm: _confirm.text,
            ),
          ),
        ],
      ),
    );
  }
}
