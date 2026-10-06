import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Clase de tamano de la ventana (por ancho en dp), como Material 3.
///
/// Se calcula con el ancho de la ventana actual, no el de la pantalla fisica:
/// cambia al girar, plegar o usar ventana dividida.
enum WindowSize {
  /// Menos de 600 dp: telefono en vertical.
  compact,

  /// De 600 a 839 dp: plegable abierto, tableta pequena, telefono en horizontal.
  medium,

  /// 840 dp o mas: tableta.
  expanded;

  static const mediumFrom = 600.0;
  static const expandedFrom = 840.0;

  static WindowSize fromWidth(double width) {
    if (width >= expandedFrom) return expanded;
    if (width >= mediumFrom) return medium;
    return compact;
  }
}

/// Medidas de la interfaz para el ancho actual.
///
/// El diseno base (mockups) es de 360 dp de ancho. Para conservar sus
/// proporciones:
///  - en compacta se mantienen las medidas del mockup (solo se reducen
///    levemente por debajo de 360 dp);
///  - en media y expandida todo crece en la misma proporcion ([scale]) y el
///    contenido se centra con un ancho maximo, en vez de estirarse.
@immutable
class Responsive {
  const Responsive._(this.size, this.width);

  factory Responsive.forWidth(double width) =>
      Responsive._(WindowSize.fromWidth(width), width);

  /// Ancho de la ventana en dp.
  final double width;
  final WindowSize size;

  /// Ancho de diseno de los mockups.
  static const baseWidth = 360.0;

  /// Ancho maximo de formularios, login y listas de datos.
  static const formMaxWidth = 560.0;

  /// Ancho maximo del login en dos paneles (marca y formulario).
  static const expandedAuthMaxWidth = 1100.0;

  bool get isCompact => size == WindowSize.compact;
  bool get isMedium => size == WindowSize.medium;
  bool get isExpanded => size == WindowSize.expanded;

  /// Factor de proporcion respecto del mockup.
  double get scale => switch (size) {
    WindowSize.compact => (width / baseWidth).clamp(0.88, 1.0),
    WindowSize.medium => 1.15,
    WindowSize.expanded => 1.3,
  };

  /// Escala una medida (dp, tamano de fuente, icono) del mockup.
  double s(double value) => value * scale;

  /// Columnas de la rejilla de modulos.
  int get moduleColumns => switch (size) {
    WindowSize.compact => 2,
    WindowSize.medium => 3,
    WindowSize.expanded => 4,
  };

  /// En media y expandida la navegacion pasa de barra inferior a riel lateral.
  bool get useRail => !isCompact;

  /// Ancho del riel lateral.
  double get railWidth => isExpanded ? 104 : 88;

  /// Ancho maximo del contenido de la pantalla de inicio.
  double get homeMaxWidth => switch (size) {
    WindowSize.compact => double.infinity,
    WindowSize.medium => 840,
    WindowSize.expanded => 1100,
  };

  /// Relleno lateral para centrar contenido de ancho maximo [maxWidth] dentro
  /// de [available] (por omision, el ancho de la ventana), con al menos
  /// [minGutter] a cada lado.
  EdgeInsets sidePadding({
    double maxWidth = formMaxWidth,
    required double minGutter,
    double? available,
  }) {
    final side = math.max(minGutter, ((available ?? width) - maxWidth) / 2);
    return EdgeInsets.symmetric(horizontal: side);
  }
}

extension ResponsiveContext on BuildContext {
  /// Medidas para el ancho actual de la ventana.
  Responsive get responsive =>
      Responsive.forWidth(MediaQuery.sizeOf(this).width);
}
