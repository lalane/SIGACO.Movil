import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/demo/demo_mode.dart';
import '../../../../core/device/device_info_source.dart';
import '../../../../core/offline/sync_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'account_choices.dart';
import 'account_cubit.dart';
import 'account_widgets.dart';

/// Configuracion de la app: seguridad del acceso, preferencias, sincronizacion
/// y datos del dispositivo. Lo del perfil esta en Mi cuenta.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String _version = '';
  String _device = '';

  @override
  void initState() {
    super.initState();
    // Modelo del telefono y version de Android: solo se muestran, no se envian.
    context.read<DeviceInfoSource>().describe().then((d) {
      if (mounted) setState(() => _device = d);
    });
    PackageInfo.fromPlatform()
        .then((i) {
          if (mounted) setState(() => _version = i.version);
        })
        .catchError((_) {});
  }

  void _setColorOrigin(BuildContext context, bool concession) => context
      .read<SettingsCubit>()
      .setColorOrigin(concession ? ColorOrigin.concession : ColorOrigin.sigaco);

  void _toggleDemo(BuildContext context, bool on) {
    context.read<DemoMode>().set(on);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(on ? l10n.demoModeSnackOn : l10n.demoModeSnackOff),
        ),
      );
  }

  void _toggleBiometric(BuildContext context, bool on) {
    final bloc = context.read<AuthBloc>();
    bloc.add(
      on
          ? AuthBiometricEnableRequested(
              AppLocalizations.of(context).biometricReason,
            )
          : const AuthBiometricDisabled(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final language = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final biometricAvailable = context.select(
      (AuthBloc b) => b.state.biometricAvailable,
    );
    final biometricEnabled = context.select(
      (AuthBloc b) => b.state.biometricEnabled,
    );
    // El servidor informa si la verificacion esta activa (DEV-MOB-052); sin ese
    // dato se usa lo deducido del acceso.
    final mfaFromLogin = context.select((AuthBloc b) => b.state.mfaActive);
    final mfaActive =
        context.select((AccountCubit c) => c.state.profile?.mfa?.active) ??
        mfaFromLogin;
    final settings = context.select((SettingsCubit c) => c.state);
    final demo = context.read<DemoMode>();
    // Ultima respuesta del servidor.
    final lastContact = context.select(
      (ConnectivityCubit c) => c.state.lastContactAt,
    );
    // Zona horaria de la concesion: en ella se muestran las fechas del negocio.
    final zone = context.select((ConcessionZoneCubit c) => c.state);
    // Lo capturado sin conexion que aun no llego al servidor.
    final sync = context.watch<SyncCubit>().state;
    final deviceRows = <(IconData, String, String)>[
      if (zone != null)
        (
          Icons.schedule_outlined,
          l10n.fieldTimezone,
          '${zone.id} (${zone.offsetLabelAt(DateTime.now())})',
        ),
      (Icons.info_outline, l10n.fieldAppVersion, _version),
      if (_device.isNotEmpty)
        (Icons.smartphone_outlined, l10n.fieldDevice, _device),
      (
        Icons.cloud_done_outlined,
        l10n.fieldLastConnection,
        lastContact == null
            ? '—'
            : DateFormat.yMd(locale).add_Hm().format(lastContact),
      ),
      // Lo capturado sin conexion se envia por pasadas: cuando termino la
      // ultima sin problemas de red ni de sesion.
      if (sync.enabled)
        (
          Icons.sync,
          l10n.fieldLastSync,
          sync.lastSyncAt == null
              ? '—'
              : DateFormat.yMd(
                  locale,
                ).add_Hm().format(sync.lastSyncAt!.toLocal()),
        ),
    ];

    return AccountScaffold(
      title: l10n.accountSettingsTitle,
      child: BlocListener<AuthBloc, AuthState>(
        // Confirma al usuario que la biometria quedo activada o apagada.
        listenWhen: (a, b) => a.biometricEnabled != b.biometricEnabled,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.biometricEnabled
                  ? l10n.biometricEnabledDone
                  : l10n.biometricDisabledDone,
            ),
          ),
        ),
        child: ListView(
          key: const Key('account-settings'),
          // Centrado con ancho maximo en pantallas medias y grandes.
          padding: r
              .sidePadding(minGutter: r.s(20))
              .copyWith(top: r.s(20), bottom: r.s(32)),
          children: [
            AccountSectionTitle(l10n.securityTitle),
            AccountActionTile(
              icon: Icons.lock_reset,
              title: l10n.changePasswordAction,
              subtitle: l10n.actionChangePasswordSub,
              onTap: () => context.push('/account/password'),
            ),
            SizedBox(height: r.s(10)),
            // La activa o desactiva un administrador (M02-05): aqui solo se
            // renueva la clave de una cuenta que ya la tiene.
            AccountActionTile(
              icon: Icons.shield_outlined,
              title: l10n.mfaSettingTitle,
              subtitle: mfaActive ? l10n.mfaSettingOn : l10n.mfaSettingOff,
              onTap: mfaActive
                  ? () => context.push('/account/mfa')
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.mfaAdminManaged)),
                    ),
              trailing: mfaActive
                  ? null
                  : Icon(
                      Icons.info_outline,
                      color: const Color(0xFF94A3B8),
                      size: r.s(22),
                    ),
            ),
            if (biometricAvailable) ...[
              SizedBox(height: r.s(10)),
              // Interruptor: activar pide la huella o el rostro al momento, sin
              // cerrar sesion (la contrasena de esta sesion sigue en memoria).
              AccountActionTile(
                icon: Icons.fingerprint,
                title: l10n.biometricSettingTitle,
                subtitle: biometricEnabled
                    ? l10n.biometricSettingOn
                    : l10n.biometricSettingOff,
                onTap: () => _toggleBiometric(context, !biometricEnabled),
                trailing: Switch(
                  value: biometricEnabled,
                  activeTrackColor: p.accent,
                  activeThumbColor: p.onAccent,
                  onChanged: (on) => _toggleBiometric(context, on),
                ),
              ),
            ],
            SizedBox(height: r.s(18)),
            AccountSectionTitle(l10n.preferencesTitle),
            AccountActionTile(
              icon: Icons.language,
              title: l10n.languageLabel,
              subtitle: language == 'pt'
                  ? l10n.languagePortuguese
                  : l10n.languageSpanish,
              onTap: () => chooseLanguage(context),
            ),
            SizedBox(height: r.s(10)),
            AccountActionTile(
              icon: Icons.palette_outlined,
              title: l10n.appearanceLabel,
              subtitle: switch (settings.appearance) {
                Appearance.original => l10n.appearanceOriginal,
                Appearance.day => l10n.appearanceDay,
                Appearance.night => l10n.appearanceNight,
              },
              onTap: () => chooseAppearance(context),
            ),
            if (settings.brandAvailable) ...[
              SizedBox(height: r.s(10)),
              AccountActionTile(
                icon: Icons.format_color_fill,
                title: l10n.useConcessionColors,
                subtitle: settings.colorOrigin == ColorOrigin.concession
                    ? l10n.useConcessionColorsOn
                    : l10n.useConcessionColorsOff,
                onTap: () => _setColorOrigin(
                  context,
                  settings.colorOrigin != ColorOrigin.concession,
                ),
                trailing: Switch(
                  value: settings.colorOrigin == ColorOrigin.concession,
                  activeTrackColor: p.accent,
                  activeThumbColor: p.onAccent,
                  onChanged: (on) => _setColorOrigin(context, on),
                ),
              ),
            ],
            if (sync.enabled) ...[
              SizedBox(height: r.s(18)),
              AccountActionTile(
                key: const Key('account-sync'),
                icon: Icons.sync,
                title: l10n.syncTitle,
                subtitle: sync.isEmpty
                    ? l10n.syncAllDone
                    : sync.attention > 0
                    ? l10n.syncStripAttention(sync.attention)
                    : l10n.syncStripPending(sync.pending),
                onTap: () => context.push('/sync'),
              ),
            ],
            SizedBox(height: r.s(18)),
            AccountSectionTitle(l10n.accountDeviceSection),
            AccountInfoRows(rows: deviceRows),
            // Para ver como esta armada la app: todos los modulos con datos
            // inventados, sin tocar el servidor. Se apaga al cerrar sesion.
            SizedBox(height: r.s(10)),
            ListenableBuilder(
              listenable: demo.listenable,
              builder: (context, _) => AccountActionTile(
                key: const Key('account-demo-switch'),
                icon: Icons.science_outlined,
                title: l10n.demoModeTitle,
                subtitle: demo.on ? l10n.demoModeOn : l10n.demoModeOff,
                onTap: () => _toggleDemo(context, !demo.on),
                trailing: Switch(
                  value: demo.on,
                  activeTrackColor: p.accent,
                  activeThumbColor: p.onAccent,
                  onChanged: (on) => _toggleDemo(context, on),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
