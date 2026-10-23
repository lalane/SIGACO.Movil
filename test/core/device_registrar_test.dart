import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';
import 'package:sigaco_movil/core/device/device_registrar.dart';

import '../support/fake_api.dart';

const _profile = DeviceProfile(
  identifier: 'dev-1',
  appVersion: '1.0.1+23',
  osVersion: 'Android 14',
  model: 'Samsung SM-A155M',
);

class _Source implements DeviceProfileSource {
  _Source(this.profile);

  DeviceProfile? profile;

  @override
  Future<DeviceProfile?> read() async => profile;
}

class _Remote implements DeviceRemote {
  final sent = <DeviceProfile>[];
  DeviceRegistration? reply = const DeviceRegistration(status: 'ACTIVO');
  Object? fail;

  @override
  Future<DeviceRegistration?> register(DeviceProfile profile) async {
    sent.add(profile);
    if (fail != null) throw fail!;
    return reply;
  }
}

void main() {
  group('DeviceProfile', () {
    test('manda lo que el servidor espera y omite lo que no se pudo leer', () {
      expect(_profile.toJson(), {
        'identifier': 'dev-1',
        'platform': 'ANDROID',
        'appVersion': '1.0.1+23',
        'osVersion': 'Android 14',
        'model': 'Samsung SM-A155M',
      });
      const bare = DeviceProfile(identifier: 'x', appVersion: '1.0.0+1');
      expect(bare.toJson().keys, ['identifier', 'platform', 'appVersion']);
    });
  });

  group('ApiDeviceRemote', () {
    late FakeApi api;
    late ApiDeviceRemote remote;

    setUp(() {
      api = FakeApi();
      remote = ApiDeviceRemote(api.client());
    });

    test('registra en /api/mobile/devices y lee el estado', () async {
      api.on('POST /api/mobile/devices', const FakeReply(200, {
        'id': 'd1',
        'status': 'ACTIVO',
        'wipeData': false,
      }));
      final result = await remote.register(_profile);

      expect(result?.status, 'ACTIVO');
      expect(result?.wipeData, isFalse);
      final sent = api.to('POST /api/mobile/devices').single;
      expect(sent.data, _profile.toJson());
    });

    test('un telefono bloqueado pide borrar los datos', () async {
      api.on('POST /api/mobile/devices', const FakeReply(200, {
        'status': 'BLOQUEADO',
        'wipeData': true,
      }));
      expect((await remote.register(_profile))?.wipeData, isTrue);
    });
  });

  group('DeviceRegistrar', () {
    late _Remote remote;
    late DateTime now;
    late DeviceRegistrar registrar;

    setUp(() {
      remote = _Remote();
      now = DateTime.utc(2026, 10, 23, 12);
      registrar = DeviceRegistrar(
        source: _Source(_profile),
        remote: remote,
        now: () => now,
      );
    });

    test('registra la primera vez', () async {
      expect(await registrar.register('c1'), DeviceOutcome.registered);
      expect(remote.sent.single.appVersion, '1.0.1+23');
    });

    test('no repite el mismo registro dentro del tiempo minimo', () async {
      await registrar.register('c1');
      now = now.add(const Duration(minutes: 29));
      expect(await registrar.register('c1'), DeviceOutcome.recent);
      expect(remote.sent, hasLength(1));

      now = now.add(const Duration(minutes: 2));
      expect(await registrar.register('c1'), DeviceOutcome.registered);
      expect(remote.sent, hasLength(2));
    });

    test('otra concesion o forzarlo vuelven a registrar', () async {
      await registrar.register('c1');
      expect(await registrar.register('c2'), DeviceOutcome.registered);
      expect(
        await registrar.register('c2', force: true),
        DeviceOutcome.registered,
      );
      expect(remote.sent, hasLength(3));
    });

    test('una version nueva de la app se registra aunque sea reciente', () async {
      final source = _Source(_profile);
      registrar = DeviceRegistrar(source: source, remote: remote, now: () => now);
      await registrar.register('c1');
      source.profile = const DeviceProfile(
        identifier: 'dev-1',
        appVersion: '1.0.2+24',
      );
      expect(await registrar.register('c1'), DeviceOutcome.registered);
      expect(remote.sent.last.appVersion, '1.0.2+24');
    });

    test('al cerrar la sesion la siguiente persona registra de nuevo', () async {
      await registrar.register('c1');
      registrar.forget();
      expect(await registrar.register('c1'), DeviceOutcome.registered);
    });

    test('un telefono bloqueado se avisa', () async {
      remote.reply = const DeviceRegistration(
        status: 'BLOQUEADO',
        wipeData: true,
      );
      expect(await registrar.register('c1'), DeviceOutcome.blocked);
    });

    test('un fallo no estorba y se reintenta despues', () async {
      remote.fail = StateError('sin red');
      expect(await registrar.register('c1'), DeviceOutcome.failed);

      remote.fail = null;
      expect(await registrar.register('c1'), DeviceOutcome.registered);
    });

    test('sin respuesta del servidor cuenta como fallo', () async {
      remote.reply = null;
      expect(await registrar.register('c1'), DeviceOutcome.failed);
    });

    test('sin datos del telefono no registra nada', () async {
      final empty = DeviceRegistrar(
        source: _Source(null),
        remote: remote,
        now: () => now,
      );
      expect(await empty.register('c1'), DeviceOutcome.skipped);
      expect(remote.sent, isEmpty);

      expect(
        await DeviceRegistrar().register('c1'),
        DeviceOutcome.skipped,
      );
    });
  });

  group('PlatformDeviceProfileSource', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'SIGACO',
        packageName: 'com.idare.sigaco_movil',
        version: '1.0.1',
        buildNumber: '23',
        buildSignature: '',
      );
    });

    test('lee la version con su compilacion y guarda un identificador', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = PlatformDeviceProfileSource(prefs);

      final first = await source.read();
      expect(first?.appVersion, '1.0.1+23');
      expect(first?.platform, 'ANDROID');
      expect(first?.identifier, isNotEmpty);

      // El mismo telefono sigue siendo el mismo.
      final again = await PlatformDeviceProfileSource(prefs).read();
      expect(again?.identifier, first?.identifier);
      expect(prefs.getString('device_install_id'), first?.identifier);
    });

    test('un identificador ya guardado se respeta', () async {
      SharedPreferences.setMockInitialValues({'device_install_id': 'abc-123'});
      final prefs = await SharedPreferences.getInstance();
      final profile = await PlatformDeviceProfileSource(prefs).read();
      expect(profile?.identifier, 'abc-123');
    });
  });

  group('deviceModelLabel', () {
    test('no repite el fabricante', () {
      expect(
        deviceModelLabel(manufacturer: 'samsung', model: 'SM-A155M'),
        'Samsung SM-A155M',
      );
      expect(
        deviceModelLabel(manufacturer: 'motorola', model: 'Motorola Edge 30'),
        'Motorola Edge 30',
      );
    });
  });
}
