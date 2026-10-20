import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../bloc/inventory_detail_cubit.dart';
import '../inventory_labels.dart';
import '../widgets/inventory_widgets.dart';

/// La ficha de un activo: estado, datos y el boton para verlo en el mapa.
class InventoryDetailPage extends StatelessWidget {
  const InventoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<InventoryDetailCubit, InventoryDetailState>(
      builder: (context, state) {
        final asset = state.asset;
        if (asset != null) return _Detail(asset: asset);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.invDetailTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == InventoryDetailStatus.failure
                      ? InventoryStateView(
                          error: state.error ?? InventoryError.server,
                          onRetry: context.read<InventoryDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('inventory-detail-loading'),
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.asset});

  final InventoryAsset asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    const none = '—';
    final latitude = asset.latitude;
    final longitude = asset.longitude;
    return Scaffold(
      backgroundColor: p.gradientTop,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.formMaxWidth,
                ),
                child: ListView(
                  key: const Key('inventory-detail'),
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        child: Row(
                          children: [
                            const ModuleBackPill(
                              key: Key('inventory-detail-back'),
                            ),
                            const Spacer(),
                            ModuleStatusPill(
                              key: const Key('inventory-detail-condition'),
                              label: conditionLabel(l10n, asset.condition),
                              color: conditionColor(asset.condition),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.s(24)),
                      decoration: BoxDecoration(
                        color: moduleSurface,
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            key: const Key('inventory-detail-title'),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PlusJakartaSans',
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                              fontSize: r.s(28),
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: r.s(10)),
                          Text(
                            '${asset.id} · ${asset.category}',
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(16),
                            ),
                          ),
                          if (asset.notes != null) ...[
                            SizedBox(height: r.s(16)),
                            Text(
                              l10n.invNotes,
                              style: TextStyle(
                                color: moduleMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: r.s(15),
                              ),
                            ),
                            SizedBox(height: r.s(6)),
                            Text(
                              asset.notes!,
                              key: const Key('inventory-detail-notes'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: r.s(16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(28)),
                    Text(
                      l10n.invDetailsTitle,
                      style: TextStyle(
                        color: const Color(0xFF9AA3C7),
                        fontSize: r.s(16),
                      ),
                    ),
                    SizedBox(height: r.s(14)),
                    KeyedSubtree(
                      key: const Key('inventory-info'),
                      child: ModuleInfoGrid(
                        items: [
                          ModuleInfo(
                            Icons.category_outlined,
                            l10n.invCategoryLabel,
                            asset.category,
                          ),
                          ModuleInfo(
                            Icons.route,
                            l10n.invKm,
                            asset.kmLabel ?? none,
                          ),
                          ModuleInfo(
                            Icons.fact_check,
                            l10n.invSegment,
                            asset.segmentCode ?? none,
                          ),
                          ModuleInfo(
                            Icons.explore,
                            l10n.invDirection,
                            asset.direction ?? none,
                          ),
                          ModuleInfo(
                            Icons.calendar_today_outlined,
                            l10n.invInstalled,
                            asset.installedAt == null
                                ? none
                                : moduleDay(asset.installedAt!, zone),
                          ),
                          ModuleInfo(
                            Icons.event_available_outlined,
                            l10n.invLastInspection,
                            asset.lastInspectionAt == null
                                ? none
                                : moduleDay(asset.lastInspectionAt!, zone),
                          ),
                          ModuleInfo(
                            Icons.place_outlined,
                            l10n.invCoordinates,
                            latitude == null || longitude == null
                                ? none
                                : '${moduleDms(latitude, latitude: true)}\n'
                                      '${moduleDms(longitude, latitude: false)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ModuleActionBar(
            actions: [
              ModuleActionButton(
                key: const Key('inventory-action-map'),
                icon: Icons.map_outlined,
                tooltip: l10n.invViewOnMap,
                onTap: () {
                  if (!asset.hasLocation) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.invNoLocation)),
                      );
                    return;
                  }
                  context.push(
                    Uri(
                      path: '/map',
                      queryParameters: {'layer': 'inventory', 'pin': asset.id},
                    ).toString(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
