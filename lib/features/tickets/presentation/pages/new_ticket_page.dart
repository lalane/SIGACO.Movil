import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../domain/entities/ticket.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/new_ticket_cubit.dart';
import '../../../../core/ui/module_form.dart';

/// Levantar un ticket nuevo. El mockup no trae esta pantalla: usa el mismo
/// formulario del seguimiento, con titulo, tipo y cadenamiento.
class NewTicketPage extends StatelessWidget {
  const NewTicketPage({super.key, this.minAccuracyMeters = 30});

  /// Precision minima para dar por buena una lectura del GPS (DEC-005); peor que
  /// esto se avisa antes de guardar.
  final double minAccuracyMeters;

  /// Guarda; si la ubicacion es dudosa (poca precision o una posicion vieja)
  /// primero lo avisa y deja elegir.
  Future<void> _submit(BuildContext context, NewTicketCubit cubit) async {
    final issue = cubit.location?.issue(minAccuracyMeters);
    // Con campos por corregir no se pregunta nada: se muestran los errores.
    if (issue != null && cubit.state.issues.isEmpty) {
      final l10n = AppLocalizations.of(context);
      final accuracy = cubit.location?.accuracyMeters ?? 0;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('ticket-location-warning'),
          title: Text(l10n.ticketLocationIssueTitle),
          content: Text(
            issue == TicketLocationIssue.lowAccuracy
                ? l10n.ticketLocationLowAccuracy(
                    accuracy.round().toString(),
                    minAccuracyMeters.round().toString(),
                  )
                : l10n.ticketLocationLastKnownWarn,
          ),
          actions: [
            TextButton(
              key: const Key('ticket-location-cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.ticketLocationCancel),
            ),
            FilledButton(
              key: const Key('ticket-location-confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.ticketLocationSaveAnyway),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await cubit.save();
  }

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
          onSubmit: () => _submit(context, cubit),
          photos: ModulePhotoSlots(
            keyPrefix: 'ticket-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: [
            if (cubit.location != null)
              ModuleField(
                label: l10n.ticketLocationTitle,
                child: _LocationBlock(location: cubit.location!),
              ),
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

/// La ubicacion del registro, de solo lectura (FRM-02): donde, que tan precisa
/// es y de donde salio.
class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.location});

  final TicketLocation location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = switch (location.origin) {
      TicketLocationOrigin.gps => l10n.ticketLocOriginGps,
      TicketLocationOrigin.lastKnown => l10n.ticketLocOriginLastKnown,
      TicketLocationOrigin.mapPoint => l10n.ticketLocOriginMapPoint,
      TicketLocationOrigin.asset => l10n.ticketLocOriginAsset,
    };
    final readAt = location.readAt;
    final ago =
        location.origin == TicketLocationOrigin.lastKnown && readAt != null
        ? ' ${l10n.ticketLocationAgo(DateTime.now().toUtc().difference(readAt).inMinutes)}'
        : '';
    final lines = [
      '$origin$ago',
      '${moduleDms(location.latitude, latitude: true)}  '
          '${moduleDms(location.longitude, latitude: false)}',
      if (location.accuracyMeters != null)
        l10n.ticketLocationAccuracy(
          location.accuracyMeters!.round().toString(),
        ),
      if (location.assetId != null) l10n.ticketLocationAsset(location.assetId!),
    ];
    return Container(
      key: const Key('ticket-location'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_outlined, color: Color(0xFF475569)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final l in lines) Text(l, style: moduleInkStyle)],
            ),
          ),
        ],
      ),
    );
  }
}
