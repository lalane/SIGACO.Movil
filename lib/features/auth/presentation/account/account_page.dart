import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/profile/profile_photo_cubit.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_entities.dart';
import 'account_cubit.dart';
import 'account_widgets.dart';

String initialsOf(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

/// Mi cuenta (FEAT-M01-03): el perfil de la persona, de solo lectura, y la foto.
/// La configuracion de la app esta en su propia pantalla.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return AccountScaffold(
      title: l10n.accountTitle,
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
            language: Localizations.localeOf(context).languageCode,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile, required this.language});

  final MyProfile profile;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final user = profile.user;
    final roads = profile.roads
        .map((road) => road.name.isEmpty ? road.code : road.name)
        .join(', ');
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
      (Icons.business_outlined, l10n.fieldCompany, user.companyName ?? '—'),
      (Icons.groups_outlined, l10n.fieldTeam, user.teamName ?? '—'),
      (
        Icons.apartment_outlined,
        l10n.fieldConcession,
        profile.activeConcession?.name ?? '—',
      ),
      (Icons.add_road, l10n.fieldRoads, roads.isEmpty ? '—' : roads),
    ];

    return Column(
      children: [
        _ProfileCard(
          user: user,
          profile: profile,
          language: language,
          onChangePhoto: () => _changePhoto(context),
        ),
        Expanded(
          child: ListView(
            key: const Key('account-profile'),
            // Centrado con ancho maximo en pantallas medias y grandes.
            padding: r
                .sidePadding(minGutter: r.s(20))
                .copyWith(top: r.s(12), bottom: r.s(32)),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: r.s(20),
                    backgroundColor: p.accent,
                    child: Icon(Icons.person, color: p.onAccent, size: r.s(22)),
                  ),
                  SizedBox(width: r.s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.accountInfoTitle,
                          style: TextStyle(
                            color: p.textOnBottom,
                            fontSize: r.s(17),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.accountInfoSubtitle,
                          style: TextStyle(color: p.hint, fontSize: r.s(13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.s(8)),
              AccountInfoRows(rows: rows),
              SizedBox(height: r.s(16)),
              AccountActionTile(
                key: const Key('account-settings-entry'),
                icon: Icons.settings_outlined,
                title: l10n.accountSettingsTitle,
                subtitle: l10n.accountSettingsSub,
                onTap: () => context.push('/account/settings'),
              ),
            ],
          ),
        ),
      ],
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
}

/// La tarjeta de arriba de Mi cuenta (mockup): foto cuadrada con su boton para
/// cambiarla, nombre, cargo y area, sobre un degradado que baja de la cabecera.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.profile,
    required this.language,
    required this.onChangePhoto,
  });

  final CurrentUser user;
  final MyProfile profile;
  final String language;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final path = context.select((ProfilePhotoCubit c) => c.state.path);
    final file = path == null ? null : File(path);
    final photo = file != null && file.existsSync() ? file : null;
    final side = r.s(76);
    final role = user.jobTitle ?? profile.profileLabel(language);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.gradientTop, p.gradientBottom],
        ),
      ),
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(12)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.formMaxWidth),
          child: Material(
            key: const Key('account-card'),
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(r.s(24)),
            child: Padding(
              padding: EdgeInsets.all(r.s(16)),
              child: Row(
                children: [
                  InkWell(
                    key: const Key('account-photo'),
                    borderRadius: BorderRadius.circular(r.s(16)),
                    onTap: onChangePhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(r.s(16)),
                          child: SizedBox(
                            width: side,
                            height: side,
                            child: photo == null
                                ? ColoredBox(
                                    color: p.accent,
                                    child: Center(
                                      child: Text(
                                        initialsOf(user.fullName),
                                        style: TextStyle(
                                          color: p.onAccent,
                                          fontSize: r.s(24),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.file(photo, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          left: -r.s(4),
                          top: -r.s(4),
                          child: CircleAvatar(
                            radius: r.s(11),
                            backgroundColor: const Color(0xFF94A3B8),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: r.s(13),
                              color: Colors.white,
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
                          user.fullName.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF1E293B),
                            fontSize: r.s(14),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (role.isNotEmpty)
                          Text(
                            role,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF475569),
                              fontSize: r.s(12.5),
                            ),
                          ),
                        if (user.organizationArea != null)
                          Text(
                            '${l10n.fieldArea}: ${user.organizationArea}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: r.s(12),
                            ),
                          ),
                        SizedBox(height: r.s(8)),
                        FilledButton.icon(
                          key: const Key('account-photo-button'),
                          onPressed: onChangePhoto,
                          icon: Icon(Icons.photo_camera, size: r.s(16)),
                          label: Text(l10n.profilePhotoChange),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.onAccent,
                            visualDensity: VisualDensity.compact,
                            textStyle: TextStyle(
                              fontSize: r.s(13),
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
      ),
    );
  }
}
