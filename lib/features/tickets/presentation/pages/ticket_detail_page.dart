import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/ui/photo_viewer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../bloc/ticket_detail_cubit.dart';
import '../ticket_labels.dart';
import '../widgets/ticket_widgets.dart';
import '../widgets/tickets_state_view.dart';

/// La ficha de un ticket (mockup nuevo): fotos arriba con el estado, los datos
/// en dos columnas, el seguimiento y las tres acciones de abajo.
class TicketDetailPage extends StatelessWidget {
  const TicketDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<TicketDetailCubit, TicketDetailState>(
      builder: (context, state) {
        final ticket = state.ticket;
        if (ticket != null) return _Detail(ticket: ticket);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.ticketsTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == TicketDetailStatus.failure
                      ? TicketsStateView(
                          error: state.error ?? TicketsError.server,
                          onRetry: context.read<TicketDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('ticket-detail-loading'),
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
  const _Detail({required this.ticket});

  final Ticket ticket;

  Future<void> _addFollowUp(BuildContext context) async {
    final cubit = context.read<TicketDetailCubit>();
    await context.push('/tickets/${ticket.id}/follow-up');
    if (!cubit.isClosed) await cubit.load();
  }

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
                  key: const Key('ticket-detail'),
                  padding: EdgeInsets.zero,
                  children: [
                    ModuleDetailHero(
                      backKey: const Key('ticket-detail-back'),
                      photoPaths: ticket.photoPaths,
                      status: TicketStatusPill(
                        key: const Key('ticket-detail-status'),
                        status: ticket.status,
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
                            l10n.ticketIdLabel(ticket.code),
                            style: TextStyle(
                              color: const Color(0xFF9AA3C7),
                              fontWeight: FontWeight.w800,
                              fontSize: r.s(15),
                            ),
                          ),
                          SizedBox(height: r.s(8)),
                          Text(
                            ticket.title,
                            key: const Key('ticket-detail-title'),
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
                                    ticketLongDate(
                                      context,
                                      ticket.createdAt,
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
                            key: const Key('ticket-info'),
                            child: ModuleInfoGrid(
                              items: [
                                ModuleInfo(
                                  Icons.person,
                                  l10n.ticketInfoGeneratedBy,
                                  ticket.authorName ?? none,
                                ),
                                ModuleInfo(
                                  Icons.manage_accounts,
                                  l10n.ticketInfoProfile,
                                  ticket.authorProfile ?? none,
                                ),
                                ModuleInfo(
                                  Icons.fact_check,
                                  l10n.ticketInfoConcession,
                                  ticket.concessionName ??
                                      activeConcessionOf(context) ??
                                      none,
                                ),
                                ModuleInfo(
                                  Icons.apartment,
                                  l10n.ticketInfoCompany,
                                  ticket.company ?? none,
                                ),
                                ModuleInfo(
                                  Icons.explore,
                                  l10n.ticketInfoLatitude,
                                  ticket.latitude == null
                                      ? none
                                      : dms(ticket.latitude!, latitude: true),
                                ),
                                ModuleInfo(
                                  Icons.explore,
                                  l10n.ticketInfoLongitude,
                                  ticket.longitude == null
                                      ? none
                                      : dms(ticket.longitude!, latitude: false),
                                ),
                                ModuleInfo(
                                  Icons.straighten,
                                  l10n.ticketInfoChainage,
                                  ticket.kmLabel ?? none,
                                ),
                                ModuleInfo(
                                  Icons.shield_outlined,
                                  l10n.ticketInfoBody,
                                  ticket.carriageway ?? none,
                                ),
                              ],
                            ),
                          ),
                          if (ticket.category != null) ...[
                            SizedBox(height: r.s(24)),
                            ModuleSectionTitle(l10n.ticketTypeTitle),
                            SizedBox(height: r.s(10)),
                            Chip(
                              label: Text(ticket.category!),
                              backgroundColor: moduleSurface,
                              labelStyle: const TextStyle(color: Colors.white),
                              side: BorderSide.none,
                            ),
                          ],
                          if (ticket.description != null) ...[
                            SizedBox(height: r.s(24)),
                            ModuleSectionTitle(l10n.ticketDescriptionTitle),
                            SizedBox(height: r.s(10)),
                            Text(
                              ticket.description!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: r.s(15),
                                height: 1.4,
                              ),
                            ),
                          ],
                          SizedBox(height: r.s(24)),
                          ModuleSectionTitle(l10n.ticketFollowUpsTitle),
                          SizedBox(height: r.s(10)),
                          if (ticket.followUps.isEmpty)
                            Text(
                              l10n.ticketFollowUpsEmpty,
                              key: const Key('ticket-follow-ups-empty'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            )
                          else
                            for (final f in [
                              ...ticket.followUps,
                            ]..sort((a, b) => b.at.compareTo(a.at)))
                              _FollowUpTile(followUp: f, zone: zone),
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
                key: const Key('ticket-action-download'),
                icon: Icons.download,
                tooltip: l10n.ticketActionDownload,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('ticket-action-edit'),
                icon: Icons.edit,
                tooltip: l10n.ticketActionEdit,
                onTap: () => showActionSoon(context),
              ),
              ModuleActionButton(
                key: const Key('ticket-action-follow-up'),
                icon: Icons.add,
                tooltip: l10n.ticketActionFollowUp,
                onTap: () => _addFollowUp(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({required this.followUp, required this.zone});

  final TicketFollowUp followUp;
  final ConcessionZone? zone;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      key: Key('follow-up-${followUp.id}'),
      width: double.infinity,
      margin: EdgeInsets.only(bottom: r.s(10)),
      padding: EdgeInsets.all(r.s(14)),
      decoration: BoxDecoration(
        color: moduleSurface,
        borderRadius: BorderRadius.circular(r.s(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TicketStatusPill(status: followUp.status),
              const Spacer(),
              Text(
                ticketDate(followUp.at, zone),
                style: TextStyle(
                  color: moduleMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: r.s(12),
                ),
              ),
            ],
          ),
          SizedBox(height: r.s(10)),
          Text(
            followUp.description,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.s(14),
              height: 1.4,
            ),
          ),
          if (followUp.photoPaths.isNotEmpty) ...[
            SizedBox(height: r.s(10)),
            Row(
              children: [
                for (final (i, path) in followUp.photoPaths.indexed)
                  Padding(
                    padding: EdgeInsets.only(right: r.s(8)),
                    child: GestureDetector(
                      key: Key('follow-up-photo-$i'),
                      onTap: () => showPhotoViewer(
                        context,
                        followUp.photoPaths,
                        initial: i,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(r.s(10)),
                        child: SizedBox(
                          width: r.s(56),
                          height: r.s(56),
                          child: ModulePhoto(path: path),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
