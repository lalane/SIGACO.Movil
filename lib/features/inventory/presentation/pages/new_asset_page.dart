import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/repositories/asset_capture_repository.dart';
import '../bloc/new_asset_cubit.dart';
import '../inventory_labels.dart';
import '../widgets/asset_attribute_field.dart';

/// El alta de un activo en campo. No hay diseno propio: usa el marco de los
/// formularios de la app (el del ticket nuevo). El formulario se arma con la
/// ficha vigente del tipo elegido. Al guardar vuelve con `true`.
class NewAssetPage extends StatelessWidget {
  const NewAssetPage({super.key, this.minAccuracyMeters = 30});

  /// Precision minima para dar por buena una lectura del GPS; peor que esto se
  /// avisa antes de guardar.
  final double minAccuracyMeters;

  Future<void> _submit(BuildContext context, NewAssetCubit cubit) async {
    final accuracy = cubit.state.position?.accuracyMeters;
    // Con campos por corregir no se pregunta nada: se muestran los errores.
    if (cubit.state.isValid &&
        cubit.state.pointLocates &&
        accuracy != null &&
        accuracy > minAccuracyMeters) {
      final l10n = AppLocalizations.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('asset-location-warning'),
          title: Text(l10n.ticketLocationIssueTitle),
          content: Text(
            l10n.ticketLocationLowAccuracy(
              accuracy.round().toString(),
              minAccuracyMeters.round().toString(),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('asset-location-cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.ticketLocationCancel),
            ),
            FilledButton(
              key: const Key('asset-location-confirm'),
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
    final cubit = context.read<NewAssetCubit>();
    final shot = await context.read<FileSource>().takePhoto();
    if (shot != null) cubit.setPhoto(slot, shot.path);
  }

  void _onState(BuildContext context, NewAssetState state) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = state.result;
    if (result != null) {
      final text = result.queued
          ? l10n.invNewQueued
          : result.warning != null
          ? l10n.invNewSavedPartly(result.warning!)
          : l10n.invNewSaved(result.code ?? '');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('asset-new-saved'),
            content: Text(text),
            duration: result.warning == null
                ? const Duration(seconds: 5)
                : const Duration(seconds: 10),
          ),
        );
      context.pop(true);
      return;
    }
    final failure = state.failure;
    if (failure == null) return;
    final text = switch (failure.error) {
      AssetCaptureError.permissionDenied => l10n.invNewNoPermission,
      AssetCaptureError.channelNotAllowed => l10n.invNewChannel,
      AssetCaptureError.noTemplate => l10n.invNewTemplateMissing,
      AssetCaptureError.network => l10n.invNewOffline,
      AssetCaptureError.validation when failure.message != null =>
        l10n.invNewFailedReason(failure.message!),
      _ => l10n.invNewFailed,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('asset-new-failed'),
          content: Text(text),
          duration: const Duration(seconds: 8),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<NewAssetCubit, NewAssetState>(
      listenWhen: (a, b) =>
          (a.result == null && b.result != null) ||
          (b.failure != null && a.failure != b.failure),
      listener: _onState,
      builder: (context, state) {
        if (state.typesStatus != NewAssetLoad.ready || state.types.isEmpty) {
          return _Blocked(state: state);
        }
        final cubit = context.read<NewAssetCubit>();
        return ModuleFormScaffold(
          submitKey: const Key('asset-new-submit'),
          header: SigacoModuleHeader(title: l10n.invNewTitle),
          saving: state.saving,
          buttonLabel: l10n.invNewSave,
          buttonIcon: Icons.add_location_alt_outlined,
          onSubmit: () => _submit(context, cubit),
          photos: ModulePhotoSlots(
            keyPrefix: 'asset-photo',
            photos: state.photos,
            onPick: (i) => _takePhoto(context, i),
            onRemove: (i) => cubit.setPhoto(i, null),
          ),
          fields: _fields(context, state),
        );
      },
    );
  }

  List<Widget> _fields(BuildContext context, NewAssetState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NewAssetCubit>();
    final language = appLanguage(context);
    final zone = context.watch<ConcessionZoneCubit>().state;
    bool shows(NewAssetIssue i) => state.showIssues && state.issues.contains(i);
    final attributeIssues = state.showIssues
        ? state.attributeIssues
        : const <String, AttributeIssue>{};
    final type = state.type;
    return [
      ModuleField(
        label: '${l10n.invNewType} *',
        error: shows(NewAssetIssue.type) ? l10n.invNewTypeError : null,
        child: DropdownButtonFormField<String>(
          key: const Key('asset-new-type'),
          initialValue: type?.code,
          isExpanded: true,
          style: moduleInkStyle,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: Text(l10n.followUpSelect, style: moduleHintStyle),
          decoration: moduleInput(context, error: shows(NewAssetIssue.type)),
          items: [
            for (final t in state.types)
              DropdownMenuItem(
                value: t.code,
                child: Text(
                  t.label(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (code) {
            for (final t in state.types) {
              if (t.code == code) cubit.chooseType(t);
            }
          },
        ),
      ),
      ModuleField(
        label: l10n.ticketLocationTitle,
        error: shows(NewAssetIssue.location) ? l10n.invNewLocationError : null,
        child: _LocationBlock(state: state, onRetry: cubit.readPosition),
      ),
      ModuleField(
        label: l10n.invNewKm,
        error: shows(NewAssetIssue.km) ? l10n.invNewKmError : null,
        // Cuando el punto se ubica en la carretera, el km llega despues.
        child: KeyedSubtree(
          key: ValueKey('asset-new-km-${state.placement?.km}'),
          child: TextFormField(
            key: const Key('asset-new-km'),
            initialValue: state.kmLabel,
            onChanged: cubit.setKm,
            style: moduleInkStyle,
            decoration: moduleInput(
              context,
              hint: 'KM 150+200',
              error: shows(NewAssetIssue.km),
            ),
          ),
        ),
      ),
      ModuleField(
        label: (type?.requiresKmEnd ?? false)
            ? '${l10n.invNewKmEnd} *'
            : l10n.invNewKmEnd,
        error: shows(NewAssetIssue.kmEnd)
            ? (state.kmEndLabel.trim().isEmpty
                  ? l10n.invNewKmEndRequired
                  : l10n.invNewKmEndError)
            : null,
        child: TextFormField(
          key: const Key('asset-new-km-end'),
          initialValue: state.kmEndLabel,
          onChanged: cubit.setKmEnd,
          style: moduleInkStyle,
          decoration: moduleInput(
            context,
            hint: (type?.requiresKmEnd ?? false)
                ? 'KM 150+400'
                : l10n.invNewKmEndHint,
            error: shows(NewAssetIssue.kmEnd),
          ),
        ),
      ),
      ModuleField(
        label: l10n.invNewDirection,
        error: shows(NewAssetIssue.direction)
            ? l10n.invNewDirectionError
            : null,
        child: KeyedSubtree(
          key: ValueKey('asset-new-direction-${state.placement?.direction}'),
          child: DropdownButtonFormField<String>(
            key: const Key('asset-new-direction'),
            initialValue: state.direction,
            isExpanded: true,
            style: moduleInkStyle,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: Text(l10n.followUpSelect, style: moduleHintStyle),
            decoration: moduleInput(
              context,
              error: shows(NewAssetIssue.direction),
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
      ),
      if (type != null) ..._templateFields(context, state),
      for (final f in state.fields)
        AssetAttributeField(
          key: ValueKey('asset-attr-${state.template?.number}-${f.key}'),
          field: f,
          value: state.values[f.key],
          onChanged: (v) => cubit.setValue(f.key, v),
          language: language,
          zone: zone,
          options: state.catalogs[f.catalogCode] ?? const [],
          error: switch (attributeIssues[f.key]) {
            final issue? => attributeIssueText(l10n, f, issue),
            null => _serverError(state, f.key),
          },
        ),
      ModuleField(
        label: l10n.invDescription,
        child: TextFormField(
          key: const Key('asset-new-description'),
          initialValue: state.description,
          onChanged: cubit.setDescription,
          style: moduleInkStyle,
          textCapitalization: TextCapitalization.sentences,
          decoration: moduleInput(context, hint: l10n.invNewDescriptionHint),
        ),
      ),
      ModuleField(
        label: l10n.invNotes,
        child: TextFormField(
          key: const Key('asset-new-notes'),
          initialValue: state.notes,
          onChanged: cubit.setNotes,
          minLines: 3,
          maxLines: 5,
          style: moduleInkStyle,
          textCapitalization: TextCapitalization.sentences,
          decoration: moduleInput(context, hint: l10n.invNewDescriptionHint),
        ),
      ),
    ];
  }

  /// El estado de la ficha del tipo mientras llega (o si no llega).
  List<Widget> _templateFields(BuildContext context, NewAssetState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NewAssetCubit>();
    switch (state.templateStatus) {
      case NewAssetLoad.loading:
        return [
          Padding(
            key: const Key('asset-new-template-loading'),
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(l10n.invNewTemplateLoading, style: moduleInkStyle),
              ],
            ),
          ),
        ];
      case NewAssetLoad.failure:
        return [
          Padding(
            key: const Key('asset-new-template-error'),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.templateError == AssetCaptureError.noTemplate
                      ? l10n.invNewTemplateMissing
                      : l10n.invNewTemplateError,
                  style: moduleInkStyle.copyWith(
                    color: const Color(0xFFDC2626),
                  ),
                ),
                if (state.templateError != AssetCaptureError.noTemplate)
                  TextButton.icon(
                    key: const Key('asset-new-template-retry'),
                    // Sobre la tarjeta blanca, el acento legible.
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.accentOnLight,
                    ),
                    onPressed: cubit.retryTemplate,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.invRetry),
                  ),
              ],
            ),
          ),
        ];
      case NewAssetLoad.ready:
        if (state.template != null && state.fields.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(l10n.invNewNoFields, style: moduleHintStyle),
            ),
          ];
        }
        return const [];
    }
  }

