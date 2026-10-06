import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Enrolamiento de la verificacion en dos pasos. Provisional: sin codigo QR.
class MfaEnrollPage extends StatefulWidget {
  const MfaEnrollPage({super.key});

  @override
  State<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends State<MfaEnrollPage> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthMfaEnrollmentRequested());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final enrollment = state.mfaEnrollment;
        return StepScaffold(
          title: l10n.mfaEnrollTitle,
          subtitle: l10n.mfaEnrollBody,
          children: [
            if (enrollment == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                l10n.mfaEnrollSecret,
                style: TextStyle(color: p.hint, fontSize: 13),
              ),
              const SizedBox(height: 6),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          enrollment.secret,
                          style: const TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.copy, color: p.accentOnDark, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _code,
                hint: l10n.mfaCode,
                keyboardType: TextInputType.number,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 14),
              ErrorBanner(authErrorText(l10n, state.error!)),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: l10n.mfaVerify,
              busy: state.busy,
              onPressed: enrollment == null
                  ? null
                  : () => context.read<AuthBloc>().add(
                      AuthMfaActivationSubmitted(_code.text),
                    ),
            ),
          ],
        );
      },
    );
  }
}
