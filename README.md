# SIGACO Móvil

Aplicación **Android** de SIGACO (Sistema de Gestión de Activos de Concesión). Flutter + Dart, SDK fijado con FVM.

- Backend: `SIGACO.Api` (DEV: `https://sigaco-api-dev.azurewebsites.net`, Swagger en `/swagger`).
- Alcance funcional: módulos APP-MOB-01 a 07 del BBP §7 (acceso, indicadores, tickets, dashboard y mapa, accidentes, inventario, mantenimiento). M02 (gestión de usuarios) **no** existe en móvil (RN-M02-02).
- Diseño de referencia: diseño v2 (Original / Día / Noche).

## Empezar

```bash
fvm install            # lee .fvmrc (Flutter 3.44.8)
fvm flutter pub get
fvm flutter run        # o F5 en VS Code
fvm flutter analyze && fvm flutter test
```

Otro ambiente de API: `--dart-define=API_BASE_URL=https://...`.
Android mínimo **10 (API 29)**, target 36 (propuesta pendiente de confirmar por TEKIA, DTF RNF-MOB-01).

## Arquitectura

**Feature-first + Clean Architecture ligera + BLoC.** Cada módulo funcional es una carpeta en `lib/features/`
con tres capas:

```
lib/
├── main.dart                 Arranque: observador de trazabilidad + dependencias
├── app/                      Composición: app, router, dependencias, shell (home)
├── core/                     Compartido y sin lógica de negocio
│   ├── api/                  Cliente HTTP (dio), errores, X-Correlation-Id
│   ├── config/  theme/  ui/  settings/  branding/  observability/
├── features/<modulo>/
│   ├── domain/               Dart puro: entidades + interfaces de repositorio
│   ├── data/                 Implementaciones (API, almacenamiento) + mappers JSON
│   └── presentation/         bloc/ (eventos, estados, lógica) + pages/ + widgets/
└── l10n/                     Textos es / pt (.arb)
```

### Reglas (las hace cumplir `test/architecture_test.dart`)

1. Un módulo **no importa** a otro módulo. Lo compartido va a `core/`; la composición entre módulos, a `app/`.
2. `core/` no depende de `features/` ni de `app/`.
3. `domain/` es Dart puro: sin Flutter, sin HTTP, sin `data/` ni `presentation/`.
4. `data/` no depende de `presentation/`; `presentation/` no importa `data/` (las implementaciones se inyectan en `app/dependencies.dart`).
5. Un caso de uso (`domain/usecases/`) solo se agrega donde haya lógica de negocio real (por ejemplo, sincronización o reglas de ticket); no por defecto.

### Crear un módulo nuevo

Copiar la estructura de `features/auth/`: `domain` (entidades + interfaz) → `data` (implementación + mapper) → `presentation/bloc` (eventos, estado, bloc) → `pages`. Registrar la implementación en `app/dependencies.dart`, el Bloc en `app/app.dart` y las rutas en `app/router.dart`. Agregar pruebas del Bloc con `bloc_test` y fakes en `test/support/`.

## Restablecer la contraseña (FEAT-M01-03)

El enlace del correo se abre en el **navegador**; la contraseña nueva se define en el portal web y de ahí se vuelve a la app:

1. En la app, «¿Olvidaste tu contraseña?» pide el enlace (`POST /api/auth/password/recovery`, respuesta uniforme). Si la solicitud no llega (sin red o error 5xx) no se dice que se envió.
2. El correo lleva a `{App:PortalUrl}{App:PasswordSetupPath}?token=…` (`/establecer-contrasena`; el portal tiene esa ruta y `/recuperar-acceso/confirmar`). El portal llama a `POST /api/auth/password/reset`, que cierra todas las sesiones de la cuenta.
3. En un navegador Android, el portal ofrece «Volver a la aplicación», que abre `sigaco://app/login?reset=ok` (esquema registrado en `AndroidManifest.xml`; no lleva ningún secreto).
4. La app muestra «Contraseña actualizada», **borra la contraseña guardada** (recordar y biometría, que ya no sirven) y deja el correo. Aviso: otra app podría abrir ese enlace, y el efecto es solo olvidar la contraseña guardada.

Configuración necesaria en cada ambiente del backend: `App__PortalUrl` (por omisión `http://localhost:5173`). Pendiente: usar App Links (`https://`) en lugar del esquema propio, para que ninguna otra app pueda registrarlo.

## Perfil: seguridad y preferencias

La pantalla de cuenta (avatar del inicio) concentra:

