import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ticket.dart';
import '../bloc/follow_up_cubit.dart';
import '../ticket_labels.dart';
import '../../../../core/ui/module_form.dart';

/// El formulario de seguimiento de un ticket (mockup nuevo): fecha, hora,
/// estado, descripcion y hasta tres fotos.
class FollowUpPage extends StatelessWidget {
  const FollowUpPage({super.key});

  Future<void> _pickDate(BuildContext context, FollowUpState state) async {
    final cubit = context.read<FollowUpCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) cubit.setDate(picked);
  }

  Future<void> _pickTime(BuildContext context, FollowUpState state) async {
    final cubit = context.read<FollowUpCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.minutes ~/ 60,
        minute: state.minutes % 60,
      ),
    );
    if (picked != null) cubit.setMinutes(picked.hour * 60 + picked.minute);
  }

  Future<void> _takePhoto(BuildContext context, int slot) async {
    final cubit = context.read<FollowUpCubit>();
    final shot = await context.read<FileSource>().takePhoto();
    if (shot != null) cubit.setPhoto(slot, shot.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<FollowUpCubit, FollowUpState>(
      listenWhen: (a, b) => (!a.saved && b.saved) || (!a.failed && b.failed),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.saved) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.followUpSaved)));
          context.pop();
        } else if (state.failed) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('follow-up-failed'),
                content: Text(l10n.ticketSaveFailed),
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<FollowUpCubit>();
        final statusError =
            state.showIssues && state.issues.contains(FollowUpIssue.status);
        final descriptionError =
            state.showIssues &&
            state.issues.contains(FollowUpIssue.description);
        return ModuleFormScaffold(
          submitKey: const Key('ticket-form-submit'),
          header: SigacoModuleHeader(title: l10n.followUpTitle),
          saving: state.saving,
          buttonLabel: l10n.followUpSave,
          buttonIcon: Icons.check,
          onSubmit: cubit.save,
          photos: ModulePhotoSlots(
            keyPrefix: 'ticket-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: [
            ModuleField(
              label: l10n.followUpDate,
              child: ModulePickerField(
                key: const Key('follow-up-date'),
                value: formatCalendarDay(context, state.date),
                icon: Icons.calendar_today_outlined,
                onTap: () => _pickDate(context, state),
              ),
            ),
            ModuleField(
              label: l10n.followUpTime,
              child: ModulePickerField(
                key: const Key('follow-up-time'),
                value: minutesLabel(state.minutes),
                icon: Icons.schedule,
                onTap: () => _pickTime(context, state),
              ),
            ),
            ModuleField(
              label: l10n.followUpStatus,
              error: statusError ? l10n.followUpErrorStatus : null,
              child: DropdownButtonFormField<TicketStatus>(
                key: const Key('follow-up-status'),
                initialValue: state.status,
                isExpanded: true,
                style: moduleInkStyle,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                decoration: moduleInput(context, error: statusError),
                items: [
                  for (final s in TicketStatus.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(statusLabel(l10n, s)),
                    ),
                ],
                onChanged: (s) {
                  if (s != null) cubit.setStatus(s);
                },
              ),
            ),
            ModuleField(
              label: l10n.followUpDescription,
              error: descriptionError ? l10n.followUpErrorDescription : null,
              child: TextFormField(
                key: const Key('follow-up-description'),
                initialValue: state.description,
                onChanged: cubit.setDescription,
                minLines: 4,
                maxLines: 6,
                style: moduleInkStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: moduleInput(
                  context,
                  hint: l10n.followUpFillIn,
                  error: descriptionError,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
