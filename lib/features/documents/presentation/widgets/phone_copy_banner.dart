import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aviso de que lo que se ve viene del telefono y de cuando es: sin conexion no
/// se presenta informacion atrasada como si fuera nueva (CA-HU-MOB-03-01-06).
class PhoneCopyBanner extends StatelessWidget {
  const PhoneCopyBanner({super.key, required this.savedAt});

  /// UTC: cuando se guardo lo que se muestra.
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    return Container(
      key: const Key('docs-phone-copy'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(8)),
      color: p.hint.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: r.s(16), color: p.hint),
          SizedBox(width: r.s(8)),
          Expanded(
            child: Text(
              l10n.docsFromPhone(formatInZone(context, savedAt, zone)),
              style: TextStyle(color: p.textOnBottom, fontSize: r.s(12.5)),
            ),
          ),
        ],
      ),
    );
  }
}
