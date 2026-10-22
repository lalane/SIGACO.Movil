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
import '../../domain/entities/inspection.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../bloc/inspection_detail_cubit.dart';
import '../inspections_labels.dart';
import '../widgets/finding_widgets.dart';
import '../widgets/inspection_widgets.dart';

/// La ficha de una inspeccion: datos, checklist para llenar y el boton para
/// finalizarla.
class InspectionDetailPage extends StatelessWidget {
  const InspectionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocConsumer<InspectionDetailCubit, InspectionDetailState>(
      listenWhen: (a, b) =>
          (!a.justCompleted && b.justCompleted) ||
          (!a.justSavedFinding && b.justSavedFinding) ||
          (a.actionError != b.actionError && b.actionError != null),
      listener: (context, state) {
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        if (state.justSavedFinding) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('inspection-finding-saved'),
                content: Text(l10n.inspEvidenceSaved),
              ),
            );
          context.read<InspectionDetailCubit>().findingShown();
          return;
        }
        if (state.justCompleted) {
          final critical = (state.inspection?.criticalFindings ?? 0) > 0;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('inspection-completed-message'),
                content: Text(
                  critical ? l10n.inspCompletedCritical : l10n.inspCompleted,
                ),
              ),
            );
          context.read<InspectionDetailCubit>().completionShown();
          return;
        }
        final text = switch (state.actionError) {
          InspectionsError.notEditable => l10n.inspNotEditable,
          InspectionsError.incomplete => l10n.inspIncomplete,
          _ => l10n.inspSaveError,
        };
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const Key('inspection-action-error'),
              content: Text(text),
            ),
          );
      },
      builder: (context, state) {
        final inspection = state.inspection;
        if (inspection != null) {
          return _Detail(inspection: inspection, busy: state.busy);
        }
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.inspDetailTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == InspectionDetailStatus.failure
                      ? InspectionsStateView(
                          error: state.error ?? InspectionsError.server,
                          onRetry: context.read<InspectionDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('inspection-detail-loading'),
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
  const _Detail({required this.inspection, required this.busy});

  final Inspection inspection;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final cubit = context.read<InspectionDetailCubit>();
    // Sin la configuracion de la concesion (y su zona horaria) no se captura (RN-13).
    final configured = zone != null;
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
                  key: const Key('inspection-detail'),
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        child: Row(
                          children: [
                            const ModuleBackPill(
                              key: Key('inspection-detail-back'),
                            ),
                            const Spacer(),
                            ModuleStatusPill(
                              key: const Key('inspection-detail-status'),
                              label: inspectionStatusLabel(
                                l10n,
                                inspection.status,
                              ),
                              color: inspectionStatusColor(inspection.status),
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
                            inspection.title,
                            key: const Key('inspection-detail-title'),
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
                            '${inspection.id} · ${inspection.type}',
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(24)),
                    KeyedSubtree(
                      key: const Key('inspection-info'),
                      child: ModuleInfoGrid(
                        items: [
                          ModuleInfo(
                            Icons.inventory_2_outlined,
                            l10n.inspAsset,
                            inspection.assetName ?? none,
                          ),
                          ModuleInfo(
                            Icons.route,
                            l10n.inspKm,
                            inspection.kmLabel ?? none,
                          ),
                          ModuleInfo(
                            Icons.fact_check,
                            l10n.inspSegment,
                            inspection.segmentCode ?? none,
                          ),
                          ModuleInfo(
                            Icons.explore,
                            l10n.inspDirection,
                            inspection.direction ?? none,
                          ),
                          ModuleInfo(
                            Icons.person_outline,
                            l10n.inspAssignee,
                            inspection.assignee ?? none,
                          ),
                          ModuleInfo(
                            Icons.calendar_today_outlined,
                            inspection.completedAt == null
                                ? l10n.inspScheduled
                                : l10n.inspCompletedOn,
                            (inspection.completedAt ??
                                        inspection.scheduledAt) ==
                                    null
                                ? none
                                : moduleDay(
                                    (inspection.completedAt ??
                                        inspection.scheduledAt)!,
                                    zone,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(28)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.inspChecklistTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.s(20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          l10n.inspChecklistProgress(
                            inspection.answered,
                            inspection.checklist.length,
                          ),
                          key: const Key('inspection-detail-progress'),
                          style: TextStyle(
                            color: moduleMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: r.s(14),
                          ),
                        ),
                      ],
                    ),
                    if (inspection.status == InspectionStatus.inProgress) ...[
                      SizedBox(height: r.s(6)),
                      Text(
                        l10n.inspDraftSaved,
                        key: const Key('inspection-draft-saved'),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(13)),
                      ),
                    ],
                    if (inspection.findings > 0) ...[
                      SizedBox(height: r.s(6)),
                      Text(
                        [
                          l10n.inspFindings(inspection.findings),
                          if (inspection.criticalFindings > 0)
                            l10n.inspCriticalFindings(
                              inspection.criticalFindings,
                            ),
                        ].join(' · '),
                        key: const Key('inspection-detail-findings'),
                        style: TextStyle(
                          color: const Color(0xFFF87171),
                          fontWeight: FontWeight.w700,
                          fontSize: r.s(14),
                        ),
                      ),
                    ],
                    if (inspection.editable && !configured) ...[
                      SizedBox(height: r.s(8)),
                      Text(
                        l10n.cfgGateInspection,
                        key: const Key('inspection-no-config'),
                        style: TextStyle(
                          color: const Color(0xFFFBBF24),
                          fontWeight: FontWeight.w700,
                          fontSize: r.s(14),
                        ),
                      ),
                    ],
                    SizedBox(height: r.s(16)),
                    for (final item in inspection.checklist)
                      ChecklistTile(
                        item: item,
                        editable: inspection.editable && !busy && configured,
                        onAnswer: (result) => cubit.answer(item.id, result),
                      ),
                    SizedBox(height: r.s(24)),
                    Text(
                      l10n.inspEvidenceTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.s(20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: r.s(12)),
                    if (inspection.evidence.isEmpty)
                      Text(
                        l10n.inspEvidenceEmpty,
                        key: const Key('inspection-evidence-empty'),
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                    for (final finding in inspection.evidence)
                      FindingTile(
                        key: Key('finding-${finding.id}'),
                        finding: finding,
                        zone: zone,
                        itemText: [
                          for (final i in inspection.checklist)
                            if (i.id == finding.itemId) i.text,
                        ].firstOrNull,
                      ),
                  ],
                ),
              ),
            ),
          ),
          ModuleActionBar(
            actions: [
              if (inspection.assetId != null)
                ModuleActionButton(
                  key: const Key('inspection-action-asset'),
                  icon: Icons.inventory_2_outlined,
                  tooltip: l10n.inspViewAsset,
                  onTap: () => context.push('/inventory/${inspection.assetId}'),
                ),
              if (inspection.editable && configured)
                ModuleActionButton(
                  key: const Key('inspection-action-finding'),
                  icon: Icons.add_a_photo_outlined,
                  tooltip: l10n.inspEvidenceAdd,
                  onTap: busy
                      ? () {}
                      : () => showFindingSheet(
                          context,
                          checklist: inspection.checklist,
                          onSave: ({itemId, required note, required photoPaths}) =>
                              cubit.addFinding(
                                itemId: itemId,
                                note: note,
                                photoPaths: photoPaths,
                              ),
                        ),
                ),
              if (inspection.editable && configured)
                ModuleActionButton(
                  key: const Key('inspection-action-complete'),
                  icon: Icons.check,
                  tooltip: inspection.complete
                      ? l10n.inspComplete
                      : l10n.inspCompleteHint,
                  onTap: busy ? () {} : cubit.complete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
