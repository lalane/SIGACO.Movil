import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/concession_logo_tile.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_entities.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Hoja inferior con una lista de opciones; devuelve la elegida. La usan el
/// panel de la cuenta y la pantalla de configuracion.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required List<(T, String)> options,
}) {
  final p = context.palette;
  return showModalBottomSheet<T>(
    context: context,
    constraints: const BoxConstraints(maxWidth: Responsive.formMaxWidth),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == selected
                  ? Icon(Icons.check, color: p.accentOnBottom)
                  : null,
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    ),
  );
}

/// Idioma de la app: antes de iniciar sesion se usa el del telefono.
Future<void> chooseLanguage(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<SettingsCubit>();
  final language = Localizations.localeOf(context).languageCode;
  final chosen = await showOptionSheet<Locale>(
    context,
    title: l10n.languageLabel,
    selected: Locale(language),
    options: [
      (const Locale('es'), l10n.languageSpanish),
      (const Locale('pt'), l10n.languagePortuguese),
    ],
  );
  if (chosen != null) cubit.setLocale(chosen);
}

/// Apariencia: original (colores de SIGACO o de la concesion), dia o noche.
Future<void> chooseAppearance(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<SettingsCubit>();
  final chosen = await showOptionSheet<Appearance>(
    context,
    title: l10n.appearanceLabel,
    selected: cubit.state.appearance,
    options: [
      (Appearance.original, l10n.appearanceOriginal),
      (Appearance.day, l10n.appearanceDay),
      (Appearance.night, l10n.appearanceNight),
    ],
  );
  if (chosen != null) cubit.setAppearance(chosen);
}

/// Cambia de concesion: ofrece las demas y, al elegir una, vuelve al menu.
Future<void> switchConcession(
  BuildContext context, {
  required List<ConcessionSummary> concessions,
  required String? activeId,
}) async {
  final l10n = AppLocalizations.of(context);
  final bloc = context.read<AuthBloc>();
  final router = GoRouter.of(context);
  final others = concessions.where((c) => c.id != activeId).toList();
  final chosen = await showModalBottomSheet<ConcessionSummary>(
    context: context,
    // En pantallas anchas la hoja no se estira de lado a lado.
    constraints: const BoxConstraints(maxWidth: Responsive.formMaxWidth),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l10n.actionSwitchConcession,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(l10n.switchConcessionWarning),
          ),
          for (final c in others)
            ListTile(
              leading: c.logoUrl == null
                  ? null
                  : ConcessionLogoTile(url: c.logoUrl, name: c.name),
              title: Text(c.name),
              subtitle: Text(c.code),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    ),
  );
  if (chosen == null) return;
  bloc.add(AuthConcessionSelected(chosen.id));
  router.go('/home');
}
