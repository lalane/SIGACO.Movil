abstract final class AppConfig {
  /// Se puede cambiar por ambiente: --dart-define=API_BASE_URL=https://...
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sigaco-api-dev.azurewebsites.net',
  );

  /// Marca de prueba, mientras el servidor no entregue la de la concesion:
  /// `--dart-define=BRAND_PRIMARY=#0EA5E9` (y, opcionales, BRAND_SECONDARY,
  /// BRAND_HEADER_START, BRAND_HEADER_END, BRAND_LOGO_LIGHT, BRAND_LOGO_DARK).
  static const demoBrandPrimary = String.fromEnvironment('BRAND_PRIMARY');
  static const demoBrandSecondary = String.fromEnvironment('BRAND_SECONDARY');
  static const demoBrandHeaderStart = String.fromEnvironment(
    'BRAND_HEADER_START',
  );
  static const demoBrandHeaderEnd = String.fromEnvironment('BRAND_HEADER_END');
  static const demoBrandLogoLight = String.fromEnvironment('BRAND_LOGO_LIGHT');
  static const demoBrandLogoDark = String.fromEnvironment('BRAND_LOGO_DARK');

  /// Gestor documental con documentos de ejemplo, mientras el backend no
  /// publique sus endpoints: `--dart-define=SAMPLE_DOCUMENTS=true`. Tambien
  /// agrega el modulo al menu, que solo se ve asi en esa prueba.
  static const sampleDocuments = bool.fromEnvironment('SAMPLE_DOCUMENTS');

  /// El backend usa este valor para no ofrecer Configuracion en movil (RN-M02-02).
  static const clientType = 'MOBILE';
}
