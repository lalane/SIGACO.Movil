import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../../../core/geo/km_label.dart';
import '../../../../core/ids/client_id.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_supervision.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Los tickets contra el backend (`/api/tickets`, M11). El servidor aplica el
/// ambito de la persona y el SLA; la app traduce el ticket del servidor a lo que
/// muestra (abierto o atendido, APP-MOB-03) y el seguimiento y las fotos que
/// captura a lo que el servidor guarda.
class ApiTicketsRepository
    implements
        TicketsRepository,
        TicketFailureSource,
        TicketPlacementSource,
        TicketRoadSource,
        TicketSupervision {
  ApiTicketsRepository(
    this._api, {
    required this.roadId,
    this.language = _spanish,
    Future<Directory> Function()? cacheDir,
  }) : _cacheDir = cacheDir ?? getTemporaryDirectory;

  final ApiClient _api;

  /// Donde se guardan las fotos que baja de los tickets.
  final Future<Directory> Function() _cacheDir;

  /// Una foto de ticket pesa unos cuantos MB; mas que esto no se baja.
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  /// La carretera donde se levanta un ticket que no viene de un activo; null si
  /// no se puede saber (el servidor lo rechaza y la pantalla lo dice).
  final Future<String?> Function() roadId;

  /// `es` o `pt`: el idioma de los tipos de ticket.
  final String Function() language;

  static String _spanish() => 'es';

  static const _pageSize = 100;
  static const _maxPages = 10;

  /// Tipos de ticket ya vistos: nombre que se muestra -> codigo del servidor.
  final _typeCodes = <String, String>{};

  /// De los cerrados y cancelados solo se traen los mas recientes: los que
  /// faltan por atender son los que importan en campo, y esos llegan todos.
  static const _finishedPageSize = 50;

  @override
  Future<List<Ticket>> list() => _guard(() async {
    // Sin estado, el servidor da los que siguen vivos (SIN_VALIDAR, ABIERTO y
    // ATENDIDO).
    final result = await _pages(const {}, maxPages: _maxPages);
    final seen = {for (final t in result) t.id};
    // Los cerrados y los cancelados, para sus filtros (DTF M11 v0.3). Si no
    // llegan, la lista se ve igual con los vivos.
    final finished = await Future.wait([
      for (final stage in const [TicketStage.closed, TicketStage.cancelled])
        _pages(
          {'status': stage.code},
          maxPages: 1,
          pageSize: _finishedPageSize,
        ).catchError((Object _) => const <Ticket>[]),
    ]);
    for (final t in finished.expand((l) => l)) {
      if (seen.add(t.id)) result.add(t);
    }
    return _withCovers(result);
  }, listing: true);

  /// Los tickets de `GET /api/tickets` con [query], pagina por pagina.
  Future<List<Ticket>> _pages(
    Map<String, Object?> query, {
    required int maxPages,
    int pageSize = _pageSize,
  }) async {
    final result = <Ticket>[];
    var page = 1;
    var total = 0;
    do {
      final json = await _api.getJson(
        '/api/tickets',
        query: {...query, 'page': page, 'pageSize': pageSize},
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
    } while (result.length < total && page <= maxPages);
    return result;
  }

  /// Cuantos tickets del historial traen su primera foto: los mas recientes, que
  /// son los que se ven al abrir.
  static const _coverLimit = 30;
  static const _coverBatch = 6;

  /// Le pone a cada ticket reciente su primera foto, para la tarjeta del
  /// historial. Una foto que no baja deja la tarjeta como estaba.
  Future<List<Ticket>> _withCovers(List<Ticket> tickets) async {
    final newest = [...tickets]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final covers = <String, String>{};
    final wanted = newest.take(_coverLimit).toList();
    for (var i = 0; i < wanted.length; i += _coverBatch) {
      final batch = wanted.skip(i).take(_coverBatch);
      await Future.wait([
        for (final t in batch)
          _cover(t.id).then((path) {
            if (path != null) covers[t.id] = path;
          }),
      ]);
    }
    if (covers.isEmpty) return tickets;
    return [
      for (final t in tickets)
        covers.containsKey(t.id) ? t.copyWith(photoPaths: [covers[t.id]!]) : t,
    ];
  }

  /// La primera foto del ticket (la suya, no la de un seguimiento) bajada al
  /// telefono; null si no tiene o no se pudo bajar.
  Future<String?> _cover(String id) async {
    try {
      final key = Uri.encodeComponent(id);
      final raw = await _api.getJson('/api/tickets/$key/attachments');
      final items = raw is List
          ? raw
          : (raw is Map ? raw['items'] : null) as List? ?? const [];
      final images = [
        for (final a in items)
          if (a is Map<String, dynamic> &&
              (_text(a['contentType']) ?? '').startsWith('image/'))
            a,
      ];
      if (images.isEmpty) return null;
      final own = images.where((a) => _text(a['followUpId']) == null);
      final a = (own.isEmpty ? images : own).first;
      final photoId = _text(a['id']);
      if (photoId == null) return null;
      final dir = Directory(p.join((await _cacheDir()).path, 'ticket_photos'));
      final file = File(
        p.join(dir.path, '$photoId${_extension(_text(a['contentType'])!)}'),
      );
      if (!file.existsSync()) {
        final bytes = await _api.downloadFile(
          '/api/tickets/$key/attachments/${Uri.encodeComponent(photoId)}/content',
          maxBytes: _maxPhotoBytes,
        );
        if (bytes == null) return null;
        await dir.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

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
    final photos = await _photos(key);
    return base.copyWith(
      photoPaths: photos[null] ?? const [],
      followUps: [
        for (final f in items)
          if (f is Map<String, dynamic>)
            followUpFromDto(
              f,
              fallback: base.status,
            ).withPhotos(photos[_text(f['id'])] ?? const []),
      ],
    );
  }

  /// Las fotos del ticket bajadas al telefono, por seguimiento (la clave null es
  /// el ticket mismo). Una foto que no baja no impide ver la ficha.
  Future<Map<String?, List<String>>> _photos(String key) async {
    final result = <String?, List<String>>{};
    try {
      final raw = await _api.getJson('/api/tickets/$key/attachments');
      final items = raw is List
          ? raw
          : (raw is Map ? raw['items'] : null) as List? ?? const [];
      final dir = Directory(p.join((await _cacheDir()).path, 'ticket_photos'));
      for (final a in items) {
        if (a is! Map<String, dynamic>) continue;
        final id = _text(a['id']);
        final type = _text(a['contentType']) ?? '';
        if (id == null || !type.startsWith('image/')) continue;
        final file = File(p.join(dir.path, '$id${_extension(type)}'));
        if (!file.existsSync()) {
          final bytes = await _api.downloadFile(
            '/api/tickets/$key/attachments/${Uri.encodeComponent(id)}/content',
            maxBytes: _maxPhotoBytes,
          );
          if (bytes == null) continue;
          await dir.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
        }
        (result[_text(a['followUpId'])] ??= []).add(file.path);
      }
    } catch (_) {
      // Sin las fotos la ficha se ve igual.
    }
    return result;
  }

  static String _extension(String contentType) => switch (contentType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    'image/heic' || 'image/heif' => '.heic',
    'image/gif' => '.gif',
    _ => '.jpg',
  };

  /// Las fallas de la Matriz: los tipos de ticket con plazo fijo
  /// (`attentionHours`), con su indicador y su subclasificacion.
  @override
  @override
  Future<TicketPlacement> place(double longitude, double latitude) async {
    try {
      final m = _asMap(
        await _api.getJson(
          '/api/road-network/locate',
          query: {
            'lon': longitude,
            'lat': latitude,
            'tolerance': ticketAxisToleranceMeters,
          },
        ),
      );
      final km = _num(m['km']);
      if (km == null) return const TicketPlacement.unknown();
      return TicketPlacement(
        status: TicketPlacementStatus.onRoad,
        km: km.toDouble(),
        direction: _text(m['direction']),
        segmentCode: _text(m['roadSegmentCode']),
        distanceMeters: _num(m['distanceMeters'])?.toDouble(),
        directionAmbiguous: m['directionAmbiguous'] == true,
      );
    } on ApiFailure catch (e) {
      return e.code == 'LOCATION_OUT_OF_AXIS'
          ? const TicketPlacement.offRoad()
          : const TicketPlacement.unknown();
    } catch (_) {
      return const TicketPlacement.unknown();
    }
  }

  @override
  Future<List<TicketFailure>> failures() => _guard(() async {
    final json = _asMap(await _api.getJson('/api/app-configuration'));
    final catalogs = json['operationalCatalogs'];
    final types = catalogs is Map ? catalogs['ticketTypes'] : null;
    if (types is! List) return const <TicketFailure>[];
    final rows = [
      for (final t in types)
        if (t is Map<String, dynamic> && t['active'] != false) t,
    ]..sort((a, b) => _int(a['sortOrder']).compareTo(_int(b['sortOrder'])));
    final pt = language() == 'pt';
    final result = <TicketFailure>[];
    for (final t in rows) {
      final code = _text(t['code']);
      final hours = t['attentionHours'];
      final subsystem = _text(t['subsystemCode']);
      final label = (pt ? _text(t['labelPt']) : null) ?? _text(t['labelEs']);
      if (code == null || hours is! num || subsystem == null || label == null) {
        continue;
      }
      // El codigo tambien vale como categoria al armar el ticket.
      _typeCodes[code] = code;
      result.add(
        TicketFailure(
          code: code,
          label: label,
          subsystemCode: subsystem.toUpperCase(),
          group:
              (pt ? _text(t['classificationPt']) : null) ??
              _text(t['classification']) ??
              '',
          attentionHours: hours.toDouble(),
          attentionLabel: _text(t['attentionLabel']),
        ),
      );
    }
    return result;
  });

  @override
  Future<List<String>> categories() => _guard(() async {
    final json = _asMap(await _api.getJson('/api/app-configuration'));
    final catalogs = json['operationalCatalogs'];
    final types = catalogs is Map ? catalogs['ticketTypes'] : null;
    if (types is! List) return const <String>[];
    // Las fallas de la Matriz (con plazo) se eligen en cascada, no aqui.
    final rows = [
      for (final t in types)
        if (t is Map<String, dynamic> &&
            t['active'] != false &&
            t['attentionHours'] is! num)
          t,
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

  /// La carretera de la concesion activa, la ultima que se pudo saber: sin red no
  /// se puede preguntar, y lo capturado sin conexion la necesita.
  String? _road;

  /// Pregunta la carretera ahora para tenerla si despues falta la red.
  Future<void> warmRoad() async => _road = await roadId() ?? _road;

  /// Olvida lo aprendido de la concesion (al cambiar de concesion o cerrar
  /// sesion).
  void forget() {
    _road = null;
    _typeCodes.clear();
  }

  /// Lo que el servidor recibe para crear el ticket. Sin red solo se puede armar
  /// si ya se conocian los tipos de ticket y la carretera.
  Future<Map<String, Object?>> ticketBody(NewTicket draft) async {
    // Una falla de la Matriz ya trae su codigo; la lista plana va por nombre.
    if (!draft.fixedAttention && _typeCodes.isEmpty) await categories();
    final code = draft.fixedAttention
        ? draft.category
        : _typeCodes[draft.category] ?? _codeOf(draft.category);
    if (code == null) throw const TicketsException(TicketsError.server);

    final location = draft.location;
    // Con activo, la carretera (y lo que no se indique) la pone el servidor.
    final assetId = draft.assetId ?? location?.assetId;
    String? road;
    if (assetId == null) {
      // La elegida en el formulario manda; si no, la unica de la concesion.
      road = draft.roadId ?? await roadId() ?? _road;
      if (draft.roadId == null) _road = road;
    }
    final km = parseKm(draft.kmLabel ?? location?.kmLabel);
    return <String, Object?>{
      'ticketTypeCode': code,
      // Con una falla de la Matriz la prioridad sale del plazo (servidor).
      if (!draft.fixedAttention) 'priority': draft.priority.code,
      'description': composeDescription(draft.title, draft.description),
      'assetId': ?assetId,
      'roadId': ?road,
      'kmStart': ?km,
      'kmEnd': ?parseKm(draft.kmEndLabel),
      'direction': ?draft.direction,
      if (location != null)
        'geometry': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        },
      if (draft.capturedAt != null)
        'detectedAt': draft.capturedAt!.toUtc().toIso8601String(),
      'clientUuid': ?draft.clientId,
    };
  }

  @override
  Future<Ticket> create(NewTicket draft) => _guard(() async {
    final body = await ticketBody(draft);
    final dto = (await _api.post('/api/tickets', data: body)) ?? const {};
    final id = _text(dto['id']);
    if (id == null) throw const FormatException('sin id');
    try {
      await attachPhotos(
        id,
        draft.photoPaths,
        capturedAt: draft.capturedAt,
        location: draft.location,
      );
    } on ApiFailure catch (e) {
      // Sin red se encola entero (el servidor reconoce el registro por su clave);
      // con otro fallo, el registro ya existe y solo faltan las fotos.
      if (e.isNetwork) rethrow;
      throw TicketPartiallySavedException(_reason(e));
    }
    return ticketFromDto(dto);
  });

  /// Sube las fotos de un ticket ya creado.
  Future<void> attachPhotos(
    String ticketId,
    List<String> photos, {
    DateTime? capturedAt,
    TicketLocation? location,
    String? followUpId,
  }) => _uploadPhotos(
    '/api/tickets/${Uri.encodeComponent(ticketId)}/attachments',
    photos,
    capturedAt: capturedAt,
    location: location,
    followUpId: followUpId,
  );

  /// Lo que el servidor recibe para registrar el seguimiento.
  Map<String, Object?> followUpBody(NewFollowUp followUp) {
    final text = followUp.description.trim();
    return {
      'kind': 'AVANCE',
      'description': text.isEmpty ? _fallbackNote : text,
      // Fecha y hora de la atencion en campo (DTF M11 HU-11-09).
      'attendedAt': followUp.at.toUtc().toIso8601String(),
    };
  }

  /// Lo que sigue a un seguimiento ya registrado: sus fotos y, si se marco como
  /// atendido, dejar el ticket ATENDIDO con ese seguimiento (DTF M11 v0.3,
  /// HU-11-10: exige al menos una foto). Solo si el servidor ofrece ATENDER (el
  /// ticket esta ABIERTO y el usuario es de su equipo o Supervisor); validar y
  /// cerrar es del Supervisor.
  Future<void> finishFollowUp(
    String ticketId,
    String? followUpId, {
    required List<String> photos,
    required DateTime at,
    required bool attended,
  }) async {
    final key = Uri.encodeComponent(ticketId);
    await attachPhotos(
      ticketId,
      photos,
      capturedAt: at,
      followUpId: followUpId,
    );
    if (attended && followUpId != null) {
      final dto = _asMap(await _api.getJson('/api/tickets/$key'));
      final actions =
          (dto['actions'] as List?)?.map((e) => '$e').toSet() ??
          const <String>{};
      if (actions.contains('ATENDER')) {
        await _api.post(
          '/api/tickets/$key/attend',
          data: {'followUpId': followUpId, 'rowVersion': dto['rowVersion']},
        );
      }
    }
  }

  @override
  Future<Ticket> addFollowUp(String ticketId, NewFollowUp followUp) =>
      _guard(() async {
        final key = Uri.encodeComponent(ticketId);
        final created = await _api.post(
          '/api/tickets/$key/follow-ups',
          data: followUpBody(followUp),
        );
        final followUpId = _text(created?['id']);
        try {
          await attachPhotos(
            ticketId,
            followUp.photoPaths,
            capturedAt: followUp.at,
            followUpId: followUpId,
          );
        } on ApiFailure catch (e) {
          if (e.isNetwork) rethrow;
          throw TicketPartiallySavedException(_reason(e));
        }
        // Las fotos ya subieron: queda, si se marco como atendido, el estado.
        await finishFollowUp(
          ticketId,
          followUpId,
          photos: const [],
          at: followUp.at,
          attended: followUp.status == TicketStatus.attended,
        );
        return _load(ticketId);
      });

  @override
  Future<List<TicketRoad>> roads() => _guard(() async {
    final me = _asMap(await _api.getJson('/api/auth/me'));
    final context = me['context'];
    final raw = context is Map ? context['roads'] : null;
    return [
      for (final r in _items(raw))
        if (r is Map && _text(r['id']) != null)
          TicketRoad(
            id: _text(r['id'])!,
            code: _text(r['code']) ?? _text(r['name']) ?? _text(r['id'])!,
            name: _text(r['name']),
          ),
    ];
  });

  // Acciones del Supervisor (DTF M11 v0.3, HU-11-24).

  @override
  Future<List<TicketAssignableCompany>> assignableTeams() => _guard(() async {
    final raw = await _api.getJson('/api/tickets/assignable-teams');
    return [
      for (final c in _items(raw))
        if (c is Map<String, dynamic> && _text(c['id']) != null)
          TicketAssignableCompany(
            id: _text(c['id'])!,
            name: _text(c['name']) ?? _text(c['id'])!,
            isExternal: c['isExternal'] == true,
            teams: [
              for (final t in _items(c['teams']))
                if (t is Map<String, dynamic> && _text(t['id']) != null)
                  TicketAssignableTeam(
                    id: _text(t['id'])!,
                    name: _text(t['name']) ?? _text(t['id'])!,
                    members: [
                      for (final m in _items(t['members']))
                        if (m is Map<String, dynamic> &&
                            _text(m['userId']) != null)
                          TicketTeamMember(
                            userId: _text(m['userId'])!,
                            fullName: _text(m['fullName']) ?? '',
                            profileCode: _text(m['profileCode']),
                          ),
                    ],
                  ),
            ],
          ),
    ];
  });

  @override
  Future<Ticket> assign(Ticket ticket, TicketAssignment assignment) =>
      _act(ticket, 'assign', {
        'companyId': assignment.companyId,
        'teamId': assignment.teamId,
        'responsibleUserId': ?assignment.responsibleUserId,
        'reason': ?_clean(assignment.reason),
      });

  @override
  Future<Ticket> close(Ticket ticket, TicketClosing closing) => _act(
    ticket,
    'close',
    {'notes': ?_clean(closing.notes), 'assetCondition': closing.condition.code},
  );

  @override
  Future<Ticket> returnToOpen(Ticket ticket, String reason) =>
      _act(ticket, 'return', {'reason': reason.trim()});

  @override
  Future<Ticket> reopen(Ticket ticket, String reason) =>
      _act(ticket, 'reopen', {'reason': reason.trim()});

  @override
  Future<Ticket> cancel(Ticket ticket, TicketCancellation cancellation) =>
      _act(ticket, 'cancel', {
        'reason': cancellation.reason.code,
        'duplicateOfFolio': ?_clean(cancellation.duplicateOfFolio),
        'notes': ?_clean(cancellation.notes),
      });

  /// Manda la accion con la version del ticket que se ve y devuelve el ticket
  /// como quedo. Lo que el servidor rechaza por regla (409, 400) llega con su
  /// motivo; sin red, sin permiso o sin el ticket, como cualquier otro fallo.
  Future<Ticket> _act(
    Ticket ticket,
    String step,
    Map<String, Object?> body,
  ) => _guard(() async {
    final key = Uri.encodeComponent(ticket.id);
    final Map<String, dynamic>? dto;
    try {
      dto = await _api.post(
        '/api/tickets/$key/$step',
        data: {...body, 'rowVersion': ?ticket.rowVersion},
      );
    } on ApiFailure catch (e) {
      if (e.isNetwork || e.status == 403 || e.status == 404) rethrow;
      throw TicketActionRejected(_reason(e));
    }
    try {
      return await _load(ticket.id);
    } catch (_) {
      // La accion ya quedo: si la ficha no se puede volver a pedir, se muestra
      // lo que respondio el servidor con lo que ya se veia.
      if (dto == null || _text(dto['id']) == null) rethrow;
      return ticketFromDto(
        dto,
      ).copyWith(photoPaths: ticket.photoPaths, followUps: ticket.followUps);
    }
  });

  static String? _clean(String? text) {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static List<Object?> _items(Object? raw) => raw is List
      ? raw
      : (raw is Map ? raw['items'] : null) as List? ?? const [];

  /// Estados en los que falta atender el ticket y el SLA corre (DTF M11 v0.3);
  /// los del BBP siguen entendiendose por si llega un dato viejo.
  static const _pending = {
    'SIN_VALIDAR',
    'ABIERTO',
    'NUEVO',
    'ASIGNADO',
    'EN_PROCESO',
    'EN_ESPERA',
    'REABIERTO',
  };

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
          'kind': 'FOTO',
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

  /// Abierto (SIN_VALIDAR o ABIERTO: falta atenderlo) o atendido (ATENDIDO,
  /// CERRADO o CANCELADO).
  static TicketStatus statusFromCode(String? code) =>
      code == null || _pending.contains(code)
      ? TicketStatus.open
      : TicketStatus.attended;

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
      // El cuerpo de la via (DTF M11 v0.3); el carril del BBP si no viene.
      carriageway: _text(m['carriageway']) ?? _text(m['lane']),
      authorName: _text(m['createdByName']),
      authorProfile: _text(m['createdByProfile']),
      stage: TicketStage.fromCode(_text(m['status'])),
      actions: actionsFrom(m['actions']),
      rowVersion: (m['rowVersion'] as num?)?.toInt(),
      assignedCompanyId: _text(m['assignedCompanyId']),
      assignedCompanyName: _text(m['assignedCompanyName']),
      assignedTeamId: _text(m['assignedTeamId']),
      assignedTeamName: _text(m['assignedTeamName']),
      responsibleName: _text(m['responsibleName']),
      cancelReason: _text(m['cancelReason']),
      duplicateOfFolio: _text(m['duplicateOfFolio']),
      closingAssetCondition: _text(m['closingAssetCondition']),
      assetId: _text(m['assetId']),
    );
  }

  /// Las acciones que el servidor ofrece; null si no las manda (un servidor
  /// anterior). Un codigo que la app no conoce se ignora.
  static Set<TicketAction>? actionsFrom(Object? raw) {
    if (raw is! List) return null;
    return {for (final code in raw) ?TicketAction.fromCode('$code')};
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
  /// El motivo que dio el servidor, con su codigo, para mostrarlo a la persona.
  static String _reason(ApiFailure e) {
    final field = e.fieldErrors.values.expand((m) => m).firstOrNull;
    final text = (field ?? e.message)?.trim();
    final tag = e.code ?? '${e.status}';
    return text == null || text.isEmpty ? tag : '$text ($tag)';
  }

  Future<T> _guard<T>(Future<T> Function() body, {bool listing = false}) async {
    try {
      return await body();
    } on TicketPartiallySavedException {
      rethrow;
    } on TicketActionRejected {
      rethrow;
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
