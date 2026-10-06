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

- **Qué cambia (capa 2):** color de acción (`primary`), cabecera (`headerStart`, `headerEnd`), navegación (`secondary`) y los logos (`logoLightUrl` para fondo claro, `logoDarkUrl` para fondo oscuro). Los colores de estatus, el error y las superficies neutras no cambian (`StatusColors`).
- **Qué se deriva (capa 3):** `SigacoPalette.withBrand(seed)` calcula el texto sobre el color de acción (`onAccent`) y tres variantes del acento: `accentOnDark` (texto sobre fondo oscuro, 4,5:1), `accentOnLight` (texto sobre fondo claro, 4,5:1) y `accentIconOnLight` (iconos sobre fondo claro, 3:1). **Regla de uso:** sobre una superficie oscura, `p.accentOnDark`; sobre las tarjetas blancas, `p.accentIconOnLight`; sobre el fondo inferior del tema, `p.accentOnBottom`; `p.accent` solo para rellenos (botones, avatar, interruptor). Un color de acento como texto sobre un fondo cualquiera es un error de revisión.
- **Validaciones (`BrandRules`):** se rechaza el color de acción si ni blanco ni el azul de marca se leen encima, o si se parece a un estatus (ΔE < 35); una cabecera o navegación que no deja leer el texto se descarta sola y queda la de SIGACO. Con una marca rechazada la app usa los colores de SIGACO.
- **Cuándo se aplica:** solo con una concesión activa; el login siempre usa SIGACO. Al cerrar sesión o cambiar de concesión se descarta (`BrandingCubit`, `SessionLifecycle`). El usuario puede elegir «Colores de SIGACO» en su perfil, sección Preferencias (se recuerda). La configuración de la concesión (colores, logo, zona horaria) se hace solo en el portal web (DTF Configuración, D1 y D4); la app no tiene pantallas para editarla. El logo de la concesión va arriba de SIGACO en la cabecera del inicio.
- **De dónde sale:** `GET /api/context/branding` (propuesto; ver S11 §6.4). Se guarda por concesión y solo se reemplaza si cambia `version`; sin conexión se usa lo guardado. Un 404 significa «sin marca propia».
- **Probar sin backend:** `--dart-define=BRAND_PRIMARY=#0EA5E9` (opcionales `BRAND_HEADER_START`, `BRAND_HEADER_END`, `BRAND_SECONDARY`, `BRAND_LOGO_LIGHT`, `BRAND_LOGO_DARK`). Hay configuraciones en `.vscode/launch.json`.
- **Pruebas:** `test/core/brand_rules_test.dart` (reglas y contraste de los derivados), `test/features/branding/` (repositorio, cubit y flujo completo).
- **Capturas:** `fvm flutter test tool/capture_brand_test.dart` (menú y cuenta con 7 marcas de ejemplo).
- **Pendiente:** el logo se descarga con `Image.network` (sin caché en disco: sin conexión no aparece hasta la siguiente carga) y el endpoint del backend.

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