- **Seguridad:** cambiar contraseña, verificación en dos pasos y acceso con biometría.
- **Preferencias:** idioma, apariencia (Original, Día, Noche) y, si la concesión trae colores propios, usar los de la concesión o los de SIGACO. Se guardan en el dispositivo.
- **Idioma y apariencia solo se cambian aquí**: no hay selectores en el login ni en las demás pantallas. Antes de iniciar sesión se usa el idioma del teléfono (es o pt; si no, es) y la última apariencia guardada.
- **Verificación en dos pasos:** la activa o desactiva un administrador (M02-05; el backend responde 409 `MFA_NOT_REQUIRED` si no está habilitada). El perfil la muestra como activa si el acceso pidió el código o el enrolamiento (el perfil del servidor no informa el estado) y permite generar una clave nueva, por ejemplo al cambiar de teléfono. Si se genera y no se confirma con un código, la cuenta queda pendiente y pedirá configurarla de nuevo al iniciar sesión.

## Diseño responsivo

Tres clases de tamaño según el **ancho de la ventana** en dp (`core/responsive/responsive.dart`):

| Clase | Ancho | Inicio | Navegación | Login |
|---|---|---|---|---|
| Compacta | menos de 600 dp | 2 columnas | barra inferior | una columna |
| Media | 600 a 839 dp | 3 columnas | riel lateral | una columna centrada (máx. 560 dp) |
| Expandida | 840 dp o más | 4 columnas | riel lateral | dos paneles: marca y formulario |

- **Proporción:** el mockup mide 360 dp. En compacta las medidas no cambian desde 360 dp; en media todo crece ×1,15 y en expandida ×1,3, en la misma proporción. El contenido se centra con ancho máximo, no se estira.
- **Cómo usarlo:** `final r = context.responsive;` y `r.s(16)` para cualquier medida o tamaño de fuente del mockup; `r.isCompact`, `r.moduleColumns`, `r.sidePadding(...)` para el diseño. Prohibido fijar anchos o alturas que dependan del texto.
- **Texto del sistema:** soporta de 85 % a 200 %. El wordmark SIGACO no escala con el texto (es un logo).
- **Pruebas:** `test/core/responsive_test.dart` recorre 7 tamaños de ventana × 3 escalas de texto sin desbordes y verifica la estructura de cada clase. Las pruebas que dependen del diseño fijan su ventana con `useSurface` (`test/support/surface.dart`); la superficie por omisión de `flutter test` es de 800×600 dp (clase media).
- **Capturas:** `fvm flutter test tool/capture_responsive_test.dart` genera las vistas clave en compacta, media, expandida y teléfono en horizontal.
- Reglas completas: documento S11 (`Seguimiento/SIGACO`).

## Colores y logo por concesionaria

El administrador de la concesionaria cambia pocos colores; la app deriva el resto y garantiza que todo se lea (S11, sección 6).

