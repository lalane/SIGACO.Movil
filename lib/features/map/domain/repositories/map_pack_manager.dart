import 'dart:typed_data';

import '../entities/map_pack.dart';

/// Por que fallo algo de los paquetes de mapa.
enum MapPackError {
  /// Sin conexion o se corto la descarga (se puede reanudar).
  network,

  /// El perfil no puede descargar mapas.
  permissionDenied,

  /// El servidor todavia no publica paquetes para esta concesion.
  notAvailable,

  /// El paquete ya no existe en el servidor.
  notFound,

  /// Error del servidor.
  server,

  /// Lo descargado no coincide con el tamano o la huella: se descarta.
  corrupt,

  /// No hay espacio en el telefono.
  noSpace,
}

class MapPackException implements Exception {
  const MapPackException(this.error);

  final MapPackError error;

  @override
  String toString() => 'MapPackException($error)';
}

/// Las teselas de un paquete instalado. El que lo implementa abre el archivo
/// (un MBTiles) y lo cierra con [close].
abstract interface class TileReader {
  /// La tesela (imagen PNG, JPEG o WebP) en el esquema XYZ de los mapas web, o
  /// `null` si el paquete no la trae.
  Future<Uint8List?> tile(int z, int x, int y);

  Future<void> close();
}

/// Los paquetes de mapa para trabajar sin conexion: que hay en el servidor,
/// que hay en el telefono, bajarlos, borrarlos y leer sus teselas.
abstract interface class MapPackManager {
  /// Los paquetes que publica el servidor para la concesion activa. Lanza
  /// [MapPackException].
  Future<List<MapPack>> available();

  /// Lo que hay guardado en el telefono para la persona y concesion activas.
  Future<List<InstalledPack>> installed();

  /// Baja el paquete, verifica su huella e instala. Si una descarga anterior se
  /// corto, sigue donde quedo. Cancelar la suscripcion pausa la descarga (lo ya
  /// bajado se conserva). Emite errores [MapPackException].
  Stream<PackProgress> download(MapPack pack);

  /// Descarta lo bajado a medias de ese paquete.
  Future<void> discardPartial(String packId);

  /// Cuanto se lleva bajado de un paquete a medias (0 si nada).
  Future<int> partialBytes(String packId);

  /// Borra el paquete instalado.
  Future<void> remove(String packId);

  /// Abre el paquete instalado que se usara de mapa base, o `null` si no hay.
  Future<TileReader?> openActive();
}
