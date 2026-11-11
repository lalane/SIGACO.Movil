import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../../../core/time/concession_zone_cubit.dart';
import '../../../../core/ui/module_format.dart';
import '../../../../core/ui/module_header.dart';
import '../../../../core/ui/module_nav.dart';
import '../../../../core/ui/module_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/indicator_events.dart';
import '../../domain/repositories/indicator_events_repository.dart';
import '../../domain/entities/maintenance.dart';
import '../maintenance_labels.dart';

/// Desempeño del indicador (consulta) y, en SGITS, SGSEI y SGOST, los eventos
/// de indisponibilidad o interrupción con su registro en campo (HU-ITS-04,
/// HU-SEI-07, HU-OST-06). Lo demás (aprobar, expurgos, cierre) queda en la web.
class IndicatorEventsPage extends StatefulWidget {
  const IndicatorEventsPage({super.key, required this.indicator});

  final MaintenanceIndicator indicator;

  @override
  State<IndicatorEventsPage> createState() => _IndicatorEventsPageState();
}

class _IndicatorEventsPageState extends State<IndicatorEventsPage> {
  late Future<(List<IndicatorParameterStatus>, List<IndicatorEvent>)> _data;

  bool get _withEvents => mc2EventIndicators.contains(widget.indicator);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<IndicatorEventsRepository>();
    _data = () async {
      final performance = await repo.performance(widget.indicator);
      final events = _withEvents
          ? await repo.events(widget.indicator)
          : const <IndicatorEvent>[];
      return (performance, events);
    }();
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventForm(indicator: widget.indicator),
    );
    if (created == true && mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: moduleSurface,
      bottomNavigationBar: const SigacoModuleNav(
        current: ModuleTab.maintenance,
      ),
      floatingActionButton: _withEvents
          ? FloatingActionButton.extended(
              key: const Key('indicator-event-create'),
              onPressed: _create,
              icon: const Icon(Icons.add_alert),
              label: Text(l10n.maintEventsCreate),
            )
          : null,
      body: Column(
        children: [
          SigacoModuleHeader(
            title:
                '${indicatorCode(widget.indicator)} · ${l10n.maintPerformanceTitle}',
            subtitle: indicatorLabel(l10n, widget.indicator),
            showBack: true,
          ),
          Expanded(
            child: FutureBuilder(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(_load),
                      child: Text(l10n.retry),
                    ),
                  );
                }
                final (performance, events) = snapshot.data!;
                final zone = context.watch<ConcessionZoneCubit>().state;
                return RefreshIndicator(
                  onRefresh: () async => setState(_load),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      Text(
                        l10n.maintPerformanceHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      for (final p in performance)
                        Card(
                          key: Key('indicator-parameter-${p.code}'),
                          child: ListTile(
                            dense: true,
                            title: Text('${p.code} · ${p.name}'),
                            subtitle: Text(p.reason),
                            trailing: _StatusChip(status: p.status),
                          ),
                        ),
                      if (_withEvents) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.maintEventsTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l10n.maintEventsEmpty),
                          ),
                        for (final e in events)
                          Card(
                            key: Key('indicator-event-${e.id}'),
                            child: ListTile(
                              dense: true,
                              title: Text('${e.folio} · ${e.assetCode}'),
                              subtitle: Text(
                                '${moduleDate(e.startedAt, zone)}'
                                ' → ${e.endedAt == null ? l10n.maintEventsOpen : moduleDate(e.endedAt!, zone)}'
                                '${e.cause == null ? '' : '\n${e.cause}'}',
                              ),
                              trailing: Text(
                                '${e.computableHours.toStringAsFixed(1)} h'
                                '${e.slaHours == null ? '' : ' / ${e.slaHours} h'}',
                                style: TextStyle(
                                  color: e.slaState == 'EXCEDIDO'
                                      ? Colors.red
                                      : e.slaState == 'EN_RIESGO'
                                      ? Colors.orange
                                      : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      'CUMPLE' => (l10n.maintStatusComplies, Colors.green),
      'NO_CUMPLE' => (l10n.maintStatusNotComplies, Colors.red),
      'PENDIENTE_VALIDACION' => (l10n.maintStatusPending, Colors.orange),
      'AUN_NO_EXIGIBLE' => (l10n.maintStatusNotYet, Colors.blueGrey),
      _ => (l10n.maintStatusNotEvaluated, Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.indicator});

  final MaintenanceIndicator indicator;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _search = TextEditingController();
  final _cause = TextEditingController();
  final _clientUuid = newClientId();
  List<IndicatorAssetOption> _options = const [];
  IndicatorAssetOption? _asset;
  DateTime _startedAt = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    _cause.dispose();
    super.dispose();
  }

  Future<void> _find(String term) async {
    if (term.trim().length < 2) return;
    final found = await context.read<IndicatorEventsRepository>().searchAssets(
      widget.indicator,
      term.trim(),
    );
    if (mounted) setState(() => _options = found);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_asset == null || _cause.text.trim().isEmpty) {
      setState(() => _error = l10n.maintEventsRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<IndicatorEventsRepository>().create(
        widget.indicator,
        assetId: _asset!.id,
        startedAt: _startedAt,
        cause: _cause.text.trim(),
        clientUuid: _clientUuid,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on IndicatorEventRejected catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.maintEventsRejected(e.reason);
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.maintEventsFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.maintEventsCreate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_asset == null) ...[
            TextField(
              key: const Key('indicator-event-asset'),
              controller: _search,
              decoration: InputDecoration(labelText: l10n.maintEventsAsset),
              onChanged: _find,
            ),
            for (final o in _options.take(6))
              ListTile(
                dense: true,
                title: Text(o.code),
                onTap: () => setState(() => _asset = o),
              ),
          ] else
            ListTile(
              title: Text(_asset!.code),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _asset = null),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.maintEventsStart),
            subtitle: Text(_startedAt.toLocal().toString().substring(0, 16)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startedAt,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now(),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startedAt),
              );
              if (time == null) return;
              setState(
                () => _startedAt = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
            },
          ),
          TextField(
            key: const Key('indicator-event-cause'),
            controller: _cause,
            maxLength: 2000,
            decoration: InputDecoration(labelText: l10n.maintEventsCause),
          ),
          if (widget.indicator == MaintenanceIndicator.sgits)
            Text(
              l10n.maintEventsApprovalHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('indicator-event-save'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.maintEventsSave),
          ),
        ],
      ),
    );
  }
}
