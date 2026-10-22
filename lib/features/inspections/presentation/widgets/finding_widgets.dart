import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/time/concession_zone.dart';
import '../../../../core/ui/module_form.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/inspection.dart';

/// Un hallazgo ya capturado: su nota, el punto del checklist, las fotos, cuando
/// y donde (o que no hubo posicion).
class FindingTile extends StatelessWidget {
  const FindingTile({
    super.key,
    required this.finding,
    required this.zone,
    this.itemText,
  });

  final InspectionFinding finding;
  final ConcessionZone? zone;

  /// El texto del punto del checklist al que se refiere, si lo hay.
  final String? itemText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    final position = finding.position;
    final muted = TextStyle(color: moduleMuted, fontSize: r.s(13));
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: r.s(12)),
      padding: EdgeInsets.all(r.s(16)),
      decoration: BoxDecoration(
        color: moduleSurface,
        borderRadius: BorderRadius.circular(r.s(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemText != null)
            Padding(
              padding: EdgeInsets.only(bottom: r.s(6)),
              child: Text(
                itemText!,
                style: TextStyle(
                  color: const Color(0xFFF87171),
                  fontWeight: FontWeight.w700,
                  fontSize: r.s(13),
                ),
              ),
            ),
          if (finding.note.isNotEmpty)
            Text(
              finding.note,
              style: TextStyle(color: Colors.white, fontSize: r.s(15)),
            ),
          if (finding.photoPaths.isNotEmpty) ...[
            SizedBox(height: r.s(10)),
            Row(
              children: [
                for (var i = 0; i < finding.photoPaths.length; i++)
                  Padding(
                    padding: EdgeInsets.only(right: r.s(8)),
                    child: SizedBox(
                      width: r.s(64),
                      height: r.s(64),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(r.s(12)),
                        child: ModulePhoto(
                          key: Key('finding-photo-${finding.id}-$i'),
                          path: finding.photoPaths[i],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: r.s(10)),
          Text(moduleDate(finding.capturedAt, zone), style: muted),
          SizedBox(height: r.s(2)),
          Text(
            position == null
                ? l10n.inspEvidenceNoPosition
                : l10n.inspEvidencePosition(
                    position.latitude.toStringAsFixed(5),
                    position.longitude.toStringAsFixed(5),
                    position.accuracyMeters.round().toString(),
                  ),
            key: Key('finding-position-${finding.id}'),
            style: muted,
          ),
        ],
      ),
    );
  }
}

/// Lo que se captura en el formulario de un hallazgo.
typedef FindingSubmit =
    void Function({
      String? itemId,
      required String note,
      required List<String> photoPaths,
    });

/// Abre el formulario de un hallazgo en una hoja inferior.
Future<void> showFindingSheet(
  BuildContext context, {
  required List<ChecklistItem> checklist,
  required FindingSubmit onSave,
}) {
  final files = context.read<FileSource>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) =>
        FindingSheet(checklist: checklist, files: files, onSave: onSave),
  );
}

/// El formulario: punto del checklist (opcional), descripcion y hasta tres
/// fotos. Pide al menos la descripcion o una foto.
class FindingSheet extends StatefulWidget {
  const FindingSheet({
    super.key,
    required this.checklist,
    required this.files,
    required this.onSave,
  });

  final List<ChecklistItem> checklist;
  final FileSource files;
  final FindingSubmit onSave;

  @override
  State<FindingSheet> createState() => _FindingSheetState();
}

class _FindingSheetState extends State<FindingSheet> {
  final _note = TextEditingController();
  final _photos = List<String?>.filled(InspectionFinding.maxPhotos, null);
  String? _itemId;
  bool _showError = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _empty => _note.text.trim().isEmpty && _photos.every((p) => p == null);

  Future<void> _takePhoto(int slot) async {
    final shot = await widget.files.takePhoto();
    if (shot != null && mounted) setState(() => _photos[slot] = shot.path);
  }

  void _save() {
    if (_empty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop();
    widget.onSave(
      itemId: _itemId,
      note: _note.text.trim(),
      photoPaths: [for (final p in _photos) ?p],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(r.s(20)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Responsive.formMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.checklist.isNotEmpty)
                    ModuleField(
                      label: l10n.inspEvidenceItem,
                      child: DropdownButtonFormField<String?>(
                        key: const Key('finding-item'),
                        initialValue: _itemId,
                        isExpanded: true,
                        style: moduleInkStyle,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        decoration: moduleInput(context),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.inspEvidenceNoItem),
                          ),
                          for (final item in widget.checklist)
                            DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(
                                item.text,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _itemId = v),
                      ),
                    ),
                  ModuleField(
                    label: l10n.inspEvidenceNote,
                    error: _showError && _empty
                        ? l10n.inspEvidenceErrorEmpty
                        : null,
                    child: TextField(
                      key: const Key('finding-note'),
                      controller: _note,
                      minLines: 3,
                      maxLines: 5,
                      style: moduleInkStyle,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: moduleInput(
                        context,
                        hint: l10n.followUpFillIn,
                        error: _showError && _empty,
                      ),
                    ),
                  ),
                  ModulePhotoSlots(
                    keyPrefix: 'finding-slot',
                    photos: _photos,
                    onPick: _takePhoto,
                    onRemove: (i) => setState(() => _photos[i] = null),
                  ),
                  SizedBox(height: r.s(20)),
                  FilledButton.icon(
                    key: const Key('finding-save'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(r.s(56)),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.inspEvidenceSave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
