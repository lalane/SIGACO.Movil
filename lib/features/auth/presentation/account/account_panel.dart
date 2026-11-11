import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/profile_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'account_choices.dart';
import 'account_page.dart' show initialsOf;

/// "Configuraciones de la cuenta": lo de todos los dias a un toque del circulo
/// de la cabecera. Mi cuenta (perfil), idioma, claro u oscuro, cambiar de
/// concesion y cerrar sesion.
Future<void> showAccountPanel(BuildContext context) async {
  final auth = context.read<AuthBloc>();
  final settings = context.read<SettingsCubit>();
  final action = await showModalBottomSheet<_PanelAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    constraints: const BoxConstraints(maxWidth: Responsive.formMaxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    // La hoja vive en otra ruta: se le pasan los bloques que usa.
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: auth),
        BlocProvider.value(value: settings),
      ],
      child: const AccountPanel(),
    ),
  );
  // Lo que lleva a otra pantalla se hace con la hoja ya cerrada.
  if (!context.mounted || action == null) return;
  switch (action) {
    case _PanelAction.myAccount:
      context.push('/account');
    // Definiciones pendientes (tanda 4): lo que TEKIA confirma de SIGACO.
    case _PanelAction.definitions:
      context.push('/definitions');
    case _PanelAction.switchConcession:
      await switchConcession(
        context,
        concessions: auth.state.concessions,
        activeId: auth.state.activeConcessionId,
      );
    case _PanelAction.signOut:
      auth.add(const AuthLogoutRequested());
  }
}

enum _PanelAction { myAccount, definitions, switchConcession, signOut }

class AccountPanel extends StatelessWidget {
  const AccountPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final auth = context.watch<AuthBloc>().state;
    final settings = context.watch<SettingsCubit>().state;
    final user = auth.user;
    final language = Localizations.localeOf(context).languageCode;
    final dayNight = switch (settings.appearance) {
      Appearance.day => {Appearance.day},
      Appearance.night => {Appearance.night},
      Appearance.original => <Appearance>{},
    };
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('account-panel'),
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accountPanelTitle,
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: r.s(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('account-panel-close'),
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF94A3B8),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Row(
              children: [
                ProfileAvatar(
                  initials: initialsOf(user?.fullName ?? ''),
                  radius: r.s(26),
                  background: p.accent,
                  foreground: p.onAccent,
                  fontSize: r.s(18),
                ),
                SizedBox(width: r.s(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.s(17),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.accentOnDark,
                          fontSize: r.s(13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: r.s(12)),
            _PanelTile(
              key: const Key('panel-my-account'),
              icon: Icons.account_circle_outlined,
              label: l10n.accountMyAccount,
              onTap: () => Navigator.of(context).pop(_PanelAction.myAccount),
            ),
            _PanelTile(
              key: const Key('panel-definitions'),
              icon: Icons.contact_support_outlined,
              label: l10n.defTitle,
              onTap: () => Navigator.of(context).pop(_PanelAction.definitions),
            ),
            _PanelTile(
              key: const Key('panel-language'),
              icon: Icons.language,
              label: l10n.languageLabel,
              value: language == 'pt'
                  ? l10n.languagePortuguese
                  : l10n.languageSpanish,
              onTap: () => chooseLanguage(context),
            ),
            if (auth.concessions.length > 1)
              _PanelTile(
                key: const Key('panel-switch-concession'),
                icon: Icons.swap_horiz,
                label: l10n.actionSwitchConcession,
                onTap: () =>
                    Navigator.of(context).pop(_PanelAction.switchConcession),
              ),
            SizedBox(height: r.s(8)),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Appearance>(
                key: const Key('panel-appearance'),
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: Appearance.day,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.appearanceDay),
                  ),
                  ButtonSegment(
                    value: Appearance.night,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.appearanceNight),
                  ),
                ],
                selected: dayNight,
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) {
                    context.read<SettingsCubit>().setAppearance(s.first);
                  }
                },
              ),
            ),
            SizedBox(height: r.s(8)),
            _PanelTile(
              key: const Key('panel-sign-out'),
              icon: Icons.logout,
              label: l10n.signOut,
              onTap: () => Navigator.of(context).pop(_PanelAction.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTile extends StatelessWidget {
  const _PanelTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white, size: r.s(22)),
      title: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: r.s(15)),
      ),
      trailing: value == null
          ? null
          : Text(
              value!,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: r.s(13),
              ),
            ),
      onTap: onTap,
    );
  }
}
