import 'package:url_launcher/url_launcher.dart';

/// Abre un enlace https en el navegador del telefono (por ejemplo la licencia
/// de los datos del mapa). Un fallo no rompe la pantalla: simplemente no abre.
abstract final class ExternalLink {
  /// Las pruebas lo reemplazan para no llamar al sistema.
  static Future<bool> Function(Uri uri) opener = _launch;

  static Future<bool> _launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Solo abre direcciones https; devuelve si se pudo abrir.
  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    try {
      return await opener(uri);
    } catch (_) {
      return false;
    }
  }
}
