import 'package:local_auth/local_auth.dart';

/// Desbloqueo local del telefono: huella, rostro o el codigo del dispositivo.
/// Abre la app tras el bloqueo por inactividad sin volver a pedir la contrasena
/// ni llamar al servidor (RN-M01-37).
abstract interface class DeviceUnlock {
  /// El telefono puede confirmar la identidad (tiene bloqueo de pantalla).
  Future<bool> isAvailable();

  /// Pide confirmar la identidad; `true` si la persona lo logro.
  Future<bool> authenticate(String reason);
}

class LocalAuthDeviceUnlock implements DeviceUnlock {
  LocalAuthDeviceUnlock(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Sin `biometricOnly`: si no hay huella o rostro, vale el codigo del
      // telefono.
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}

/// Sin forma de confirmar la identidad (pruebas y equipos sin bloqueo de
/// pantalla): la unica salida del bloqueo es cerrar sesion.
class NoDeviceUnlock implements DeviceUnlock {
  const NoDeviceUnlock();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
