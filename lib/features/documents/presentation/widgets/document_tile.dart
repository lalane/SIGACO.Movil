import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import '../document_labels.dart';
import 'signature_badge.dart';

/// Fila de documento (MQ-MOB-13): nombre, tipo y categoria, propietario y fecha,
/// estado de firma y favorito. Tocar la fila abre la ficha; la estrella marca o
/// desmarca el favorito sin entrar.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.zone,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final DocumentSummary document;
  final ConcessionZone? zone;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final category = document.categoryLabel;
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(10)),
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(16)),
        child: InkWell(
          key: Key('doc-tile-${document.id}'),
          borderRadius: BorderRadius.circular(r.s(16)),
          onTap: onOpen,
          child: Container(
            padding: EdgeInsets.fromLTRB(r.s(14), r.s(12), r.s(4), r.s(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.s(16)),
              border: Border.all(color: p.hint.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  fileIcon(document.format),
                  color: p.accentOnBottom,
                  size: r.s(30),
                ),
                SizedBox(width: r.s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textOnBottom,
                          fontSize: r.s(15),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: r.s(2)),
                      Text(
                        category == null
                            ? document.typeLabel
                            : '${document.typeLabel} · $category',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
                      ),
                      SizedBox(height: r.s(2)),
                      Text(
                        l10n.docsOwnerLine(
                          document.ownerUsername,
                          formatDayInZone(context, document.modifiedAt, zone),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.hint, fontSize: r.s(12.5)),
                      ),
                      SizedBox(height: r.s(8)),
                      SignatureBadge(signature: document.signature),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('doc-fav-${document.id}'),
                  tooltip: document.isFavorite
                      ? l10n.docsFavoriteRemove
                      : l10n.docsFavoriteAdd,
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    document.isFavorite ? Icons.star : Icons.star_border,
                    color: document.isFavorite ? p.accentOnBottom : p.hint,
                    size: r.s(26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
