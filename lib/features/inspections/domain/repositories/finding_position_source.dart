import '../entities/inspection.dart';

/// La posicion del telefono al capturar un hallazgo. Devuelve null si no hay
/// (GPS apagado, sin permiso o ubicacion simulada): el hallazgo se guarda igual
/// y se avisa que va sin posicion. Nunca lanza.
abstract interface class FindingPositionSource {
  Future<FindingPosition?> current();
}

/// Sin GPS (pruebas y entornos sin plugin): nunca hay posicion.
class NoFindingPositionSource implements FindingPositionSource {
  const NoFindingPositionSource();

  @override
  Future<FindingPosition?> current() async => null;
}