  /// Lo que dijo el servidor de un campo de la ficha, si lo rechazo.
  static String? _serverError(NewAssetState state, String key) {
    final errors = state.failure?.fieldErrors;
    if (errors == null) return null;
    for (final e in errors.entries) {
      if (e.key.toLowerCase() == 'attributes.${key.toLowerCase()}') {
        return e.value.firstOrNull;
      }
    }
    return null;
  }
}

/// Mientras llegan los tipos, o si no se pueden traer.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.state});

  final NewAssetState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final cubit = context.read<NewAssetCubit>();
    final Widget body;
    if (state.typesStatus == NewAssetLoad.loading) {
      body = const Center(
        key: Key('asset-new-loading'),
        child: CircularProgressIndicator(),
      );
    } else if (state.typesStatus == NewAssetLoad.ready) {
      body = KeyedSubtree(
        key: const Key('asset-new-empty'),
        child: ModuleStateView(
          icon: Icons.category_outlined,
          body: l10n.invNewTypesEmpty,
        ),
      );
    } else {
      final denied = state.typesError == AssetCaptureError.permissionDenied;
      body = KeyedSubtree(
        key: const Key('asset-new-types-error'),
        child: ModuleStateView(
          icon: denied ? Icons.lock_outline : Icons.cloud_off_outlined,
          title: denied ? l10n.invNewNoPermission : l10n.invNewTypesError,
          retryLabel: denied ? null : l10n.invRetry,
          onRetry: denied ? null : cubit.loadTypes,
          retryKey: const Key('asset-new-retry'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: p.gradientTop,
      body: Column(
        children: [
          SigacoModuleHeader(title: l10n.invNewTitle),
          Expanded(
            child: Container(color: moduleSheet, child: body),
          ),
        ],
      ),
    );
  }
}

/// Donde se da de alta: lo que leyo el GPS y donde cae sobre la carretera.
class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.state, required this.onRetry});

  final NewAssetState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final position = state.position;
    final placement = state.placement;
    final lines = <String>[];
    if (state.gps == GpsStatus.reading && position == null) {
      lines.add(l10n.invNewGpsReading);
    } else if (position == null) {
      lines.add(l10n.invNewGpsUnavailable);
    } else {
      lines.add(l10n.invNewGpsOrigin);
      lines.add(
        '${moduleDms(position.latitude, latitude: true)}  '
        '${moduleDms(position.longitude, latitude: false)}',
      );
      if (position.accuracyMeters != null) {
        lines.add(
          l10n.ticketLocationAccuracy(
            position.accuracyMeters!.round().toString(),
          ),
        );
      }
      switch (placement?.status) {
        case RoadPlacementStatus.onRoad:
          lines.add(
            [
              ?placement!.roadCode,
              ?kmLabel(placement.km, null),
              if (!placement.directionAmbiguous &&
                  placement.direction == 'CRECIENTE')
                l10n.mapDirectionIncreasing,
              if (!placement.directionAmbiguous &&
                  placement.direction == 'DECRECIENTE')
                l10n.mapDirectionDecreasing,
              if (placement.segmentCode != null)
                l10n.ticketPlacementSegment(placement.segmentCode!),
              if (placement.distanceMeters != null)
                l10n.ticketPlacementDistance(placement.distanceMeters!.round()),
            ].join(' · '),
          );
        case RoadPlacementStatus.offRoad:
          lines.add(l10n.invNewOffRoad);
        case RoadPlacementStatus.unknown:
          lines.add(l10n.invNewPlacementUnknown);
        case null:
          break;
      }
      if (!(state.type?.acceptsPoint ?? true)) {
        lines.add(l10n.invNewPointOnlyKm);
      }
    }
    return Container(
      key: const Key('asset-new-location'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, color: Color(0xFF475569)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in lines) Text(l, style: moduleInkStyle),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('asset-new-gps'),
              style: TextButton.styleFrom(
                foregroundColor: context.palette.accentOnLight,
              ),
              onPressed: state.gps == GpsStatus.reading ? null : onRetry,
              icon: const Icon(Icons.my_location),
              label: Text(l10n.invNewGpsRetry),
            ),
          ),
        ],
      ),
    );
  }
}
