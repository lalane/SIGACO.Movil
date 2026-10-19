import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/features/map/data/packs/map_pack_remote.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_bounds.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pack.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_pack_manager.dart';

/// Los bytes de un paquete de prueba (contenido cualquiera, de [size] bytes).
Uint8List packBytes(int size, {int seed = 7}) =>
    Uint8List.fromList([for (var i = 0; i < size; i++) (i * 31 + seed) % 251]);

String sha256Of(List<int> bytes) => crypto.sha256.convert(bytes).toString();

/// Un paquete del servidor que describe [bytes].
MapPack packFor(
  List<int> bytes, {
  String id = 'br381',
  String name = 'BR-381',
  int version = 1,
  int minZoom = 8,
  int maxZoom = 16,
  String? attribution = '© OpenStreetMap contributors',
}) => MapPack(
  id: id,
  name: name,
  version: version,
  sizeBytes: bytes.length,
  sha256: sha256Of(bytes),
  minZoom: minZoom,
  maxZoom: maxZoom,
  bounds: const GeoBounds(south: -19.2, west: -42.3, north: -18.7, east: -41.8),
  attribution: attribution,
);

InstalledPack installedFor(MapPack pack, {DateTime? at}) => InstalledPack(
  id: pack.id,
  name: pack.name,
  version: pack.version,
  sizeBytes: pack.sizeBytes,
  sha256: pack.sha256,
  minZoom: pack.minZoom,
  maxZoom: pack.maxZoom,
  bounds: pack.bounds,
  installedAt: at ?? DateTime.utc(2026, 10, 14, 12),
  attribution: pack.attribution,
);

/// Un lector de teselas en memoria que cuenta si se cerro.
class FakeTileReader implements TileReader {
  FakeTileReader([Map<(int, int, int), Uint8List>? tiles])
    : tiles = tiles ?? {};

  final Map<(int, int, int), Uint8List> tiles;
  bool closed = false;
  Object? failWith;

  @override
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (failWith != null) throw failWith!;
    return tiles[(z, x, y)];
  }

  @override
  Future<void> close() async => closed = true;
}

/// Servidor de paquetes falso: sirve [files] por id, respeta (o no) el Range y
/// puede cortar la descarga despues de cierta cantidad de bytes.
class FakeMapPackRemote implements MapPackRemote {
  FakeMapPackRemote({List<MapPack>? packs, Map<String, Uint8List>? files})
    : packs = packs ?? [],
      files = files ?? {};

  List<MapPack> packs;
  final Map<String, Uint8List> files;

  /// Si es false, ignora `Range` y manda todo desde el byte 0.
  bool honorRange = true;

  /// Corta el flujo con un error de red despues de estos bytes (por llamada).
  int? cutAfter;

  /// Hace terminar el flujo antes de tiempo (sin error) despues de estos bytes.
  int? endEarlyAfter;

  /// Manda de mas.
  int extraBytes = 0;

  MapPackException? listFailure;
  MapPackException? contentFailure;
  final List<int> requestedFrom = [];
  int chunkSize = 100;

  @override
  Future<List<MapPack>> list() async {
    if (listFailure != null) throw listFailure!;
    return packs;
  }

  @override
  Future<PackContent> content(MapPack pack, {int from = 0}) async {
    requestedFrom.add(from);
    if (contentFailure != null) throw contentFailure!;
    final all = files[pack.id]!;
    final start = honorRange ? from : 0;
    var data = all.sublist(start);
    if (extraBytes > 0) {
      data = Uint8List.fromList([...data, ...List.filled(extraBytes, 1)]);
    }
    final cut = cutAfter;
    final early = endEarlyAfter;
    Stream<List<int>> body() async* {
      var sent = 0;
      while (sent < data.length) {
        if (cut != null && sent >= cut) {
          throw const SocketLikeException();
        }
        if (early != null && sent >= early) return;
        final end = (sent + chunkSize).clamp(0, data.length);
        yield data.sublist(sent, end);
        sent = end;
        // Cede el turno para que se pueda pausar entre pedazos.
        await Future<void>.delayed(Duration.zero);
      }
    }

    return PackContent(body: body(), resumed: honorRange && from > 0);
  }
}

class SocketLikeException implements Exception {
  const SocketLikeException();
}

/// Un administrador de paquetes controlable desde la prueba.
class FakeMapPackManager implements MapPackManager {
  FakeMapPackManager({List<MapPack>? available, List<InstalledPack>? installed})
    : availablePacks = available ?? [],
      installedPacks = installed ?? [];

  List<MapPack> availablePacks;
  List<InstalledPack> installedPacks;
  MapPackException? availableFailure;
  final Map<String, int> partial = {};
  final Map<String, StreamController<PackProgress>> controllers = {};
  final List<String> downloads = [];
  final List<String> removed = [];
  final List<String> discarded = [];
  TileReader? reader;
  int openActiveCalls = 0;
  Object? installedFailure;

  @override
  Future<List<MapPack>> available() async {
    if (availableFailure != null) throw availableFailure!;
    return availablePacks;
  }

  @override
  Future<List<InstalledPack>> installed() async {
    if (installedFailure != null) throw installedFailure!;
    return installedPacks;
  }

  @override
  Stream<PackProgress> download(MapPack pack) {
    downloads.add(pack.id);
    final c = StreamController<PackProgress>(
      onCancel: () {
        controllers.remove(pack.id);
      },
    );
    controllers[pack.id] = c;
    return c.stream;
  }

  /// Termina la descarga con exito: queda instalado.
  Future<void> finish(MapPack pack) async {
    final c = controllers[pack.id]!;
    c.add(
      PackProgress(
        receivedBytes: pack.sizeBytes,
        totalBytes: pack.sizeBytes,
        verifying: true,
      ),
    );
    installedPacks = [
      ...installedPacks.where((i) => i.id != pack.id),
      installedFor(pack),
    ];
    partial.remove(pack.id);
    await c.close();
  }

  @override
  Future<void> discardPartial(String packId) async {
    discarded.add(packId);
    partial.remove(packId);
  }

  @override
  Future<int> partialBytes(String packId) async => partial[packId] ?? 0;

  @override
  Future<void> remove(String packId) async {
    removed.add(packId);
    installedPacks = [
      for (final i in installedPacks)
        if (i.id != packId) i,
    ];
  }

  @override
  Future<TileReader?> openActive() async {
    openActiveCalls++;
    return installedPacks.isEmpty ? null : reader;
  }
}

/// Red del telefono controlable.
class FakeConnectivity implements ConnectivitySource {
  FakeConnectivity({this.connected = true});

  bool connected;
  final _controller = StreamController<bool>.broadcast();

  void set(bool value) {
    connected = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => _controller.stream;
}

String json(Object? value) => jsonEncode(value);
