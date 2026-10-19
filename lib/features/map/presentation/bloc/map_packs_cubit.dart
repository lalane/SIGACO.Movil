import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/map_pack.dart';
import '../../domain/repositories/map_pack_manager.dart';

enum PacksStatus { loading, ready, failure }

/// En que va un paquete en esta pantalla.
enum PackPhase {
  /// Sin descarga en curso.
  idle,

  /// Bajando.
  downloading,

  /// Ya llego todo y se comprueba la huella.
  verifying,

  /// Se corto o se pauso: lo bajado se conserva y se puede reanudar.
  paused,

  /// No se pudo; [PackItem.error] dice por que.
  failed,
}

/// Un renglon de la lista: el paquete del servidor, el instalado (o ambos).
class PackItem extends Equatable {
  const PackItem({
    required this.id,
    this.remote,
    this.installed,
    this.phase = PackPhase.idle,
    this.progress,
    this.error,
    this.partialBytes = 0,
  });

  final String id;

  /// Lo que publica el servidor; `null` si la lista no se pudo traer (sin
  /// conexion) y solo se conoce lo instalado.
  final MapPack? remote;
  final InstalledPack? installed;
  final PackPhase phase;
  final PackProgress? progress;
  final MapPackError? error;

  /// Bytes ya bajados de una descarga a medias.
  final int partialBytes;

  String get name => remote?.name ?? installed?.name ?? id;
  int get sizeBytes => remote?.sizeBytes ?? installed?.sizeBytes ?? 0;

  bool get isInstalled => installed != null;
  bool get updateAvailable =>
      remote != null && installed != null && installed!.isOlderThan(remote!);

  /// Se puede empezar o reanudar la descarga (hay paquete del servidor y no
  /// esta instalado al dia ni bajandose).
  bool get canDownload =>
      remote != null &&
      (phase == PackPhase.idle ||
          phase == PackPhase.paused ||
          phase == PackPhase.failed) &&
      (!isInstalled || updateAvailable);

  bool get isBusy =>
      phase == PackPhase.downloading || phase == PackPhase.verifying;

  PackItem copyWith({
    MapPack? remote,
    InstalledPack? installed,
    bool clearInstalled = false,
    PackPhase? phase,
    PackProgress? progress,
    bool clearProgress = false,
    MapPackError? error,
    bool clearError = false,
    int? partialBytes,
  }) => PackItem(
    id: id,
    remote: remote ?? this.remote,
    installed: clearInstalled ? null : (installed ?? this.installed),
    phase: phase ?? this.phase,
    progress: clearProgress ? null : (progress ?? this.progress),
    error: clearError ? null : (error ?? this.error),
    partialBytes: partialBytes ?? this.partialBytes,
  );

  @override
  List<Object?> get props => [
    id,
    remote,
    installed,
    phase,
    progress,
    error,
    partialBytes,
  ];
}

class MapPacksState extends Equatable {
  const MapPacksState({
    this.status = PacksStatus.loading,
    this.items = const [],
    this.error,
    this.listError,
  });

  final PacksStatus status;
  final List<PackItem> items;

  /// Por que no se pudo abrir la pantalla (sin paquetes ni instalados).
  final MapPackError? error;

  /// La lista del servidor no se pudo traer, pero hay paquetes instalados que
  /// se siguen mostrando.
  final MapPackError? listError;

  bool get hasInstalled => items.any((i) => i.isInstalled);

  MapPacksState copyWith({
    PacksStatus? status,
    List<PackItem>? items,
    MapPackError? error,
    bool clearError = false,
    MapPackError? listError,
    bool clearListError = false,
  }) => MapPacksState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: clearError ? null : (error ?? this.error),
    listError: clearListError ? null : (listError ?? this.listError),
  );

  @override
  List<Object?> get props => [status, items, error, listError];
}

/// La pantalla de mapas sin conexion: que paquetes hay, bajarlos, pausarlos,
/// actualizarlos y borrarlos.
class MapPacksCubit extends Cubit<MapPacksState> {
  MapPacksCubit(this.manager) : super(const MapPacksState());

  final MapPackManager manager;
  final Map<String, StreamSubscription<PackProgress>> _downloads = {};

