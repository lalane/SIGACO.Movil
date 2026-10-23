import 'dart:io';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Los tickets contra el backend (`/api/tickets`, M11). El servidor aplica el
/// ambito de la persona y el SLA; la app traduce el ticket del servidor a lo que
/// muestra (abierto o atendido, APP-MOB-03) y el seguimiento y las fotos que
/// captura a lo que el servidor guarda.
class ApiTicketsRepository implements TicketsRepository {
  ApiTicketsRepository(
    this._api, {
    required this.roadId,
    this.language = _spanish,
    this.defaultPriority = 'MEDIA',
  });

  final ApiClient _api;

  /// La carretera donde se levanta un ticket que no viene de un activo; null si
  /// no se puede saber (el servidor lo rechaza y la pantalla lo dice).
  final Future<String?> Function() roadId;

  /// `es` o `pt`: el idioma de los tipos de ticket.
  final String Function() language;

  /// El servidor exige prioridad y el formulario movil no la pregunta.
  final String defaultPriority;

  static String _spanish() => 'es';

  static const _pageSize = 100;
  static const _maxPages = 10;

  /// Tipos de ticket ya vistos: nombre que se muestra -> codigo del servidor.
  final _typeCodes = <String, String>{};

  @override
  Future<List<Ticket>> list() => _guard(() async {
    final result = <Ticket>[];
    var page = 1;
    var total = 0;
    do {
      final json = await _api.getJson(
        '/api/tickets',
        query: {'page': page, 'pageSize': _pageSize},
      );
      final map = _asMap(json);
      total = (map['total'] as num?)?.toInt() ?? 0;
      final items = map['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      for (final item in items) {
        result.add(ticketFromDto(_asMap(item)));
      }
      page++;
    } while (result.length < total && page <= _maxPages);
    return result;
  }, listing: true);

  @override
  Future<Ticket> get(String id) => _guard(() => _load(id));

  Future<Ticket> _load(String id) async {
    final key = Uri.encodeComponent(id);
    final dto = _asMap(await _api.getJson('/api/tickets/$key'));
    final raw = await _api.getJson('/api/tickets/$key/follow-ups');
    final items = raw is List
        ? raw
        : (raw is Map ? raw['items'] : null) as List? ?? const [];
    final base = ticketFromDto(dto);
    return base.copyWith(
      followUps: [
        for (final f in items)
          if (f is Map<String, dynamic>) followUpFromDto(f, fallback: base.status),
      ],
    );
  }

  @override
  Future<List<String>> categories() => _guard(() async {
    final json = _asMap(await _api.getJson('/api/app-configuration'));
    final catalogs = json['operationalCatalogs'];
    final types = catalogs is Map ? catalogs['ticketTypes'] : null;
    if (types is! List) return const <String>[];
    final rows = [
      for (final t in types)
        if (t is Map<String, dynamic> && t['active'] != false) t,
    ]..sort((a, b) => _int(a['sortOrder']).compareTo(_int(b['sortOrder'])));
    _typeCodes.clear();
    final labels = <String>[];
    final pt = language() == 'pt';
    for (final t in rows) {
      final code = _text(t['code']);
      final es = _text(t['labelEs']);
      final label = (pt ? _text(t['labelPt']) : null) ?? es ?? code;
      if (code == null || label == null) continue;
      _typeCodes[label] = code;
      labels.add(label);
    }
    return labels;
  });

