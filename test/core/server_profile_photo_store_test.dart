import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/core/api/api_failure.dart';
import 'package:sigaco_movil/core/profile/profile_photo.dart';
import 'package:sigaco_movil/core/profile/server_profile_photo_store.dart';

import '../support/fake_api.dart';

/// La foto de perfil en el servidor, con copia en el telefono (MOB-001): se baja
/// al entrar, se sube al cambiarla y lo hecho sin red se envia despues.
void main() {
  const route = '/api/auth/me/photo';
  late Directory dir;
  late FakeApi api;
  late LocalProfilePhotoStore local;
  late SharedPreferences prefs;
  late ServerProfilePhotoStore store;
  var tick = 0;

  File image(String name, List<int> bytes) =>
      File('${dir.path}/$name')..writeAsBytesSync(bytes);

  Uint8List bytes(List<int> v) => Uint8List.fromList(v);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('spp_');
    tick = 0;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = FakeApi();
    local = LocalProfilePhotoStore(
      root: () async => Directory('${dir.path}/store'),
      clock: () => DateTime.utc(2026, 10, 28).add(Duration(seconds: tick++)),
    );
    store = ServerProfilePhotoStore(
      api: api.client(),
      local: local,
      prefs: prefs,
    );
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Lo recoge el sistema.
      }
    });
  });

  Future<int> storedFiles() async {
    final d = Directory('${dir.path}/store');
    return d.existsSync() ? d.listSync().whereType<File>().length : 0;
  }

  group('al entrar', () {
    test('baja la foto del servidor y la guarda en el telefono', () async {
      api.on('GET $route', FakeReply.bytes(200, bytes([1, 2, 3])));
      final path = await store.read('u1');
      expect(path, isNotNull);
      expect(File(path!).readAsBytesSync(), [1, 2, 3]);
      expect(await local.read('u1'), path);
    });

    test('si no cambio no la vuelve a guardar ni cambia su ruta', () async {
      api.on('GET $route', FakeReply.bytes(200, bytes([1, 2, 3])));
      final first = await store.read('u1');
      final second = await store.read('u1');
      expect(second, first);
      expect(await storedFiles(), 1);
    });

    test('si cambio en el servidor reemplaza la copia', () async {
      api.on('GET $route', FakeReply.bytes(200, bytes([1, 2, 3])));
      final first = await store.read('u1');
      api.on('GET $route', FakeReply.bytes(200, bytes([9, 9])));
      final second = await store.read('u1');
      expect(second, isNot(first));
      expect(File(second!).readAsBytesSync(), [9, 9]);
      expect(await storedFiles(), 1);
    });

    test('sin foto en el servidor no queda copia vieja', () async {
      await local.save('u1', image('a.jpg', [1]).path);
      api.on(
        'GET $route',
        const FakeReply(404, {'code': 'PROFILE_PHOTO_NOT_FOUND'}),
      );
      expect(await store.read('u1'), isNull);
      expect(await local.read('u1'), isNull);
    });

    test('sin red se ve la copia del telefono', () async {
      final saved = await local.save('u1', image('a.jpg', [1]).path);
      api.offline = true;
      expect(await store.read('u1'), saved);
    });

    test('con un error del servidor tambien se ve la copia', () async {
      final saved = await local.save('u1', image('a.jpg', [1]).path);
      api.on('GET $route', const FakeReply(500, {}));
      expect(await store.read('u1'), saved);
    });

    test('sin red y sin copia, no hay foto', () async {
      api.offline = true;
      expect(await store.read('u1'), isNull);
    });
  });

  group('al cambiarla', () {
    test('la sube con el archivo en el campo file y guarda la copia', () async {
      api.on('PUT $route', const FakeReply(200, {'sha256': 'abc'}));
      final path = await store.save('u1', image('a.jpg', [1, 2]).path);

      final sent = api.to('PUT $route').single;
      final form = sent.data as FormData;
      expect(form.files.single.key, 'file');
      expect(File(path).readAsBytesSync(), [1, 2]);
      expect(prefs.getString('profile_photo_pending_u1'), isNull);
    });

    test(
      'sin red queda en el telefono y se sube en el siguiente acceso',
      () async {
        api.offline = true;
        final path = await store.save('u1', image('a.jpg', [1, 2]).path);
        expect(File(path).existsSync(), isTrue);
        expect(prefs.getString('profile_photo_pending_u1'), 'upload');

        api
          ..requests.clear()
          ..offline = false
          ..on('PUT $route', const FakeReply(200, {}))
          ..on('GET $route', FakeReply.bytes(200, bytes([1, 2])));
        final read = await store.read('u1');

        expect(api.to('PUT $route'), hasLength(1));
        expect(prefs.getString('profile_photo_pending_u1'), isNull);
        expect(File(read!).readAsBytesSync(), [1, 2]);
      },
    );

    test('si el servidor la rechaza, avisa y conserva la anterior', () async {
      final previous = await local.save('u1', image('antes.jpg', [7]).path);
      api.on(
        'PUT $route',
        const FakeReply(400, {
          'errors': {
            'file': ['La foto pesa más de 1 MB.'],
          },
        }),
      );

      await expectLater(
        store.save('u1', image('grande.jpg', [1, 2, 3]).path),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 400)),
      );
      expect(await local.read('u1'), previous);
      expect(prefs.getString('profile_photo_pending_u1'), isNull);
    });

    test(
      'lo pendiente que el servidor rechaza se descarta y no se repite',
      () async {
        api.offline = true;
        await store.save('u1', image('a.jpg', [1]).path);
        api
          ..requests.clear()
          ..offline = false
          ..on('PUT $route', const FakeReply(400, {}))
          ..on('GET $route', FakeReply.bytes(200, bytes([5])));
        await store.read('u1');
        expect(prefs.getString('profile_photo_pending_u1'), isNull);
        await store.read('u1');
        expect(api.to('PUT $route'), hasLength(1));
      },
    );
  });

  group('con un servidor que aun no tiene la foto', () {
    test('cambiarla la deja en el telefono y se sube cuando exista', () async {
      // Sin ruta: el servidor responde 404 sin codigo.
      final path = await store.save('u1', image('a.jpg', [1, 2]).path);
      expect(File(path).existsSync(), isTrue);
      expect(prefs.getString('profile_photo_pending_u1'), 'upload');

      api
        ..requests.clear()
        ..on('PUT $route', const FakeReply(200, {}))
        ..on('GET $route', FakeReply.bytes(200, bytes([1, 2])));
      await store.read('u1');
      expect(api.to('PUT $route'), hasLength(1));
      expect(prefs.getString('profile_photo_pending_u1'), isNull);
    });

    test('al entrar se ve la copia, no se borra', () async {
      final saved = await local.save('u1', image('a.jpg', [1]).path);
      expect(await store.read('u1'), saved);
      expect(await local.read('u1'), saved);
    });

    test(
      'quitarla se borra del telefono y se avisa al servidor despues',
      () async {
        await local.save('u1', image('a.jpg', [1]).path);
        await store.remove('u1');
        expect(await local.read('u1'), isNull);
        expect(prefs.getString('profile_photo_pending_u1'), 'remove');
      },
    );
  });

  group('al quitarla', () {
    test('la borra en el servidor y en el telefono', () async {
      await local.save('u1', image('a.jpg', [1]).path);
      api.on('DELETE $route', const FakeReply(200, {}));
      await store.remove('u1');
      expect(api.to('DELETE $route'), hasLength(1));
      expect(await local.read('u1'), isNull);
    });

    test('sin red se borra del telefono y en el servidor despues', () async {
      await local.save('u1', image('a.jpg', [1]).path);
      api.offline = true;
      await store.remove('u1');
      expect(await local.read('u1'), isNull);
      expect(prefs.getString('profile_photo_pending_u1'), 'remove');

      api
        ..requests.clear()
        ..offline = false
        ..on('DELETE $route', const FakeReply(200, {}))
        ..on('GET $route', const FakeReply(404, {}));
      expect(await store.read('u1'), isNull);
      expect(api.to('DELETE $route'), hasLength(1));
      expect(prefs.getString('profile_photo_pending_u1'), isNull);
    });
  });

  test('lo pendiente de una persona no se manda en nombre de otra', () async {
    api.offline = true;
    await store.save('u1', image('a.jpg', [1]).path);
    api
      ..requests.clear()
      ..offline = false
      ..on('PUT $route', const FakeReply(200, {}))
      ..on('GET $route', const FakeReply(404, {}));
    await store.read('u2');
    expect(api.to('PUT $route'), isEmpty);
    expect(prefs.getString('profile_photo_pending_u1'), 'upload');
  });
}