- **Qué cambia (capa 2):** color de acción (`primary`), cabecera (`headerStart`, `headerEnd`), navegación (`secondary`) y los logos (`logoLightUrl` para fondo claro, `logoDarkUrl` para fondo oscuro, `logoReducedUrl` reducido para la cabecera). Llegan además `background` (fondo del portal web; la app no lo usa, el fondo lo resuelven los modos del usuario) y `timezone` (ver abajo). Los colores de estatus, el error y las superficies neutras no cambian (`StatusColors`).
- **Qué se deriva (capa 3):** `SigacoPalette.withBrand(seed)` calcula el texto sobre el color de acción (`onAccent`) y tres variantes del acento: `accentOnDark` (texto sobre fondo oscuro, 4,5:1), `accentOnLight` (texto sobre fondo claro, 4,5:1) y `accentIconOnLight` (iconos sobre fondo claro, 3:1). **Regla de uso:** sobre una superficie oscura, `p.accentOnDark`; sobre las tarjetas blancas, `p.accentIconOnLight`; sobre el fondo inferior del tema, `p.accentOnBottom`; `p.accent` solo para rellenos (botones, avatar, interruptor). Un color de acento como texto sobre un fondo cualquiera es un error de revisión.
- **Validaciones (`BrandRules`):** se rechaza el color de acción si ni blanco ni el azul de marca se leen encima, o si se parece a un estatus (ΔE < 35); una cabecera o navegación que no deja leer el texto se descarta sola y queda la de SIGACO. Con una marca rechazada la app usa los colores de SIGACO.
- **Cuándo se aplica:** solo con una concesión activa; el login siempre usa SIGACO. Al cerrar sesión o cambiar de concesión se descarta (`BrandingCubit`, `SessionLifecycle`). El usuario puede elegir «Colores de SIGACO» en su perfil, sección Preferencias (se recuerda). La configuración de la concesión (colores, logo, zona horaria) se hace solo en el portal web (DTF Configuración, D1 y D4); la app no tiene pantallas para editarla. El logo de la concesión va arriba de SIGACO en la cabecera del inicio.
- **De dónde sale:** `GET /api/app-configuration` (la configuración vigente de la concesión activa, publicada el 15/10/2026 en SIGACO.Api). Antes de bajarla la app consulta `GET /api/app-configuration/version` y, si es la que ya tiene, no descarga nada (P-09). Se guarda por concesión; sin conexión se usa lo guardado. Un 404 o una respuesta sin colores propios ni logos significan «sin marca propia». **Cómo se traduce** (`brandingFromConfiguration`): color de acción = `buttonColor` (o `primaryColor` si falta); fondo de la barra de navegación = `menuBackgroundColor`; inicio del degradado de la cabecera = `headerColor`; logo para fondo claro y oscuro = `logos.principal` (el servidor no distingue); logo reducido = `logos.reduced`; zona = `timeZone`; versión = `configurationVersion`. **Colores provisionales:** el servidor llena lo que una concesión no personalizó con los de SIGACO (`#1F4E79`, `#F28C28`, `#0D1B2A`, `#424241`); la app los toma como «sin color propio» (`serverDefaultColors`) para no repintar su diseño hasta que TEKIA entregue la paleta. **Logos:** llegan como ruta de la API (`/api/configuration-logos/{id}`, sin extensión y con sesión): se descargan con el token (`ApiClient.downloadFile`) y el SVG se reconoce por su contenido. Quedan sin usar `secondaryColor`, `primaryTextColor` y el logo documental.
- **Refresco con la sesión abierta (DEV-MOB-088):** `BrandingCubit.refresh` vuelve a consultar la versión al volver a la app (como máximo cada minuto, `brandingRefreshGap`) y al recuperar la conexión (siempre), sin vaciar la marca que se ve; solo cambia la pantalla si la versión es otra. Un fallo conserva lo que había. Cuándo aplicar el cambio en el móvil sigue pendiente de TEKIA (P-09).
- **Zona horaria (DEV-MOB-057):** `timezone` es un identificador IANA. `ConcessionZone` (`core/time`, paquete `timezone`) convierte un instante UTC a la zona de la concesión; `ConcessionZoneCubit` la deja disponible a cualquier módulo (la compone `SessionLifecycle`). Para mostrar una fecha del negocio: `inConcessionZone(utc, zone)`; sin zona se usa la del teléfono como respaldo temporal, nunca UTC. La cuenta muestra la zona y su desfase. Las fechas propias del teléfono (la última conexión) siguen en la hora del teléfono. La marca manda cuando trae zona; si no, `ApiConcessionZoneSource` pide la que el backend guarda por concesión (`GET /api/document-settings/concessions/{id}/time-zone`) al iniciar sesión, al cambiar de concesión y al recuperar la conexión (`ConcessionZoneCubit.setFallback`). Sin ninguna, la del teléfono. Las fechas del gestor documental y del centro de sincronización ya salen en esa zona.
- **Probar sin backend:** `--dart-define=BRAND_PRIMARY=#0EA5E9` (opcionales `BRAND_HEADER_START`, `BRAND_HEADER_END`, `BRAND_SECONDARY`, `BRAND_LOGO_LIGHT`, `BRAND_LOGO_DARK`). Hay configuraciones en `.vscode/launch.json`.
- **Pruebas:** `test/core/brand_rules_test.dart` (reglas y contraste de los derivados), `test/features/branding/` (repositorio, cubit y flujo completo).
- **Capturas:** `fvm flutter test tool/capture_brand_test.dart` (menú y cuenta con 7 marcas de ejemplo).
- **Formatos de logo:** PNG, JPG y WebP (`Image.memory`) y SVG (`flutter_svg`). Es SVG si la ruta de la URL termina en `.svg` (la consulta se ignora, así que valen las URL firmadas). Los bytes salen de `LogoStore`: `DiskLogoStore` los descarga con `downloadCapped` (solo estado 200, hasta 1 MB y 15 s) y los guarda en disco (`getApplicationSupportDirectory()/logos`, un archivo por URL y versión de la marca, máximo 12), así que el logo aparece también sin conexión (DEV-MOB-059). El SVG solo se dibuja si el contenido contiene `<svg`; si falla, la app queda sin logo, sin error. `flutter_svg` no ejecuta scripts ni carga recursos externos, pero no soporta todo SVG (filtros, fuentes incrustadas): hay que probar con los logos reales de cada concesión.
- **Logo reducido (DEV-MOB-089):** la cabecera del inicio prefiere `logoReducedUrl` si existe y, si no, el logo del fondo (claro u oscuro). Se asume que la reducida sirve sobre el fondo oscuro de la cabecera; hay que confirmarlo con el diseño.
- **Sin Configuración (DEV-MOB-087):** ningún módulo móvil se habilita con códigos de Configuración, usuarios, roles o permisos (`navigation_test` y `branding_refresh_flow_test`).
- **Pendiente:** el endpoint del backend, y limpiar los logos de una concesión anterior cuando exista la base local (DEV-MOB-045).

## Accesos durante la sesión (M01-05, M02-02-04)

