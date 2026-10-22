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

/// Registrar un accidente nuevo con los campos del BBP (§7.8, "Accidentes
/// graves"): tipo, condiciones del lugar, causa, y un renglon por cada vehiculo
/// y por cada victima segun las cantidades. La gravedad del accidente es la de
/// su victima mas grave. Sigue sujeto a la homologacion OI-33.
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
        final vehicleError = issue(NewAccidentIssue.vehicle);
        final victimError = issue(NewAccidentIssue.victim);
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
            _pick<AccidentType>(
              context,
              key: 'new-accident-type',
              label: l10n.accidentTypeTitle,
              error: typeError ? l10n.newAccidentErrorType : null,
              value: state.type,
              options: AccidentType.values,
              text: (t) => typeLabel(l10n, t),
              onChanged: cubit.setType,
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
            _pick<AccidentZone>(
              context,
              key: 'new-accident-zone',
              label: l10n.accidentZoneTitle,
              value: state.zone,
              options: AccidentZone.values,
              text: (z) => zoneLabel(l10n, z),
              onChanged: cubit.setZone,
            ),
            _pick<AccidentWeather>(
              context,
              key: 'new-accident-weather',
              label: l10n.accidentWeatherTitle,
              value: state.weather,
              options: AccidentWeather.values,
              text: (w) => weatherLabel(l10n, w),
              onChanged: cubit.setWeather,
            ),
            _pick<RoadCondition>(
              context,
              key: 'new-accident-pavement-condition',
              label: l10n.accidentPavementConditionTitle,
              value: state.pavementCondition,
              options: RoadCondition.values,
              text: (c) => conditionLabel(l10n, c),
              onChanged: cubit.setPavementCondition,
            ),
            _pick<RoadLayout>(
              context,
              key: 'new-accident-layout',
              label: l10n.accidentLayoutTitle,
              value: state.layout,
              options: RoadLayout.values,
              text: (x) => layoutLabel(l10n, x),
              onChanged: cubit.setLayout,
            ),
            _pick<PavementType>(
              context,
              key: 'new-accident-pavement-type',
              label: l10n.accidentPavementTypeTitle,
              value: state.pavementType,
              options: PavementType.values,
              text: (p) => pavementTypeLabel(l10n, p),
              onChanged: cubit.setPavementType,
            ),
            _pick<RoadCondition>(
              context,
              key: 'new-accident-signage-condition',
              label: l10n.accidentSignageConditionTitle,
              value: state.signageCondition,
              options: RoadCondition.values,
              text: (c) => conditionLabel(l10n, c),
              onChanged: cubit.setSignageCondition,
            ),
            _pick<AccidentCause>(
              context,
              key: 'new-accident-cause',
              label: l10n.accidentCauseTitle,
              value: state.cause,
              options: AccidentCause.values,
              text: (c) => causeLabel(l10n, c),
              onChanged: cubit.setCause,
            ),
            _pick<AccidentPlace>(
              context,
              key: 'new-accident-place',
              label: l10n.accidentPlaceTitle,
              value: state.place,
              options: AccidentPlace.values,
              text: (p) => placeLabel(l10n, p),
              onChanged: cubit.setPlace,
            ),
            _Counter(
              keyPrefix: 'accident-vehicles',
              label: l10n.accidentVehiclesCount,
              count: state.vehicles.length,
              onChanged: cubit.setVehicleCount,
            ),
            for (var i = 0; i < state.vehicles.length; i++)
              _pick<VehicleType>(
                context,
                key: 'new-accident-vehicle-$i',
                label:
                    '${l10n.accidentVehicleTitle(i + 1)} · '
                    '${l10n.accidentVehicleTypeTitle}',
                error: vehicleError && state.vehicles[i] == null
                    ? l10n.newAccidentErrorVehicle
                    : null,
                value: state.vehicles[i],
                options: VehicleType.values,
                text: (v) => vehicleLabel(l10n, v),
                onChanged: (v) => cubit.setVehicleType(i, v),
              ),
            _Counter(
              keyPrefix: 'accident-victims',
              label: l10n.accidentVictimsCount,
              count: state.victims.length,
              onChanged: cubit.setVictimCount,
            ),
            for (var i = 0; i < state.victims.length; i++) ...[
              _pick<VictimSex>(
                context,
                key: 'new-accident-victim-sex-$i',
                label:
                    '${l10n.accidentVictimTitle(i + 1)} · '
                    '${l10n.accidentSexTitle}',
                value: state.victims[i].sex,
                options: VictimSex.values,
                text: (s) => sexLabel(l10n, s),
                onChanged: (s) => cubit.setVictimSex(i, s),
              ),
              _pick<AccidentSeverity>(
                context,
                key: 'new-accident-victim-severity-$i',
                label:
                    '${l10n.accidentVictimTitle(i + 1)} · '
                    '${l10n.accidentSeverityTitle}',
                error: victimError && state.victims[i].severity == null
                    ? l10n.newAccidentErrorVictim
                    : null,
                value: state.victims[i].severity,
                options: AccidentSeverity.values,
                text: (s) => severityLabel(l10n, s),
                onChanged: (s) => cubit.setVictimSeverity(i, s),
              ),
            ],
            if (state.victims.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${l10n.accidentSeverityTitle}: '
                  '${severityLabel(l10n, state.severity)}. '
                  '${l10n.accidentSeverityDerived}',
                  key: const Key('new-accident-derived-severity'),
                  style: moduleHintStyle,
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

/// Un campo de lista de opciones del formulario.
ModuleField _pick<T>(
  BuildContext context, {
  required String key,
  required String label,
  required T? value,
  required List<T> options,
  required String Function(T) text,
  required void Function(T) onChanged,
  String? error,
}) {
  final l10n = AppLocalizations.of(context);
  return ModuleField(
    label: label,
    error: error,
    child: DropdownButtonFormField<T>(
      key: Key(key),
      initialValue: value,
      isExpanded: true,
      style: moduleInkStyle,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down),
      hint: Text(l10n.followUpSelect, style: moduleHintStyle),
      decoration: moduleInput(context, error: error != null),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o, child: Text(text(o))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

/// Una cantidad con menos y mas: decide cuantos renglones se piden.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.keyPrefix,
    required this.label,
    required this.count,
    required this.onChanged,
  });

  final String keyPrefix;
  final String label;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ModuleField(
      label: label,
      child: Row(
        children: [
          IconButton.outlined(
            key: Key('$keyPrefix-minus'),
            icon: const Icon(Icons.remove),
            onPressed: count == 0 ? null : () => onChanged(count - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '$count',
              key: Key('$keyPrefix-count'),
              style: moduleInkStyle.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.outlined(
            key: Key('$keyPrefix-plus'),
            icon: const Icon(Icons.add),
            onPressed: count >= accidentMaxParties
                ? null
                : () => onChanged(count + 1),
          ),
        ],
      ),
    );
  }
}
