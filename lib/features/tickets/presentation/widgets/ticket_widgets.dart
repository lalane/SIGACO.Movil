import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ticket.dart';
import '../ticket_labels.dart';

/// La etiqueta de estado de un ticket.
class TicketStatusPill extends StatelessWidget {
  const TicketStatusPill({super.key, required this.status, this.large = false});

  final TicketStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) => ModuleStatusPill(
    label: statusLabel(AppLocalizations.of(context), status),
    color: statusColor(status),
    large: large,
  );
}

/// La tarjeta del historial: estado, vencimiento, foto con el titulo encima y
/// quien lo levanto.
/// La concesion activa de la sesion, o null si no hay sesion en el arbol.
String? activeConcessionOf(BuildContext context) {
  try {
    return context.watch<AuthBloc>().state.activeConcessionName;
  } on ProviderNotFoundException {
    return null;
  }
}

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.now,
    required this.zone,
    required this.onTap,
  });

  final Ticket ticket;
  final DateTime now;
  final ConcessionZone? zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final color = statusColor(ticket.status);
    final due = ticket.timeToDue(now);
    final overdue = due != null && due.isNegative;
    final dueColor = overdue ? Colors.redAccent.shade100 : color;
    final radius = BorderRadius.circular(r.s(28));
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(16)),
      child: Material(
        color: moduleSurface,
        elevation: 3,
        shadowColor: Colors.black38,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('ticket-${ticket.id}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: r.s(5), color: color),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.s(16),
                  r.s(14),
                  r.s(16),
                  r.s(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Con texto grande el estado pasa al renglon de abajo en
                        // lugar de salirse de la tarjeta.
                        Expanded(
                          child: Wrap(
                            spacing: r.s(10),
                            runSpacing: r.s(6),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: r.s(12),
                                    height: r.s(12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: r.s(10)),
                                  Text(
                                    'ID ${ticket.code}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.s(18),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              TicketStatusPill(status: ticket.status),
                            ],
                          ),
                        ),
                        SizedBox(width: r.s(8)),
                        if (due != null)
                          Column(
                            key: Key('ticket-due-${ticket.id}'),
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: r.s(16),
                                    color: dueColor,
                                  ),
                                  SizedBox(width: r.s(4)),
                                  Text(
                                    dueValue(l10n, due),
                                    style: TextStyle(
                                      color: dueColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: r.s(15),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                overdue
                                    ? l10n.ticketOverdueCaption
                                    : l10n.ticketDueCaption,
                                style: TextStyle(
                                  color: dueColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.s(10.5),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: r.s(14)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(r.s(20)),
                      child: SizedBox(
                        height: r.s(170),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ModulePhoto(
                              path: ticket.photoPaths.isEmpty
                                  ? null
                                  : ticket.photoPaths.first,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                            Positioned(
                              left: r.s(14),
                              right: r.s(14),
                              bottom: r.s(12),
                              child: Text(
                                ticket.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.s(18),
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: r.s(14)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ticket.authorName != null)
                                Text(
                                  ticket.authorName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: r.s(15),
                                  ),
                                ),
                              if ((ticket.concessionName ??
                                      activeConcessionOf(context)) !=
                                  null)
                                Text(
                                  ticket.concessionName ??
                                      activeConcessionOf(context)!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: r.s(13),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: r.s(8)),
                        Text(
                          ticketDate(ticket.createdAt, zone),
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: r.s(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
