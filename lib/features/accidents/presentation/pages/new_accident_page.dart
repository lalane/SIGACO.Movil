import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/accident.dart';
import '../accident_labels.dart';
import '../bloc/new_accident_cubit.dart';

/// Registrar un accidente nuevo. El mockup no trae esta pantalla: usa el mismo
/// formulario de los tickets, con tipo y gravedad.
class NewAccidentPage extends StatelessWidget {
  const NewAccidentPage({super.key});

  Future<void> _takePhoto(BuildContext context, int slot) async {
    final cubit = context.read<NewAccidentCubit>();
    final shot = await context.read<FileSource>().takePhoto();
    if (shot != null) cubit.setPhoto(slot, shot.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<NewAccidentCubit, NewAccidentState>(
      listenWhen: (a, b) => (!a.saved && b.saved) || (!a.failed && b.failed),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.saved) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.newAccidentCreated)));
          context.pop();
        } else if (state.failed) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('new-accident-failed'),
                content: Text(l10n.ticketSaveFailed),
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<NewAccidentCubit>();
        bool issue(NewAccidentIssue i) =>
            state.showIssues && state.issues.contains(i);
        final titleError = issue(NewAccidentIssue.title);
        final typeError = issue(NewAccidentIssue.type);
        final severityError = issue(NewAccidentIssue.severity);
        return ModuleFormScaffold(
          submitKey: const Key('accident-form-submit'),
          header: SigacoModuleHeader(title: l10n.newAccidentTitle),
          saving: state.saving,
          buttonLabel: l10n.newAccidentCreate,
          buttonIcon: Icons.add,
          onSubmit: cubit.save,
          photos: ModulePhotoSlots(
            keyPrefix: 'accident-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: [
            ModuleField(
              label: l10n.newTicketName,
              error: titleError ? l10n.newTicketErrorTitle : null,
              child: TextFormField(
                key: const Key('new-accident-title'),
                initialValue: state.title,
                onChanged: cubit.setTitle,
                style: moduleInkStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: moduleInput(
                  context,
                  hint: l10n.followUpFillIn,
                  error: titleError,
                ),
              ),
            ),
            ModuleField(
              label: l10n.accidentTypeTitle,
              error: typeError ? l10n.newAccidentErrorType : null,
              child: DropdownButtonFormField<AccidentType>(
                key: const Key('new-accident-type'),
                initialValue: state.type,
                isExpanded: true,
                style: moduleInkStyle,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                decoration: moduleInput(context, error: typeError),
                items: [
                  for (final t in AccidentType.values)
                    DropdownMenuItem(value: t, child: Text(typeLabel(l10n, t))),
                ],
                onChanged: (t) {
                  if (t != null) cubit.setType(t);
                },
              ),
            ),
            ModuleField(
              label: l10n.accidentSeverityTitle,
              error: severityError ? l10n.newAccidentErrorSeverity : null,
              child: DropdownButtonFormField<AccidentSeverity>(
                key: const Key('new-accident-severity'),
                initialValue: state.severity,
                isExpanded: true,
                style: moduleInkStyle,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                decoration: moduleInput(context, error: severityError),
                items: [
                  for (final s in AccidentSeverity.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(severityLabel(l10n, s)),
                    ),
                ],
                onChanged: (s) {
                  if (s != null) cubit.setSeverity(s);
                },
              ),
            ),
            ModuleField(
              label: l10n.newTicketChainage,
              child: TextFormField(
                key: const Key('new-accident-km'),
                initialValue: state.kmLabel,
                onChanged: cubit.setKm,
                style: moduleInkStyle,
                decoration: moduleInput(context, hint: 'KM 150+200'),
              ),
            ),
            ModuleField(
              label: l10n.followUpDescription,
              child: TextFormField(
                key: const Key('new-accident-description'),
                initialValue: state.description,
                onChanged: cubit.setDescription,
                minLines: 4,
                maxLines: 6,
                style: moduleInkStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: moduleInput(context, hint: l10n.followUpFillIn),
              ),
            ),
          ],
        );
      },
    );
  }
}
