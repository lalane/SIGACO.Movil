import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/geo/geojson_anchor.dart';
import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';

/// El inventario contra el backend (`/api/assets`, M13). El servidor aplica el
/// ambito de la persona (carreteras autorizadas) y deja fuera los activos dados
/// de baja; la app solo traduce la ficha del servidor a lo que muestra.
class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository(this._api);

  final ApiClient _api;

  /// Tamano de pagina maximo del servidor y tope de paginas: la lista movil no
  /// tiene paginacion propia (se busca y filtra en el telefono).
  static const _pageSize = 200;
  static const _maxPages = 10;

  /// Una foto de ficha mas grande que esto no se baja (lista movil).
  static const _maxPhotoBytes = 6 * 1024 * 1024;

  @override
  Future<List<InventoryAsset>> list() => _guard(() async {
    final result = <InventoryAsset>[];
    var page = 1;
    var total = 0;
    do {
      final json = await _api.getJson(
        '/api/assets',
        query: {'page': page, 'pageSize': _pageSize},
      );
      final map = _asMap(json);
      total = (map['total'] as num?)?.toInt() ?? 0;
      final items = map['items'];
      if (items is! List) throw const FormatException('sin items');
      if (items.isEmpty) break;
      for (final item in items) {
        result.add(fromListItem(_asMap(item)));
      }
      page++;
    } while (result.length < total && page <= _maxPages);
    return result;
  }, listing: true);

  @override
  Future<InventoryAsset> get(String id) => _guard(() async {
    final json = await _api.getJson('/api/assets/${Uri.encodeComponent(id)}');
    return fromDetail(_asMap(_asMap(json)['asset']));
  });

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async {
    final photo = asset.mainPhotoId;
    if (photo == null) return null;
    // Una foto que no baja no impide ver la ficha.
    return _api.downloadFile(
      '/api/assets/${Uri.encodeComponent(asset.id)}'
      '/attachments/${Uri.encodeComponent(photo)}/content',
      maxBytes: _maxPhotoBytes,
    );
  }

  /// Un renglon de la lista (`AssetListItemDto`): sin descripcion ni geometria.
  static InventoryAsset fromListItem(Map<String, dynamic> m) {
    final code = (m['code'] as String?)?.trim() ?? '';
    return InventoryAsset(
      id: m['id'] as String,
      code: code.isEmpty ? null : code,
      name: code,
      category: (m['assetTypeLabel'] as String?)?.trim() ?? '',
      condition: _condition(m['conservationState'] as String?),
      kmLabel: _kmLabel(_num(m['kmStart']), _num(m['kmEnd'])),
      segmentCode: _text(m['roadSegmentCode']),
      direction: _text(m['direction']),
    );
  }

  /// La ficha completa (`AssetDto`).
  static InventoryAsset fromDetail(Map<String, dynamic> m) {
    final code = (m['code'] as String?)?.trim() ?? '';
    final description = _text(m['description']);
    final anchor = geoJsonAnchor(m['geometry']);
    return InventoryAsset(
      id: m['id'] as String,
      code: code.isEmpty ? null : code,
      name: description ?? code,
      category: (m['assetTypeLabel'] as String?)?.trim() ?? '',
      condition: _condition(m['conservationState'] as String?),
      kmLabel: _kmLabel(_num(m['kmStart']), _num(m['kmEnd'])),
      segmentCode: _text(m['roadSegmentCode']),
      direction: _text(m['direction']),
      latitude: anchor?.$1,
      longitude: anchor?.$2,
      installedAt: _day(m['installedOn']),
      notes: _text(m['notes']),
      mainPhotoId: _text(m['mainPhotoId']),
    );
  }

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
  Future<T> _guard<T>(
    Future<T> Function() body, {
    bool listing = false,
  }) async {
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
