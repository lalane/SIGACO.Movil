import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_condition_info.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'api_asset_capture_repository.dart';
import 'inventory_json.dart';

/// El inventario contra el backend (`/api/assets`, M13). El servidor aplica el
/// ambito de la persona (carreteras autorizadas), deja fuera los activos dados
/// de baja y busca, filtra, ordena y pagina: la app pide de a una pagina y solo
/// traduce la ficha del servidor a lo que muestra. Lo consultado con red queda
/// en el telefono (las respuestas, por el cache de la API; las fotos, en
/// archivos) para verlo sin senal.
class ApiInventoryRepository
    implements
        InventoryRepository,
        AssetPhotosSource,
        AssetTemplateSource,
        AssetCatalogSource,
        AssetQrSource,
        AssetHistorySource {
  ApiInventoryRepository(this._api, {Future<Directory> Function()? cacheDir})
    : _cacheDir = cacheDir ?? _defaultCacheDir;

  final ApiClient _api;

  /// Donde se guardan las fotos que baja de los activos.
  final Future<Directory> Function() _cacheDir;

  static Future<Directory> _defaultCacheDir() async =>
      Directory(p.join((await getTemporaryDirectory()).path, 'asset_photos'));

  /// Filas por pagina de la lista (el servidor acepta hasta 200): lo que cabe en
  /// unas pantallas, para que la primera llegue pronto aun con poca senal.
  static const pageSize = 50;

  /// Una foto de ficha mas grande que esto no se baja (lista movil).
  static const _maxPhotoBytes = 6 * 1024 * 1024;

  /// Cuantas fotos de la galeria se bajan por ficha.
  static const _maxPhotos = 8;

  /// El estado de conservacion como lo filtra el servidor (`conservationState`
  /// acepta un solo valor). "Malo" junta dos valores del catalogo: se piden uno
  /// tras otro, primero los pesimos. Sin filtro, una sola consulta.
  static List<String?> _conservationCodes(AssetCondition? c) => switch (c) {
    null => const [null],
    AssetCondition.good => const ['BUENO'],
    AssetCondition.regular => const ['REGULAR'],
    AssetCondition.poor => const ['PESIMO', 'MALO'],
    // El servidor no filtra lo que no se evaluo (la pantalla no lo ofrece).
    AssetCondition.unknown => const [null],
  };

  /// Los filtros de [query] como los lee `GET /api/assets` (sin la pagina).
  static Map<String, Object?> _filters(InventoryQuery query, String? state) {
    final from = query.inspectedFrom;
    final to = query.inspectedTo;
    return {
      'search': query.trimmedSearch,
      'assetTypeCode': query.typeCode,
      'conservationState': state,
      if (from != null || to != null) 'dateField': 'INSPECCION',
      'from': _isoDay(from),
      'to': _isoDay(to),
    };
  }

  static String? _isoDay(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  /// Una consulta que se puede cortar.
  static CancelToken? _token(InventoryCancellation? cancellation) {
    if (cancellation == null) return null;
    final token = CancelToken();
    cancellation.whenCancelled(token.cancel);
    return token;
  }

  Future<({List<InventoryAsset> items, int total})> _fetch(
    InventoryQuery query,
    String? state, {
    required int page,
    required int size,
    CancelToken? token,
  }) async {
    final json = await _api.getJson(
      '/api/assets',
      query: {
        'page': page,
        'pageSize': size,
        if (size > 1) 'sort': 'road',
        ..._filters(query, state),
      },
      cancelToken: token,
    );
    final map = _asMap(json);
    final items = map['items'];
    if (items is! List) throw const FormatException('sin items');
    return (
      items: [for (final item in items) fromListItem(_asMap(item))],
      total: (map['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  }) => _guard(() async {
    assert(
      query.condition != AssetCondition.unknown,
      'El servidor no filtra lo que no se evaluo',
    );
    final codes = _conservationCodes(query.condition);
    final token = _token(cancellation);
    final cursor = after is _Cursor && after.totals.length == codes.length
        ? after
        : null;
    final totals = cursor?.totals.toList() ?? List<int>.filled(codes.length, 0);
    var segment = cursor?.segment ?? 0;
    var serverPage = cursor?.page ?? 1;
    // Con varios valores, el total de los que van despues se sabe desde la
    // primera pagina.
    if (cursor == null && codes.length > 1) {
      final rest = await Future.wait([
        for (var i = 1; i < codes.length; i++)
          _fetch(query, codes[i], page: 1, size: 1, token: token),
      ]);
      for (var i = 1; i < codes.length; i++) {
        totals[i] = rest[i - 1].total;
      }
    }
    final items = <InventoryAsset>[];
    while (segment < codes.length && items.length < pageSize) {
      final got = await _fetch(
        query,
        codes[segment],
        page: serverPage,
        size: pageSize,
        token: token,
      );
      totals[segment] = got.total;
      items.addAll(got.items);
      final seen = (serverPage - 1) * pageSize + got.items.length;
      if (got.items.isEmpty || seen >= got.total) {
        segment++;
        serverPage = 1;
      } else {
        serverPage++;
      }
    }
    return InventoryResultPage(
      items: items,
      total: totals.fold(0, (sum, t) => sum + t),
      next: segment < codes.length
          ? _Cursor(segment: segment, page: serverPage, totals: totals)
          : null,
    );
  }, listing: true);

  /// Cuantos cumplen la consulta y cuantos de cada estado: una consulta de una
  /// fila por valor (el servidor da el total de cada una).
  @override
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  }) => _guard(() async {
    final base = query.withoutCondition();
    final token = _token(cancellation);
    Future<int> total(String? state) async =>
        (await _fetch(base, state, page: 1, size: 1, token: token)).total;
    final r = await Future.wait([
      total(null),
      total('BUENO'),
      total('REGULAR'),
      total('MALO'),
      total('PESIMO'),
    ]);
    return InventoryCounts(
      total: r[0],
      good: r[1],
      regular: r[2],
      poor: r[3] + r[4],
    );
  }, listing: true);

  /// `GET /api/catalogs/asset-types` (si no, los tipos de `/api/catalogs`). Se
  /// dejan fuera los que el servidor dice que no tienen activos.
  @override
  Future<List<AssetTypeOption>> types() async {
    List<Object?> rows;
    try {
      rows = InventoryJson.list(
        await _api.getJson('/api/catalogs/asset-types'),
      );
    } catch (_) {
      rows = const [];
    }
    if (rows.isEmpty) {
      try {
        final json = InventoryJson.map(await _api.getJson('/api/catalogs'));
        rows = InventoryJson.list(json?['assetTypes']);
      } catch (_) {
        return const [];
      }
    }
    return [
      for (final row in rows)
        if (InventoryJson.map(row)?['assetCount'] != 0)
          ?InventoryJson.assetType(row),
    ]..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.labelEs.compareTo(b.labelEs);
    });
  }

  @override
  Future<InventoryAsset> get(String id) => _guard(() async {
    final json = await _api.getJson('/api/assets/${Uri.encodeComponent(id)}');
    return fromDetailResponse(_asMap(json));
  });

  @override
  Future<InventoryAsset> byQr(String token) => _guard(() async {
    final json = await _api.getJson(
      '/api/assets/by-qr/${Uri.encodeComponent(token.trim())}',
    );
    return fromDetailResponse(_asMap(json));
  });

  /// Los registros que tienen al activo, con las listas de cada modulo (el
  /// servidor filtra por `assetId` y aplica los permisos y el ambito de la
  /// persona): los tickets con los cerrados, los mantenimientos del mas
  /// reciente al mas viejo.
  @override
  Future<AssetHistoryPage> history(
    String assetId,
    AssetHistoryKind kind, {
    int limit = 5,
  }) => _guard(() async {
    final (path, extra) = switch (kind) {
      AssetHistoryKind.tickets => (
        '/api/tickets',
        const <String, Object?>{'includeClosed': true},
      ),
      AssetHistoryKind.inspections => (
        '/api/inspections',
        const <String, Object?>{},
      ),
      AssetHistoryKind.maintenances => (
        '/api/preventive-maintenance',
        const <String, Object?>{'sort': 'recent'},
      ),
    };
    final json = _asMap(
      await _api.getJson(
        path,
        query: {'assetId': assetId, 'page': 1, 'pageSize': limit, ...extra},
      ),
    );
    final items = json['items'];
    if (items is! List) throw const FormatException('sin items');
    return AssetHistoryPage(
      items: [
        for (final item in items)
          ?historyEntry(kind, InventoryJson.map(item) ?? const {}),
      ],
      total: InventoryJson.integer(json['total']) ?? items.length,
    );
  });

  /// Un renglon de la lista de su modulo (`TicketDto`, `InspectionDto` o
  /// `PreventiveMaintenanceDto`) resumido para la ficha; null si no trae id.
  static AssetHistoryEntry? historyEntry(
    AssetHistoryKind kind,
    Map<String, dynamic> m,
  ) {
    final id = _text(m['id']);
    if (id == null) return null;
    final folio = _text(m['folio']) ?? id;
    final status = _text(m['status'])?.toUpperCase() ?? '';
    DateTime? moment(Object? v) => DateTime.tryParse(_text(v) ?? '')?.toUtc();
    switch (kind) {
      case AssetHistoryKind.tickets:
        return AssetHistoryEntry(
          id: id,
          kind: kind,
          folio: folio,
          status: status,
          title:
              _text(m['ticketTypeLabel']) ??
              _text(m['description'])?.split('\n').first.trim(),
          date: moment(m['detectedAt']) ?? moment(m['createdAt']),
          responsible: _text(m['responsibleName']),
          overdue: m['isOverdue'] == true,
          subsystemCode: _text(m['subsystemCode']),
        );
      case AssetHistoryKind.inspections:
        final executed = moment(m['executedAt']);
        return AssetHistoryEntry(
          id: id,
          kind: kind,
          folio: folio,
          status: status,
          title:
              _text(m['inspectionTypeLabel']) ?? _text(m['inspectionTypeCode']),
          date: executed ?? _day(m['scheduledOn']),
          dateOnly: executed == null,
          responsible: _text(m['inspectorName']),
        );
      case AssetHistoryKind.maintenances:
        return AssetHistoryEntry(
          id: id,
          kind: kind,
          folio: folio,
          status: status,
          title: _text(m['activity']),
          date:
              _day(m['actualEnd']) ??
              _day(m['actualStart']) ??
              _day(m['plannedStart']),
          dateOnly: true,
          responsible: _text(m['responsibleName']),
          overdue: m['isOverdue'] == true,
          subsystemCode: _text(m['subsystemCode']),
        );
    }
  }

  /// `operationalHistory` de la ficha: cuantos registros de cada tipo tiene
  /// el activo. Un tipo en null es un modulo que la persona no puede ver; sin
  /// el campo (servidor anterior), null.
  static AssetHistoryCounts? historyCounts(Object? json) {
    final m = InventoryJson.map(json);
    if (m == null) return null;
    AssetHistoryCount? count(Object? v) {
      final c = InventoryJson.map(v);
      final total = InventoryJson.integer(c?['total']);
      if (c == null || total == null) return null;
      return AssetHistoryCount(
        open: InventoryJson.integer(c['open']) ?? 0,
        total: total,
      );
    }

    return AssetHistoryCounts(
      tickets: count(m['tickets']),
      inspections: count(m['inspections']),
      maintenances: count(m['maintenances']),
    );
  }

  @override
  Future<AssetTemplate?> template(String typeCode) async {
    try {
      return await ApiAssetCaptureRepository.currentTemplate(_api, typeCode);
    } catch (_) {
      // Sin ficha, la seccion de campos no se pinta.
      return null;
    }
  }

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async {
    try {
      final json = InventoryJson.map(await _api.getJson('/api/catalogs'));
      return InventoryJson.catalogs(json?['catalogs']);
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async {
    final photo = asset.mainPhotoId;
    if (photo == null) return null;
    // Una foto que no baja no impide ver la ficha: si ya se habia bajado, se
    // muestra la guardada.
    final bytes = await _api.downloadFile(
      '/api/assets/${Uri.encodeComponent(asset.id)}'
      '/attachments/${Uri.encodeComponent(photo)}/content',
      maxBytes: _maxPhotoBytes,
    );
    final file = await _photoFile(photo);
    if (bytes != null) {
      await _write(file, bytes);
      return bytes;
    }
    try {
      if (file != null && file.existsSync()) return await file.readAsBytes();
    } catch (_) {}
    return null;
  }

  @override
  Future<List<String>> photos(InventoryAsset asset) async {
    final key = Uri.encodeComponent(asset.id);
    final List<Object?> items;
    try {
      items = InventoryJson.list(
        await _api.getJson('/api/assets/$key/attachments'),
      );
    } catch (_) {
      return const [];
    }
    final paths = <String>[];
    for (final item in items) {
      if (paths.length >= _maxPhotos) break;
      final a = InventoryJson.map(item);
      final id = InventoryJson.text(a?['id']);
      final type = InventoryJson.text(a?['contentType']) ?? '';
      final kind = InventoryJson.text(a?['kind'])?.toUpperCase();
      if (a == null || id == null || id == asset.mainPhotoId) continue;
      if (!type.startsWith('image/') && kind != 'FOTO') continue;
      final file = await _photoFile(id);
      if (file == null) continue;
      try {
        if (!file.existsSync()) {
          final bytes = await _api.downloadFile(
            '/api/assets/$key/attachments/${Uri.encodeComponent(id)}/content',
            maxBytes: _maxPhotoBytes,
          );
          if (bytes == null) continue;
          await _write(file, bytes);
        }
        paths.add(file.path);
      } catch (_) {
        // Una foto que no baja se omite.
      }
    }
    return paths;
  }

  Future<File?> _photoFile(String attachmentId) async {
    try {
      final dir = await _cacheDir();
      final safe = attachmentId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      return File(p.join(dir.path, '$safe.img'));
    } catch (_) {
      return null;
    }
  }

  /// Guardar es un extra: un fallo del disco no debe romper la ficha.
  static Future<void> _write(File? file, Uint8List bytes) async {
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  /// Un renglon de la lista (`AssetListItemDto`): sin descripcion y, salvo que
  /// se pida, sin geometria.
  static InventoryAsset fromListItem(Map<String, dynamic> m) {
    final code = (m['code'] as String?)?.trim() ?? '';
    final status = _text(m['status']);
    final anchor = geoJsonAnchor(m['geometry']);
    return InventoryAsset(
      id: m['id'] as String,
      code: code.isEmpty ? null : code,
      name: code,
      category: (m['assetTypeLabel'] as String?)?.trim() ?? '',
      typeCode: _text(m['assetTypeCode']),
      subsystemCode: _text(m['subsystemCode']),
      roadCode: _text(m['roadCode']),
      condition: _condition(m['conservationState'] as String?),
      lifecycle: AssetLifecycle.fromCode(status),
      inMaintenance: _inMaintenance(m, status),
      source: _text(m['source']),
      externalLayerCode: _text(m['externalLayerCode']),
      kmLabel: _kmLabel(_num(m['kmStart']), _num(m['kmEnd'])),
      segmentCode: _text(m['roadSegmentCode']),
      direction: _text(m['direction']),
      latitude: anchor?.$1,
      longitude: anchor?.$2,
      lastInspectionAt: _moment(m['lastInspectionAt']),
      // En la lista basta saber si el tipo lleva condicion ("No aplica").
      conditionInfo: m['conditionApplies'] == false
          ? const AssetConditionInfo(applies: false)
          : null,
    );
  }

  /// La ficha completa (`AssetDetailDto`): el activo y, si el servidor ya los
  /// manda, la ficha con la que se valido y los datos crudos del WebGIS.
  static InventoryAsset fromDetailResponse(Map<String, dynamic> json) {
    final asset = InventoryJson.map(json['asset']) ?? json;
    final typeCode = _text(asset['assetTypeCode']);
    final template = InventoryJson.template(
      json['template'] ?? asset['template'],
      typeCode: typeCode,
    );
    final external = InventoryJson.map(
      json['externalAttributes'] ?? asset['externalAttributes'],
    );
    return fromDetail(
      asset,
      template: template,
      externalAttributes: external,
      attachmentCount: InventoryJson.integer(json['attachmentCount']),
      history: historyCounts(json['operationalHistory']),
      conditionInfo: conditionInfo(json, asset),
      lastInspectionAt: _moment(
        InventoryJson.map(json['schedule'])?['lastInspectionAt'],
      ),
    );
  }

  /// La condicion de la ficha (M13 Parte 2: `condition`, `marks` y `schedule`);
  /// null si el servidor es anterior y no la manda.
  static AssetConditionInfo? conditionInfo(
    Map<String, dynamic> json,
    Map<String, dynamic> asset,
  ) {
    final condition = InventoryJson.map(json['condition']);
    final marks = InventoryJson.map(json['marks']);
    final schedule = InventoryJson.map(json['schedule']);
    if (condition == null && marks == null) return null;
    return AssetConditionInfo(
      applies: (condition?['applies'] ?? asset['conditionApplies']) != false,
      nativeValue: _text(
        condition?['nativeValue'] ?? asset['conservationNative'],
      ),
      source: _text(condition?['source'] ?? asset['conservationStateSource']),
      sourceRef: _text(condition?['sourceRef']),
      executedAt: _moment(
        condition?['executedAt'] ?? asset['conservationStateAt'],
      ),
      cycle: InventoryJson.integer(condition?['cycle']),
      openFindings: InventoryJson.integer(marks?['openFindings']) ?? 0,
      notLocatedAt: _moment(marks?['notLocatedAt'] ?? asset['notLocatedAt']),
      notLocatedNote: _text(
        marks?['notLocatedNote'] ?? asset['notLocatedNote'],
      ),
      nextInspectionOn: _day(schedule?['nextInspectionOn']),
    );
  }

  /// El activo (`AssetDto`).
  static InventoryAsset fromDetail(
    Map<String, dynamic> m, {
    AssetTemplate? template,
    Map<String, dynamic>? externalAttributes,
    int? attachmentCount,
    AssetHistoryCounts? history,
    AssetConditionInfo? conditionInfo,
    DateTime? lastInspectionAt,
  }) {
    final code = (m['code'] as String?)?.trim() ?? '';
    final description = _text(m['description']);
    final anchor = geoJsonAnchor(m['geometry']);
    final status = _text(m['status']);
    return InventoryAsset(
      id: m['id'] as String,
      code: code.isEmpty ? null : code,
      name: description ?? code,
      category: (m['assetTypeLabel'] as String?)?.trim() ?? '',
      typeCode: _text(m['assetTypeCode']),
      subsystemCode: _text(m['subsystemCode']),
      roadCode: _text(m['roadCode']),
      condition: _condition(m['conservationState'] as String?),
      lifecycle: AssetLifecycle.fromCode(status),
      statusReason: _text(m['statusReason']),
      inMaintenance: _inMaintenance(m, status),
      openTicketCount: InventoryJson.integer(m['openTicketCount']),
      source: _text(m['source']),
      externalLayerCode: _text(m['externalLayerCode']),
      externalId: _text('${m['externalId'] ?? ''}'),
      kmLabel: _kmLabel(_num(m['kmStart']), _num(m['kmEnd'])),
      segmentCode: _text(m['roadSegmentCode']),
      direction: _text(m['direction']),
      latitude: anchor?.$1,
      longitude: anchor?.$2,
      installedAt: _day(m['installedOn']),
      notes: _text(m['notes']),
      mainPhotoId: _text(m['mainPhotoId']),
      description: description,
      brand: _text(m['brand']),
      model: _text(m['model']),
      serialNumber: _text(m['serialNumber']),
      usefulLifeMonths: InventoryJson.integer(m['usefulLifeMonths']),
      attributes: InventoryJson.map(m['attributes']) ?? const {},
      externalAttributes: externalAttributes,
      template: template,
      templateNumber: InventoryJson.integer(m['templateNumber']),
      attachmentCount: attachmentCount,
      history: history,
      conditionInfo: conditionInfo,
      lastInspectionAt: lastInspectionAt,
    );
  }

  /// Con ticket abierto (`inMaintenance`, `openTicketCount`) o, en un servidor
  /// anterior al contrato, en estado EN_MANTENIMIENTO.
  static bool _inMaintenance(Map<String, dynamic> m, String? status) =>
      m['inMaintenance'] == true ||
      (InventoryJson.integer(m['openTicketCount']) ?? 0) > 0 ||
      status?.toUpperCase() == 'EN_MANTENIMIENTO';

  /// BUENO, REGULAR, MALO y PESIMO (catalogo de conservacion del servidor); lo
  /// que no se evaluo o no se conoce queda "sin evaluar".
  static AssetCondition _condition(String? code) =>
      switch (code?.trim().toUpperCase()) {
        'BUENO' => AssetCondition.good,
        'REGULAR' => AssetCondition.regular,
        'MALO' || 'PESIMO' => AssetCondition.poor,
        _ => AssetCondition.unknown,
      };

  /// `KM 150+200`; con kilometro final distinto, `KM 150+200 - 151+000`.
  static String? _kmLabel(double? start, double? end) {
    if (start == null) return null;
    String km(double v) {
      final meters = (v * 1000).round();
      return '${meters ~/ 1000}+${(meters % 1000).toString().padLeft(3, '0')}';
    }

    final from = km(start);
    if (end == null || km(end) == from) return 'KM $from';
    return 'KM $from - ${km(end)}';
  }

  static String? _text(Object? v) {
    final s = v is String ? v.trim() : null;
    return s == null || s.isEmpty ? null : s;
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  /// Un instante ISO del servidor, en UTC.
  static DateTime? _moment(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;

  static DateTime? _day(Object? v) {
    if (v is! String) return null;
    final d = DateTime.tryParse(v);
    return d == null ? null : DateTime.utc(d.year, d.month, d.day);
  }

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  /// [listing]: un 404 al listar es que el servidor aun no publica el
  /// inventario; al pedir una ficha es que el activo ya no existe.
  Future<T> _guard<T>(Future<T> Function() body, {bool listing = false}) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw InventoryException(
        e.isNetwork
            ? InventoryError.network
            : switch (e.status) {
                403 => InventoryError.permissionDenied,
                404 =>
                  listing
                      ? InventoryError.notAvailable
                      : InventoryError.notFound,
                _ => InventoryError.server,
              },
      );
    } on InventoryException {
      rethrow;
    } catch (_) {
      throw const InventoryException(InventoryError.server);
    }
  }
}

/// Por donde va la lista: en que valor del estado de conservacion (cuando el
/// filtro junta varios), que pagina del servidor sigue y el total de cada
/// valor.
class _Cursor {
  const _Cursor({
    required this.segment,
    required this.page,
    required this.totals,
  });

  final int segment;
  final int page;
  final List<int> totals;
}
