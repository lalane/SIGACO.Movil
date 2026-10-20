import 'package:shared_preferences/shared_preferences.dart';

/// De donde sale el token push del telefono (Firebase Cloud Messaging en
/// Android). Sin proyecto de Firebase configurado no hay fuente real: se usa
/// [NoPushTokenSource] y la app no registra nada.
abstract interface class PushTokenSource {
  /// El token actual; null si el telefono no puede recibir push (sin servicios
  /// de Google, sin permiso, sin Firebase en la app).
  Future<String?> token();
}

class NoPushTokenSource implements PushTokenSource {
  const NoPushTokenSource();

  @override
  Future<String?> token() async => null;
}

/// Si la concesion activa tiene encendido el canal push (DTF Configuracion,
/// RN-19: la concesionaria activa o desactiva cada canal de notificacion).
abstract interface class PushChannelSource {
  /// Null si no se pudo saber (sin red o el servidor no lo publica).
  Future<bool?> isActive(String concessionId);
}

class NoPushChannelSource implements PushChannelSource {
  const NoPushChannelSource();

  @override
  Future<bool?> isActive(String concessionId) async => null;
}

/// El servidor al que se manda el token (`/api/auth/me/devices`): el dispositivo
/// es de la persona en sesion y el servidor devuelve su identificador.
abstract interface class PushRemote {
  /// Registra el token y devuelve el identificador del dispositivo.
  Future<String?> register(String token);

  /// Retira el dispositivo. Si ya no existe, no es un error.
  Future<void> unregister(String deviceId);
}

/// Sin servicio en el servidor: no hace nada.
class NoPushRemote implements PushRemote {
  const NoPushRemote();

  @override
  Future<String?> register(String token) async => null;

  @override
  Future<void> unregister(String deviceId) async {}
}

/// Lo que paso al intentar sincronizar el registro push.
enum PushOutcome {
  /// Se registro el token en el servidor.
  registered,

  /// Ya estaba registrado: no se vuelve a mandar.
  unchanged,

  /// El canal esta apagado: se retiro el dispositivo que hubiera.
  unregistered,

  /// No hay nada que hacer (canal apagado o desconocido sin registro previo).
  skipped,

  /// El telefono no tiene token (sin Firebase o sin permiso).
  noToken,

  /// No se pudo hablar con el servidor: se reintenta en la proxima sesion.
  failed,
}

/// Registra el token push de este telefono **solo si el canal push de la
/// concesion activa esta encendido** (RN-19), y retira el dispositivo si la
/// concesion lo apaga o al cerrar sesion. Recuerda lo registrado para no repetirlo
/// en cada apertura.
class PushRegistrar {
  PushRegistrar({
    required this.prefs,
    this.tokens = const NoPushTokenSource(),
    this.channels = const NoPushChannelSource(),
    this.remote = const NoPushRemote(),
  });

  final SharedPreferences prefs;
  final PushTokenSource tokens;
  final PushChannelSource channels;
  final PushRemote remote;

  static const _kRegistered = 'push_registered';

  /// `concesion|token|dispositivo` del ultimo registro, o null.
  List<String>? get _registered {
    final raw = prefs.getString(_kRegistered);
    final parts = raw?.split('|');
    return parts != null && parts.length == 3 ? parts : null;
  }

  Future<PushOutcome> sync(String concessionId) async {
    try {
      final active = await channels.isActive(concessionId);
      final previous = _registered;
      if (active != true) {
        // Apagado: se retira el dispositivo registrado. Si no se pudo saber, no
        // se toca nada.
        if (active == false && previous != null) {
          await remote.unregister(previous[2]);
          await prefs.remove(_kRegistered);
          return PushOutcome.unregistered;
        }
        return PushOutcome.skipped;
      }
      final token = await tokens.token();
      if (token == null || token.isEmpty) return PushOutcome.noToken;
      if (previous != null &&
          previous[0] == concessionId &&
          previous[1] == token) {
        return PushOutcome.unchanged;
      }
      final deviceId = await remote.register(token);
      if (deviceId == null || deviceId.isEmpty) return PushOutcome.failed;
      await prefs.setString(_kRegistered, '$concessionId|$token|$deviceId');
      return PushOutcome.registered;
    } catch (_) {
      return PushOutcome.failed;
    }
  }

  /// Retira el dispositivo de la persona en sesion: se llama **antes** de cerrar
  /// la sesion, porque despues el servidor ya no la reconoce. Un fallo no impide
  /// cerrarla.
  Future<void> retire() async {
    final previous = _registered;
    await prefs.remove(_kRegistered);
    if (previous == null) return;
    try {
      await remote.unregister(previous[2]);
    } catch (_) {
      // Sin red: el servidor lo retira cuando expire la sesion.
    }
  }

  /// Olvida lo registrado sin avisar al servidor (la sesion ya termino por
  /// inactividad o expiro).
  Future<void> forget() => prefs.remove(_kRegistered);
}
