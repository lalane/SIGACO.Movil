import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sigaco_movil/core/profile/profile_photo.dart';
import 'package:sigaco_movil/core/profile/profile_photo_cubit.dart';

class _Picker implements ProfilePhotoPicker {
  _Picker({this.camera, this.gallery, this.fail = false});

  final String? camera;
  final String? gallery;
  final bool fail;

  @override
  Future<String?> fromCamera() async {
    if (fail) throw StateError('sin camara');
    return camera;
  }

  @override
  Future<String?> fromGallery() async {
    if (fail) throw StateError('sin galeria');
    return gallery;
  }
}

/// La foto de perfil: se elige con la camara o la galeria, se guarda por persona
/// en el telefono y se ve en la cuenta y en el inicio (MOB-002).
void main() {
  late Directory dir;
  late LocalProfilePhotoStore store;
  var tick = 0;

  File image(String name, List<int> bytes) =>
      File('${dir.path}/$name')..writeAsBytesSync(bytes);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_');
    tick = 0;
    store = LocalProfilePhotoStore(
      root: () async => Directory('${dir.path}/store'),
      clock: () => DateTime.utc(2026, 10, 26).add(Duration(seconds: tick++)),
    );
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    });
  });

  group('almacen', () {
    test('sin foto no devuelve nada', () async {
      expect(await store.read('u1'), isNull);
    });

    test('guarda una copia y la devuelve', () async {
      final source = image('a.jpg', [1, 2, 3]);
      final saved = await store.save('u1', source.path);
      expect(saved, isNot(source.path));
      expect(File(saved).readAsBytesSync(), [1, 2, 3]);
      expect(await store.read('u1'), saved);
    });

    test('la nueva reemplaza a la anterior y no deja basura', () async {
      final first = await store.save('u1', image('a.jpg', [1]).path);
      final second = await store.save('u1', image('b.jpg', [2]).path);
      expect(second, isNot(first));
      expect(File(first).existsSync(), isFalse);
      expect(await store.read('u1'), second);
      expect(Directory('${dir.path}/store').listSync(), hasLength(1));
    });

    test('cada persona tiene la suya', () async {
      final a = await store.save('u1', image('a.jpg', [1]).path);
      final b = await store.save('u2', image('b.jpg', [2]).path);
      expect(await store.read('u1'), a);
      expect(await store.read('u2'), b);
      await store.remove('u1');
      expect(await store.read('u1'), isNull);
      expect(await store.read('u2'), b);
    });

    test('un identificador raro no sale de la carpeta', () async {
      final saved = await store.save('../../x', image('a.jpg', [1]).path);
      expect(p.isWithin(p.join(dir.path, 'store'), saved), isTrue);
    });
  });

  group('cubit', () {
    ProfilePhotoCubit cubit(ProfilePhotoPicker picker) =>
        ProfilePhotoCubit(store: store, picker: picker);

    test('al entrar muestra la foto que ya tenia', () async {
      final saved = await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(const NoProfilePhotoPicker());
      await c.load('u1');
      expect(c.state.path, saved);
    });

    test('cambiar con la galeria guarda y muestra la nueva', () async {
      final c = cubit(_Picker(gallery: image('g.jpg', [7]).path));
      await c.load('u1');
      await c.change(ProfilePhotoSource.gallery);
      expect(c.state.path, isNotNull);
      expect(File(c.state.path!).readAsBytesSync(), [7]);
      expect(c.state.saving, isFalse);
      expect(await store.read('u1'), c.state.path);
    });

    test('cambiar con la camara usa la camara', () async {
      final c = cubit(_Picker(camera: image('c.jpg', [9]).path));
      await c.load('u1');
      await c.change(ProfilePhotoSource.camera);
      expect(File(c.state.path!).readAsBytesSync(), [9]);
    });

    test('cancelar no cambia nada', () async {
      final saved = await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(_Picker());
      await c.load('u1');
      await c.change(ProfilePhotoSource.camera);
      expect(c.state.path, saved);
      expect(c.state.failed, isFalse);
    });

    test('un fallo lo avisa y conserva la anterior', () async {
      final saved = await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(_Picker(fail: true));
      await c.load('u1');
      await c.change(ProfilePhotoSource.gallery);
      expect(c.state.failed, isTrue);
      expect(c.state.path, saved);
    });

    test('quitar vuelve a las iniciales', () async {
      await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(const NoProfilePhotoPicker());
      await c.load('u1');
      await c.remove();
      expect(c.state.path, isNull);
      expect(await store.read('u1'), isNull);
    });

    test('sin sesion no cambia nada', () async {
      final c = cubit(_Picker(gallery: image('g.jpg', [7]).path));
      await c.change(ProfilePhotoSource.gallery);
      expect(c.state.path, isNull);
    });

    test('la foto no pasa a la siguiente persona', () async {
      await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(const NoProfilePhotoPicker());
      await c.load('u1');
      c.clear();
      expect(c.state.path, isNull);
      await c.load('u2');
      expect(c.state.path, isNull);
    });

    test('volver a cargar a la misma persona no la parpadea', () async {
      final saved = await store.save('u1', image('a.jpg', [1]).path);
      final c = cubit(const NoProfilePhotoPicker());
      final states = <ProfilePhotoState>[];
      await c.load('u1');
      final sub = c.stream.listen(states.add);
      await c.load('u1');
      await sub.cancel();
      expect(states, isEmpty);
      expect(c.state.path, saved);
    });
  });
}