  Future<void> load() async {
    emit(
      state.copyWith(
        status: PacksStatus.loading,
        clearError: true,
        clearListError: true,
      ),
    );
    final installed = await _installedSafe();
    List<MapPack>? remote;
    MapPackError? listError;
    try {
      remote = await manager.available();
    } on MapPackException catch (e) {
      listError = e.error;
    }
    if (isClosed) return;
    if (remote == null && installed.isEmpty) {
      emit(state.copyWith(status: PacksStatus.failure, error: listError));
      return;
    }
    final items = <PackItem>[];
    final seen = <String>{};
    for (final r in remote ?? const <MapPack>[]) {
      seen.add(r.id);
      items.add(
        await _itemFor(r.id, remote: r, installed: _find(installed, r.id)),
      );
    }
    for (final i in installed) {
      if (seen.contains(i.id)) continue;
      items.add(await _itemFor(i.id, installed: i));
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PacksStatus.ready,
        items: items,
        clearError: true,
        listError: listError,
        clearListError: listError == null,
      ),
    );
  }

  Future<PackItem> _itemFor(
    String id, {
    MapPack? remote,
    InstalledPack? installed,
  }) async {
    final partial = await _partialSafe(id);
    return PackItem(
      id: id,
      remote: remote,
      installed: installed,
      phase:
          partial > 0 &&
              (installed == null ||
                  (remote != null && installed.isOlderThan(remote)))
          ? PackPhase.paused
          : PackPhase.idle,
      partialBytes: partial,
    );
  }

  static InstalledPack? _find(List<InstalledPack> list, String id) {
    for (final i in list) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<List<InstalledPack>> _installedSafe() async {
    try {
      return await manager.installed();
    } catch (_) {
      return const [];
    }
  }

  Future<int> _partialSafe(String id) async {
    try {
      return await manager.partialBytes(id);
    } catch (_) {
      return 0;
    }
  }

  void _update(String id, PackItem Function(PackItem) change) {
    if (isClosed) return;
    emit(
      state.copyWith(
        items: [
          for (final i in state.items)
            if (i.id == id) change(i) else i,
        ],
      ),
    );
  }

  PackItem? _item(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Empieza o reanuda la descarga de un paquete.
  void download(String id) {
    final item = _item(id);
    final pack = item?.remote;
    if (item == null || pack == null || item.isBusy) return;
    _update(
      id,
      (i) => i.copyWith(
        phase: PackPhase.downloading,
        clearError: true,
        progress: PackProgress(
          receivedBytes: i.partialBytes,
          totalBytes: pack.sizeBytes,
        ),
      ),
    );
    final sub = manager
        .download(pack)
        .listen(
          (progress) => _update(
            id,
            (i) => i.copyWith(
              phase: progress.verifying
                  ? PackPhase.verifying
                  : PackPhase.downloading,
              progress: progress,
              partialBytes: progress.receivedBytes,
            ),
          ),
          onError: (Object e) async {
            _downloads.remove(id);
            final error = e is MapPackException ? e.error : MapPackError.server;
            final partial = await _partialSafe(id);
            _update(
              id,
              (i) => i.copyWith(
                // Sin red se puede reanudar; lo demas es un fallo.
                phase: error == MapPackError.network && partial > 0
                    ? PackPhase.paused
                    : PackPhase.failed,
                error: error,
                partialBytes: partial,
                clearProgress: true,
              ),
            );
          },
          onDone: () async {
            _downloads.remove(id);
            await _afterInstall(id);
          },
          cancelOnError: true,
        );
    _downloads[id] = sub;
  }

  Future<void> _afterInstall(String id) async {
    final installed = _find(await _installedSafe(), id);
    _update(
      id,
      (i) => installed == null
          ? i
          : i.copyWith(
              installed: installed,
              phase: PackPhase.idle,
              clearProgress: true,
              clearError: true,
              partialBytes: 0,
            ),
    );
  }

  /// Pausa la descarga: lo bajado se conserva para reanudar.
  Future<void> pause(String id) async {
    final sub = _downloads.remove(id);
    if (sub == null) return;
    await sub.cancel();
    final partial = await _partialSafe(id);
    _update(
      id,
      (i) => i.copyWith(
        phase: PackPhase.paused,
        partialBytes: partial,
        clearProgress: true,
      ),
    );
  }

  /// Tira lo bajado a medias (libera espacio) y deja el paquete como estaba.
  Future<void> discardPartial(String id) async {
    await pause(id);
    await manager.discardPartial(id);
    _update(
      id,
      (i) =>
          i.copyWith(phase: PackPhase.idle, partialBytes: 0, clearError: true),
    );
  }

  /// Borra el paquete instalado.
  Future<void> remove(String id) async {
    await pause(id);
    await manager.remove(id);
    final item = _item(id);
    if (item == null) return;
    if (item.remote == null) {
      // Sin paquete en el servidor, ya no queda nada que mostrar.
      if (isClosed) return;
      emit(
        state.copyWith(
          items: [
            for (final i in state.items)
              if (i.id != id) i,
          ],
        ),
      );
      return;
    }
    _update(
      id,
      (i) => i.copyWith(
        clearInstalled: true,
        phase: PackPhase.idle,
        partialBytes: 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final sub in _downloads.values) {
      await sub.cancel();
    }
    _downloads.clear();
    return super.close();
  }
}
