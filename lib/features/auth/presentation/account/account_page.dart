import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/branding/sigaco_wordmark.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/demo/demo_mode.dart';
import '../../../../core/device/device_info_source.dart';
import '../../../../core/offline/sync_cubit.dart';
import '../../../../core/profile/profile_photo_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/profile_avatar.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_entities.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'account_cubit.dart';

String initialsOf(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

/// Informacion de la cuenta (FEAT-M01-03): perfil propio, cambio de contrasena,
/// cambio de concesion y cierre de sesion.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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

  Future<void> _switchConcession(
    BuildContext context,
    MyProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AuthBloc>();
    final router = GoRouter.of(context);
    final others = profile.availableConcessions
        .where((c) => c.id != profile.activeConcession?.id)
        .toList();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: p.gradientBottom,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: p.gradientTop),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.s(8), r.s(4), r.s(16), r.s(16)),
                child: Row(
                  children: [
                    BackButton(color: p.textOnTop),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SigacoWordmark(fontSize: r.s(26)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.accountTitle,
                              maxLines: 1,
                              style: TextStyle(
                                color: p.textOnTop.withValues(alpha: 0.8),
                                fontSize: r.s(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                if (state.status == AccountStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profile = state.profile;
                if (profile == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.menuLoadError,
                          style: TextStyle(color: p.textOnBottom),
                        ),
                        TextButton(
                          onPressed: context.read<AccountCubit>().load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                return _Body(
                  profile: profile,
                  language: lang,
                  version: _version,
                  device: _device,
                  onSwitchConcession: profile.availableConcessions.length > 1
                      ? () => _switchConcession(context, profile)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.profile,
    required this.language,
    required this.version,
    required this.device,
    required this.onSwitchConcession,
  });

  final MyProfile profile;
  final String language;
  final String version;
  final String device;
  final VoidCallback? onSwitchConcession;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final user = profile.user;
    final roads = profile.roads
        .map((road) => road.name.isEmpty ? road.code : road.name)
        .join(', ');
    final biometricAvailable = context.select(
      (AuthBloc b) => b.state.biometricAvailable,
    );
    final biometricEnabled = context.select(
      (AuthBloc b) => b.state.biometricEnabled,
    );
    // El servidor informa si la verificacion esta activa (DEV-MOB-052); sin ese
    // dato se usa lo deducido del acceso.
    final mfaFromLogin = context.select((AuthBloc b) => b.state.mfaActive);
    final mfaActive = profile.mfa?.active ?? mfaFromLogin;
    final settings = context.select((SettingsCubit c) => c.state);
    final demo = context.read<DemoMode>();
    // Ultima respuesta del servidor. Cuando exista la sincronizacion sin
    // conexion, aqui se mostrara la ultima sincronizacion.
    final lastContact = context.select(
      (ConnectivityCubit c) => c.state.lastContactAt,
    );
    // Zona horaria de la concesion: en ella se muestran las fechas del negocio.
    final zone = context.select((ConcessionZoneCubit c) => c.state);
    // Lo capturado sin conexion que aun no llego al servidor.
    final sync = context.watch<SyncCubit>().state;
    final rows = <(IconData, String, String)>[
      (Icons.person_outline, l10n.fieldUser, user.username),
      (Icons.mail_outline, l10n.fieldEmailShort, user.email),
      (
        Icons.badge_outlined,
        l10n.fieldProfile,
        profile.profileLabel(language).isEmpty
            ? '—'
            : profile.profileLabel(language),
      ),
      (
        Icons.location_on_outlined,
        l10n.fieldArea,
        user.organizationArea ?? '—',
      ),
      if (user.jobTitle != null)
        (Icons.work_outline, l10n.fieldJobTitle, user.jobTitle!),
      if (user.companyName != null)
        (Icons.business_outlined, l10n.fieldCompany, user.companyName!),
      (
        Icons.apartment_outlined,
        l10n.fieldConcession,
        profile.activeConcession?.name ?? '—',
      ),
      if (zone != null)
        (
          Icons.schedule_outlined,
          l10n.fieldTimezone,
          '${zone.id} (${zone.offsetLabelAt(DateTime.now())})',
        ),
      (Icons.add_road, l10n.fieldRoads, roads.isEmpty ? '—' : roads),
      (Icons.info_outline, l10n.fieldAppVersion, version),
      if (device.isNotEmpty)
        (Icons.smartphone_outlined, l10n.fieldDevice, device),
      (
        Icons.cloud_done_outlined,
        l10n.fieldLastConnection,
        lastContact == null
            ? '—'
            : DateFormat.yMd(
                Localizations.localeOf(context).toString(),
              ).add_Hm().format(lastContact),
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
                  Localizations.localeOf(context).toString(),
                ).add_Hm().format(sync.lastSyncAt!.toLocal()),
        ),
    ];

    return BlocListener<AuthBloc, AuthState>(
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
        // Centrado con ancho maximo en pantallas medias y grandes.
        padding: r
            .sidePadding(minGutter: r.s(20))
            .copyWith(top: r.s(20), bottom: r.s(32)),
        children: [
          Row(
            children: [
              InkWell(
                key: const Key('account-photo'),
                customBorder: const CircleBorder(),
                onTap: () => _changePhoto(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(
                      initials: initialsOf(user.fullName),
                      radius: r.s(32),
                      background: p.accent,
                      foreground: p.onAccent,
                      fontSize: r.s(22),
                    ),
                    Positioned(
                      right: -r.s(2),
                      bottom: -r.s(2),
                      child: CircleAvatar(
                        radius: r.s(11),
                        backgroundColor: p.gradientTop,
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: r.s(14),
                          color: p.accentOnBottom,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.s(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: p.textOnBottom,
                        fontSize: r.s(18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      profile.profileLabel(language),
                      style: TextStyle(
                        color: p.accentOnBottom,
                        fontSize: r.s(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(24)),
          Text(
            l10n.accountInfoTitle,
            style: TextStyle(
              color: p.textOnBottom,
              fontSize: r.s(17),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: r.s(2)),
          Text(
            l10n.accountInfoSubtitle,
            style: TextStyle(color: p.hint, fontSize: r.s(13)),
          ),
          SizedBox(height: r.s(8)),
          for (final (icon, label, value) in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: r.s(10)),
              // La etiqueta mide lo que necesita, hasta la mitad de la fila: con
              // texto grande se parte en dos lineas en vez de empujar el valor
              // fuera de la pantalla. El valor ocupa el resto, alineado a la derecha.
              child: LayoutBuilder(
                builder: (context, box) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: p.hint, size: r.s(20)),
                    SizedBox(width: r.s(12)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
                      child: Text(
                        label,
                        style: TextStyle(color: p.hint, fontSize: r.s(14)),
                      ),
                    ),
                    SizedBox(width: r.s(16)),
                    Expanded(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: p.textOnBottom,
                          fontSize: r.s(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: r.s(12)),
          if (onSwitchConcession != null) ...[
            _ActionTile(
              icon: Icons.swap_horiz,
              title: l10n.actionSwitchConcession,
              subtitle: l10n.actionSwitchConcessionSub,
              onTap: onSwitchConcession!,
            ),
            SizedBox(height: r.s(10)),
          ],
          if (sync.enabled) ...[
            _ActionTile(
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
            SizedBox(height: r.s(10)),
          ],
          _SectionTitle(l10n.securityTitle),
          _ActionTile(
            icon: Icons.lock_reset,
            title: l10n.changePasswordAction,
            subtitle: l10n.actionChangePasswordSub,
            onTap: () => context.push('/account/password'),
          ),
          SizedBox(height: r.s(10)),
          // La activa o desactiva un administrador (M02-05): aqui solo se
          // renueva la clave de una cuenta que ya la tiene.
          _ActionTile(
            icon: Icons.shield_outlined,
            title: l10n.mfaSettingTitle,
            subtitle: mfaActive ? l10n.mfaSettingOn : l10n.mfaSettingOff,
            onTap: mfaActive
                ? () => context.push('/account/mfa')
                : () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.mfaAdminManaged))),
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
            _ActionTile(
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
          // Idioma y apariencia se cambian solo aqui (no hay selectores en las
          // demas pantallas); antes de iniciar sesion se usa el idioma del telefono.
          SizedBox(height: r.s(18)),
          _SectionTitle(l10n.preferencesTitle),
          _ActionTile(
            icon: Icons.language,
            title: l10n.languageLabel,
            subtitle: language == 'pt'
                ? l10n.languagePortuguese
                : l10n.languageSpanish,
            onTap: () => _chooseLanguage(context),
          ),
          SizedBox(height: r.s(10)),
          _ActionTile(
            icon: Icons.palette_outlined,
            title: l10n.appearanceLabel,
            subtitle: switch (settings.appearance) {
              Appearance.original => l10n.appearanceOriginal,
              Appearance.day => l10n.appearanceDay,
              Appearance.night => l10n.appearanceNight,
            },
            onTap: () => _chooseAppearance(context, settings.appearance),
          ),
          if (settings.brandAvailable) ...[
            SizedBox(height: r.s(10)),
            _ActionTile(
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
          // Para ver como esta armada la app: todos los modulos con datos
          // inventados, sin tocar el servidor. Se apaga al cerrar sesion.
          SizedBox(height: r.s(10)),
          ListenableBuilder(
            listenable: demo.listenable,
            builder: (context, _) => _ActionTile(
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
          SizedBox(height: r.s(20)),
          PrimaryButton(
            label: l10n.signOut,
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  void _setColorOrigin(BuildContext context, bool concession) => context
      .read<SettingsCubit>()
      .setColorOrigin(concession ? ColorOrigin.concession : ColorOrigin.sigaco);

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final chosen = await _chooseOption<Locale>(
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

  Future<void> _chooseAppearance(
    BuildContext context,
    Appearance current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final chosen = await _chooseOption<Appearance>(
      context,
      title: l10n.appearanceLabel,
      selected: current,
      options: [
        (Appearance.original, l10n.appearanceOriginal),
        (Appearance.day, l10n.appearanceDay),
        (Appearance.night, l10n.appearanceNight),
      ],
    );
    if (chosen != null) cubit.setAppearance(chosen);
  }

  /// Hoja inferior con una lista de opciones; devuelve la elegida.
  Future<T?> _chooseOption<T>(
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

  /// Cambiar o quitar la foto de perfil: camara, galeria o volver a las
  /// iniciales.
  Future<void> _changePhoto(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ProfilePhotoCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      constraints: const BoxConstraints(maxWidth: Responsive.formMaxWidth),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.profilePhotoTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              key: const Key('photo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profilePhotoTake),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              key: const Key('photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profilePhotoGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (cubit.state.path != null)
              ListTile(
                key: const Key('photo-remove'),
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.profilePhotoRemove),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    switch (choice) {
      case 'camera':
        await cubit.change(ProfilePhotoSource.camera);
      case 'gallery':
        await cubit.change(ProfilePhotoSource.gallery);
      case 'remove':
        await cubit.remove();
      default:
        return;
    }
    if (cubit.state.failed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.profilePhotoFailed)));
    }
  }

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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(8)),
      child: Text(
        text,
        style: TextStyle(
          color: p.textOnBottom,
          fontSize: r.s(15),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Sustituye a la flecha (por ejemplo, un interruptor).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(r.s(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.s(16)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(r.s(14)),
          child: Row(
            children: [
              Icon(icon, color: p.accentOnDark, size: r.s(24)),
              SizedBox(width: r.s(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.s(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: r.s(12),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF94A3B8),
                    size: r.s(24),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
