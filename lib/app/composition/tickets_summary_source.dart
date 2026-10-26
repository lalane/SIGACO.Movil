import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../features/dashboard/domain/entities/dashboard_summary.dart';

/// El resumen de tickets que calcula el servidor, para no bajar toda la lista
/// solo para contarla. Devuelve null cuando no hay que usarlo (datos de ejemplo,
/// sin respuesta del servidor): el dashboard cuenta entonces con las listas.
abstract interface class TicketsSummarySource {
  Future<TicketsSummary?> load();
}

class NoTicketsSummarySource implements TicketsSummarySource {
  const NoTicketsSummarySource();

  @override
  Future<TicketsSummary?> load() async => null;
}

/// `GET /api/tickets/summary`: abiertos, atendidos (resueltos o cerrados) y
/// vencidos, y los cinco usuarios que mas tickets registraron, con el mismo
/// ambito que la bandeja.
class ApiTicketsSummarySource implements TicketsSummarySource {
  const ApiTicketsSummarySource(this._api, {this.enabled = _always});

  final ApiClient _api;

  /// Falso con datos de ejemplo: el servidor no los conoce.
  final bool Function() enabled;

  static bool _always() => true;

  @override
  Future<TicketsSummary?> load() async {
    if (!enabled()) return null;
    try {
      return parse(await _api.get('/api/tickets/summary'));
    } on ApiFailure {
      return null;
    }
  }

  /// Null si la respuesta no trae los tres conteos.
  static TicketsSummary? parse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final open = _int(json['open']);
    final attended = _int(json['attended']);
    final overdue = _int(json['overdue']);
    if (open == null || attended == null || overdue == null) return null;
    final creators = json['topCreators'];
    return TicketsSummary(
      open: open,
      attended: attended,
      overdue: overdue,
      creators: [
        if (creators is List)
          for (final c in creators)
            if (c is Map && c['name'] is String && _int(c['count']) != null)
              TicketCreator(
                name: (c['name'] as String).trim(),
                count: _int(c['count'])!,
              ),
      ].where((c) => c.name.isNotEmpty).take(5).toList(),
    );
  }

  static int? _int(Object? v) => switch (v) {
    int n => n,
    num n => n.toInt(),
    String s => int.tryParse(s),
    _ => null,
  };
}
