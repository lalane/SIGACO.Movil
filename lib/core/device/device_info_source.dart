import 'package:device_info_plus/device_info_plus.dart';

/// Datos del telefono para mostrar al usuario (por ejemplo en su cuenta). Lo
/// que se manda al servidor para que el administrador vea la version de la app
/// sale de `DeviceProfileSource`.
abstract interface class DeviceInfoSource {
  /// Texto corto como «Samsung SM-A155M · Android 14»; vacio si no se puede leer.
  Future<String> describe();
}

class NoDeviceInfo implements DeviceInfoSource {
  const NoDeviceInfo();

  @override
  Future<String> describe() async => '';
}

class DeviceInfoPlusSource implements DeviceInfoSource {
  DeviceInfoPlusSource([DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<String> describe() async {
    try {
      final info = await _plugin.androidInfo;
      return describeDevice(
        manufacturer: info.manufacturer,
        model: info.model,
        release: info.version.release,
      );
    } catch (_) {
      return '';
    }
  }
}

/// Une fabricante y modelo sin repetir el fabricante.
String deviceModelLabel({required String manufacturer, required String model}) {
  String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  final maker = capitalize(manufacturer.trim());
  final name = model.trim();
  return name.toLowerCase().startsWith(maker.toLowerCase())
      ? name
      : [maker, name].where((s) => s.isNotEmpty).join(' ');
}

/// Une fabricante, modelo y version de Android sin repetir el fabricante.
String describeDevice({
  required String manufacturer,
  required String model,
  required String release,
}) {
  final device = deviceModelLabel(manufacturer: manufacturer, model: model);
  final os = release.trim().isEmpty ? '' : 'Android ${release.trim()}';
  return [device, os].where((s) => s.isNotEmpty).join(' · ');
}
