import 'dart:io';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/asset_capture.dart';
import '../../domain/entities/asset_template.dart';
import '../../domain/repositories/asset_capture_repository.dart';
import 'inventory_json.dart';

/// El alta de activos en campo contra el backend (`/api/assets`, contrato de
/// Activos del 08/11/2026). El servidor decide el estado con que nace (desde la
/// app, PENDIENTE_VALIDACION), genera el codigo, calcula el tramo con el km y
/// valida los campos contra la ficha vigente; la app arma el formulario con esa
/// misma ficha y manda lo capturado.
class ApiAssetCaptureRepository implements AssetCaptureRepository {
  ApiAssetCaptureRepository(this._api, {required this.roadId});

  final ApiClient _api;

  /// La carretera de la concesion activa, si es una sola; con ella se da de
  /// alta lo que el GPS no pudo ubicar.
  final Future<String?> Function() roadId;

  /// Distancia maxima del punto al eje para tomar su km (la misma del ticket).
  static const locateToleranceMeters = 100;

  /// La carretera ya conocida (de una ubicacion o de la sesion).
  String? _road;

  @override
  Future<List<AssetTypeOption>> types() => _guard(() async {
    List<AssetTypeOption>? types;
    try {
      final json = await _api.getJson(
        '/api/catalogs/asset-types',
        query: {'channel': mobileBirthChannel},
      );
      // Sin el grupo nuevo, la ruta cae en un catalogo generico (404) o
      // responde otra forma: se usa el catalogo completo.
      if (json is List) types = _types(json);
    } on ApiFailure catch (e) {
      if (e.status == 403) rethrow;
    }
    types ??= _types(await _fromCatalogs('assetTypes'));
    return types;
  });

