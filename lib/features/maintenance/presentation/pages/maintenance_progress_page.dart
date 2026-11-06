import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../bloc/maintenance_progress_cubit.dart';

/// Un numero con hasta dos decimales y sin ceros de sobra (`12.5`, `40`).
String progressNumber(double v) {
  final fixed = v.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
}

/// El formulario para registrar un seguimiento de un mantenimiento (HU-MC-10):
/// lo ejecutado en este seguimiento (que se suma al acumulado) o, si no se
/// conoce, el avance acumulado; una nota y hasta tres fotos.
class MaintenanceProgressPage extends StatelessWidget {
  const MaintenanceProgressPage({super.key, this.unit});

  /// La unidad del volumen de la orden (`PZA`, `M2`), si se conoce.
  final String? unit;

  String _failure(AppLocalizations l10n, MaintenanceProgressState s) =>
      switch (s.error!) {
        MaintenanceError.network => l10n.maintProgressNetwork,
        MaintenanceError.permissionDenied => l10n.maintProgressNoPermission,
        MaintenanceError.photosNotSaved => l10n.maintProgressPhotosFailed,
        MaintenanceError.invalid => s.errorMessage ?? l10n.maintProgressFailed,
        _ => l10n.maintProgressFailed,
      };

  Future<void> _takePhoto(BuildContext context, int slot) async {
    final cubit = context.read<MaintenanceProgressCubit>();
    final shot = await context.read<FileSource>().takePhoto();
    if (shot != null) cubit.setPhoto(slot, shot.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final u = unit ?? '';
    return BlocConsumer<MaintenanceProgressCubit, MaintenanceProgressState>(
      listenWhen: (a, b) =>
          (!a.saved && b.saved) || (a.error != b.error && b.error != null),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        if (state.saved) {
          final partly = state.error == MaintenanceError.photosNotSaved;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                partly
                    ? l10n.maintProgressPhotosFailed
                    : l10n.maintProgressSaved,
              ),
              duration: Duration(seconds: partly ? 8 : 4),
            ),
          );
          context.pop(true);
        } else if (state.error != null) {
          messenger.showSnackBar(
            SnackBar(
              key: const Key('maintenance-progress-failed'),
              content: Text(_failure(l10n, state)),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<MaintenanceProgressCubit>();
        final issue = state.showIssues && state.issues.isNotEmpty
            ? state.issues.first
            : null;
        final volumeError = switch (issue) {
          ProgressIssue.volume => l10n.maintProgressErrorVolume,
          ProgressIssue.volumeOverRemaining =>
            l10n.maintProgressErrorVolumeOver(
              '${progressNumber(state.remaining ?? 0)} $u'.trim(),
            ),
          ProgressIssue.missing => l10n.maintProgressErrorMissing,
          _ => null,
        };
        final percentError = switch (issue) {
          ProgressIssue.percent => l10n.maintProgressErrorPercent,
          ProgressIssue.percentBelowCurrent =>
            l10n.maintProgressErrorPercentBelow(
              progressNumber(state.currentPercent ?? 0),
            ),
          _ => null,
        };
        final current = state.currentPercent;
        final result = state.resultingPercent;
        const decimal = TextInputType.numberWithOptions(decimal: true);
        final allowed = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
        const muted = TextStyle(color: Color(0xFF64748B), fontSize: 13);
        return ModuleFormScaffold(
          submitKey: const Key('maintenance-progress-submit'),
          header: SigacoModuleHeader(title: l10n.maintProgressTitle),
          saving: state.saving,
          buttonLabel: l10n.maintProgressSave,
          buttonIcon: Icons.check,
          onSubmit: cubit.save,
          photos: ModulePhotoSlots(
            keyPrefix: 'maintenance-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: [
            if (current != null)
              Text(
                l10n.maintProgressStatus(
                  progressNumber(state.executedVolume ?? 0),
                  progressNumber(state.totalVolume!),
                  u,
                  progressNumber(current),
                  '${progressNumber(state.remaining!)} $u'.trim(),
                ),
                key: const Key('maintenance-progress-status'),
                style: muted,
              ),
            ModuleField(
              label: u.isEmpty
                  ? l10n.maintProgressVolume
                  : l10n.maintProgressVolumeUnit(u),
              error: volumeError,
              child: TextFormField(
                key: const Key('maintenance-progress-volume'),
                initialValue: state.volume,
                onChanged: cubit.setVolume,
                keyboardType: decimal,
                inputFormatters: [allowed],
                style: moduleInkStyle,
                decoration: moduleInput(
                  context,
                  hint: l10n.maintProgressVolumeRules,
                  error: volumeError != null,
                ),
              ),
            ),
            ModuleField(
              label: l10n.maintProgressPercent,
              error: percentError,
              child: TextFormField(
                key: const Key('maintenance-progress-percent'),
                initialValue: state.percent,
                onChanged: cubit.setPercent,
                // Con volumen el avance sale de el: no se escribe aparte.
                enabled: !state.usesVolume,
                keyboardType: decimal,
                inputFormatters: [allowed],
                style: moduleInkStyle,
                decoration: moduleInput(
                  context,
                  hint: current == null
                      ? '0 – 100'
                      : '${progressNumber(current)} – 100',
                  suffix: const Icon(Icons.percent, color: Color(0xFF64748B)),
                  error: percentError != null,
                ),
              ),
            ),
            if (result != null && state.issues.isEmpty)
              Text(
                l10n.maintProgressResult(progressNumber(result)),
                key: const Key('maintenance-progress-result'),
                style: muted.copyWith(fontWeight: FontWeight.w700),
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
