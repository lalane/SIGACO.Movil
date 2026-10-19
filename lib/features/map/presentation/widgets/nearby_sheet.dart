import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/map_settings.dart';
import '../../domain/entities/nearby_pin.dart';
import '../bloc/map_cubit.dart';
import '../map_labels.dart';

/// Activos cercanos a la ubicacion del usuario, con el radio configurable. Al
/// elegir uno se devuelve su pin para que el mapa lo seleccione.
Future<MapPin?> showNearbySheet(BuildContext context) {
  final cubit = context.read<MapCubit>();
  return showModalBottomSheet<MapPin>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _NearbySheet()),
  );
}

class _NearbySheet extends StatelessWidget {
  const _NearbySheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final p = context.palette;
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        final cubit = context.read<MapCubit>();
        final nearby = state.nearby;
        final radius = state.settings.nearbyRadiusMeters;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(16)),
              child: Column(
                key: const Key('map-nearby-sheet'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mapNearbyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.s(12)),
                  Text(
                    l10n.mapNearbyRadius,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SizedBox(height: r.s(8)),
                  Wrap(
                    spacing: r.s(8),
                    runSpacing: r.s(8),
                    children: [
                      for (final m in MapSettings.radiusOptionsMeters)
                        ChoiceChip(
                          key: Key('map-radius-${m.round()}'),
                          label: Text(distanceLabel(l10n, m)),
                          selected: radius == m,
                          onSelected: (_) => cubit.setRadius(m),
                        ),
                    ],
                  ),
                  SizedBox(height: r.s(12)),
                  Flexible(
                    child: _body(context, l10n, p, state, nearby, radius),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    SigacoPalette p,
    MapState state,
    List<NearbyPin> nearby,
    double radius,
  ) {
    String? message;
    if (state.location == null) {
      message = l10n.mapNearbyNeedLocation;
    } else if (!state.inventoryLoaded) {
      message = l10n.mapNearbyLoading;
    } else if (nearby.isEmpty) {
      message = l10n.mapNearbyEmpty(distanceLabel(l10n, radius));
    }
    if (message != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          message,
          key: const Key('map-nearby-message'),
          style: TextStyle(color: p.hint),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: nearby.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = nearby[i];
        final pin = n.pin;
        return ListTile(
          key: Key('map-nearby-${pin.id}'),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: pinColor(p, pin.status),
            child: Icon(
              layerIcon(pin.layer),
              size: 18,
              color: SigacoPalette.readableOn(pinColor(p, pin.status)),
            ),
          ),
          title: Text(pin.title),
          subtitle: Text([?pin.kmLabel, ?pin.subtitle].join(' · ')),
          trailing: Text(
            distanceLabel(l10n, n.distanceMeters),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onTap: () => Navigator.of(context).pop(pin),
        );
      },
    );
  }
}
