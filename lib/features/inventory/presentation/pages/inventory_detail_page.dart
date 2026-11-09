import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/ui/photo_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../bloc/inventory_detail_cubit.dart';
import '../inventory_labels.dart';
import '../widgets/asset_history_view.dart';
import '../widgets/inventory_widgets.dart';

/// La ficha de un activo: estado (y si esta en mantenimiento), su historia
/// operativa (tickets, inspecciones y mantenimientos), los campos de su ficha,
/// los datos del WebGIS si nacio ahi, la gestion, las fotos y los botones para
/// verlo en el mapa y levantarle un ticket.
class InventoryDetailPage extends StatelessWidget {
  const InventoryDetailPage({super.key, this.actions});

  /// Lo que se abre en otros modulos (la ficha de cada registro y el alta de
  /// ticket); sin ellas la historia solo se lista.
  final AssetRecordActions? actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<InventoryDetailCubit, InventoryDetailState>(
      builder: (context, state) {
        final asset = state.asset;
        if (asset != null) {
          return _Detail(state: state, asset: asset, actions: actions);
        }
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
  const _Detail({required this.state, required this.asset, this.actions});

  final InventoryDetailState state;
  final InventoryAsset asset;
  final AssetRecordActions? actions;

  /// La ruta del alta de ticket con este activo; null si no se puede: sin el
  /// modulo de tickets, un activo que aun no sale del telefono o uno dado de
  /// baja o descartado (el servidor lo rechaza).
  String? get _newTicketRoute {
    final route = actions?.newTicketRoute;
    if (route == null || asset.pendingSync) return null;
    if (asset.lifecycle == AssetLifecycle.decommissioned ||
        asset.lifecycle == AssetLifecycle.discarded) {
      return null;
    }
    return route(asset);
  }

  /// La vista en sitio, si el activo tiene foto.
  Uint8List? get photo => state.photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    const none = '—';
    // Un punto, o el punto representativo de una linea (su mitad) o de un
    // poligono (su centro): lo calcula el repositorio con la geometria.
    final latitude = asset.latitude;
    final longitude = asset.longitude;
    final lifecycle = asset.lifecycle;
    final reason = statusReasonLabel(l10n, asset.statusReason);
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
                            '${asset.code ?? asset.id} · ${asset.category}',
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(16),
                            ),
                          ),
                          if (lifecycle != null ||
                              asset.inMaintenance ||
                              asset.pendingSync) ...[
                            SizedBox(height: r.s(14)),
                            AssetStatusPills(
                              asset: asset,
                              keyPrefix: 'inventory-detail',
                            ),
                          ],
                          if (reason != null) ...[
                            SizedBox(height: r.s(10)),
                            Text(
                              reason,
                              key: const Key('inventory-detail-reason'),
                              style: TextStyle(
                                color: moduleMuted,
                                fontSize: r.s(14),
                              ),
                            ),
                          ],
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
                    if (photo != null) ...[
                      SizedBox(height: r.s(24)),
                      _SectionTitle(l10n.invSitePhoto),
                      SizedBox(height: r.s(10)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(r.s(16)),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.memory(
                            photo!,
                            key: const Key('inventory-detail-photo'),
                            fit: BoxFit.cover,
                            // Un archivo que no es imagen no tira la ficha.
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: moduleSurface),
                          ),
                        ),
                      ),
                    ],
                    if (state.photos.isNotEmpty) ...[
                      SizedBox(height: r.s(24)),
                      _SectionTitle(l10n.invPhotosTitle),
                      SizedBox(height: r.s(10)),
                      _Gallery(paths: state.photos),
                    ],
                    SizedBox(height: r.s(28)),
                    _SectionTitle(l10n.invDetailsTitle),
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
                          if (asset.roadCode != null)
                            ModuleInfo(
                              Icons.add_road,
                              l10n.invRoad,
                              asset.roadCode!,
                            ),
                          if (asset.openTicketCount != null)
                            ModuleInfo(
                              Icons.build_circle_outlined,
                              l10n.invOpenTickets,
                              '${asset.openTicketCount}',
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
                    if (state.history.isNotEmpty) ...[
                      SizedBox(height: r.s(28)),
                      _SectionTitle(l10n.invHistoryTitle),
                      SizedBox(height: r.s(14)),
                      AssetHistoryView(
                        history: state.history,
                        zone: zone,
                        routeOf: actions?.openRoute,
                      ),
                    ],
                    ..._templateSection(context, zone),
                    ..._webGisSection(context),
                    SizedBox(height: r.s(28)),
                    _SectionTitle(l10n.invManagementTitle),
                    SizedBox(height: r.s(14)),
                    KeyedSubtree(
                      key: const Key('inventory-management'),
                      child: ModuleInfoGrid(
                        items: [
                          ModuleInfo(
                            Icons.sell_outlined,
                            l10n.invBrand,
                            asset.brand ?? none,
                          ),
                          ModuleInfo(
                            Icons.style_outlined,
                            l10n.invModel,
                            asset.model ?? none,
                          ),
                          ModuleInfo(
                            Icons.qr_code_2,
                            l10n.invSerial,
                            asset.serialNumber ?? none,
                          ),
                          ModuleInfo(
                            Icons.hourglass_bottom,
                            l10n.invUsefulLife,
                            asset.usefulLifeMonths == null
                                ? none
                                : l10n.invUsefulLifeMonths(
                                    asset.usefulLifeMonths!,
                                  ),
                          ),
                          ModuleInfo(
                            Icons.input,
                            l10n.invSource,
                            asset.source == null
                                ? none
                                : sourceLabel(l10n, asset.source!),
                          ),
                          if (asset.templateNumber != null)
                            ModuleInfo(
                              Icons.list_alt,
                              l10n.invTemplateTitle,
                              l10n.invTemplateVersion(asset.templateNumber!),
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
              if (_newTicketRoute case final route?)
                ModuleActionButton(
                  key: const Key('inventory-action-ticket'),
                  icon: Icons.confirmation_number_outlined,
                  tooltip: l10n.invCreateTicket,
                  onTap: () async {
                    final cubit = context.read<InventoryDetailCubit>();
                    await context.push<Object?>(route);
                    // Si se levanto, cambian los conteos y "en mantenimiento".
                    await cubit.refresh();
                  },
                ),
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
                  // Con su punto (el centro, si es linea o poligono), el mapa
                  // se centra aunque su pin no este entre los que bajaron.
                  context.push(
                    Uri(
                      path: '/map',
                      queryParameters: {
                        'layer': 'inventory',
                        'pin': asset.id,
                        'lat': '${asset.latitude}',
                        'lon': '${asset.longitude}',
                      },
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

  /// Los campos de la ficha del tipo, en su orden. Sin ficha, los que trae el
  /// activo con su clave.
  List<Widget> _templateSection(BuildContext context, ConcessionZone? zone) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final language = appLanguage(context);
    final template = asset.template;
    final fields = template?.attributes ?? const <AttributeDefinition>[];
    final known = {for (final f in fields) f.key};
    final extra = [
      for (final k in asset.attributes.keys)
        if (!known.contains(k)) k,
    ];
    if (fields.isEmpty && extra.isEmpty) return const [];
    String value(AttributeDefinition? f, Object? v) => attributeValueText(
      l10n,
      f,
      v,
      zone: zone,
      catalogLabel: (catalog, code) =>
          state.catalogLabel(catalog, code, language),
    );
    return [
      SizedBox(height: r.s(28)),
      _SectionTitle(l10n.invTemplateTitle),
      SizedBox(height: r.s(14)),
      KeyedSubtree(
        key: const Key('inventory-template'),
        child: ModuleInfoGrid(
          items: [
            for (final f in fields)
              ModuleInfo(
                attributeIcon(f.type),
                f.label(language),
                value(f, asset.attributes[f.key]),
              ),
            for (final k in extra)
              ModuleInfo(Icons.notes, k, value(null, asset.attributes[k])),
          ],
        ),
      ),
    ];
  }

  /// Las columnas crudas del elemento del WebGIS, solo lectura.
  List<Widget> _webGisSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final data = asset.externalAttributes;
    if (data == null || data.isEmpty) return const [];
    final keys = data.keys.toList()..sort();
    return [
      SizedBox(height: r.s(28)),
      _SectionTitle(l10n.invWebGisTitle),
      if (asset.externalLayerCode != null) ...[
        SizedBox(height: r.s(6)),
        Text(
          l10n.invWebGisSource(
            asset.externalLayerCode!,
            asset.externalId ?? '—',
          ),
          key: const Key('inventory-webgis-source'),
          style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
        ),
      ],
      SizedBox(height: r.s(14)),
      KeyedSubtree(
        key: const Key('inventory-webgis'),
        child: ModuleInfoGrid(
          items: [
            for (final k in keys)
              ModuleInfo(
                Icons.layers_outlined,
                k,
                attributeValueText(l10n, null, data[k], zone: null),
              ),
          ],
        ),
      ),
    ];
  }
}

/// El icono de un campo de la ficha segun su tipo de dato.
IconData attributeIcon(AttributeType type) => switch (type) {
  AttributeType.integer || AttributeType.decimal => Icons.straighten,
  AttributeType.boolean => Icons.check_box_outlined,
  AttributeType.date => Icons.event_outlined,
  AttributeType.dateTime => Icons.schedule,
  AttributeType.catalog => Icons.list_alt,
  AttributeType.text || AttributeType.unknown => Icons.notes,
};

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: const Color(0xFF9AA3C7),
      fontSize: context.responsive.s(16),
    ),
  );
}

/// Las demas fotos del activo: cuadros que se abren a pantalla completa.
class _Gallery extends StatelessWidget {
  const _Gallery({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return SizedBox(
      key: const Key('inventory-detail-gallery'),
      height: r.s(110),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => SizedBox(width: r.s(10)),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(r.s(14)),
          child: SizedBox(
            width: r.s(110),
            child: Material(
              color: moduleSurface,
              child: InkWell(
                key: Key('inventory-gallery-$i'),
                onTap: () => showPhotoViewer(context, paths, initial: i),
                child: ModulePhoto(path: paths[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
