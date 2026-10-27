import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../profile/profile_photo_cubit.dart';

/// El circulo de la persona: su foto de perfil si la tiene y, si no, sus
/// iniciales.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    required this.radius,
    required this.background,
    required this.foreground,
    required this.fontSize,
  });

  final String initials;
  final double radius;
  final Color background;
  final Color foreground;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final path = context.select((ProfilePhotoCubit c) => c.state.path);
    final file = path == null ? null : File(path);
    // Una foto que ya no esta en el disco se ve como si no existiera.
    final photo = file != null && file.existsSync() ? FileImage(file) : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      backgroundImage: photo,
      child: photo != null
          ? null
          : Text(
              initials,
              style: TextStyle(
                color: foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
