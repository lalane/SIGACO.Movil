import 'package:equatable/equatable.dart';

/// Marca configurada por el administrador de una concesionaria. Los colores
/// llegan como texto `#RRGGBB`; la app los valida antes de usarlos (MAR-01 a 03).
///
/// Sale de `GET /api/app-configuration` (la configuracion vigente de la
/// concesion activa); ver `brandingFromConfiguration`.
class ConcessionBranding extends Equatable {
  const ConcessionBranding({
    required this.version,
    this.primary,
    this.secondary,
    this.headerStart,
    this.headerEnd,
    this.background,
    this.logoLightUrl,
    this.logoDarkUrl,
    this.logoReducedUrl,
    this.timezone,
  });

  /// Sube con cada cambio; la app solo reemplaza lo guardado si cambia.
  final int version;

  /// Color de accion. Null si la concesion no tiene color propio (se usan los
  /// de SIGACO) y solo hay logos.
  final String? primary;
  final String? secondary;
  final String? headerStart;
  final String? headerEnd;

  /// Fondo de la app en el portal web. La app movil no lo usa: el fondo lo
  /// resuelven los modos original, dia y noche del usuario.
  final String? background;

  /// Logo para fondos claros.
  final String? logoLightUrl;

  /// Logo para fondos oscuros.
  final String? logoDarkUrl;

  /// Variante reducida del logotipo (DTF Configuracion, US-07).
  final String? logoReducedUrl;

  /// Identificador IANA de la zona horaria de la concesion (por ejemplo
  /// `America/Sao_Paulo`). Las fechas del negocio se muestran en esta zona.
  final String? timezone;

  @override
  List<Object?> get props => [
    version,
    primary,
    secondary,
    headerStart,
    headerEnd,
    background,
    logoLightUrl,
    logoDarkUrl,
    logoReducedUrl,
    timezone,
  ];
}