El menú no se queda fijo desde el inicio de sesión: un administrador puede quitar o dar accesos mientras la app sigue abierta.

- **Cuándo se vuelve a consultar** (`NavigationRefreshed`): al volver a la app con la sesión abierta (mínimo 30 s entre consultas, `AppDependencies.accessRefreshGap`), al jalar hacia abajo en el inicio (siempre), y cuando el servidor niega una acción con 403 (`ApiClient.accessDenied`, mínimo 5 s; los 403 que piden MFA, cambio de contraseña o concesión no cuentan, ni la propia consulta del menú).
- **Sin parpadeo:** el menú anterior sigue a la vista mientras se consulta (`NavigationState.refreshing`). Sin conexión o con error del servidor se conserva; si cambió, se avisa con un aviso breve (`accessChanges`). Una respuesta tardía de otra sesión o concesión se descarta.
- **Estados de acceso** (`core/ui/access_state_view.dart`, MQ-MOB-08): «Sin permiso» (403 al cargar el menú o perfil sin módulos) y «No pudimos verificar tus accesos» (error del servidor). Cualquier módulo nuevo debe usar `AccessStateView` en lugar de armar su propia pantalla; nunca muestran códigos ni mensajes técnicos.
- **Pruebas:** `test/features/navigation/access_refresh_test.dart`.

## Sin conexión y datos del teléfono

- **Aviso «Sin conexión» (MQ-MOB-10):** barra discreta y persistente sobre todas las pantallas con sesión abierta (`app/shell/connection_banner.dart`). Empuja el contenido hacia abajo, no lo tapa. Al volver la conexión muestra «Conexión restablecida» unos segundos.
- **De dónde sale** (`core/connectivity`): `ConnectivityCubit` une la red del teléfono (`connectivity_plus`) con las respuestas del servidor (`ApiClient.reachability`: una respuesta, aunque sea de error, prueba que hay conexión; un fallo de red sin respuesta, no). Al volver la red se da por buena hasta la siguiente petición.
- **Al volver la conexión** se actualizan los accesos; mientras no hay conexión se vuelve a consultar el menú cada 20 s como sonda.
- **Cuenta:** muestra el dispositivo (modelo y versión de Android, solo local: no se envía a ningún servidor) y la última conexión con el servidor. Cuando exista la sincronización sin conexión, esa fila pasará a ser la última sincronización.
- **Pruebas:** `test/core/connectivity_test.dart`, `test/features/navigation/connection_flow_test.dart`.

## Operaciones sin conexión (EP-TR-MOB, DEV-MOB-060 a 067)

Base local, cola y sincronizador que usarán los módulos que capturan datos en campo (Gestor documental: carga y firma; después tickets, inspecciones...). Está en `core/offline` y no depende de ninguna entidad: cada tipo de registro solo aporta su cliente (`SyncRemote`).

