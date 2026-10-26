import 'package:flutter/foundation.dart';

/// El modo de datos de ejemplo: con el interruptor de la cuenta, todos los
/// modulos muestran datos inventados (sin llamar al servidor) para ver como esta
/// armada la app. Vive solo en memoria: al cerrar sesion o abrir la app otra vez
/// se vuelve a los datos reales, para que nadie lo deje encendido sin querer.
///
/// No es un `Listenable` a proposito: se entrega con un `RepositoryProvider` y el
/// proveedor rechaza a los que lo son. Quien quiera enterarse del cambio usa
/// [addListener] o [listenable].
class DemoMode {
  DemoMode();

  final _value = ValueNotifier<bool>(false);

  bool get on => _value.value;

  /// Para `ListenableBuilder`.
  Listenable get listenable => _value;

  void set(bool value) => _value.value = value;

  void addListener(VoidCallback listener) => _value.addListener(listener);

  void removeListener(VoidCallback listener) => _value.removeListener(listener);
}
