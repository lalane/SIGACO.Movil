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

  /// Muestra el gestor documental en el menu. Apagado por omision: el
  /// Business Blueprint no lo incluye entre los modulos moviles. Se enciende
  /// con `--dart-define=DOCUMENTS_MODULE=true`.
  static const documentsModule = bool.fromEnvironment('DOCUMENTS_MODULE');

  /// Gestor documental con documentos de ejemplo, mientras el backend no
  /// publique sus endpoints: `--dart-define=SAMPLE_DOCUMENTS=true`. Tambien
  /// agrega el modulo al menu, que solo se ve asi en esa prueba.
  static const sampleDocuments = bool.fromEnvironment('SAMPLE_DOCUMENTS');

  /// Mapa con pines de ejemplo, para probar sin servidor. Tambien agrega el
  /// modulo al menu. **Por omision esta apagado: la app habla con el servidor
  /// real** (activos, tickets y obras). Se enciende con
  /// `--dart-define=SAMPLE_MAP=true`.
  static const sampleMap = bool.fromEnvironment('SAMPLE_MAP');

  /// Tickets de ejemplo, para probar sin servidor. Tambien agrega el modulo al
  /// menu. Igual que [sampleMap]: apagado por omision (servidor real). Se
  /// enciende con `--dart-define=SAMPLE_TICKETS=true`.
  static const sampleTickets = bool.fromEnvironment('SAMPLE_TICKETS');

  /// Accidentes de ejemplo, mientras el backend no publique sus endpoints.
  /// Igual que [sampleTickets]. `--dart-define=SAMPLE_ACCIDENTS=true|false`.
  static const sampleAccidents = bool.fromEnvironment('SAMPLE_ACCIDENTS');

  /// Mantenimientos de ejemplo, mientras el backend no publique sus endpoints.
  /// Igual que [sampleTickets]. `--dart-define=SAMPLE_MAINTENANCE=true|false`.
  static const sampleMaintenance = bool.fromEnvironment('SAMPLE_MAINTENANCE');

  /// Inventario de ejemplo, mientras el backend no publique sus endpoints.
  /// Igual que [sampleTickets]. `--dart-define=SAMPLE_INVENTORY=true|false`.
  static const sampleInventory = bool.fromEnvironment('SAMPLE_INVENTORY');

  /// Obras de ejemplo, mientras el backend no publique sus endpoints. Igual que
  /// [sampleTickets]. `--dart-define=SAMPLE_WORKS=true|false`.
  static const sampleWorks = bool.fromEnvironment('SAMPLE_WORKS');

  /// Alertas de ejemplo, mientras el backend no publique las de la persona.
  /// Igual que [sampleTickets]. `--dart-define=SAMPLE_ALERTS=true|false`.
  static const sampleAlerts = bool.fromEnvironment('SAMPLE_ALERTS');

  /// Inspecciones de ejemplo, mientras el backend no publique sus endpoints.
  /// Igual que [sampleTickets]. `--dart-define=SAMPLE_INSPECTIONS=true|false`.
  static const sampleInspections = bool.fromEnvironment('SAMPLE_INSPECTIONS');

  /// Con [sampleMap], los pines de ejemplo se reparten alrededor de donde esta
  /// el telefono (para probar "ubicarme" y los cercanos). Si no hay ubicacion,
  /// o con `--dart-define=SAMPLE_MAP_NEAR_ME=false`, caen sobre la BR-381.
  static const sampleMapNearMe = bool.fromEnvironment(
    'SAMPLE_MAP_NEAR_ME',
    defaultValue: true,
  );

  /// El mapa de la app es de MapLibre. Con `--dart-define=MAP_LEGACY=true` se
  /// vuelve al de `flutter_map` (solo de respaldo mientras se estabiliza el
  /// nuevo): ese no dibuja teselas vectoriales, asi que necesita [mapTileUrl].
  static const mapLegacy = bool.fromEnvironment('MAP_LEGACY');

  /// Estilo de MapLibre del mapa base: por omision, Liberty de OpenFreeMap
  /// (teselas vectoriales abiertas, gratuitas y de uso comercial, con
  /// atribucion). Lo normal es que el servidor indique el de cada concesion
  /// (`mapBase` en la configuracion); este es el de respaldo.
  /// `--dart-define=MAP_STYLE_URL=https://...`; vacio = sin mapa base.
  static const mapStyleUrl = String.fromEnvironment(
    'MAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );

  /// Atribucion del estilo de [mapStyleUrl].
  static const mapStyleAttribution = String.fromEnvironment(
    'MAP_STYLE_ATTRIBUTION',
    defaultValue: 'OpenFreeMap © OpenMapTiles Data from OpenStreetMap',
  );

  /// A donde lleva tocar la atribucion del estilo.
  static const mapStyleAttributionUrl = String.fromEnvironment(
    'MAP_STYLE_ATTRIBUTION_URL',
    defaultValue: 'https://openfreemap.org',
  );

  /// Plantilla de teselas de imagen del mapa base, para un proveedor que no
  /// entrega un estilo: `--dart-define=MAP_TILE_URL=https://tiles.example.com/{z}/{x}/{y}.png`.
  /// Si se define, manda sobre [mapStyleUrl]. Ya no hay un valor por omision: el
  /// servidor publico de OpenStreetMap no se usa en produccion.
  static const mapTileUrl = String.fromEnvironment('MAP_TILE_URL');

  /// Atribucion que se muestra sobre el mapa con [mapTileUrl].
  static const mapTileAttribution = String.fromEnvironment(
    'MAP_TILE_ATTRIBUTION',
    defaultValue: '© OpenStreetMap contributors',
  );

  /// A donde lleva tocar la atribucion.
  static const mapTileAttributionUrl = String.fromEnvironment(
    'MAP_TILE_ATTRIBUTION_URL',
    defaultValue: 'https://www.openstreetmap.org/copyright',
  );

  /// El backend usa este valor para no ofrecer Configuracion en movil (RN-M02-02).
  static const clientType = 'MOBILE';
}