- **Base local (060):** `OfflineDatabase` (`sqflite`, SQLite del teléfono; en pruebas `sqflite_common_ffi`). Esquema versionado con `PRAGMA user_version`: `pending_operation` (espejo de `sync.operacion` de la base del servidor), `sync_conflict` y `sync_meta`.
- **Aislamiento (028, 053):** todo lleva persona y concesión (`OfflineScope`) y toda consulta filtra por ambas. Otra persona u otra concesión no ve ni envía lo ajeno; una clave de idempotencia de otro alcance no se puede reusar.
- **Cola (062):** `OperationQueue.enqueue` guarda la operación con su clave de idempotencia (UUID v4 generado en el teléfono), la hora de captura en UTC y su estado: `pending`, `sending`, `accepted`, `rejected`, `conflict`. `update` y `delete` exigen `recordId` y `baseVersion` (igual que la restricción de la base). Encolar la misma clave dos veces no duplica. Al arrancar, lo que quedó `sending` vuelve a la cola (es seguro por la clave). Las aceptadas se borran a los 7 días.
- **Sincronizador (064):** `SyncEngine.run` envía en el orden de captura, una pasada a la vez por alcance. Un rechazo no detiene a los demás (varios archivos, DEV-MOB-083); lo siguiente sobre el mismo registro espera si una operación quedó rechazada, en conflicto o esperando reintento. Un fallo de red detiene la pasada, devuelve la operación a la cola y espera 5 s, 10 s, 20 s... hasta 15 min. Un conflicto nunca se aplica en silencio (DEV-MOB-085). Antes de enviar corre `SyncPreflight`: `SyncRevalidation` (`app/sync_revalidation.dart`, DEV-MOB-094 y 095) consulta el menú; si el servidor no confirma la sesión y el contexto, retiene la pasada y conserva todo; la operación cuyo permiso ya no existe (`documento` pide Ver y Cargar; `documento_firma`, Ver y Firmar) queda rechazada con un motivo claro y no se envía (CA-HU-MOB-03-02-04). **Es una propuesta de la regla RN-M01-38, que sigue pendiente con TEKIA.** El servidor igual vuelve a validar cada operación.
- **Estado (063):** `SyncCubit` expone lo pendiente, lo rechazado, los conflictos, la última sincronización y la hora del siguiente reintento. Envía al recuperar la conexión, al volver a la app (mínimo 30 s entre pasadas), cuando la persona lo pide, tras encolar (`syncNow`) y a la hora del reintento; nunca por el simple cambio de la cola (se lanzaría sola sin fin). `SessionLifecycle` fija el alcance al iniciar sesión o cambiar de concesión y lo suelta al cerrarla.
- **Pantallas (063, 065, 066):** un aviso en el inicio con lo pendiente o lo que pide decisión; el centro de sincronización (`/sync`, también desde la cuenta) con lo pendiente, lo rechazado y los conflictos, y `/sync/conflict/:id`, que muestra lo capturado junto a lo del servidor (marcando lo que cambió) y deja quedarse con el servidor o mantener lo propio. Las fechas salen en la zona de la concesión. Son genéricas: faltan las maquetas MQ-MOB-20 y 21, que no se revisaron.
- **Qué sale hoy:** los documentos nuevos (`documento`) y las firmas (`documento_firma`) con `DocumentsSyncRemote` (ver Gestor documental). Cualquier otra entidad se rechaza. Con `SAMPLE_DOCUMENTS` o en pruebas queda `UnavailableSyncRemote` y todo se queda en la cola.
- **Datos locales por ambiente (RN-CTX-02, DEV-MOB-045 y 053):** lo capturado (la cola) es de una persona y una concesión y sobrevive al cierre de sesión; lo consultado (caches) no. `SessionScope` registra los limpiadores (`ScopeCleaner`) y los caches de un alcance (`ScopeBound.bind`): `SessionLifecycle` fija el alcance al iniciar sesión (y lo vacía si el guardado era de otra persona o concesión, aunque la app se haya cerrado a la fuerza) y lo suelta al cerrar sesión o cambiar de concesión. Registrados: los catálogos en memoria de `DocumentsRepositoryImpl` y `FileDocumentsCache`. Descartar una operación borra su archivo local (`SyncCubit.onDiscarded`).
- **Pendiente:** el paquete operativo (061).
- **Pruebas:** `test/core/offline` (cola, motor, cubit) y `test/features/sync` (pantallas y conexión con la sesión).

## Gestor documental (M03, FEAT-003-MOB)

Consulta, vista previa y carga de documentos en `features/documents`, conectados a `/api/documents` y `/api/uploads` de SIGACO.Api, con firma de la versión vigente y lo ya consultado disponible sin conexión. Alcance móvil según el DTF M03 §3.1: no hay historial de versiones ni descarga del original.

