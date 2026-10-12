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
- **De dónde sale:** `GET /api/context/branding` (propuesto; en la base lo arma `core.fn_branding` con `version`, `primary`, `secondary`, `headerStart`, `headerEnd`, `background`, `logoLightUrl`, `logoDarkUrl`, `timezone`; la app lee también `logoReducedUrl`, que la función aún no devuelve). Se guarda por concesión y solo se reemplaza si cambia `version`; sin conexión se usa lo guardado. Un 404 significa «sin marca propia».
- **Refresco con la sesión abierta (DEV-MOB-088):** `BrandingCubit.refresh` vuelve a consultar la versión al volver a la app (como máximo cada minuto, `brandingRefreshGap`) y al recuperar la conexión (siempre), sin vaciar la marca que se ve; solo cambia la pantalla si la versión es otra. Un fallo conserva lo que había. Cuándo aplicar el cambio en el móvil sigue pendiente de TEKIA (P-09).
- **Zona horaria (DEV-MOB-057):** `timezone` es un identificador IANA. `ConcessionZone` (`core/time`, paquete `timezone`) convierte un instante UTC a la zona de la concesión; `ConcessionZoneCubit` la deja disponible a cualquier módulo (la compone `SessionLifecycle`). Para mostrar una fecha del negocio: `inConcessionZone(utc, zone)`; sin zona se usa la del teléfono como respaldo temporal, nunca UTC. La cuenta muestra la zona y su desfase. Las fechas propias del teléfono (la última conexión) siguen en la hora del teléfono. Aún no hay fechas de negocio en pantalla: el primer uso será Gestor documental.
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
- **Sincronizador (064):** `SyncEngine.run` envía en el orden de captura, una pasada a la vez por alcance. Un rechazo no detiene a los demás (varios archivos, DEV-MOB-083); lo siguiente sobre el mismo registro espera si una operación quedó rechazada, en conflicto o esperando reintento. Un fallo de red detiene la pasada, devuelve la operación a la cola y espera 5 s, 10 s, 20 s... hasta 15 min. Un conflicto nunca se aplica en silencio (DEV-MOB-085). Antes de enviar corre `SyncPreflight` (revalidar sesión y permisos, DEV-MOB-094; la app aún no lo define porque la regla RN-M01-38 está pendiente con TEKIA).
- **Estado (063):** `SyncCubit` expone lo pendiente, lo rechazado, los conflictos, la última sincronización y la hora del siguiente reintento. Envía al recuperar la conexión, al volver a la app (mínimo 30 s entre pasadas), cuando la persona lo pide, tras encolar (`syncNow`) y a la hora del reintento; nunca por el simple cambio de la cola (se lanzaría sola sin fin). `SessionLifecycle` fija el alcance al iniciar sesión o cambiar de concesión y lo suelta al cerrarla.
- **Pantallas (063, 065, 066):** un aviso en el inicio con lo pendiente o lo que pide decisión; el centro de sincronización (`/sync`, también desde la cuenta) con lo pendiente, lo rechazado y los conflictos, y `/sync/conflict/:id`, que muestra lo capturado junto a lo del servidor (marcando lo que cambió) y deja quedarse con el servidor o mantener lo propio. Las fechas salen en la zona de la concesión. Son genéricas: faltan las maquetas MQ-MOB-20 y 21, que no se revisaron.
- **Pendiente:** el backend aún no tiene los endpoints (`UnavailableSyncRemote` deja todo en la cola); el paquete operativo (061) y limpiar los datos locales de una concesión anterior (045).
- **Pruebas:** `test/core/offline` (cola, motor, cubit) y `test/features/sync` (pantallas y conexión con la sesión).

## Gestor documental (M03, FEAT-003-MOB)

Consulta de documentos en `features/documents`. Por ahora solo lectura: faltan vista previa, carga y firma. Alcance móvil según el DTF M03 §3.1: no hay historial de versiones ni descarga del original.

- **Tarjeta (DEV-MOB-091):** `MobileModule.documents` (código `DOCUMENTOS`); aparece solo si el menú del backend lo trae.
- **Permisos (DEV-MOB-092):** `DocumentAccess.fromPermissions` (Ver, Cargar, Firmar). Cargar y Firmar suponen Ver. **Las claves (`DOCUMENTOS:R`, `DOCUMENTOS:C`, `DOCUMENTOS.FIRMAR:C`) son una suposición** hasta que el backend publique la matriz M02/M03; viven solo en `document_access.dart`. Sin Ver no se consulta nada y se muestra «sin permiso». El router (en `app/`) calcula el acceso desde el menú y lo pasa a las páginas, porque un módulo no importa a otro.
- **Consulta (068, 069):** `DocumentsCubit` con las vistas Todos, Recientes, Favoritos y Mis documentos, búsqueda (nombre, propietario, categoría) y filtros (tipo, categoría, carpeta, modificado por, rango Desde/Hasta). Cada cambio vuelve a consultar; gana la última consulta. Un rango con Desde posterior a Hasta se rechaza sin consultar. El servidor aplica las vistas y los filtros; la app no recalcula nada. Cada consulta nueva empieza arriba de la lista.
- **Fila y ficha (070, 077):** `DocumentTile` (tipo, categoría, propietario, fecha en la zona de la concesión, estado de firma, favorito) y `DocumentDetailPage` (versión vigente, sin historial). El favorito se refleja al instante y se revierte si el servidor no lo acepta.
- **Estados (078):** `DocumentStateView` agrupa cargando, vacío (por vista), sin resultados, error con reintento, sin conexión, sin permiso, documento inexistente y contenido no disponible sin conexión. Reusa `AccessStateView` para «sin permiso».
- **Datos:** `DocumentsRepository` es la interfaz; `UnavailableDocumentsRepository` (lo que usa la app hoy) responde error del servidor hasta que existan los endpoints, y `SampleDocumentsRepository` son 14 documentos de ejemplo con las reglas del servidor. Para verlos en un teléfono: `--dart-define=SAMPLE_DOCUMENTS=true` (también agrega el módulo y sus permisos al menú).
- **Pendiente:** vista previa (071), carga (072, 073, 082, 083), firma (074, 075, 084, 085), consulta de lo guardado sin conexión (080), maquetas MQ-MOB-13 a 15 (no revisadas: la UI es funcional, no calca el diseño) y DEV-MOB-079 (descarga del original, fuera del alcance móvil: se consulta al PO).
- **Pruebas:** `test/features/documents` (reglas de dominio y del repositorio de ejemplo, cubits y pantallas de punta a punta).

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
