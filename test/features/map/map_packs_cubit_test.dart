import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pack.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_pack_manager.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_packs_cubit.dart';

import '../../support/map_pack_fakes.dart';

void main() {
  late MapPack pack;
  late FakeMapPackManager manager;
  late MapPacksCubit cubit;

  PackItem item([String id = 'br381']) =>
      cubit.state.items.firstWhere((i) => i.id == id);

  setUp(() {
    pack = packFor(packBytes(1000));
    manager = FakeMapPackManager(available: [pack]);
    cubit = MapPacksCubit(manager);
  });

  tearDown(() => cubit.close());

  group('carga', () {
    test('lista lo que publica el servidor, sin instalar', () async {
      await cubit.load();
      expect(cubit.state.status, PacksStatus.ready);
      expect(item().remote, pack);
      expect(item().isInstalled, isFalse);
      expect(item().canDownload, isTrue);
      expect(item().phase, PackPhase.idle);
    });

    test('un paquete ya instalado y al dia no ofrece descargar', () async {
      manager.installedPacks = [installedFor(pack)];
      await cubit.load();
      expect(item().isInstalled, isTrue);
      expect(item().updateAvailable, isFalse);
      expect(item().canDownload, isFalse);
    });

    test('una version nueva en el servidor ofrece actualizar', () async {
      manager.installedPacks = [installedFor(pack)];
      manager.availablePacks = [packFor(packBytes(1200), version: 2)];
      await cubit.load();
      expect(item().updateAvailable, isTrue);
      expect(item().canDownload, isTrue);
    });

    test('lo bajado a medias aparece pausado', () async {
      manager.partial['br381'] = 400;
      await cubit.load();
      expect(item().phase, PackPhase.paused);
      expect(item().partialBytes, 400);
    });

    test('sin servidor pero con paquetes guardados, los muestra', () async {
      manager.availableFailure = const MapPackException(MapPackError.network);
      manager.installedPacks = [installedFor(pack)];
      await cubit.load();
      expect(cubit.state.status, PacksStatus.ready);
      expect(cubit.state.listError, MapPackError.network);
      expect(item().remote, isNull);
      expect(item().isInstalled, isTrue);
      expect(item().canDownload, isFalse);
      expect(item().name, 'BR-381');
    });

    test('sin servidor y sin nada guardado, es un error', () async {
      manager.availableFailure = const MapPackException(
        MapPackError.notAvailable,
      );
      await cubit.load();
      expect(cubit.state.status, PacksStatus.failure);
      expect(cubit.state.error, MapPackError.notAvailable);
    });

    test('un fallo al leer lo instalado no rompe la pantalla', () async {
      manager.installedFailure = StateError('disco');
      await cubit.load();
      expect(cubit.state.status, PacksStatus.ready);
      expect(item().isInstalled, isFalse);
    });

    test('lo instalado que el servidor ya no publica se conserva', () async {
      final old = packFor(packBytes(500), id: 'viejo', name: 'Viejo');
      manager.installedPacks = [installedFor(old)];
      await cubit.load();
      expect(cubit.state.items.map((i) => i.id), ['br381', 'viejo']);
      expect(item('viejo').remote, isNull);
    });

    test('el servidor sin paquetes deja la lista vacia', () async {
      manager.availablePacks = [];
      await cubit.load();
      expect(cubit.state.status, PacksStatus.ready);
      expect(cubit.state.items, isEmpty);
    });
  });

  group('descarga', () {
    test('mientras baja muestra el avance', () async {
      await cubit.load();
      cubit.download('br381');
      expect(item().phase, PackPhase.downloading);
      manager.controllers['br381']!.add(
        PackProgress(receivedBytes: 250, totalBytes: pack.sizeBytes),
      );
      await Future<void>.delayed(Duration.zero);
      expect(item().progress?.fraction, 0.25);
      expect(item().phase, PackPhase.downloading);
    });

    test('al verificar lo indica y al terminar queda instalado', () async {
      await cubit.load();
      cubit.download('br381');
      await manager.finish(pack);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(item().isInstalled, isTrue);
      expect(item().phase, PackPhase.idle);
      expect(item().progress, isNull);
      expect(item().canDownload, isFalse);
    });

    test('verificando se ve como tal', () async {
      await cubit.load();
      cubit.download('br381');
      manager.controllers['br381']!.add(
        PackProgress(
          receivedBytes: pack.sizeBytes,
          totalBytes: pack.sizeBytes,
          verifying: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(item().phase, PackPhase.verifying);
      expect(item().isBusy, isTrue);
    });

    test('pausar conserva lo bajado y se puede reanudar', () async {
      await cubit.load();
      cubit.download('br381');
      manager.partial['br381'] = 300;
      await cubit.pause('br381');
      expect(item().phase, PackPhase.paused);
      expect(item().partialBytes, 300);
      expect(item().canDownload, isTrue);
      cubit.download('br381');
      expect(manager.downloads, ['br381', 'br381']);
      expect(item().phase, PackPhase.downloading);
    });

    test(
      'un corte de red con lo ya bajado queda pausado, con el aviso',
      () async {
        await cubit.load();
        cubit.download('br381');
        manager.partial['br381'] = 400;
        manager.controllers['br381']!.addError(
          const MapPackException(MapPackError.network),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(item().phase, PackPhase.paused);
        expect(item().error, MapPackError.network);
        expect(item().partialBytes, 400);
      },
    );

    test('un corte sin nada bajado es un fallo', () async {
      await cubit.load();
      cubit.download('br381');
      manager.controllers['br381']!.addError(
        const MapPackException(MapPackError.network),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(item().phase, PackPhase.failed);
    });

    for (final error in [
      MapPackError.corrupt,
      MapPackError.noSpace,
      MapPackError.notFound,
      MapPackError.permissionDenied,
    ]) {
      test('el error ${error.name} deja la descarga como fallida', () async {
        await cubit.load();
        cubit.download('br381');
        manager.controllers['br381']!.addError(MapPackException(error));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(item().phase, PackPhase.failed);
        expect(item().error, error);
        // Se puede volver a intentar.
        expect(item().canDownload, isTrue);
      });
    }

    test('un error desconocido se informa como del servidor', () async {
      await cubit.load();
      cubit.download('br381');
      manager.controllers['br381']!.addError(StateError('raro'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(item().error, MapPackError.server);
    });

    test('no se bajan dos veces a la vez', () async {
      await cubit.load();
      cubit.download('br381');
      cubit.download('br381');
      expect(manager.downloads, ['br381']);
    });

    test('un paquete que el servidor no publica no se puede bajar', () async {
      manager.availableFailure = const MapPackException(MapPackError.network);
      manager.installedPacks = [installedFor(pack)];
      await cubit.load();
      cubit.download('br381');
      expect(manager.downloads, isEmpty);
    });

    test('descartar lo bajado libera y vuelve a empezar de cero', () async {
      manager.partial['br381'] = 400;
      await cubit.load();
      await cubit.discardPartial('br381');
      expect(manager.discarded, ['br381']);
      expect(item().phase, PackPhase.idle);
      expect(item().partialBytes, 0);
    });
  });

  group('borrar', () {
    test('borra lo instalado y deja el paquete para descargar', () async {
      manager.installedPacks = [installedFor(pack)];
      await cubit.load();
      await cubit.remove('br381');
      expect(manager.removed, ['br381']);
      expect(item().isInstalled, isFalse);
      expect(item().canDownload, isTrue);
    });

    test('lo que el servidor ya no publica desaparece de la lista', () async {
      final old = packFor(packBytes(500), id: 'viejo');
      manager.installedPacks = [installedFor(old)];
      await cubit.load();
      await cubit.remove('viejo');
      expect(cubit.state.items.where((i) => i.id == 'viejo'), isEmpty);
    });

    test('borrar mientras baja primero pausa', () async {
      manager.installedPacks = [installedFor(pack)];
      manager.availablePacks = [packFor(packBytes(1200), version: 2)];
      await cubit.load();
      cubit.download('br381');
      await cubit.remove('br381');
      expect(item().isInstalled, isFalse);
      expect(manager.controllers.containsKey('br381'), isFalse);
    });
  });

  test('cerrar la pantalla pausa las descargas en curso', () async {
    await cubit.load();
    cubit.download('br381');
    await cubit.close();
    expect(manager.controllers.containsKey('br381'), isFalse);
  });
}