- **Tarjeta (DEV-MOB-091):** `MobileModule.documents` (código `DOCUMENTOS`); aparece solo si el menú del backend trae el módulo **y** el permiso de Ver. Una tarjeta puede exigir además permisos (`MobileModule.requiredPermissions`): el **Mapa** sale de Inventario con `INVENTARIO:VISUALIZAR_CONTENIDO`, no de Panel (`PANEL:PANEL_WEB` es solo de la web). Las claves están en `core/permissions/permission_keys.dart`; referencia completa de permisos del backend en `SIGACO_Permisos_Backend_vs_Movil.xlsx`.
- **Permisos (DEV-MOB-092):** `DocumentAccess.fromPermissions` (Ver, Cargar, Firmar). Cargar y Firmar suponen Ver. Las claves son las del backend: Ver (`DOCUMENTOS:VISUALIZAR_CONTENIDO`), Cargar (`DOCUMENTOS:CARGAR_INFORMACION`) y Firmar (`DOCUMENTOS:FIRMAR`). Viven en `core/permissions/permission_keys.dart`. Sin Ver no se consulta nada y se muestra «sin permiso». El router (en `app/`) calcula el acceso desde el menú y lo pasa a las páginas, porque un módulo no importa a otro.
- **Consulta (068, 069):** `DocumentsCubit` con las vistas Todos, Recientes, Favoritos y Mis documentos, búsqueda (nombre, propietario, categoría) y filtros (tipo, categoría, carpeta, modificado por, rango Desde/Hasta). Cada cambio vuelve a consultar; gana la última consulta. Un rango con Desde posterior a Hasta se rechaza sin consultar. El servidor aplica las vistas y los filtros; la app no recalcula nada. Cada consulta nueva empieza arriba de la lista.
- **Fila y ficha (070, 077):** `DocumentTile` (tipo, categoría, propietario, fecha en la zona de la concesión, estado de firma, favorito) y `DocumentDetailPage` (versión vigente, sin historial). El favorito se refleja al instante y se revierte si el servidor no lo acepta.
- **Estados (078):** `DocumentStateView` agrupa cargando, vacío (por vista), sin resultados, error con reintento, sin conexión, sin permiso, documento inexistente y contenido no disponible sin conexión. Reusa `AccessStateView` para «sin permiso».
- **Datos:** `DocumentsRepository` es la interfaz. `DocumentsRepositoryImpl` (lo que usa la app) habla con `/api/documents`: el servidor aplica vistas, búsqueda y filtros; la app traduce códigos de tipo y categoría, ruta de carpeta y usuario a los identificadores que pide el servidor, pide en el idioma elegido y junta hasta 5 páginas de 100. «Todos» se pide plano desde la carpeta raíz (el servidor navega por carpetas). La fila muestra a quien modificó por última vez (el listado no trae al propietario; la ficha sí). Un 403 `ROAD_ACCESS_REQUIRED` (sin carreteras asignadas en la concesión) se distingue de «sin permiso». `SampleDocumentsRepository` son 14 documentos de ejemplo con las reglas del servidor, y `UnavailableDocumentsRepository` queda como valor por omisión de pruebas. **Sin conexión (080, DTF M03 §3.2):** `CachedDocumentsRepository` envuelve al repositorio con `FileDocumentsCache`: con red todo sale del servidor y se guarda (listas por consulta, fichas, vistas previas hasta 15 MB, catálogos; con tope por clase); sin red solo se entrega lo guardado, marcado con su fecha (`PhoneCopyBanner`, `DocumentListing.cachedAt`), y lo que no se guardó dice «requiere conexión». Un fallo que no es de red (sin permiso, error del servidor) nunca entrega lo guardado. Es de la persona y concesión activas y se vacía al cambiar o cerrar sesión. Los catálogos guardados permiten capturar una carga sin red. Para verlos en un teléfono: `--dart-define=SAMPLE_DOCUMENTS=true` (también agrega el módulo y sus permisos al menú).
- **Vista previa (071):** `DocumentPreviewPage` muestra imágenes con zoom (JPG, PNG) y pide solo la representación, nunca el original; sin descarga ni abrir en otra app. Un formato sin visor no ofrece el botón y lo dice. **PDF:** `PdfPreviewView` dibuja las páginas una debajo de otra, con acercar y alejar (1x a 3x) y «Página n de N». Usa el `PdfRenderer` de Android por un canal propio (`core/pdf/pdf_renderer.dart`, `android/.../PdfChannel.kt`), sin plugin de terceros: el PDF se escribe en la caché de la app mientras dura la vista previa y se borra al salir. Un PDF dañado o con contraseña dice «No se pudo mostrar el PDF». Office solo se verá cuando el backend lo convierta a PDF (hoy responde `PREVIEW_PENDING` y la pantalla dice «sin vista previa»). Sin conexión y sin copia local: «contenido no disponible sin conexión».
- **Carga (072, 073, 082, 083):** botón «Cargar documento» solo con Ver + Cargar. `DocumentUploadRules` valida lo mismo que el DTF (extensiones bloqueadas D-03-46, nombre D-03-79 con extensión real fija, tipo obligatorio, descripción de 10 a 2000 caracteres si el tipo es «Otro», archivo no vacío). Uno o varios archivos del selector del sistema o de la cámara (`file_picker`, `image_picker`; `core/files`). Cada archivo se copia al teléfono (`LocalFileStore`) y entra a la cola con su clave de idempotencia (`SyncCubit.enqueue`, entidad `documento`): la pantalla dice «guardado en el dispositivo» y nunca «cargado»; el documento no existe en el servidor hasta que este lo acepte. Con errores se conserva lo capturado. El servidor vuelve a validar todo. **Envío (`DocumentsSyncRemote`):** `POST /api/uploads` con el `uploadId` igual a la clave de idempotencia de la operación, `PUT /blocks/{n}` (bytes) solo de los `missingBlocks`, `POST /complete` y consulta hasta COMPLETADO (hasta ~16 s; si sigue validando, queda para la siguiente pasada). Un corte de red solo repite lo que no llegó. RECHAZADO, EXPIRADO, CANCELADO o FALLIDO, un 400 o un 403 quedan como rechazados con el motivo del servidor y el archivo se conserva; sin red, 5xx o 429 se reintenta; 401 es sesión vencida. Si la carpeta, el tipo o la categoría ya no existen, se rechaza en lugar de subirlo a la raíz. Al publicarse se borra la copia local. **Pendiente:** verificar el build de Android con `file_picker`, `image_picker` y el canal de PDF, y borrar la copia local cuando se descarta una operación rechazada.
- **Firma (074, 075, 084, 085):** la ficha ofrece «Firmar» solo con Ver + Firmar (`DOCUMENTOS:FIRMAR`), si la versión no está validada y no hay ya una firma pendiente; pide confirmación explícita. Con conexión se firma al momento (`POST /api/documents/{id}/versions/{versionId}/signature`; repetir la firma de la misma persona no crea otra) y la ficha pasa a «Validado». Sin conexión, o si la red falla a medias, la operación `documento_firma` queda en la cola con el documento, la versión, su hash y la versión base (§3.2) y **no se presenta como firmada** hasta que el servidor la acepte; la ficha dice «Firma pendiente de sincronizar» y se actualiza sola al aplicarse. Al sincronizar (`DocumentsSyncRemote`) se consulta el historial (`GET .../versions`, que no cuenta como abrir el documento): si hay otra versión vigente o el archivo cambió, la firma queda **en conflicto** y no se aplica (el centro de sincronización deja descartar o firmar de todos modos la capturada); si no, se firma. El backend no recibe hash ni versión base: esa comprobación la hace la app y el backend valida el hash del archivo guardado (HASH_MISMATCH). Errores: ya firmada por otra persona, hash distinto y sin perfil firmante se avisan con su texto.
- **Pendiente:** maquetas MQ-MOB-13 a 19 (no revisadas: la UI es funcional, no calca el diseño) y DEV-MOB-079 (descarga del original, fuera del alcance móvil: se consulta al PO).
- **Pruebas:** `test/features/documents` (reglas de dominio y del repositorio de ejemplo, cubits y pantallas de punta a punta).

