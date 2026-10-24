import 'package:flutter/foundation.dart';

/// El modo de datos de ejemplo: con el interruptor de la cuenta, todos los
/// modulos muestran datos inventados (sin llamar al servidor) para ver como esta
/// armada la app. Vive solo en memoria: al cerrar sesion o abrir la app otra vez
/// se vuelve a los datos reales, para que nadie lo deje encendido sin querer.
class DemoMode extends ChangeNotifier {
  DemoMode();

  bool _on = false;

  bool get on => _on;

  void set(bool value) {
    if (value == _on) return;
    _on = value;
    notifyListeners();
  }
}