  /// Los activos y que pueden nacer en la app, por orden y nombre.
  static List<AssetTypeOption> _types(Object? json) {
    final result = [
      for (final t in InventoryJson.list(json))
        if (InventoryJson.assetType(t) case final type?)
          if (type.allows(mobileBirthChannel)) type,
    ];
    result.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.labelEs.compareTo(b.labelEs);
    });
    return result;
  }

  /// Una lista de los catalogos operativos (`/api/catalogs`); sin red y sin lo
  /// guardado, de la configuracion de la app (que tambien queda guardada).
  Future<Object?> _fromCatalogs(String key) async {
    try {
      final json = await _api.getJson('/api/catalogs');
      final value = InventoryJson.map(json)?[key];
      if (value != null) return value;
    } on ApiFailure catch (e) {
      if (!e.isNetwork) rethrow;
    }
    final config = InventoryJson.map(
      await _api.getJson('/api/app-configuration'),
    );
    return InventoryJson.map(config?['operationalCatalogs'])?[key];
  }

  @override
  Future<AssetTemplate> template(String typeCode) => _guard(() async {
    final found = await currentTemplate(_api, typeCode);
    if (found == null) {
      throw const AssetCaptureException(AssetCaptureError.noTemplate);
    }
    return found;
  });

  /// La ficha vigente de un tipo: `/api/asset-templates/{tipo}` (una ficha o
  /// sus versiones), si no `/api/asset-templates` (las vigentes) y, sin red, la
  /// de la configuracion de la app. Null si el tipo no tiene.
  static Future<AssetTemplate?> currentTemplate(
    ApiClient api,
    String typeCode,
  ) async {
    final type = typeCode.trim().toUpperCase();
    Future<AssetTemplate?> attempt(String path) async {
      try {
        return InventoryJson.currentTemplate(await api.getJson(path), type);
      } on ApiFailure catch (e) {
        if (e.status == 403) rethrow;
        return null;
      }
    }

    final found =
        await attempt('/api/asset-templates/${Uri.encodeComponent(type)}') ??
        await attempt('/api/asset-templates');
    if (found != null) return found;
    try {
      final config = InventoryJson.map(
        await api.getJson('/api/app-configuration'),
      );
      return InventoryJson.currentTemplate(config?['assetTemplates'], type);
    } on ApiFailure {
      return null;
    }
  }

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async {
    try {
      return InventoryJson.catalogs(await _fromCatalogs('catalogs'));
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) async {
    try {
      final m = InventoryJson.map(
        await _api.getJson(
          '/api/road-network/locate',
          query: {
            'lon': longitude,
            'lat': latitude,
            'tolerance': locateToleranceMeters,
          },
        ),
      );
      final km = InventoryJson.number(m?['km']);
      if (m == null || km == null) return const RoadPlacement.unknown();
      final road = InventoryJson.text(m['roadId']);
      if (road != null) _road = road;
      return RoadPlacement(
        status: RoadPlacementStatus.onRoad,
        roadId: road,
        roadCode: InventoryJson.text(m['roadCode']),
        direction: InventoryJson.text(m['direction'])?.toUpperCase(),
        km: km,
        segmentId: InventoryJson.text(m['roadSegmentId']),
        segmentCode: InventoryJson.text(m['roadSegmentCode']),
        distanceMeters: InventoryJson.number(m['distanceMeters']),
        directionAmbiguous: m['directionAmbiguous'] == true,
      );
    } on ApiFailure catch (e) {
      return e.code == 'LOCATION_OUT_OF_AXIS'
          ? const RoadPlacement.offRoad()
          : const RoadPlacement.unknown();
    } catch (_) {
      return const RoadPlacement.unknown();
    }
  }

  /// Aprende la carretera mientras hay red, por si el alta sale sin ella.
  Future<void> warmRoad() async {
    try {
      _road = await resolveRoad() ?? _road;
    } catch (_) {}
  }

  /// La carretera del alta cuando la ubicacion no la dio: la ya conocida, la de
  /// la sesion o, si todos los tramos de la configuracion son de una sola
  /// carretera, esa.
  Future<String?> resolveRoad() async {
    final known = _road;
    if (known != null) return known;
    final fromSession = await roadId();
    if (fromSession != null) return _road = fromSession;
    try {
      final config = InventoryJson.map(
        await _api.getJson('/api/app-configuration'),
      );
      final roads = {
        for (final s in InventoryJson.list(config?['roadSegments']))
          ?InventoryJson.text(InventoryJson.map(s)?['roadId']),
      };
      if (roads.length == 1) return _road = roads.single;
    } catch (_) {}
    return null;
  }

  /// Lo que recibe el servidor (`AssetInput`).
  Future<Map<String, Object?>> body(NewAsset draft) async {
    final road = draft.roadId ?? await resolveRoad();
    final position = draft.position;
    double? km(double? v) => v == null ? null : (v * 1000).round() / 1000;
    final attributes = {
      for (final e in draft.attributes.entries)
        if (e.value != null) e.key: e.value,
    };
    return {
      'assetTypeCode': draft.typeCode,
      'roadId': road,
      'kmStart': ?km(draft.kmStart),
      'kmEnd': ?km(draft.kmEnd),
      'direction': ?draft.direction,
      if (draft.sendPoint && position != null)
        'geometry': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
      'attributes': attributes,
      'description': ?_clean(draft.description),
      'notes': ?_clean(draft.notes),
      'clientUuid': draft.clientId,
    };
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  @override
  Future<CapturedAsset> create(NewAsset draft) => _guard(() async {
    final payload = await body(draft);
    final detail = InventoryJson.map(
      await _api.post('/api/assets', data: payload),
    );
    final asset = InventoryJson.map(detail?['asset']) ?? detail;
    final id = InventoryJson.text(asset?['id']);
    if (id == null) throw const FormatException('sin id');
    final code = InventoryJson.text(asset?['code']);
    try {
      await attachPhotos(
        id,
        draft.clientId,
        draft.photoPaths,
        capturedAt: draft.capturedAt,
        position: draft.position,
        hasMainPhoto: InventoryJson.text(asset?['mainPhotoId']) != null,
      );
    } on ApiFailure catch (e) {
      // Sin red se encola entero (el servidor reconoce el alta por su clave);
      // con otro fallo el activo ya existe y solo faltan las fotos.
      if (e.isNetwork) rethrow;
      return CapturedAsset(id: id, code: code, warning: _reason(e));
    }
    return CapturedAsset(id: id, code: code);
  });

  /// Sube las fotos de un activo ya creado, cada una con su clave de captura
  /// (reenviarla no la duplica). La primera queda como foto principal si el
  /// activo no tiene.
  Future<void> attachPhotos(
    String assetId,
    String clientId,
    List<String> photos, {
    DateTime? capturedAt,
    AssetPosition? position,
    bool hasMainPhoto = false,
  }) async {
    final key = Uri.encodeComponent(assetId);
    String? first;
    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (!File(photo).existsSync()) continue;
      final created = await _api.postMultipart(
        '/api/assets/$key/attachments',
        fileField: 'file',
        filePath: photo,
        fileName: photo.split(RegExp(r'[\\/]')).last,
        contentType: imageType(photo),
        fields: {
          'kind': 'FOTO',
          'capturedAt': capturedAt?.toUtc().toIso8601String(),
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'clientUuid': InventoryJson.photoKey(clientId, i),
        },
      );
      first ??= InventoryJson.text(created?['id']);
    }
    if (hasMainPhoto || first == null) return;
    try {
      await _api.post(
        '/api/assets/$key/attachments/${Uri.encodeComponent(first)}/main',
      );
    } on ApiFailure catch (e) {
      // Elegir la principal es un extra: la foto ya quedo.
      if (e.isNetwork) rethrow;
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

  /// El motivo que dio el servidor, con su codigo, para mostrarlo a la persona.
  static String _reason(ApiFailure e) {
    final field = e.fieldErrors.values.expand((m) => m).firstOrNull;
    final text = (field ?? e.message)?.trim();
    final tag = e.code ?? '${e.status}';
    return text == null || text.isEmpty ? tag : '$text ($tag)';
  }

  static AssetCaptureException failure(ApiFailure e) {
    if (e.isNetwork) {
      return const AssetCaptureException(AssetCaptureError.network);
    }
    final code = (e.code ?? '').toUpperCase();
    final error = switch (e.status) {
      _ when code == 'ASSET_CHANNEL_NOT_ALLOWED' =>
        AssetCaptureError.channelNotAllowed,
      _ when code == 'ASSET_TEMPLATE_MISSING' => AssetCaptureError.noTemplate,
      403 => AssetCaptureError.permissionDenied,
      400 || 422 => AssetCaptureError.validation,
      _ => AssetCaptureError.server,
    };
    return AssetCaptureException(
      error,
      message: _reason(e),
      fieldErrors: e.fieldErrors,
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AssetCaptureException {
      rethrow;
    } on ApiFailure catch (e) {
      throw failure(e);
    } catch (_) {
      throw const AssetCaptureException(AssetCaptureError.server);
    }
  }
}
