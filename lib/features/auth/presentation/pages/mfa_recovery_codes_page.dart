import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/recovery_codes_view.dart';

/// Tras activar la verificacion en dos pasos: los codigos de recuperacion, que
/// se ven una sola vez. No se sigue hasta confirmar que se guardaron.
class MfaRecoveryCodesPage extends StatelessWidget {
  const MfaRecoveryCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => StepScaffold(
        title: l10n.mfaRecoveryTitle,
        subtitle: l10n.mfaRecoveryBody,
        children: [
          RecoveryCodesView(
            codes: state.recoveryCodes,
            onSaved: () => context.read<AuthBloc>().add(
              const AuthRecoveryCodesAcknowledged(),
            ),
          ),
        ],
      ),
    );
  }
}
