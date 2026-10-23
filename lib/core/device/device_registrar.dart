import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_failure.dart';
import '../ids/client_id.dart';
import 'device_info_source.dart';

/// Lo que el servidor guarda de este telefono (`POST /api/mobile/devices`): con
/// la version de la app el administrador ve quien esta al dia.
class DeviceProfile {
  const DeviceProfile({
    required this.identifier,
    required this.appVersion,
    this.platform = 'ANDROID',
    this.osVersion,
    this.model,
  });

  /// Identificador estable que genera la app al instalarse; unico por persona.
  final String identifier;

  /// `ANDROID` o `IOS`; la app es solo Android.
  final String platform;

  /// Version y numero de compilacion, por ejemplo `1.0.1+23`.
  final String appVersion;

  /// Por ejemplo `Android 14`.
  final String? osVersion;

  /// Fabricante y modelo, por ejemplo `Samsung SM-A155M`.
  final String? model;

  Map<String, Object?> toJson() => {
    'identifier': identifier,
    'platform': platform,
    'appVersion': appVersion,
    'osVersion': ?osVersion,
    'model': ?model,
  };
}

/// Lo que el servidor contesta al registrar el telefono.
class DeviceRegistration {
  const DeviceRegistration({this.status, this.wipeData = false});

  /// `ACTIVO`, `BLOQUEADO` o `RETIRADO`.
  final String? status;

  /// El administrador bloqueo el telefono (perdido o robado): la app debe borrar
  /// sus datos locales.
  final bool wipeData;
}

/// De donde salen los datos del telefono. Sin fuente real (pruebas) no se
/// registra nada.
abstract interface class DeviceProfileSource {
  /// Null si no se pueden leer.
  Future<DeviceProfile?> read();
}

class NoDeviceProfileSource implements DeviceProfileSource {
  const NoDeviceProfileSource();

  @override
  Future<DeviceProfile?> read() async => null;
}

/// Lee la version de la app, el modelo y la version de Android del telefono, y
/// guarda un identificador propio que no cambia mientras la app siga instalada.
class PlatformDeviceProfileSource implements DeviceProfileSource {
  PlatformDeviceProfileSource(this._prefs, [DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  final SharedPreferences _prefs;
  final DeviceInfoPlugin _plugin;

  static const _kInstallId = 'device_install_id';

  String _installId() {
    final saved = _prefs.getString(_kInstallId);
    if (saved != null && saved.isNotEmpty) return saved;
    final fresh = newClientId();
    // Se guarda sin esperar: si no se pudiera, el mismo telefono se veria como
    // uno nuevo en cada apertura, pero el registro no falla.
    _prefs.setString(_kInstallId, fresh);
    return fresh;
  }

  @override
  Future<DeviceProfile?> read() async {
    try {
      final app = await PackageInfo.fromPlatform();
      final build = app.buildNumber.trim();
      final version = build.isEmpty ? app.version : '${app.version}+$build';
      String? model;
      String? os;
      try {
        final info = await _plugin.androidInfo;
        model = deviceModelLabel(
          manufacturer: info.manufacturer,
          model: info.model,
        );
        final release = info.version.release.trim();
        os = release.isEmpty ? null : 'Android $release';
      } catch (_) {
        // Sin modelo ni sistema el registro sigue sirviendo para la version.
      }
      return DeviceProfile(
        identifier: _installId(),
        appVersion: version,
        osVersion: os,
        model: model == null || model.isEmpty ? null : model,
      );
    } catch (_) {
      return null;
    }
  }
}

/// El servidor al que se registra el telefono.
abstract interface class DeviceRemote {
  Future<DeviceRegistration?> register(DeviceProfile profile);
}

/// Sin servicio en el servidor: no hace nada.
class NoDeviceRemote implements DeviceRemote {
  const NoDeviceRemote();

  @override
  Future<DeviceRegistration?> register(DeviceProfile profile) async => null;
}

/// `POST /api/mobile/devices`: el telefono es de la persona en sesion y el
/// servidor guarda cuando lo vio por ultima vez.
class ApiDeviceRemote implements DeviceRemote {
  const ApiDeviceRemote(this._api);

  final ApiClient _api;

  static const path = '/api/mobile/devices';

  @override
  Future<DeviceRegistration?> register(DeviceProfile profile) async {
    final json = await _api.post(path, data: profile.toJson());
    if (json == null) return null;
    final status = json['status'];
    return DeviceRegistration(
      status: status is String ? status : null,
      wipeData: json['wipeData'] == true,
    );
  }
}

/// Lo que paso al intentar registrar el telefono.
enum DeviceOutcome {
  /// El servidor lo registro o lo actualizo.
  registered,

  /// Se registro hace poco con los mismos datos: no se repite.
  recent,

  /// No hay nada que registrar (pruebas o datos ilegibles).
  skipped,

  /// El administrador lo bloqueo: hay que borrar los datos locales.
  blocked,

  /// No se pudo hablar con el servidor: se reintenta al volver la conexion o en
  /// la proxima sesion.
  failed,
}

/// Registra este telefono en el servidor al iniciar sesion, al cambiar de
/// concesion y al volver la conexion, para que el administrador vea la version de
/// la app de cada persona (tareas 1305 y 514). Un fallo nunca estorba a la sesion.
class DeviceRegistrar {
  DeviceRegistrar({
    this.source = const NoDeviceProfileSource(),
    this.remote = const NoDeviceRemote(),
    this.minGap = const Duration(minutes: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DeviceProfileSource source;
  final DeviceRemote remote;

  /// Tiempo minimo entre dos registros con los mismos datos.
  final Duration minGap;
  final DateTime Function() _now;

  String? _lastKey;
  DateTime? _lastAt;

  Future<DeviceOutcome> register(String concessionId, {bool force = false}) async {
    try {
      final profile = await source.read();
      if (profile == null) return DeviceOutcome.skipped;
      // Otra persona, otra concesion o otra version vuelven a registrar.
      final key = '$concessionId|${profile.toJson()}';
      final last = _lastAt;
      if (!force &&
          key == _lastKey &&
          last != null &&
          _now().difference(last) < minGap) {
        return DeviceOutcome.recent;
      }
      final result = await remote.register(profile);
      if (result == null) return DeviceOutcome.failed;
      _lastKey = key;
      _lastAt = _now();
      return result.wipeData ? DeviceOutcome.blocked : DeviceOutcome.registered;
    } on ApiFailure {
      return DeviceOutcome.failed;
    } catch (_) {
      return DeviceOutcome.failed;
    }
  }

  /// Al cerrar la sesion: la proxima persona registra de nuevo.
  void forget() {
    _lastKey = null;
    _lastAt = null;
  }
}
