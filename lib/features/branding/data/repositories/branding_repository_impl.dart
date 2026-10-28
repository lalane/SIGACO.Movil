import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/concession_branding.dart';
import '../../domain/repositories/branding_repository.dart';

/// Lee la marca de la concesion activa de `GET /api/app-configuration` (la
/// configuracion vigente: colores, logos, zona horaria...) y la guarda por
/// concesion para el siguiente arranque (MAR-06).
///
/// Antes de bajar todo pregunta `GET /api/app-configuration/version` (P-09): si
/// la version es la que ya se tiene, no se descarga nada. Un 404 o una
/// respuesta sin colores propios ni logos significan "sin marca propia".
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
      if (cached != null && await _isCurrent(cached)) return cached;
      final json = await _api.get('/api/app-configuration');
      final fresh = brandingFromConfiguration(json, baseUrl: _api.baseUrl);
      if (fresh == null) {
        await _prefs.remove(_key(concessionId));
        return fallback;
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

  /// La version del servidor es la de [cached]: no hay que descargar nada. Sin
  /// version guardada (cero) siempre se baja. Si la consulta ligera falla por
  /// red o por el servidor, el error sigue su camino (se usa lo guardado); con
  /// cualquier otro error se intenta la descarga completa.
  Future<bool> _isCurrent(ConcessionBranding cached) async {
    if (cached.version <= 0) return false;
    try {
      final v = await _api.get('/api/app-configuration/version');
      return v?['configurationVersion'] == cached.version;
    } on ApiFailure catch (f) {
      if (f.isNetwork || (f.status ?? 0) >= 500) rethrow;
      return false;
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

/// Los colores provisionales con los que el servidor llena lo que una
/// concesion no personalizo (`SigacoDefaultColors`, RN-09). La app movil tiene
/// su propio diseno: un color igual a estos se toma como "sin color propio" y
/// no repinta la app.
const serverDefaultColors = {
  '#1F4E79', // primario y boton
  '#F28C28', // secundario
  '#0D1B2A', // fondo del menu
  '#424241', // cabecera
};

/// Convierte la configuracion vigente del servidor en la marca de la app.
///
/// * color de accion: el del boton y, si falta, el primario;
/// * fondo de la barra de navegacion: el del menu;
/// * inicio del degradado de la cabecera: el de la cabecera;
/// * logo para fondo claro y oscuro: el principal (el servidor no distingue);
/// * logo reducido: el reducido, que el servidor ya completa con el principal.
///
/// Los logos llegan como ruta de la API (`/api/configuration-logos/{id}`): se
/// arman contra [baseUrl]. Sin colores propios ni logos devuelve null.
ConcessionBranding? brandingFromConfiguration(
  Map<String, dynamic>? raw, {
  required String baseUrl,
}) {
  if (raw == null) return null;
  final colors = raw['colors'];
  final logos = raw['logos'];
  String? own(String key) {
    final v = colors is Map ? colors[key] : null;
    if (v is! String) return null;
    final hex = v.trim().toUpperCase();
    if (hex.isEmpty || serverDefaultColors.contains(hex)) return null;
    return hex;
  }

  String? logo(String key) {
    final entry = logos is Map ? logos[key] : null;
    final url = entry is Map ? entry['url'] : null;
    if (url is! String || url.trim().isEmpty) return null;
    return _absolute(baseUrl, url.trim());
  }

  String? text(String key) {
    final v = raw[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  final principal = logo('principal');
  final reduced = logo('reduced');
  final primary = own('buttonColor') ?? own('primaryColor');
  final menu = own('menuBackgroundColor');
  final header = own('headerColor');
  final accent = own('primaryColor');
  final secondaryAccent = own('secondaryColor');
  // El blanco es el texto de SIGACO cuando la concesion no elige uno: no cuenta
  // como suyo (si se lee sobre su color, el calculado ya es blanco).
  final chosenText = own('primaryTextColor');
  final primaryText = chosenText == '#FFFFFF' ? null : chosenText;
  if (primary == null &&
      menu == null &&
      header == null &&
      principal == null &&
      reduced == null) {
    return null;
  }
  final version = raw['configurationVersion'];
  return ConcessionBranding(
    version: version is int ? version : 0,
    primary: primary,
    secondary: menu,
    headerStart: header,
    accent: accent,
    secondaryAccent: secondaryAccent,
    primaryText: primaryText,
    logoLightUrl: principal,
    logoDarkUrl: principal,
    logoReducedUrl: reduced,
    timezone: text('timeZone'),
  );
}

String _absolute(String baseUrl, String url) {
  if (Uri.tryParse(url)?.hasScheme ?? false) return url;
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return url.startsWith('/') ? '$base$url' : '$base/$url';
}

/// Lee la marca en el formato que se guarda en el telefono (y el de pruebas).
/// Acepta el objeto directo o envuelto en `branding`.
ConcessionBranding? brandingFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final j = raw['branding'] is Map<String, dynamic>
      ? raw['branding'] as Map<String, dynamic>
      : raw;
  String? text(String key) {
    final v = j[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  final primary = text('primary');
  final hasLogo =
      text('logoLightUrl') != null ||
      text('logoDarkUrl') != null ||
      text('logoReducedUrl') != null;
  // Sin color de accion ni logo no hay marca que mostrar.
  if (primary == null && !hasLogo) return null;
  final version = j['version'];
  return ConcessionBranding(
    version: version is int ? version : 0,
    primary: primary,
    secondary: text('secondary'),
    headerStart: text('headerStart'),
    headerEnd: text('headerEnd'),
    accent: text('accent'),
    secondaryAccent: text('secondaryAccent'),
    primaryText: text('primaryText'),
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
  'accent': b.accent,
  'secondaryAccent': b.secondaryAccent,
  'primaryText': b.primaryText,
  'background': b.background,
  'logoLightUrl': b.logoLightUrl,
  'logoDarkUrl': b.logoDarkUrl,
  'logoReducedUrl': b.logoReducedUrl,
  'timezone': b.timezone,
};
