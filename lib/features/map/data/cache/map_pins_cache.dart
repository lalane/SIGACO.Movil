import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/offline/operation.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/road_segment.dart';

/// Los pines y los tramos que ya se consultaron con conexion y quedan en el
/// telefono para ver el mapa sin ella. Son de una persona y una concesion: al
/// cambiar el alcance o cerrar sesion se descartan (RN-CTX-02).
abstract interface class MapPinsCache implements ScopeBound {
  Future<void> save(MapLayer layer, List<MapPin> pins);

  /// Lo ultimo guardado de la pestana, marcado con cuando se guardo.
  Future<PinListing?> read(MapLayer layer);

  Future<void> saveSegments(List<RoadSegment> segments);

  /// Los ultimos tramos guardados, marcados con cuando se guardaron.
  Future<SegmentListing?> readSegments();
}

/// Sin cache: todo se pide al servidor (pruebas y datos de ejemplo).
class NoMapPinsCache implements MapPinsCache {
  const NoMapPinsCache();

  @override
  Future<void> bind(OfflineScope? scope) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> save(MapLayer layer, List<MapPin> pins) async {}
  @override
  Future<PinListing?> read(MapLayer layer) async => null;
  @override
  Future<void> saveSegments(List<RoadSegment> segments) async {}
  @override
  Future<SegmentListing?> readSegments() async => null;
}

/// Cache en archivos dentro de la carpeta de la app, un archivo por pestana. Sin
/// alcance fijado (nadie ha iniciado sesion) no guarda ni entrega nada.
class FileMapPinsCache implements MapPinsCache {
  FileMapPinsCache({
    Future<Directory> Function()? root,
    DateTime Function()? clock,
  }) : _root = root ?? _defaultRoot,
       _now = clock ?? DateTime.now;

  final Future<Directory> Function() _root;
  final DateTime Function() _now;

  static Future<Directory> _defaultRoot() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, 'map_pins_cache'),
  );

  String? _scopeKey;

  static String _keyOf(OfflineScope scope) =>
      '${scope.userId}|${scope.concessionId}';

  Future<File> _scopeFile() async {
    final root = await _root();
    await root.create(recursive: true);
    return File(p.join(root.path, 'scope.txt'));
  }

  @override
  Future<void> bind(OfflineScope? scope) async {
    if (scope == null) {
      _scopeKey = null;
      await clear();
      return;
    }
    final key = _keyOf(scope);
    final file = await _scopeFile();
    final stored = await file.exists() ? await file.readAsString() : null;
    // Lo guardado era de otra persona u otra concesion (o no se sabe de quien):
    // se descarta antes de poder verse.
    if (stored != key) {
      await _wipeData();
      await file.writeAsString(key, flush: true);
    }
    _scopeKey = key;
  }

  @override
  Future<void> clear() async {
    _scopeKey = null;
    await _wipeData();
    try {
      final file = await _scopeFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _wipeData() async {
    try {
      final dir = Directory(p.join((await _root()).path, 'data'));
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<File?> _file(String name) async {
    if (_scopeKey == null) return null;
    final dir = Directory(p.join((await _root()).path, 'data'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, name));
  }

  /// Escribe a un temporal y renombra: una escritura a medias no deja un archivo
  /// roto.
  Future<void> _write(String name, String key, List<Object?> items) async {
    final file = await _file(name);
    if (file == null) return;
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'at': _now().toUtc().toIso8601String(), key: items}),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  /// Los elementos guardados y cuando se guardaron; null si no hay o no se
  /// puede leer.
  Future<(List<Map<String, dynamic>>, DateTime)?> _read(
    String name,
    String key,
  ) async {
    final file = await _file(name);
    if (file == null || !await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      return (
        [for (final e in json[key] as List) e as Map<String, dynamic>],
        DateTime.parse(json['at'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(MapLayer layer, List<MapPin> pins) => _write(
    '${layer.name}.json',
    'pins',
    [for (final pin in pins) _toJson(pin)],
  );

  @override
  Future<PinListing?> read(MapLayer layer) async {
    final saved = await _read('${layer.name}.json', 'pins');
    if (saved == null) return null;
    try {
      return PinListing([
        for (final e in saved.$1) _fromJson(e, layer),
      ], cachedAt: saved.$2);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSegments(List<RoadSegment> segments) => _write(
    'segments.json',
    'segments',
    [for (final s in segments) _segmentToJson(s)],
  );

  @override
  Future<SegmentListing?> readSegments() async {
    final saved = await _read('segments.json', 'segments');
    if (saved == null) return null;
    try {
      return SegmentListing([
        for (final e in saved.$1) _segmentFromJson(e),
      ], cachedAt: saved.$2);
    } catch (_) {
      return null;
    }
  }

  /// Los puntos van planos (`[lat, lon, lat, lon...]`): una carretera son miles.
  static Map<String, Object?> _segmentToJson(RoadSegment s) => {
    'id': s.id,
    'code': s.code,
    'direction': s.direction.name,
    'name': s.name,
    'startKm': s.startKmLabel,
    'endKm': s.endKmLabel,
    'points': [
      for (final p in s.points) ...[p.latitude, p.longitude],
    ],
  };

  static RoadSegment _segmentFromJson(Map<String, dynamic> j) {
    final flat = [for (final n in j['points'] as List) (n as num).toDouble()];
    return RoadSegment(
      id: j['id'] as String,
      code: j['code'] as String,
      direction: TravelDirection.values.byName(j['direction'] as String),
      name: j['name'] as String?,
      startKmLabel: j['startKm'] as String?,
      endKmLabel: j['endKm'] as String?,
      points: [
        for (var i = 0; i + 1 < flat.length; i += 2)
          GeoPoint(flat[i], flat[i + 1]),
      ],
    );
  }

  static Map<String, Object?> _toJson(MapPin pin) => {
    'id': pin.id,
    'title': pin.title,
    'subtitle': pin.subtitle,
    'category': pin.category,
    'group': ?pin.group,
    'kmLabel': pin.kmLabel,
    'segmentCode': pin.segmentCode,
    'direction': pin.direction?.name,
    'status': pin.status.name,
    'operatingState': pin.operatingState?.name,
    'lat': pin.position.latitude,
    'lon': pin.position.longitude,
  };

  static MapPin _fromJson(Map<String, dynamic> j, MapLayer layer) => MapPin(
    id: j['id'] as String,
    layer: layer,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    category: j['category'] as String?,
    group: j['group'] as String?,
    kmLabel: j['kmLabel'] as String?,
    segmentCode: j['segmentCode'] as String?,
    direction: switch (j['direction']) {
      final String name => TravelDirection.values.byName(name),
      _ => null,
    },
    status: PinStatus.values.byName(j['status'] as String),
    operatingState: switch (j['operatingState']) {
      final String name => OperatingState.values.byName(name),
      _ => null,
    },
    position: GeoPoint(
      (j['lat'] as num).toDouble(),
      (j['lon'] as num).toDouble(),
    ),
  );
}
