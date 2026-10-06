import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Solicitud del enlace de recuperacion (FEAT-M01-03).
///
/// El enlace llega por correo y se abre en el navegador, donde el usuario
/// define su nueva contrasena; al terminar, el portal lo devuelve a la app
/// con `sigaco://app/login?reset=ok` (ver `LoginPage.passwordResetReturned`).
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lo enviado antes no debe mostrarse al volver a esta pantalla.
    context.read<AuthBloc>().add(const AuthRecoveryOpened());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRecoveryRequested(_email.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => StepScaffold(
        title: l10n.recoveryTitle,
        subtitle: l10n.recoveryBody,
        showBack: true,
        children: [
          Form(
            key: _formKey,
            child: AppTextField(
              controller: _email,
              hint: l10n.fieldEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return l10n.errEmailRequired;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return l10n.errEmailInvalid;
                }
                return null;
              },
            ),
          ),
          if (state.error != null) ...[
            SizedBox(height: r.s(14)),
            ErrorBanner(authErrorText(l10n, state.error!)),
          ],
          if (state.recoverySent) ...[
            SizedBox(height: r.s(14)),
            NoticeBanner(
              l10n.recoverySent,
              icon: Icons.mark_email_read_outlined,
            ),
            SizedBox(height: r.s(16)),
            _Steps(
              title: l10n.recoveryStepsTitle,
              steps: [
                l10n.recoveryStep1,
                l10n.recoveryStep2,
                l10n.recoveryStep3,
              ],
            ),
          ],
          SizedBox(height: r.s(18)),
          PrimaryButton(
            label: state.recoverySent ? l10n.recoveryResend : l10n.recoverySend,
            busy: state.busy,
            onPressed: _send,
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              state.recoverySent ? l10n.recoveryBackToLogin : l10n.cancel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pasos numerados de lo que sigue tras pedir el enlace.
class _Steps extends StatelessWidget {
  const _Steps({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: p.textOnTop,
            fontSize: r.s(14),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: r.s(8)),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: r.s(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: r.s(22),
                  height: r.s(22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.accentOnDark),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: p.accentOnDark,
                      fontSize: r.s(12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: r.s(10)),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: p.textOnTop.withValues(alpha: 0.9),
                      fontSize: r.s(13.5),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
