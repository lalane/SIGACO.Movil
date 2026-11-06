import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/new_ticket_cubit.dart';
import '../ticket_labels.dart';
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
            ..showSnackBar(
              SnackBar(
                key: const Key('new-ticket-saved'),
                content: Text(
                  state.warning == null
                      ? l10n.newTicketCreated
                      : l10n.ticketSavedPartly(state.warning!),
                ),
                duration: state.warning == null
                    ? const Duration(seconds: 4)
                    : const Duration(seconds: 10),
              ),
            );
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
        bool shows(NewTicketIssue i) =>
            state.showIssues && state.issues.contains(i);
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
                error: state.placement?.status == TicketPlacementStatus.offRoad
                    ? l10n.ticketPlacementOffRoad(ticketAxisToleranceMeters)
                    : null,
                child: _LocationBlock(
                  location: cubit.location!,
                  placement: state.placement,
                ),
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
            if (state.usesMatrix) ...[
              ModuleField(
                label: l10n.newTicketIndicator,
                error: categoryError && state.indicator == null
                    ? l10n.newTicketErrorFailure
                    : null,
                child: DropdownButtonFormField<String>(
                  key: const Key('new-ticket-indicator'),
                  initialValue: state.indicator,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                  decoration: moduleInput(
                    context,
                    error: categoryError && state.indicator == null,
                  ),
                  items: [
                    for (final i in state.indicators)
                      DropdownMenuItem(value: i, child: Text(i)),
                  ],
                  onChanged: (v) {
                    if (v != null) cubit.setIndicator(v);
                  },
                ),
              ),
              ModuleField(
                label: l10n.newTicketGroup,
                error:
                    categoryError &&
                        state.indicator != null &&
                        state.group == null
                    ? l10n.newTicketErrorFailure
                    : null,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('new-ticket-group-${state.indicator}'),
                  initialValue: state.group,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                  decoration: moduleInput(
                    context,
                    error:
                        categoryError &&
                        state.indicator != null &&
                        state.group == null,
                  ),
                  // Las subclasificaciones son largas: en el campo, una linea
                  // con puntos suspensivos; en la lista, completas.
                  selectedItemBuilder: (_) => [
                    for (final g in state.groups)
                      Text(g, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  items: [
                    for (final g in state.groups)
                      DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.indicator != null
                      ? (v) {
                          if (v != null) cubit.setGroup(v);
                        }
                      : null,
                ),
              ),
              ModuleField(
                label: l10n.newTicketFailure,
                error: categoryError && state.group != null
                    ? l10n.newTicketErrorFailure
                    : null,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'new-ticket-failure-${state.indicator}-${state.group}',
                  ),
                  initialValue: state.failure?.code,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                  decoration: moduleInput(
                    context,
                    error: categoryError && state.group != null,
                  ),
                  selectedItemBuilder: (_) => [
                    for (final f in state.groupFailures)
                      Text(
                        f.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                  items: [
                    for (final f in state.groupFailures)
                      DropdownMenuItem(
                        value: f.code,
                        child: Text(
                          f.label,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.group != null
                      ? (v) {
                          if (v != null) cubit.setCategory(v);
                        }
                      : null,
                ),
              ),
              ModuleField(
                label: l10n.newTicketAttention,
                child: Text(
                  state.failure == null
                      ? l10n.newTicketAttentionPending
                      : l10n.newTicketAttentionValue(
                          _attention(l10n, state.failure!),
                        ),
                  key: const Key('new-ticket-attention'),
                  style: moduleInkStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ] else
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
            // Con una falla de la Matriz la prioridad sale del plazo.
            if (state.failure == null)
              ModuleField(
                label: l10n.newTicketPriority,
                child: DropdownButtonFormField<TicketPriority>(
                  key: const Key('new-ticket-priority'),
                  initialValue: state.priority,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  decoration: moduleInput(context),
                  items: [
                    for (final p in TicketPriority.values)
                      DropdownMenuItem(
                        value: p,
                        child: Text(ticketPriorityLabel(l10n, p)),
                      ),
                  ],
                  onChanged: (p) {
                    if (p != null) cubit.setPriority(p);
                  },
                ),
              ),
            ModuleField(
              label: l10n.newTicketChainage,
              // Cuando el punto se ubica en la carretera, el km llega despues.
              child: KeyedSubtree(
                key: ValueKey('new-ticket-km-${state.placement?.km}'),
                child: TextFormField(
                  key: const Key('new-ticket-km'),
                  initialValue: state.kmLabel,
                  onChanged: cubit.setKm,
                  style: moduleInkStyle,
                  decoration: moduleInput(context, hint: 'KM 150+200'),
                ),
              ),
            ),
            ModuleField(
              label: l10n.newTicketKmEnd,
              error: shows(NewTicketIssue.kmEnd)
                  ? l10n.newTicketErrorKmEnd
                  : null,
              child: TextFormField(
                key: const Key('new-ticket-km-end'),
                initialValue: state.kmEndLabel,
                onChanged: cubit.setKmEnd,
                style: moduleInkStyle,
                decoration: moduleInput(
                  context,
                  hint: l10n.newTicketKmEndHint,
                  error: shows(NewTicketIssue.kmEnd),
                ),
              ),
            ),
            if (state.needsDirection)
              ModuleField(
                label: l10n.newTicketDirection,
                error: shows(NewTicketIssue.direction)
                    ? l10n.newTicketErrorDirection
                    : null,
                child: DropdownButtonFormField<String>(
                  key: const Key('new-ticket-direction'),
                  initialValue: state.direction,
                  isExpanded: true,
                  style: moduleInkStyle,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: Text(l10n.followUpSelect, style: moduleHintStyle),
                  decoration: moduleInput(
                    context,
                    error: shows(NewTicketIssue.direction),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'CRECIENTE',
                      child: Text(l10n.mapDirectionIncreasing),
                    ),
                    DropdownMenuItem(
                      value: 'DECRECIENTE',
                      child: Text(l10n.mapDirectionDecreasing),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) cubit.setDirection(v);
                  },
                ),
              ),
            ModuleField(
              label: l10n.followUpDescription,
              error: shows(NewTicketIssue.description)
                  ? l10n.newTicketErrorDescription
                  : null,
              child: TextFormField(
                key: const Key('new-ticket-description'),
                initialValue: state.description,
                onChanged: cubit.setDescription,
                minLines: 4,
                maxLines: 6,
                style: moduleInkStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration: moduleInput(
                  context,
                  hint: l10n.followUpFillIn,
                  error: shows(NewTicketIssue.description),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// El plazo de la falla: "Inmediato", "30 dias" o las horas.
String _attention(AppLocalizations l10n, TicketFailure f) {
  if (f.immediate) return l10n.newTicketAttentionImmediate;
  final days = f.days;
  if (days != null) return l10n.newTicketAttentionDays(days);
  return l10n.newTicketAttentionHours(f.attentionHours.round());
}

/// La ubicacion del registro, de solo lectura (FRM-02): donde, que tan precisa
/// es y de donde salio.
/// «KM 101+450 · Sentido creciente · tramo 381BMG0100 · a 12 m de la carretera».
String? _placementLine(AppLocalizations l10n, TicketPlacement? p) {
  if (p == null || p.status != TicketPlacementStatus.onRoad) return null;
  final parts = [
    ?kmLabel(p.km, null),
    if (!p.directionAmbiguous && p.direction == 'CRECIENTE')
      l10n.mapDirectionIncreasing,
    if (!p.directionAmbiguous && p.direction == 'DECRECIENTE')
      l10n.mapDirectionDecreasing,
    if (p.segmentCode != null) l10n.ticketPlacementSegment(p.segmentCode!),
    if (p.distanceMeters != null)
      l10n.ticketPlacementDistance(p.distanceMeters!.round()),
  ];
  return parts.join(' · ');
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.location, this.placement});

  final TicketLocation location;
  final TicketPlacement? placement;

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
      ?_placementLine(l10n, placement),
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
