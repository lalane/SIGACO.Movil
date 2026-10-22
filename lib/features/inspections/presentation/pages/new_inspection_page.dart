import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/new_inspection_cubit.dart';

/// Crear un monitoreo: el tipo trae el checklist; el nombre, el kilometro, el
/// tramo y el sentido son opcionales.
class NewInspectionPage extends StatelessWidget {
  const NewInspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<NewInspectionCubit, NewInspectionState>(
      listenWhen: (a, b) => (!a.saved && b.saved) || (!a.failed && b.failed),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.saved) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.inspNewCreated)));
          context.pop();
        } else if (state.failed) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('new-inspection-failed'),
                content: Text(l10n.ticketSaveFailed),
              ),
            );
        }
      },
      builder: (context, state) {
        final cubit = context.read<NewInspectionCubit>();
        final typeError = state.showIssues && state.typeMissing;
        return ModuleFormScaffold(
          submitKey: const Key('inspection-form-submit'),
          header: SigacoModuleHeader(title: l10n.inspNew),
          saving: state.saving,
          buttonLabel: l10n.inspNewCreate,
          buttonIcon: Icons.add,
          onSubmit: cubit.save,
          photos: const SizedBox.shrink(),
          fields: [
            if (state.status == NewInspectionStatus.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    key: Key('new-inspection-loading'),
                  ),
                ),
              )
            else if (state.status == NewInspectionStatus.failure ||
                state.templates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      l10n.inspNewNoTemplates,
                      key: const Key('new-inspection-no-templates'),
                      style: moduleHintStyle,
                    ),
                    TextButton(
                      onPressed: cubit.load,
                      child: Text(l10n.cfgGateRetry),
                    ),
                  ],
                ),
              )
            else ...[
              ModuleField(
                label: l10n.inspNewType,
                error: typeError ? l10n.inspNewErrorType : null,
                child: DropdownButtonFormField<String>(
                  key: const Key('new-inspection-type'),
                  initialValue: state.type,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                  decoration: moduleInput(context, error: typeError),
                  items: [
                    for (final t in state.templates)
                      DropdownMenuItem(value: t.type, child: Text(t.type)),
                  ],
                  onChanged: (v) {
                    if (v != null) cubit.setType(v);
                  },
                ),
              ),
              ModuleField(
                label: l10n.inspNewName,
                child: TextFormField(
                  key: const Key('new-inspection-title'),
                  initialValue: state.title,
                  onChanged: cubit.setTitle,
                  style: moduleInkStyle,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: moduleInput(context, hint: l10n.inspNewNameHint),
                ),
              ),
              ModuleField(
                label: l10n.newTicketChainage,
                child: TextFormField(
                  key: const Key('new-inspection-km'),
                  initialValue: state.kmLabel,
                  onChanged: cubit.setKm,
                  style: moduleInkStyle,
                  decoration: moduleInput(context, hint: 'KM 150+200'),
                ),
              ),
              ModuleField(
                label: l10n.inspSegment,
                child: TextFormField(
                  key: const Key('new-inspection-segment'),
                  initialValue: state.segmentCode,
                  onChanged: cubit.setSegment,
                  style: moduleInkStyle,
                  decoration: moduleInput(context, hint: '381BMG0160'),
                ),
              ),
              ModuleField(
                label: l10n.inspDirection,
                child: TextFormField(
                  key: const Key('new-inspection-direction'),
                  initialValue: state.direction,
                  onChanged: cubit.setDirection,
                  style: moduleInkStyle,
                  decoration: moduleInput(context),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
