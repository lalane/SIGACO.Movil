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

  /// PRUEBA DE CONCEPTO de MapLibre (rama `spike/maplibre`): con
  /// `--dart-define=MAP_SPIKE=true` la ruta del mapa abre la pantalla de prueba.
  static const mapSpike = bool.fromEnvironment('MAP_SPIKE');

  /// Estilo de MapLibre de la prueba: por omision, Liberty de OpenFreeMap.
  static const mapStyleUrl = String.fromEnvironment(
    'MAP_STYLE_URL',
    defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
  );

  /// Teselas estandar de OpenStreetMap: el proveedor de la app mientras no haya
  /// teselas propias. Su politica de uso permite mostrar el mapa a quien usa la
  /// app, pero no la precarga ni el uso masivo ni el uso sin conexion: para
  /// produccion hay que apuntar a teselas propias con [mapTileUrl] y usar los
  /// paquetes por concesion para trabajar sin red.
  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Plantilla de teselas del mapa base. Por omision, OpenStreetMap; para otro
  /// proveedor: `--dart-define=MAP_TILE_URL=https://tiles.example.com/{z}/{x}/{y}.png`.
  /// Definida y vacia (`MAP_TILE_URL=`) = sin mapa base, solo pines.
  static const mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: osmTileUrl,
  );

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