## Mapa (fase 1)

Módulo `lib/features/map`. Cuatro pestañas (tickets, inventario, mantenimiento y obras) con filtros por categoría y estado, pines con ficha, agrupación de pines por zoom, "ubicarme" con la precisión del GPS y activos cercanos con radio configurable (250 m a 5 km; se propone 1 km).

* **Datos:** `MapRepository` (pines por pestaña). El backend aún no publica los endpoints de activos, tickets, mantenimiento y obras, así que el mapa dice "aún no disponible". Los pines de ejemplo están **encendidos por omisión en debug y profile (F5) y apagados en release**, para que una versión publicada nunca muestre datos inventados; `--dart-define=SAMPLE_MAP=false` los apaga para probar contra el servidor real. Agregan la tarjeta Mapa al menú: se reparten **alrededor de donde está el teléfono** (de 60 m a 4 km, en todas las direcciones) y, si no hay ubicación o con `--dart-define=SAMPLE_MAP_NEAR_ME=false`, caen sobre el tramo 381BMG0160 de la BR-381.
* **Mapa base:** OpenStreetMap por omisión (`AppConfig.osmTileUrl`), con atribución tocable y User-Agent. Es para mostrar el mapa a quien usa la app: su política **no permite** precarga ni uso masivo. Para producción, teselas propias con `--dart-define=MAP_TILE_URL=https://.../{z}/{x}/{y}.png` (vacío = sin mapa base, solo pines). El proveedor está detrás de `MapTileSource`: cambiarlo no toca las pantallas.
* **Ubicación:** `LocationSource` (`geolocator`). Pide permiso al tocar "ubicarme"; avisa si el GPS está apagado o el permiso está bloqueado y ofrece abrir Ajustes. La precisión mínima para guardar una ubicación es 30 m (configurable) y una ubicación simulada nunca se acepta.
* **Cercanos:** se calculan en el teléfono con los pines ya cargados (haversine), con y sin conexión igual.
* **Sin conexión:** pantalla "Mapas sin conexión" (`/map/packs`). Descarga el paquete de teselas de la concesión (MBTiles raster) con reanudación (`Range`), verificación de tamaño y SHA-256, versión y aviso de actualización. Es de la persona y la concesión activas: se borra al cambiar de concesión o cerrar sesión. Sin conexión el mapa usa solo el paquete; con conexión, el paquete va encima del mapa en línea. Contrato propuesto al backend (aún no existe): `GET /api/maps/packs` y `GET /api/maps/packs/{id}/content` con `Range`; mientras responda 404 la pantalla dice que no está disponible.
* **Pendiente:** capa de pavimentos de Strata, trazo del eje y ortofoto (dependen del backend y de Engemap); crear ticket, inspección o mantenimiento desde la ficha (dependen de esos módulos); PMTiles y teselas de vectores.

## Módulos del mockup nuevo (tickets, accidentes y mantenimiento)

El alcance móvil es el del Business Blueprint (APP-MOB-01 a 09); el diseño, el de los mockups de `SIGACO_appmovil`. Los tres módulos comparten las piezas de `lib/core/ui/module_*.dart` (cabecera, barra inferior de cinco destinos, tarjetas, pestañas con cuenta, ficha y formularios) y cada uno tiene su carpeta en `lib/features`.

