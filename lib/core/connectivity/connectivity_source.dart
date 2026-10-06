import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de la red del teléfono (WiFi, datos moviles...). Solo dice si hay una
/// red; que el servidor responda lo mide [ConnectivityCubit] con las peticiones.
abstract interface class ConnectivitySource {
  /// Hay alguna red disponible ahora.
  Future<bool> get isConnected;

  /// Emite cada vez que la red aparece o desaparece.
  Stream<bool> get changes;
}

/// Sin deteccion: siempre conectado. Se usa en pruebas y como valor por omision.
class AlwaysOnlineSource implements ConnectivitySource {
  const AlwaysOnlineSource();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class ConnectivityPlusSource implements ConnectivitySource {
  ConnectivityPlusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _connected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isConnected async =>
      _connected(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_connected).distinct();
}