  @override
  Future<Ticket> create(NewTicket draft) => _guard(() async {
    if (_typeCodes.isEmpty) await categories();
    final code = _typeCodes[draft.category] ?? _codeOf(draft.category);
    if (code == null) throw const TicketsException(TicketsError.server);

    final location = draft.location;
    final assetId = location?.assetId;
    final road = assetId == null ? await roadId() : null;
    final km = parseKm(draft.kmLabel ?? location?.kmLabel);
    final body = <String, Object?>{
      'ticketTypeCode': code,
      'priority': defaultPriority,
      'description': composeDescription(draft.title, draft.description),
      'assetId': ?assetId,
      'roadId': ?road,
      'kmStart': ?km,
      if (location != null)
        'geometry': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        },
      if (draft.capturedAt != null)
        'detectedAt': draft.capturedAt!.toUtc().toIso8601String(),
      'clientUuid': ?draft.clientId,
    };
    final dto = (await _api.post('/api/tickets', data: body)) ?? const {};
    final id = _text(dto['id']);
    if (id == null) throw const FormatException('sin id');
    await _uploadPhotos(
      '/api/tickets/${Uri.encodeComponent(id)}/attachments',
      draft.photoPaths,
      capturedAt: draft.capturedAt,
      location: location,
    );
    return ticketFromDto(dto);
  });

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) =>
      _guard(() async {
        final key = Uri.encodeComponent(ticketId);
        final text = followUp.description.trim();
        final created = await _api.post(
          '/api/tickets/$key/follow-ups',
          data: {
            'kind': 'PROGRESS',
            'description': text.isEmpty ? _fallbackNote : text,
          },
        );
        final followUpId = _text(created?['id']);
        await _uploadPhotos(
          '/api/tickets/$key/attachments',
          followUp.photoPaths,
          capturedAt: followUp.at,
          followUpId: followUpId,
        );
        // «Atendido» pone en proceso un ticket que nadie ha tomado. Si ya esta en
        // proceso, resuelto o en espera, el seguimiento basta; resolverlo o
        // cerrarlo es de otro perfil y de la web.
        if (followUp.status == TicketStatus.attended) {
          final dto = _asMap(await _api.getJson('/api/tickets/$key'));
          if (_pending.contains(_text(dto['status']))) {
            await _api.post(
              '/api/tickets/$key/status',
              data: {'status': 'EN_PROCESO', 'rowVersion': dto['rowVersion']},
            );
          }
        }
        return _load(ticketId);
      });

  /// Estados en los que nadie ha atendido el ticket.
  static const _pending = {'NUEVO', 'ASIGNADO', 'REABIERTO'};

  static const _fallbackNote = 'Atendido desde la app movil.';

  Future<void> _uploadPhotos(
    String path,
    List<String> photos, {
    DateTime? capturedAt,
    TicketLocation? location,
    String? followUpId,
  }) async {
    for (final photo in photos) {
      final file = File(photo);
      if (!file.existsSync()) continue;
      await _api.postMultipart(
        path,
        fileField: 'file',
        filePath: photo,
        fileName: photo.split(RegExp(r'[\\/]')).last,
        contentType: imageType(photo),
        fields: {
          'kind': 'PHOTO',
          'capturedAt': capturedAt?.toUtc().toIso8601String(),
          'latitude': location?.latitude,
          'longitude': location?.longitude,
          'clientUuid': newClientId(),
          'followUpId': followUpId,
        },
      );
    }
  }

  /// El tipo de imagen segun la extension; el servidor exige `image/*`.
  static String imageType(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  /// El servidor guarda una sola descripcion; el formulario movil tiene titulo y
  /// descripcion: el titulo va en la primera linea.
  static String composeDescription(String title, String? description) {
    final t = title.trim();
    final d = description?.trim() ?? '';
    return d.isEmpty ? t : '$t\n\n$d';
  }

  /// Lo inverso de [composeDescription]: la primera linea es el titulo.
  static (String, String?) splitDescription(String text, {String? fallback}) {
    final lines = text.trim().split('\n');
    final title = lines.first.trim();
    final rest = lines.skip(1).join('\n').trim();
    return (
      title.isEmpty ? (fallback ?? '') : title,
      rest.isEmpty ? null : rest,
    );
  }

  /// Abierto (nadie lo ha atendido) o atendido (hay trabajo hecho o ya termino).
  static TicketStatus statusFromCode(String? code) => switch (code) {
    'NUEVO' || 'ASIGNADO' || 'REABIERTO' || null => TicketStatus.open,
    _ => TicketStatus.attended,
  };

  /// Un ticket tal como lo entrega `GET /api/tickets`.
  static Ticket ticketFromDto(Map<String, dynamic> m) {
    final typeLabel = _text(m['ticketTypeLabel']);
    final (title, body) = splitDescription(
      _text(m['description']) ?? '',
      fallback: typeLabel ?? _text(m['folio']),
    );
    final anchor = geoJsonAnchor(m['geometry']);
    return Ticket(
      id: _text(m['id']) ?? '',
      code: _text(m['folio']) ?? '',
      title: title,
      description: body,
      status: statusFromCode(_text(m['status'])),
      createdAt:
          DateTime.tryParse(_text(m['detectedAt']) ?? '')?.toUtc() ??
          DateTime.tryParse(_text(m['createdAt']) ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      category: typeLabel,
      dueAt: DateTime.tryParse(_text(m['dueAt']) ?? '')?.toUtc(),
      company: _text(m['company']),
      kmLabel: kmLabel(_num(m['kmStart']), _num(m['kmEnd'])),
      latitude: anchor?.$1,
      longitude: anchor?.$2,
      carriageway: _text(m['lane']),
    );
  }

  /// Un seguimiento tal como lo entrega `GET /api/tickets/{id}/follow-ups`.
  static TicketFollowUp followUpFromDto(
    Map<String, dynamic> m, {
    TicketStatus fallback = TicketStatus.open,
  }) {
    final code = _text(m['newStatus']) ?? _text(m['previousStatus']);
    final reason = _text(m['reason']);
    return TicketFollowUp(
      id: _text(m['id']) ?? '',
      at:
          DateTime.tryParse(_text(m['createdAt']) ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: code == null ? fallback : statusFromCode(code),
      description: _text(m['description']) ?? reason ?? '',
    );
  }

  String? _codeOf(String label) =>
      _typeCodes.values.contains(label) ? label : null;

  static String? _text(Object? v) {
    final s = v is String ? v.trim() : null;
    return s == null || s.isEmpty ? null : s;
  }

  static double? _num(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static int _int(Object? v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  /// [listing]: un 404 al listar es que el servidor aun no publica los tickets;
  /// al pedir uno es que ya no existe.
  Future<T> _guard<T>(
    Future<T> Function() body, {
    bool listing = false,
  }) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw TicketsException(
        e.isNetwork
            ? TicketsError.network
            : switch (e.status) {
                403 => TicketsError.permissionDenied,
                404 =>
                  listing ? TicketsError.notAvailable : TicketsError.notFound,
                _ => TicketsError.server,
              },
      );
    } on TicketsException {
      rethrow;
    } catch (_) {
      throw const TicketsException(TicketsError.server);
    }
  }
}