* **Tickets** (`/tickets`, APP-MOB-03): historial con búsqueda, orden por vencimiento y pestañas Todos / Abiertos / Atendidos (el Blueprint solo maneja abiertos o atendidos); ficha; seguimiento con fecha, hora, estado, descripción y hasta 3 fotos; ticket nuevo (el mockup no lo trae: usa el mismo formulario).
* **Accidentes** (`/accidents`, APP-MOB-05): resumen por tipo con su parte del total, pestañas por tipo, filtro por gravedad, ficha y registro. Está **pendiente de homologación** (OI-33 del Blueprint): las acciones de la ficha avisan que llegan después.
* **Mantenimiento** (`/maintenance`, APP-MOB-07): "Seleccione un indicador" (SGP, SGS, SGOAE, SGOAC, SGITS, SGF, SGTEC, SGE) → lista del indicador con resumen por estado, filtro de estado y fechas, y búsqueda → ficha con avance, importes y detalles. El mockup cubre consulta e historial; las acciones operativas se completan después.
* **Datos:** cada módulo tiene su interfaz de repositorio y, mientras el backend no publique los endpoints, `Unavailable…Repository` dice "aún no disponible". Los datos de ejemplo (`SAMPLE_TICKETS`, `SAMPLE_ACCIDENTS`, `SAMPLE_MAINTENANCE`) están **encendidos por omisión en debug y profile (F5) y apagados en release**; `--dart-define=SAMPLE_…=false` los apaga. Agregan la tarjeta del módulo al menú.
* **Gestor documental:** el código sigue en `lib/features/documents`, pero su tarjeta **no sale en el menú** (no es uno de los módulos móviles del Blueprint). Se enciende con `--dart-define=DOCUMENTS_MODULE=true` (`FeatureFlags`) hasta que el PO confirme su lugar.
* **Capturas:** `fvm flutter test tool/capture_mockup_test.dart` (variables `CAPTURE_DIR` y `MATERIAL_ICONS_FONT`) genera las pantallas de estos módulos y del mapa para compararlas con el mockup.

## Trazabilidad

- **De requisitos a código:** ramas y commits llevan el ID de la HU de Azure DevOps y de la regla del DTF,
  p. ej. `feature/HU-M01-01-01-login` y `HU-M01-01-01: valida correo antes de enviar`.
- **En ejecución:** `AppBlocObserver` registra cada evento y cambio de estado (solo en debug).
  Los eventos con secretos ocultan sus datos en `toString` (hay una prueba que lo verifica).
- **Contra el backend:** cada petición envía `X-Correlation-Id`; el servidor lo guarda en su auditoría, así que un reporte
  de la app se cruza con los eventos y logs de esa petición. El log de red registra método, ruta, estado y ese ID; nunca cuerpos.
- **De datos (offline, pendiente):** cada registro capturado llevará quién, cuándo y desde qué dispositivo.

## Estado funcional (M01, acceso al sistema)

| Función DTF | En la app |
|---|---|
| M01-01 / 02 Login, bloqueo | `features/auth` (login, errores genéricos, cuenta bloqueada) |
| M01-03 Perfil y contraseña | `auth/presentation/account` (perfil propio, cambio voluntario), cambio obligatorio, recuperación |
| M01-04 Concesión y contexto | Selector al entrar y cambio en sesión (`POST /api/context`) |
| M01-05 Menú dinámico | `features/navigation` + `app/shell/home_page.dart`: tarjetas según `GET /api/context/navigation` (`MobileModule` mapea catálogo → tarjeta); se vuelve a consultar durante la sesión y tiene estados «Sin permiso» y de error de autorización |
| M01-06 Sesión | Cierre ante 401, aviso de inactividad (`SessionTimeoutCubit`), pasos exigidos a mitad de sesión (MFA, contraseña, concesión) |
| M01-07 Auditoría | `X-Correlation-Id` + User-Agent propio en cada petición |
| RN-CTX-02 | `SessionScope`: al cambiar de concesión o cerrar sesión se vacía todo dato local registrado |

M02 no existe en móvil (RN-M02-02): el backend no lo ofrece a sesiones `MOBILE`.

## Herramientas

- `fvm flutter test tool/generate_brand_assets_test.dart` — regenera wordmark, icono y arranque en `assets/branding/`.
- `fvm flutter test tool/capture_screens_test.dart` — capturas 1080×2400 de las pantallas (variables `CAPTURE_DIR`, `MATERIAL_ICONS_FONT`).
- `fvm flutter test tool/capture_responsive_test.dart` — capturas de las vistas clave en las tres clases de tamaño.
- Icono y arranque nativo: `fvm dart run flutter_launcher_icons -f flutter_launcher_icons.yaml` y `fvm dart run flutter_native_splash:create --path=flutter_native_splash.yaml`.

## Seguridad

No se versionan claves de firma, `google-services.json` ni `.env` (ver `.gitignore`). Las credenciales de la biometría
se guardan cifradas (Keystore) y solo se leen tras verificar la huella o el rostro; pendiente de ratificar por Seguridad.
