import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/branding/concession_logo_tile.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Seleccion de concesion cuando el usuario tiene mas de una.
/// Provisional: aspecto pendiente de diseno.
class ConcessionPage extends StatelessWidget {
  const ConcessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => StepScaffold(
        title: l10n.concessionTitle,
        subtitle: l10n.concessionSubtitle,
        children: [
          for (final c in state.concessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: p.fieldFill,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: c.logoUrl == null
                      ? null
                      : ConcessionLogoTile(url: c.logoUrl, name: c.name),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(c.code),
                  trailing: Icon(Icons.chevron_right, color: p.accentOnBottom),
                  onTap: state.busy
                      ? null
                      : () => context.read<AuthBloc>().add(
                          AuthConcessionSelected(c.id),
                        ),
                ),
              ),
            ),
          if (state.error != null)
            ErrorBanner(authErrorText(l10n, state.error!)),
        ],
      ),
    );
  }
}
