import 'package:equatable/equatable.dart';

/// Marca configurada por el administrador de una concesionaria. Los colores
/// llegan como texto `#RRGGBB`; la app los valida antes de usarlos (MAR-01 a 03).
class ConcessionBranding extends Equatable {
  const ConcessionBranding({
    required this.version,
    required this.primary,
    this.secondary,
    this.headerStart,
    this.headerEnd,
    this.logoLightUrl,
    this.logoDarkUrl,
  });

  /// Sube con cada cambio; la app solo reemplaza lo guardado si cambia.
  final int version;

  /// Color de accion.
  final String primary;
  final String? secondary;
  final String? headerStart;
  final String? headerEnd;

  /// Logo para fondos claros.
  final String? logoLightUrl;

  /// Logo para fondos oscuros.
  final String? logoDarkUrl;

  @override
  List<Object?> get props => [
    version,
    primary,
    secondary,
    headerStart,
    headerEnd,
    logoLightUrl,
    logoDarkUrl,
  ];
}
