import '../api/api_client.dart';
import '../api/api_failure.dart';
import 'push_registrar.dart';

/// El estado del canal push de la concesion activa, de
/// `GET /api/app-configuration` (`channels.push`).
class ApiPushChannelSource implements PushChannelSource {
  const ApiPushChannelSource(this._api);

  final ApiClient _api;

  @override
  Future<bool?> isActive(String concessionId) async {
    try {
      final json = await _api.get('/api/app-configuration');
      // La configuracion es de la concesion activa: si es otra, no vale.
      final id = json?['concessionId'];
      if (id is String && id.isNotEmpty && id != concessionId) return null;
      final channels = json?['channels'];
      if (channels is Map && channels['push'] is bool) {
        return channels['push'] as bool;
      }
      return null;
    } on ApiFailure {
      return null;
    }
  }
}

/// Los dispositivos push de la persona en sesion (`/api/auth/me/devices`).
class ApiPushRemote implements PushRemote {
  const ApiPushRemote(this._api, {this.platform = 'ANDROID'});

  final ApiClient _api;

  /// `ANDROID` o `IOS`; la app es solo Android.
  final String platform;

  @override
  Future<String?> register(String token) async {
    final json = await _api.post(
      '/api/auth/me/devices',
      data: {'token': token, 'platform': platform},
    );
    final id = json?['id'];
    return id is String ? id : null;
  }

  @override
  Future<void> unregister(String deviceId) async {
    try {
      await _api.delete('/api/auth/me/devices/$deviceId');
    } on ApiFailure catch (e) {
      // 404: ya no existe, que es lo que se queria.
      if (e.status != 404) rethrow;
    }
  }
}
