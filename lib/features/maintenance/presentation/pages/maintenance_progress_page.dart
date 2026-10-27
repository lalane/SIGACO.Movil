import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../bloc/maintenance_progress_cubit.dart';

/// El formulario para registrar el avance de un mantenimiento: porcentaje,
/// volumen ejecutado (si se conoce) y una nota.
class MaintenanceProgressPage extends StatelessWidget {
  const MaintenanceProgressPage({super.key, this.unit});

  /// La unidad del volumen de la orden (`PZA`, `M2`), si se conoce.
  final String? unit;

  String _failure(AppLocalizations l10n, MaintenanceError e) => switch (e) {
    MaintenanceError.network => l10n.maintProgressNetwork,
    MaintenanceError.permissionDenied => l10n.maintProgressNoPermission,
    _ => l10n.maintProgressFailed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<MaintenanceProgressCubit, MaintenanceProgressState>(
      listenWhen: (a, b) =>
          (!a.saved && b.saved) || (a.error != b.error && b.error != null),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        if (state.saved) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.maintProgressSaved)),
          );
          context.pop(true);
        } else if (state.error != null) {
          messenger.showSnackBar(
            SnackBar(
              key: const Key('maintenance-progress-failed'),
              content: Text(_failure(l10n, state.error!)),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<MaintenanceProgressCubit>();
        final percentError =
            state.showIssues && state.issues.contains(ProgressIssue.percent);
        final volumeError =
            state.showIssues && state.issues.contains(ProgressIssue.volume);
        const decimal = TextInputType.numberWithOptions(decimal: true);
        final allowed = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
        return ModuleFormScaffold(
          submitKey: const Key('maintenance-progress-submit'),
          header: SigacoModuleHeader(title: l10n.maintProgressTitle),
          saving: state.saving,
          buttonLabel: l10n.maintProgressSave,
          buttonIcon: Icons.check,
          onSubmit: cubit.save,
          photos: const SizedBox.shrink(),
          fields: [
            ModuleField(
              label: l10n.maintProgressPercent,
              error: percentError ? l10n.maintProgressErrorPercent : null,
              child: TextFormField(
                key: const Key('maintenance-progress-percent'),
                initialValue: state.percent,
                onChanged: cubit.setPercent,
                keyboardType: decimal,
                inputFormatters: [allowed],
                style: moduleInkStyle,
                decoration: moduleInput(
                  context,
                  hint: '0 – 100',
                  suffix: const Icon(Icons.percent, color: Color(0xFF64748B)),
                  error: percentError,
                ),
              ),
            ),
            ModuleField(
              label: unit == null || unit!.isEmpty
                  ? l10n.maintProgressVolume
                  : l10n.maintProgressVolumeUnit(unit!),
              error: volumeError ? l10n.maintProgressErrorVolume : null,
              child: TextFormField(
                key: const Key('maintenance-progress-volume'),
                initialValue: state.volume,
                onChanged: cubit.setVolume,
                keyboardType: decimal,
                inputFormatters: [allowed],
                style: moduleInkStyle,
                decoration: moduleInput(
                  context,
                  hint: l10n.maintProgressOptional,
                  error: volumeError,
                ),
              ),
            ),
            ModuleField(
              label: l10n.maintProgressNotes,
              child: TextFormField(
                key: const Key('maintenance-progress-notes'),
                initialValue: state.notes,
                onChanged: cubit.setNotes,
                minLines: 3,
                maxLines: 6,
                style: moduleInkStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: moduleInput(
                  context,
                  hint: l10n.maintProgressOptional,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
