import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_detail.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../core/ui/module_widgets.dart';
import '../../../../core/ui/zone_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pending_definition.dart';
import '../bloc/definition_detail_cubit.dart';
import '../definitions_labels.dart';

/// Una definicion pendiente: la pregunta, lo que hace hoy SIGACO, que cambia si
/// TEKIA dice otra cosa y su historial. Abajo, las respuestas que el servidor
/// permite a la persona (S-DEF-01): «De acuerdo» y «No: asi es...» para quien
/// administra; comentar, para todos.
class DefinitionDetailPage extends StatelessWidget {
  const DefinitionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<DefinitionDetailCubit, DefinitionDetailState>(
      listenWhen: (a, b) =>
          b.saved > a.saved ||
          (b.sendError != null && b.sendError != a.sendError),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              state.sendError != null
                  ? (state.sendMessage ??
                        definitionsErrorMessage(l10n, state.sendError!))
                  : l10n.defSaved,
            ),
          ),
        );
      },
      builder: (context, state) {
        final detail = state.detail;
        if (detail != null) return _Detail(state: state);
        return Scaffold(
          backgroundColor: p.gradientTop,
          body: Column(
            children: [
              SigacoModuleHeader(title: l10n.defTitle),
              Expanded(
                child: Container(
                  color: moduleSheet,
                  child: state.status == DefinitionDetailStatus.failure
                      ? ModuleStateView(
                          icon: Icons.cloud_off_outlined,
                          body: definitionsErrorMessage(l10n, state.error!),
                          retryLabel: l10n.retry,
                          onRetry: context.read<DefinitionDetailCubit>().load,
                        )
                      : const Center(
                          key: Key('definition-detail-loading'),
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
  const _Detail({required this.state});

  final DefinitionDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    final zone = context.watch<ConcessionZoneCubit>().state;
    final detail = state.detail!;
    final d = detail.definition;
    final permissions = detail.permissions;
    final retired = d.status == DefinitionStatus.retired;
    final cubit = context.read<DefinitionDetailCubit>();

    Widget block(String label, String text, {Key? key}) => Padding(
      padding: EdgeInsets.only(top: r.s(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: moduleMuted,
              fontSize: r.s(11.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: r.s(4)),
          Text(
            text,
            key: key,
            style: TextStyle(color: Colors.white, fontSize: r.s(15)),
          ),
        ],
      ),
    );

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
                  key: const Key('definition-detail'),
                  padding: EdgeInsets.fromLTRB(r.s(20), 0, r.s(20), r.s(24)),
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.s(16)),
                        child: Row(
                          children: [
                            const ModuleBackPill(
                              key: Key('definition-detail-back'),
                            ),
                            const Spacer(),
                            ModuleStatusPill(
                              key: const Key('definition-detail-status'),
                              label: definitionStatusLabel(l10n, d.status),
                              color: definitionStatusColor(d.status),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.s(20)),
                      decoration: BoxDecoration(
                        color: moduleSurface,
                        borderRadius: BorderRadius.circular(r.s(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d.code} · ${d.moduleLabel}'
                            '${d.indicator == null ? '' : ' · ${d.indicator}'}'
                            ' · ${definitionPriorityLabel(l10n, d.priority)}',
                            style: TextStyle(
                              color: moduleMuted,
                              fontSize: r.s(13),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: r.s(8)),
                          Text(
                            d.title,
                            key: const Key('definition-detail-title'),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'PlusJakartaSans',
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                              fontSize: r.s(22),
                              height: 1.2,
                            ),
                          ),
                          block(
                            l10n.defQuestion,
                            d.question,
                            key: const Key('definition-detail-question'),
                          ),
                          block(l10n.defAssumption, d.assumption),
                          block(l10n.defIfVetoed, d.ifVetoed),
                          block(l10n.defSource, d.source),
                        ],
                      ),
                    ),
                    SizedBox(height: r.s(20)),
                    ModuleSectionTitle(l10n.defHistory),
                    SizedBox(height: r.s(10)),
                    if (detail.history.isEmpty)
                      Text(
                        l10n.defNoAnswers,
                        style: TextStyle(color: moduleMuted, fontSize: r.s(14)),
                      ),
                    for (final h in detail.history.reversed)
                      Container(
                        margin: EdgeInsets.only(bottom: r.s(8)),
                        padding: EdgeInsets.all(r.s(14)),
                        decoration: BoxDecoration(
                          color: moduleSurface,
                          borderRadius: BorderRadius.circular(r.s(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              definitionKindLabel(l10n, h.kind),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: r.s(14),
                              ),
                            ),
                            if (h.text != null) ...[
                              SizedBox(height: r.s(4)),
                              Text(
                                h.text!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.s(14),
                                ),
                              ),
                            ],
                            SizedBox(height: r.s(6)),
                            Text(
                              [
                                h.userName ?? l10n.defSystem,
                                if (h.profileName != null) h.profileName!,
                                if (h.fromApp) l10n.defFromApp,
                                formatInZone(context, h.createdAt, zone),
                              ].join(' · '),
                              style: TextStyle(
                                color: moduleMuted,
                                fontSize: r.s(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (retired)
                      Padding(
                        padding: EdgeInsets.only(top: r.s(8)),
                        child: Text(
                          l10n.defRetiredNote,
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(14),
                          ),
                        ),
                      )
                    else if (!permissions.canDecide && permissions.canComment)
                      Padding(
                        padding: EdgeInsets.only(top: r.s(8)),
                        child: Text(
                          l10n.defDecideHint,
                          key: const Key('definition-decide-hint'),
                          style: TextStyle(
                            color: moduleMuted,
                            fontSize: r.s(13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!retired && (permissions.canComment || permissions.canDecide))
            Container(
              color: moduleSurface,
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(12), r.s(16), r.s(12)),
              child: SafeArea(
                top: false,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: r.s(8),
                  runSpacing: r.s(8),
                  children: [
                    if (permissions.canDecide &&
                        d.status != DefinitionStatus.accepted)
                      FilledButton.icon(
                        key: const Key('definition-agree'),
                        onPressed: state.sending
                            ? null
                            : () => cubit.answer(DefinitionAnswerKind.agree),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.defAgree),
                      ),
                    if (permissions.canDecide)
                      OutlinedButton.icon(
                        key: const Key('definition-change'),
                        onPressed: state.sending
                            ? null
                            : () => _askText(
                                context,
                                DefinitionAnswerKind.change,
                                l10n.defChangeHint,
                              ),
                        icon: const Icon(Icons.close),
                        label: Text(l10n.defChange),
                      ),
                    if (permissions.canComment)
                      OutlinedButton.icon(
                        key: const Key('definition-comment'),
                        onPressed: state.sending
                            ? null
                            : () => _askText(
                                context,
                                DefinitionAnswerKind.comment,
                                l10n.defCommentHint,
                              ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.defComment),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Pide el texto del cambio o del comentario y lo manda.
  Future<void> _askText(
    BuildContext context,
    DefinitionAnswerKind kind,
    String hint,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DefinitionDetailCubit>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _AnswerDialog(
        title: kind == DefinitionAnswerKind.change
            ? l10n.defChange
            : l10n.defComment,
        hint: hint,
      ),
    );
    if (text == null) return;
    await cubit.answer(kind, text: text);
  }
}

/// Pide el texto del cambio o del comentario. Es dueno de su controlador: se
/// libera cuando el dialogo termina de cerrarse, no antes.
class _AnswerDialog extends StatefulWidget {
  const _AnswerDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_AnswerDialog> createState() => _AnswerDialogState();
}

class _AnswerDialogState extends State<_AnswerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('definition-answer-text'),
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        minLines: 3,
        maxLength: 4000,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('definition-answer-send'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.defSend),
        ),
      ],
    );
  }
}
