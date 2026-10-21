import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../widgets/recovery_codes_view.dart';
import 'mfa_setup_cubit.dart';

/// Volver a configurar la verificacion en dos pasos desde el perfil y, con ella
/// activa, generar codigos de recuperacion nuevos.
class AccountMfaPage extends StatefulWidget {
  const AccountMfaPage({super.key});

  @override
  State<AccountMfaPage> createState() => _AccountMfaPageState();
}

class _AccountMfaPageState extends State<AccountMfaPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return BlocBuilder<MfaSetupCubit, MfaSetupState>(
      builder: (context, state) {
        // Los codigos de recuperacion se ven una sola vez: hay que guardarlos.
        if (state.recoveryCodes.isNotEmpty) {
          return StepScaffold(
            title: l10n.mfaRecoveryTitle,
            subtitle: l10n.mfaRecoveryBody,
            children: [
              RecoveryCodesView(
                codes: state.recoveryCodes,
                onSaved: () {
                  final reconfigured = state.done;
                  context.read<MfaSetupCubit>().acknowledgeCodes();
                  if (reconfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.mfaReconfigureDone)),
                    );
                    context.pop();
                  }
                },
              ),
            ],
          );
        }
        final enrollment = state.enrollment;
        return StepScaffold(
          title: l10n.mfaSettingTitle,
          subtitle: enrollment == null
              ? l10n.mfaReconfigureBody
              : l10n.mfaEnrollBody,
          showBack: true,
          children: [
            if (enrollment == null) ...[
              PrimaryButton(
                label: l10n.mfaReconfigureAction,
                busy: state.busy && !state.regenerating,
                onPressed: () => context.read<MfaSetupCubit>().generate(),
              ),
              SizedBox(height: r.s(24)),
              if (state.recoveryRemaining != null)
                Text(
                  l10n.mfaRecoveryRemaining(state.recoveryRemaining!),
                  key: const Key('recovery-remaining'),
                  style: TextStyle(color: p.hint, fontSize: r.s(13)),
                ),
              SizedBox(height: r.s(10)),
              if (!state.regenerating)
                OutlinedButton(
                  key: const Key('recovery-regenerate'),
                  onPressed: () =>
                      context.read<MfaSetupCubit>().startRegeneration(),
                  child: Text(l10n.mfaRecoveryGenerate),
                )
              else ...[
                Text(
                  l10n.mfaRecoveryGenerateBody,
                  style: TextStyle(color: p.hint, fontSize: r.s(13)),
                ),
                SizedBox(height: r.s(10)),
                AppTextField(
                  controller: _code,
                  hint: l10n.mfaCode,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: r.s(14)),
                PrimaryButton(
                  key: const Key('recovery-confirm'),
                  label: l10n.mfaRecoveryGenerate,
                  busy: state.busy,
                  onPressed: () =>
                      context.read<MfaSetupCubit>().regenerate(_code.text),
                ),
                TextButton(
                  onPressed: () {
                    _code.clear();
                    context.read<MfaSetupCubit>().cancelRegeneration();
                  },
                  child: Text(l10n.cancel),
                ),
              ],
            ] else ...[
              Text(
                l10n.mfaEnrollSecret,
                style: TextStyle(color: p.hint, fontSize: r.s(13)),
              ),
              SizedBox(height: r.s(6)),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: enrollment.secret),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.mfaCopied)));
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(r.s(14)),
                  decoration: BoxDecoration(
                    color: p.fieldFill,
                    borderRadius: BorderRadius.circular(r.s(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          enrollment.secret,
                          style: TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            fontSize: r.s(14),
                            color: p.textOnTop,
                          ),
                        ),
                      ),
                      Icon(Icons.copy, color: p.accentOnDark, size: r.s(18)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: r.s(16)),
              AppTextField(
                controller: _code,
                hint: l10n.mfaCode,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: r.s(18)),
              PrimaryButton(
                label: l10n.mfaVerify,
                busy: state.busy,
                onPressed: () =>
                    context.read<MfaSetupCubit>().confirm(_code.text),
              ),
            ],
            if (state.error != null) ...[
              SizedBox(height: r.s(14)),
              ErrorBanner(authErrorText(l10n, state.error!)),
            ],
          ],
        );
      },
    );
  }
}
