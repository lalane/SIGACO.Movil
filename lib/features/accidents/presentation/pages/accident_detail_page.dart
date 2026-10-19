import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/accident.dart';
import '../../domain/repositories/accidents_repository.dart';
import '../accident_labels.dart';
import '../bloc/accident_detail_cubit.dart';
import '../widgets/accident_widgets.dart';

/// La ficha de un accidente (mockup nuevo): fotos arriba con el estado, los
/// datos en dos columnas y las tres acciones de abajo.
class AccidentDetailPage extends StatelessWidget {
  const AccidentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AccidentDetailCubit, AccidentDetailState>(
      builder: (context, state) {
        final accident = state.accident;
        if (accident != null) return _Detail(accident: accident);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.accidentsTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == AccidentDetailStatus.failure
                      ? AccidentsStateView(
                          error: state.error ?? AccidentsError.server,
                          onRetry: context.read<AccidentDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('accident-detail-loading'),
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
  const _Detail({required this.accident});

  final Accident accident;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    const none = '—';
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
                  key: const Key('accident-detail'),
                  padding: EdgeInsets.zero,
                  children: [
                    ModuleDetailHero(
                      backKey: const Key('accident-detail-back'),
                      photoPaths: accident.photoPaths,
                      fallbackIcon: Icons.warning_amber_rounded,
                      status: ModuleStatusPill(
                        key: const Key('accident-detail-status'),
                        label: statusLabel(l10n, accident.status),
                        color: statusColor(accident.status),
                        large: true,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.s(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: r.s(20)),
                          Text(
                            l10n.accidentIdLabel(accident.code),
                            style: TextStyle(
                              color: const Color(0xFF9AA3C7),
                              fontWeight: FontWeight.w800,
                              fontSize: r.s(15),
                            ),
                          ),
                          SizedBox(height: r.s(8)),
                          Text(
                            accident.title,
                            key: const Key('accident-detail-title'),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PlusJakartaSans',
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                              fontSize: r.s(26),
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: r.s(10)),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: r.s(18),
                                color: const Color(0xFF9AA3C7),
                              ),
                              SizedBox(width: r.s(8)),
                              Flexible(
                                child: Text(
                                  l10n.ticketCreatedOn(
                                    moduleLongDate(
                                      context,
                                      accident.createdAt,
                                      zone,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: const Color(0xFF9AA3C7),
                                    fontSize: r.s(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.s(20)),
                          Divider(color: Colors.white.withValues(alpha: 0.12)),
                          SizedBox(height: r.s(16)),
                          KeyedSubtree(
                            key: const Key('accident-info'),
                            child: ModuleInfoGrid(
                              items: [
                                ModuleInfo(
                                  Icons.person,
                                  l10n.ticketInfoGeneratedBy,
                                  accident.authorName ?? none,
                                ),
                                ModuleInfo(
                                  Icons.manage_accounts,
                                  l10n.ticketInfoProfile,
                                  accident.authorProfile ?? none,
                                ),
                                ModuleInfo(
                                  Icons.fact_check,
                                  l10n.ticketInfoConcession,
                                  accident.concessionName ?? none,
                                ),
                                ModuleInfo(
                                  Icons.apartment,
                                  l10n.ticketInfoCompany,
                                  accident.company ?? none,
                                ),
                                ModuleInfo(
                                  Icons.explore,
                                  l10n.ticketInfoLatitude,
                                  accident.latitude == null
                                      ? none
                                      : moduleDms(
                                          accident.latitude!,
                                          latitude: true,
                                        ),
                                ),
                                ModuleInfo(
                                  Icons.explore,
                                  l10n.ticketInfoLongitude,
                                  accident.longitude == null
                                      ? none
                                      : moduleDms(
                                          accident.longitude!,
                                          latitude: false,
                                        ),
                                ),
                                ModuleInfo(
                                  Icons.straighten,
                                  l10n.ticketInfoChainage,
                                  accident.kmLabel ?? none,
                                ),
                                ModuleInfo(
                                  Icons.shield_outlined,
                                  l10n.ticketInfoBody,
                                  accident.carriageway ?? none,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: r.s(24)),
                          ModuleSectionTitle(l10n.accidentTypeTitle),
                          SizedBox(height: r.s(10)),
                          Chip(
                            key: const Key('accident-detail-type'),
                            label: Text(typeLabel(l10n, accident.type)),
                            backgroundColor: moduleSurface,
                            labelStyle: const TextStyle(color: Colors.white),
                            side: BorderSide.none,
                          ),
                          SizedBox(height: r.s(24)),
                          ModuleSectionTitle(l10n.accidentSeverityTitle),
                          SizedBox(height: r.s(10)),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ModuleStatusPill(
                              key: const Key('accident-detail-severity'),
                              label: severityLabel(l10n, accident.severity),
                              color: severityColor(accident.severity),
                            ),
                          ),
                          if (accident.description != null) ...[
                            SizedBox(height: r.s(24)),
                            ModuleSectionTitle(l10n.ticketDescriptionTitle),
                            SizedBox(height: r.s(10)),
                            Text(
                              accident.description!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: r.s(15),
                                height: 1.4,
                              ),
                            ),
                          ],
                          SizedBox(height: r.s(24)),
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
                key: const Key('accident-action-download'),
                icon: Icons.download,
                tooltip: l10n.ticketActionDownload,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('accident-action-edit'),
                icon: Icons.edit,
                tooltip: l10n.ticketActionEdit,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('accident-action-add'),
                icon: Icons.add,
                tooltip: l10n.ticketActionFollowUp,
                onTap: () => showActionSoon(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
