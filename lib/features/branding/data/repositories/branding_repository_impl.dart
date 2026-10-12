import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/concession_branding.dart';
import '../../domain/repositories/branding_repository.dart';

/// Lee la marca de la concesion activa de `GET /api/context/branding` y la
/// guarda por concesion para el siguiente arranque (MAR-06).
///
/// El endpoint esta propuesto (S11, seccion 6.4) y puede no existir todavia: un
/// 404 o una respuesta vacia significan "sin marca propia".
class BrandingRepositoryImpl implements BrandingRepository {
  BrandingRepositoryImpl(this._api, this._prefs, {this.fallback});

  final ApiClient _api;
  final SharedPreferences _prefs;

  /// Marca de prueba para ambientes donde el servidor aun no entrega ninguna
  /// (se define con `--dart-define`; ver `AppConfig`).
  final ConcessionBranding? fallback;

  static String _key(String concessionId) => 'branding_$concessionId';

  @override
  Future<ConcessionBranding?> load(String concessionId) async {
    final cached = _readCache(concessionId);
    try {
      final json = await _api.get('/api/context/branding');
      final fresh = brandingFromJson(json);
      if (fresh == null) {
        await _prefs.remove(_key(concessionId));
        return fallback;
      }
      // Misma version: se conserva lo guardado, sin reescribirlo.
      if (cached != null &&
          fresh.version > 0 &&
          cached.version == fresh.version) {
        return cached;
      }
      await _prefs.setString(
        _key(concessionId),
        jsonEncode(brandingToJson(fresh)),
      );
      return fresh;
    } on ApiFailure catch (f) {
      // Sin red o con error del servidor se usa lo ultimo que se conocia.
      if (f.isNetwork || (f.status ?? 0) >= 500) return cached ?? fallback;
      // 404 y similares: la concesion no tiene marca configurada.
      await _prefs.remove(_key(concessionId));
      return fallback;
    }
  }

  ConcessionBranding? _readCache(String concessionId) {
    final raw = _prefs.getString(_key(concessionId));
    if (raw == null) return null;
    try {
      return brandingFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Acepta el objeto directo o envuelto en `branding`.
ConcessionBranding? brandingFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final j = raw['branding'] is Map<String, dynamic>
      ? raw['branding'] as Map<String, dynamic>
      : raw;
  final primary = j['primary'];
  if (primary is! String || primary.trim().isEmpty) return null;
  String? text(String key) {
    final v = j[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  final version = j['version'];
  return ConcessionBranding(
    version: version is int ? version : 0,
    primary: primary.trim(),
    secondary: text('secondary'),
    headerStart: text('headerStart'),
    headerEnd: text('headerEnd'),
    background: text('background'),
    logoLightUrl: text('logoLightUrl'),
    logoDarkUrl: text('logoDarkUrl'),
    logoReducedUrl: text('logoReducedUrl'),
    timezone: text('timezone'),
  );
}

Map<String, dynamic> brandingToJson(ConcessionBranding b) => {
  'version': b.version,
  'primary': b.primary,
  'secondary': b.secondary,
  'headerStart': b.headerStart,
  'headerEnd': b.headerEnd,
  'background': b.background,
  'logoLightUrl': b.logoLightUrl,
  'logoDarkUrl': b.logoDarkUrl,
  'logoReducedUrl': b.logoReducedUrl,
  'timezone': b.timezone,
};
