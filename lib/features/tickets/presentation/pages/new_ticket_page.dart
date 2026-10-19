import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/new_ticket_cubit.dart';
import '../../../../core/ui/module_form.dart';

/// Levantar un ticket nuevo. El mockup no trae esta pantalla: usa el mismo
/// formulario del seguimiento, con titulo, tipo y cadenamiento.
class NewTicketPage extends StatelessWidget {
  const NewTicketPage({super.key});

  Future<void> _takePhoto(BuildContext context, int slot) async {
    final cubit = context.read<NewTicketCubit>();
    final shot = await context.read<FileSource>().takePhoto();
    if (shot != null) cubit.setPhoto(slot, shot.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<NewTicketCubit, NewTicketState>(
      listenWhen: (a, b) => (!a.saved && b.saved) || (!a.failed && b.failed),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.saved) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.newTicketCreated)));
          context.pop();
        } else if (state.failed) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('new-ticket-failed'),
                content: Text(l10n.ticketSaveFailed),
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<NewTicketCubit>();
        final titleError =
            state.showIssues && state.issues.contains(NewTicketIssue.title);
        final categoryError =
            state.showIssues && state.issues.contains(NewTicketIssue.category);
        return ModuleFormScaffold(
          submitKey: const Key('ticket-form-submit'),
          header: SigacoModuleHeader(title: l10n.newTicketTitle),
          saving: state.saving,
          buttonLabel: l10n.newTicketCreate,
          buttonIcon: Icons.add,
          onSubmit: cubit.save,
          photos: ModulePhotoSlots(
            keyPrefix: 'ticket-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: [
            ModuleField(
              label: l10n.newTicketName,
              error: titleError ? l10n.newTicketErrorTitle : null,
              child: TextFormField(
                key: const Key('new-ticket-title'),
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
              label: l10n.newTicketCategory,
              error: categoryError ? l10n.newTicketErrorCategory : null,
              child: DropdownButtonFormField<String>(
                key: const Key('new-ticket-category'),
                initialValue: state.category,
                isExpanded: true,
                style: moduleInkStyle,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down),
                hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                decoration: moduleInput(context, error: categoryError),
                items: [
                  for (final c in state.categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (c) {
                  if (c != null) cubit.setCategory(c);
                },
              ),
            ),
            ModuleField(
              label: l10n.newTicketChainage,
              child: TextFormField(
                key: const Key('new-ticket-km'),
                initialValue: state.kmLabel,
                onChanged: cubit.setKm,
                style: moduleInkStyle,
                decoration: moduleInput(context, hint: 'KM 150+200'),
              ),
            ),
            ModuleField(
              label: l10n.followUpDescription,
              child: TextFormField(
                key: const Key('new-ticket-description'),
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
