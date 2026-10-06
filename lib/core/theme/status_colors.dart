import 'package:flutter/painting.dart';

/// Colores de estatus: son del sistema y la concesionaria no los cambia (COL-05).
/// Un rojo significa lo mismo en todas las concesiones.
abstract final class StatusColors {
  /// Abierto, critico, vencido.
  static const open = Color(0xFFF87171);

  /// Atendido, alerta, por vencer.
  static const attended = Color(0xFFFBBF24);

  /// Cerrado, correcto.
  static const closed = Color(0xFF4ADE80);

  static const all = [open, attended, closed];
}
