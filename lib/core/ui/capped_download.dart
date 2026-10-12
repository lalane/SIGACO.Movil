import 'dart:io';
import 'dart:typed_data';

/// Tope para un archivo de marca (logo SVG): un tercero lo elige, no debe poder
/// agotar la memoria del telefono.
const logoMaxBytes = 1024 * 1024;

/// Junta los bloques de [chunks] hasta [maxBytes]. Devuelve null si el total
/// los supera, sin seguir leyendo.
Future<Uint8List?> readCapped(
  Stream<List<int>> chunks, {
  int maxBytes = logoMaxBytes,
}) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in chunks) {
    builder.add(chunk);
    if (builder.length > maxBytes) return null;
  }
  return builder.takeBytes();
}

/// Descarga [url] (solo estado 200, con tiempo y tamano maximos). Devuelve null
/// si algo falla: sin conexion, error del servidor o archivo demasiado grande.
Future<Uint8List?> downloadCapped(
  String url, {
  int maxBytes = logoMaxBytes,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != 200) return null;
    return await readCapped(response, maxBytes: maxBytes).timeout(timeout);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
