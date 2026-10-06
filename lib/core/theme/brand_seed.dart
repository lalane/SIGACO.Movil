import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

/// Colores que el administrador de una concesionaria puede cambiar (capa 2 de
/// la guia de marca, S11 seccion 6). Todo lo demas se deriva o es del sistema.
class BrandSeed extends Equatable {
  const BrandSeed({
    required this.primary,
    this.secondary,
    this.headerStart,
    this.headerEnd,
  });

  /// Color de accion: botones, seleccion, avatar.
  final Color primary;

  /// Fondo de la barra o riel de navegacion.
  final Color? secondary;

  /// Inicio del degradado de la cabecera (arriba).
  final Color? headerStart;

  /// Fin del degradado en los temas oscuros (abajo).
  final Color? headerEnd;

  /// `#RRGGBB` o `RRGGBB`. Cualquier otra cosa devuelve null.
  static Color? parseHex(String? value) {
    if (value == null) return null;
    final v = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v)) return null;
    return Color(0xFF000000 | int.parse(v, radix: 16));
  }

  /// Sin color de accion valido no hay marca; los opcionales invalidos se omiten.
  static BrandSeed? tryFromHex({
    String? primary,
    String? secondary,
    String? headerStart,
    String? headerEnd,
  }) {
    final p = parseHex(primary);
    if (p == null) return null;
    return BrandSeed(
      primary: p,
      secondary: parseHex(secondary),
      headerStart: parseHex(headerStart),
      headerEnd: parseHex(headerEnd),
    );
  }

  @override
  List<Object?> get props => [primary, secondary, headerStart, headerEnd];
}
