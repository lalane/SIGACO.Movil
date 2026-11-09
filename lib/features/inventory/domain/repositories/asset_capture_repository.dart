import '../entities/asset_capture.dart';
import '../entities/asset_template.dart';

/// Por que no se pudo preparar o guardar un alta.
enum AssetCaptureError {
  /// Sin conexion y sin nada guardado con que seguir.
  network,

  /// El perfil no puede dar de alta activos.
  permissionDenied,

  /// El tipo de activo no puede nacer desde la app.
  channelNotAllowed,

  /// El servidor rechazo los datos (ver [AssetCaptureException.fieldErrors]).
  validation,

  /// El tipo no tiene una ficha vigente.
  noTemplate,

  /// El servidor todavia no publica el alta en esta concesion.
  notAvailable,

  server,
}

class AssetCaptureException implements Exception {
  const AssetCaptureException(
    this.error, {
    this.message,
    this.fieldErrors = const {},
  });

  final AssetCaptureError error;

  /// Lo que dijo el servidor, si lo dijo.
  final String? message;

  /// Errores por campo del servidor (`attributes.longitud_m`, `kmStart`...).
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => 'AssetCaptureException($error, $message)';
}

/// El alta de activos en campo (`/api/assets`). Lanza [AssetCaptureException].
abstract interface class AssetCaptureRepository {
  /// Los tipos que pueden nacer en la app (canal MOBILE), activos y en orden.
  Future<List<AssetTypeOption>> types();

  /// La ficha vigente del tipo, con la que se arma el formulario.
  Future<AssetTemplate> template(String typeCode);

  /// Los valores de los catalogos genericos, por codigo de catalogo, para los
  /// campos CATALOG. Vacio si no se pudieron traer.
  Future<Map<String, List<CatalogOption>>> catalogs();

  /// Donde cae el punto sobre la carretera. Nunca lanza: sin red o sin eje
  /// devuelve [RoadPlacement.unknown].
  Future<RoadPlacement> locate(double longitude, double latitude);

  /// Da de alta el activo y sube sus fotos. Sin conexion queda en la cola del
  /// telefono ([CapturedAsset.queued]) y sale al volver la senal.
  Future<CapturedAsset> create(NewAsset draft);
}

/// La posicion del telefono para el alta. Null si no hay (GPS apagado, sin
/// permiso o ubicacion simulada). Nunca lanza.
abstract interface class AssetPositionSource {
  Future<AssetPosition?> current();
}

/// Sin GPS (pruebas y entornos sin plugin).
class NoAssetPositionSource implements AssetPositionSource {
  const NoAssetPositionSource();

  @override
  Future<AssetPosition?> current() async => null;
}
