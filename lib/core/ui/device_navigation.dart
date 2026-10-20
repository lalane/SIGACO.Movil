import 'package:url_launcher/url_launcher.dart';

/// Entrega unas coordenadas a la aplicacion de navegacion del telefono (DTF M10,
/// HU-MOB-10-06): SIGACO no calcula rutas. Un fallo no rompe la pantalla.
abstract final class DeviceNavigation {
  /// Las pruebas lo reemplazan para no llamar al sistema.
  static Future<bool> Function(Uri uri) opener = _launch;

  static Future<bool> _launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// La direccion `geo:` que entienden las apps de mapas de Android: centra en
  /// el punto y le pone [label].
  static Uri uriFor(double latitude, double longitude, {String? label}) {
    final point = '$latitude,$longitude';
    final name = label == null || label.trim().isEmpty
        ? ''
        : '(${label.trim()})';
    return Uri.parse('geo:$point?q=$point${Uri.encodeComponent(name)}');
  }

  /// Abre la navegacion hacia el punto; devuelve si se pudo.
  static Future<bool> open(
    double latitude,
    double longitude, {
    String? label,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return false;
    }
    try {
      return await opener(uriFor(latitude, longitude, label: label));
    } catch (_) {
      return false;
    }
  }
}
