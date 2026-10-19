// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline => 'Sistema de Gestión de Activos de Concesión';

  @override
  String get loginWelcome => 'Bienvenido';

  @override
  String get loginSubtitle => 'Inicia sesión para continuar';

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get rememberCredentials => 'Recordar correo y contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get biometricAccess => 'Acceder con biometría';

  @override
  String get biometricReason => 'Confirma tu identidad para iniciar sesión';

  @override
  String get biometricEnableTitle => 'Activar acceso con biometría';

  @override
  String get biometricEnableBody =>
      'La próxima vez podrás entrar con tu huella o rostro. Tus datos se guardan cifrados en este dispositivo.';

  @override
  String get biometricEnable => 'Activar';

  @override
  String get biometricNotNow => 'Ahora no';

  @override
  String get biometricUnavailable =>
      'La biometría no está disponible o no está activada en este dispositivo.';

  @override
  String get biometricNoCredentials =>
      'La biometría aún no está activada. Inicia sesión con tu correo y contraseña y se te ofrecerá activarla.';

  @override
  String get biometricSettingTitle => 'Acceso con biometría';

  @override
  String get biometricSettingOn => 'Activo: entras con tu huella o rostro.';

  @override
  String get biometricSettingOff =>
      'Inactivo. Actívalo para entrar con tu huella o rostro.';

  @override
  String get biometricEnabledDone => 'Acceso con biometría activado.';

  @override
  String get biometricDisabledDone => 'Acceso con biometría desactivado.';

  @override
  String get valueSecure => 'Seguro';

  @override
  String get valueReliable => 'Confiable';

  @override
  String get valueCollaborative => 'Colaborativo';

  @override
  String get valueEfficient => 'Eficiente';

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get contactAdmin => 'Contacto al administrador';

  @override
  String get errEmailRequired => 'Ingresa tu correo electrónico.';

  @override
  String get errEmailInvalid => 'Ingresa un correo electrónico válido.';

  @override
  String get errPasswordRequired => 'Ingresa tu contraseña.';

  @override
  String get errInvalidCredentials =>
      'Correo o contraseña incorrectos. Tras varios intentos fallidos consecutivos la cuenta se bloquea.';

  @override
  String get errAccountBlocked =>
      'Tu acceso ha sido bloqueado por intentos fallidos. Contacta al administrador del sistema para solicitar la reactivación de tu cuenta.';

  @override
  String get errNetwork =>
      'No hay conexión con el servidor. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errServer =>
      'Ocurrió un error en el servidor. Inténtalo más tarde.';

  @override
  String get errSessionExpired => 'Tu sesión terminó. Inicia sesión de nuevo.';

  @override
  String get mfaTitle => 'Verificación en dos pasos';

  @override
  String get mfaSubtitle =>
      'Ingresa el código de 6 dígitos de tu app autenticadora.';

  @override
  String get mfaCode => 'Código';

  @override
  String get mfaVerify => 'Verificar';

  @override
  String get mfaCodeInvalid => 'El código no es válido.';

  @override
  String get mfaEnrollTitle => 'Configura tu verificación en dos pasos';

  @override
  String get mfaEnrollBody =>
      'Agrega esta clave a tu app autenticadora y escribe el primer código que genere.';

  @override
  String get mfaEnrollSecret => 'Clave';

  @override
  String get mfaCopied => 'Clave copiada';

  @override
  String get changePasswordTitle => 'Cambia tu contraseña';

  @override
  String get changePasswordSubtitle =>
      'Por seguridad debes definir una contraseña nueva para continuar.';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Contraseña nueva';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get changePasswordAction => 'Cambiar contraseña';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get concessionTitle => 'Selecciona tu concesión';

  @override
  String get concessionSubtitle =>
      'Tienes acceso a más de una concesión. Elige con cuál trabajar.';

  @override
  String get recoveryTitle => 'Recuperar contraseña';

  @override
  String get recoveryBody =>
      'Ingresa tu correo. Si corresponde a una cuenta activa, recibirás un enlace para definir tu contraseña.';

  @override
  String get recoverySend => 'Enviar enlace';

  @override
  String get recoverySent =>
      'Si el correo corresponde a una cuenta activa, recibirás un enlace para definir tu contraseña.';

  @override
  String get recoveryStepsTitle => 'Qué hacer ahora';

  @override
  String get recoveryStep1 => 'Abre el correo que te enviamos.';

  @override
  String get recoveryStep2 =>
      'Toca el enlace: se abre en el navegador. Ahí defines tu nueva contraseña.';

  @override
  String get recoveryStep3 =>
      'Al terminar, toca «Volver a la aplicación» e inicia sesión.';

  @override
  String get recoveryResend => 'Reenviar enlace';

  @override
  String get recoveryBackToLogin => 'Volver a iniciar sesión';

  @override
  String get passwordResetDone =>
      'Contraseña actualizada. Inicia sesión con tu nueva contraseña.';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get appearanceLabel => 'Apariencia';

  @override
  String get appearanceOriginal => 'Original';

  @override
  String get appearanceDay => 'Día';

  @override
  String get appearanceNight => 'Noche';

  @override
  String get preferencesTitle => 'Preferencias';

  @override
  String get preferencesSubtitle => 'Se guardan en este dispositivo.';

  @override
  String get useConcessionColors => 'Colores de mi concesión';

  @override
  String get useConcessionColorsOn => 'Se usan los colores de tu concesión.';

  @override
  String get useConcessionColorsOff => 'Se usan los colores de SIGACO.';

  @override
  String get securityTitle => 'Seguridad';

  @override
  String get mfaSettingTitle => 'Verificación en dos pasos';

  @override
  String get mfaSettingOn =>
      'Activa. Tu código lo genera tu app autenticadora. Toca para configurarla de nuevo.';

  @override
  String get mfaSettingOff =>
      'No está habilitada para tu cuenta. La activa un administrador.';

  @override
  String get mfaAdminManaged =>
      'La verificación en dos pasos la activa o desactiva un administrador del sistema.';

  @override
  String get mfaReconfigureBody =>
      'Se generará una clave nueva y la de tu app autenticadora actual dejará de funcionar. Si no terminas, tendrás que configurarla de nuevo al iniciar sesión.';

  @override
  String get mfaReconfigureAction => 'Generar clave nueva';

  @override
  String get mfaReconfigureDone => 'Verificación en dos pasos actualizada.';

  @override
  String get homePlaceholderTitle => 'Inicio';

  @override
  String get homePlaceholderBody => 'Aquí irá el menú de módulos (diseño v2).';

  @override
  String welcomeUser(String name) {
    return 'Bienvenido, $name';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get greetingMorning => 'Buenos días,';

  @override
  String get greetingAfternoon => 'Buenas tardes,';

  @override
  String get greetingEvening => 'Buenas noches,';

  @override
  String get homeQuestion => '¿Qué deseas realizar hoy?';

  @override
  String get modulesTitle => 'MÓDULOS';

  @override
  String get moduleMap => 'Mapa';

  @override
  String get moduleMapSub => 'Ubicación de activos';

  @override
  String get moduleDashboard => 'Dashboard';

  @override
  String get moduleDashboardSub => 'Resumen general';

  @override
  String get moduleAccidents => 'Accidentes';

  @override
  String get moduleAccidentsSub => 'Incidentes graves';

  @override
  String get moduleMaintenance => 'Mantenimientos';

  @override
  String get moduleMaintenanceSub => 'Órdenes de trabajo';

  @override
  String get moduleInventory => 'Inventario';

  @override
  String get moduleInventorySub => 'Control de activos y faja';

  @override
  String get moduleReports => 'Reportes';

  @override
  String get moduleReportsSub => 'Consulta y exportación';

  @override
  String get moduleTickets => 'Tickets';

  @override
  String get moduleTicketsSub => 'Seguimiento y registro';

  @override
  String get moduleAlerts => 'Alertas';

  @override
  String get moduleAlertsSub => 'Eventos operativos';

  @override
  String get moduleComingSoon => 'Este módulo está en desarrollo.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navHome => 'Inicio';

  @override
  String get navAlerts => 'Alertas';

  @override
  String get navReports => 'Reportes';

  @override
  String get menuLoadError => 'No se pudo cargar tu menú.';

  @override
  String get menuEmpty =>
      'Tu perfil no tiene módulos habilitados en esta concesión. Si crees que es un error, contacta al administrador de tu concesión.';

  @override
  String get accessNoPermissionTitle => 'Sin permiso';

  @override
  String get accessNoPermissionBody =>
      'Tu perfil no tiene permiso para ver esta información. Si crees que es un error, contacta al administrador de tu concesión.';

  @override
  String get accessErrorTitle => 'No pudimos verificar tus accesos';

  @override
  String get accessErrorBody =>
      'Ocurrió un problema al validar tus permisos. Intenta de nuevo; si continúa, contacta al administrador de tu concesión.';

  @override
  String get accessChangedNotice =>
      'Tus accesos cambiaron. Se actualizó el menú.';

  @override
  String get retry => 'Reintentar';

  @override
  String get accountTitle => 'Configuración de usuario';

  @override
  String get accountInfoTitle => 'Información de la cuenta';

  @override
  String get accountInfoSubtitle =>
      'Estos son los datos asociados a tu perfil en SIGACO.';

  @override
  String get fieldUser => 'Usuario';

  @override
  String get fieldEmailShort => 'Correo';

  @override
  String get fieldProfile => 'Perfil';

  @override
  String get fieldArea => 'Área';

  @override
  String get fieldConcession => 'Concesionaria';

  @override
  String get fieldRoads => 'Carreteras';

  @override
  String get fieldAppVersion => 'Versión de la app';

  @override
  String get fieldDevice => 'Dispositivo';

  @override
  String get fieldLastConnection => 'Última conexión';

  @override
  String get fieldTimezone => 'Zona horaria de la concesión';

  @override
  String get connectionOffline => 'Sin conexión';

  @override
  String connectionOfflineSince(String time) {
    return 'Sin conexión · última conexión $time';
  }

  @override
  String get connectionRestored => 'Conexión restablecida';

  @override
  String get actionChangePasswordSub => 'Actualiza tu contraseña de acceso';

  @override
  String get actionSwitchConcession => 'Cambiar de concesión';

  @override
  String get actionSwitchConcessionSub => 'Elige otra concesión para trabajar';

  @override
  String get switchConcessionWarning =>
      'Al cambiar de concesión se abre una sesión nueva y se descarta lo cargado de la anterior.';

  @override
  String get passwordChanged =>
      'Contraseña actualizada. Se cerraron tus otras sesiones.';

  @override
  String get sessionExpiringTitle => 'Tu sesión está por vencer';

  @override
  String get sessionContinue => 'Continuar';

  @override
  String sessionExpiringBody(int seconds) {
    return 'Por inactividad se cerrará en $seconds segundos.';
  }

  @override
  String get appTaglineShort => 'Sistema de Gestión de Activos';

  @override
  String get syncTitle => 'Sincronización';

  @override
  String syncStripPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operaciones pendientes de enviar',
      one: '1 operación pendiente de enviar',
    );
    return '$_temp0';
  }

  @override
  String syncStripAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operaciones necesitan tu decisión',
      one: '1 operación necesita tu decisión',
    );
    return '$_temp0';
  }

  @override
  String syncLastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get syncNever => 'Todavía no se ha sincronizado';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncRunning => 'Sincronizando…';

  @override
  String get syncOfflineHint => 'Sin conexión. Se enviará al recuperarla.';

  @override
  String get syncAllDone => 'Todo está sincronizado';

  @override
  String get syncAllDoneBody =>
      'No hay operaciones pendientes ni que requieran tu decisión.';

  @override
  String get syncSectionAttention => 'Requieren tu decisión';

  @override
  String get syncSectionPending => 'Pendientes de enviar';

  @override
  String get syncStatusPending => 'Pendiente';

  @override
  String get syncStatusSending => 'Enviando';

  @override
  String get syncStatusRejected => 'Rechazada';

  @override
  String get syncStatusConflict => 'En conflicto';

  @override
  String syncCaptured(String time) {
    return 'Capturada $time';
  }

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '1 intento',
    );
    return '$_temp0';
  }

  @override
  String get syncActionRetry => 'Reintentar';

  @override
  String get syncActionDiscard => 'Descartar';

  @override
  String get syncActionReview => 'Revisar';

  @override
  String get syncDiscardTitle => '¿Descartar esta operación?';

  @override
  String get syncDiscardBody =>
      'Se perderá lo capturado en este teléfono. Esto no se puede deshacer.';

  @override
  String get syncEntityDocument => 'Documento';

  @override
  String get syncEntitySignature => 'Firma de documento';

  @override
  String get syncEntityTicket => 'Ticket';

  @override
  String get syncEntityInspection => 'Inspección';

  @override
  String get syncEntityEvent => 'Evento';

  @override
  String get syncEntityAsset => 'Activo';

  @override
  String get syncEntitySurvey => 'Levantamiento';

  @override
  String get syncEntityMedia => 'Archivo';

  @override
  String get syncEntityOther => 'Operación';

  @override
  String get syncKindInsert => 'Alta';

  @override
  String get syncKindUpdate => 'Cambio';

  @override
  String get syncKindDelete => 'Baja';

  @override
  String get syncConflictTitle => 'Conflicto de sincronización';

  @override
  String get syncConflictIntro =>
      'Este registro cambió en el servidor mientras estabas sin conexión. Elige con cuál quedarte: nada se aplica en silencio.';

  @override
  String get syncConflictMine => 'Lo que capturaste';

  @override
  String get syncConflictServer => 'Lo que hay en el servidor';

  @override
  String syncConflictVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get syncConflictNoDetail => 'Sin detalle disponible';

  @override
  String get syncConflictKeepServer => 'Quedarme con el servidor';

  @override
  String get syncConflictKeepServerBody =>
      'Se descartará lo capturado en este teléfono.';

  @override
  String get syncConflictKeepMine => 'Mantener lo mío';

  @override
  String get syncConflictKeepMineBody =>
      'Se volverá a enviar sobre la versión actual del servidor, que puede rechazarlo.';

  @override
  String get syncConflictMissing => 'Este conflicto ya no existe.';

  @override
  String syncMessageFromServer(String message) {
    return 'Motivo: $message';
  }

  @override
  String get moduleDocuments => 'Gestor documental';

  @override
  String get moduleDocumentsSub => 'Consulta y firma de documentos';

  @override
  String get docsTitle => 'Gestor documental';

  @override
  String get docsViewAll => 'Todos';

  @override
  String get docsViewRecent => 'Recientes';

  @override
  String get docsViewFavorites => 'Favoritos';

  @override
  String get docsViewMine => 'Mis documentos';

  @override
  String get docsSearchHint => 'Buscar por nombre, propietario o categoría';

  @override
  String get docsFilters => 'Filtros';

  @override
  String get docsFiltersApply => 'Aplicar';

  @override
  String get docsFiltersClear => 'Limpiar filtros';

  @override
  String get docsFilterType => 'Tipo documental';

  @override
  String get docsFilterCategory => 'Categoría';

  @override
  String get docsFilterFolder => 'Carpeta';

  @override
  String get docsFilterModifiedBy => 'Modificado por';

  @override
  String get docsFilterFrom => 'Desde';

  @override
  String get docsFilterTo => 'Hasta';

  @override
  String get docsFilterAny => 'Cualquiera';

  @override
  String get docsFilterPickDate => 'Elegir fecha';

  @override
  String get docsRangeInvalid =>
      'La fecha Desde no puede ser posterior a Hasta.';

  @override
  String get docsLoading => 'Cargando documentos…';

  @override
  String get docsEmptyAllTitle => 'Aún no hay documentos';

  @override
  String get docsEmptyAllBody =>
      'Cuando se carguen documentos de esta concesión aparecerán aquí.';

  @override
  String get docsEmptyRecentTitle => 'Sin actividad reciente';

  @override
  String get docsEmptyRecentBody =>
      'Aquí aparecen los documentos que abriste o cargaste en los últimos 30 días.';

  @override
  String get docsEmptyFavoritesTitle => 'Sin favoritos';

  @override
  String get docsEmptyFavoritesBody =>
      'Marca un documento con la estrella para encontrarlo aquí.';

  @override
  String get docsEmptyMineTitle => 'No has cargado documentos';

  @override
  String get docsEmptyMineBody => 'Los documentos que cargues aparecerán aquí.';

  @override
  String get docsNoResultsTitle => 'Sin resultados';

  @override
  String get docsNoResultsBody =>
      'Prueba con otra búsqueda o quita algún filtro.';

  @override
  String get docsErrorTitle => 'No se pudieron cargar los documentos';

  @override
  String get docsErrorBody => 'Inténtalo de nuevo en unos momentos.';

  @override
  String get docsOfflineTitle => 'Sin conexión';

  @override
  String get docsOfflineBody =>
      'Los documentos necesitan conexión mientras no estén guardados en el teléfono.';

  @override
  String get docsNoPermissionTitle => 'Sin permiso para ver documentos';

  @override
  String get docsNoPermissionBody =>
      'Tu perfil no puede consultar el gestor documental en esta concesión.';

  @override
  String get docsNoRoadTitle => 'Sin carreteras asignadas';

  @override
  String get docsNoRoadBody =>
      'Tu usuario no tiene carreteras asignadas en esta concesión. Pide al administrador que te las asigne.';

  @override
  String get docsNotFoundTitle => 'El documento ya no está disponible';

  @override
  String get docsNotFoundBody => 'Pudo haberse movido o eliminado.';

  @override
  String get docsNotOfflineTitle => 'Contenido no disponible sin conexión';

  @override
  String get docsNotOfflineBody => 'Conéctate para consultar este documento.';

  @override
  String get docsSignatureUnsigned => 'Sin firma';

  @override
  String get docsSignaturePending => 'Pendiente de validación';

  @override
  String get docsSignatureValidated => 'Validado';

  @override
  String get docsFavoriteAdd => 'Marcar como favorito';

  @override
  String get docsFavoriteRemove => 'Quitar de favoritos';

  @override
  String get docsFavoriteFailed => 'No se pudo actualizar el favorito.';

  @override
  String get docsDetailTitle => 'Documento';

  @override
  String get docsFieldType => 'Tipo documental';

  @override
  String get docsFieldCategory => 'Categoría';

  @override
  String get docsFieldDescription => 'Descripción';

  @override
  String get docsFieldFolder => 'Carpeta';

  @override
  String get docsFieldOwner => 'Propietario';

  @override
  String get docsFieldVersion => 'Versión vigente';

  @override
  String get docsFieldModified => 'Última modificación';

  @override
  String get docsFieldModifiedBy => 'Modificado por';

  @override
  String get docsFieldSize => 'Tamaño';

  @override
  String get docsFieldFormat => 'Formato';

  @override
  String get docsNoCategory => 'Sin categoría';

  @override
  String get docsFolderRoot => 'Nivel inicial de la concesión';

  @override
  String get docsNoDescription => 'Sin descripción';

  @override
  String docsVersion(int number) {
    return 'V$number';
  }

  @override
  String docsOwnerLine(String owner, String date) {
    return '$owner · $date';
  }

  @override
  String docsZoneLegend(String zone, String offset) {
    return 'Fechas en hora de $zone ($offset)';
  }

  @override
  String get docsPreviewOpen => 'Previsualizar';

  @override
  String get docsPreviewTitle => 'Vista previa';

  @override
  String get docsPreviewNoneNote =>
      'Este formato no tiene vista previa en la app.';

  @override
  String get docsPreviewUnavailableTitle => 'Vista previa no disponible';

  @override
  String get docsPreviewUnavailableBody =>
      'Este formato no se puede mostrar en la app.';

  @override
  String get docsPreviewPdfError => 'No se pudo mostrar el PDF.';

  @override
  String docsPdfPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get docsPdfZoomIn => 'Acercar';

  @override
  String get docsPdfZoomOut => 'Alejar';

  @override
  String docsFromPhone(String date) {
    return 'Sin conexión · guardado en el teléfono el $date';
  }

  @override
  String get docsSignAction => 'Firmar';

  @override
  String get docsSignConfirmTitle => '¿Firmar este documento?';

  @override
  String docsSignConfirmBody(String name, String version) {
    return 'Vas a firmar «$name», versión $version. La firma queda registrada con tu nombre, tu perfil y la fecha, y no se puede deshacer.';
  }

  @override
  String get docsSignConfirmOffline =>
      'Sin conexión: la firma quedará pendiente y se aplicará al sincronizar, solo si el documento no cambió.';

  @override
  String get docsSignConfirmButton => 'Firmar';

  @override
  String get docsSignDone => 'Documento firmado.';

  @override
  String get docsSignQueued => 'Firma guardada. Se aplicará al sincronizar.';

  @override
  String get docsSignPending => 'Firma pendiente de sincronizar';

  @override
  String get docsSignAttention =>
      'La firma pendiente necesita tu decisión en el centro de sincronización.';

  @override
  String get docsSignAlready => 'Esta versión ya fue firmada por otra persona.';

  @override
  String get docsSignMismatch =>
      'El archivo no coincide con el hash de la versión: no se puede firmar. Avisa a un administrador.';

  @override
  String get docsSignProfile =>
      'Firmar requiere un perfil firmante en esta concesión.';

  @override
  String get docsSignFailed => 'No se pudo firmar. Inténtalo de nuevo.';

  @override
  String get fieldLastSync => 'Última sincronización';

  @override
  String get docsPreviewImageError => 'No se pudo mostrar la imagen.';

  @override
  String get docsUploadAction => 'Cargar documento';

  @override
  String get docsUploadTitle => 'Cargar documento';

  @override
  String get docsUploadPickFiles => 'Elegir archivos';

  @override
  String get docsUploadTakePhoto => 'Tomar foto';

  @override
  String get docsUploadNoFiles =>
      'Elige uno o varios archivos, o toma una foto.';

  @override
  String get docsUploadFileName => 'Nombre';

  @override
  String get docsUploadRemove => 'Quitar archivo';

  @override
  String get docsUploadType => 'Tipo documental';

  @override
  String get docsUploadCategory => 'Categoría (opcional)';

  @override
  String get docsUploadFolder => 'Carpeta (opcional)';

  @override
  String get docsUploadNoCategory => 'Sin categoría';

  @override
  String get docsUploadRoot => 'Nivel inicial';

  @override
  String get docsUploadDescription => 'Descripción (opcional)';

  @override
  String get docsUploadDescriptionOther =>
      'Descripción (obligatoria para «Otro»)';

  @override
  String get docsUploadSave => 'Guardar documento';

  @override
  String get docsUploadSaving => 'Guardando…';

  @override
  String get docsUploadOfflineNote =>
      'Se guarda en el dispositivo y se envía cuando haya conexión. No es un documento del servidor hasta que se confirme.';

  @override
  String get docsUploadSaveFailed =>
      'Algunos archivos no se pudieron guardar en el teléfono. Siguen aquí para que lo intentes de nuevo.';

  @override
  String get docsIssueNoFile => 'Elige al menos un archivo.';

  @override
  String get docsIssueEmptyFile => 'El archivo está vacío.';

  @override
  String get docsIssueBlocked => 'Este tipo de archivo no está permitido.';

  @override
  String get docsIssueNameEmpty => 'Escribe un nombre.';

  @override
  String get docsIssueNameInvalid =>
      'El nombre no puede tener < > : \" / \\ | ? * ni terminar en punto.';

  @override
  String get docsIssueNameTooLong =>
      'El nombre pasa de 255 caracteres: acórtalo.';

  @override
  String get docsIssueTypeMissing => 'Elige el tipo documental.';

  @override
  String get docsIssueDescriptionRequired =>
      'Para el tipo «Otro» escribe una descripción de al menos 10 caracteres.';

  @override
  String get docsIssueDescriptionTooLong =>
      'La descripción pasa de 2000 caracteres.';

  @override
  String get docsUploadDoneTitle => 'Guardado en el dispositivo';

  @override
  String docsUploadDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos pendientes de sincronización. No estarán en el servidor hasta que se confirmen.',
      one:
          '1 documento pendiente de sincronización. No estará en el servidor hasta que se confirme.',
    );
    return '$_temp0';
  }

  @override
  String get docsUploadDoneSync => 'Ver pendientes';

  @override
  String get docsUploadDoneBack => 'Volver al listado';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get mapTabTickets => 'Tickets';

  @override
  String get mapTabInventory => 'Inventario';

  @override
  String get mapTabMaintenance => 'Mantenimiento';

  @override
  String get mapTabWorks => 'Obras';

  @override
  String get mapFilters => 'Filtros';

  @override
  String mapFiltersCount(int count) {
    return 'Filtros ($count)';
  }

  @override
  String get mapFiltersTitle => 'Filtrar el mapa';

  @override
  String get mapFilterCategory => 'Categoría';

  @override
  String get mapFilterStatus => 'Estado';

  @override
  String get mapFilterAll => 'Todos';

  @override
  String get mapStatusNormal => 'Normal';

  @override
  String get mapStatusAttention => 'Atención';

  @override
  String get mapStatusCritical => 'Crítico';

  @override
  String get mapFilterClear => 'Quitar filtros';

  @override
  String get mapFilterDone => 'Listo';

  @override
  String get mapSampleBanner =>
      'Datos de ejemplo: el servidor aún no publica el mapa.';

  @override
  String mapSegmentTitle(String code) {
    return 'Tramo $code';
  }

  @override
  String get mapDirectionIncreasing => 'Sentido creciente';

  @override
  String get mapDirectionDecreasing => 'Sentido decreciente';

  @override
  String mapSegmentRange(String from, String to) {
    return '$from a $to';
  }

  @override
  String mapSegmentLayerCount(String layer, int count) {
    return '$layer: $count en este tramo';
  }

  @override
  String mapFromPhone(String date) {
    return 'Sin conexión · pines guardados en el teléfono el $date';
  }

  @override
  String get mapNoTiles => 'Sin mapa base configurado';

  @override
  String get mapLoading => 'Cargando el mapa';

  @override
  String get mapEmpty => 'No hay elementos en esta pestaña.';

  @override
  String get mapEmptyFiltered => 'Ningún elemento coincide con los filtros.';

  @override
  String get mapErrorTitle => 'No se pudo cargar el mapa';

  @override
  String get mapErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get mapRetry => 'Reintentar';

  @override
  String get mapUnavailableTitle => 'El mapa aún no está disponible';

  @override
  String get mapUnavailableBody =>
      'Tu concesión todavía no tiene el mapa publicado. Se activará cuando el servidor lo ofrezca.';

  @override
  String get mapNoPermissionTitle => 'Sin permiso para ver esta pestaña';

  @override
  String get mapNoPermissionBody =>
      'Tu perfil no puede consultar esta información. Pide acceso a un administrador.';

  @override
  String get mapLocate => 'Ubicarme';

  @override
  String get mapLocating => 'Buscando tu ubicación…';

  @override
  String get mapLocateServiceOff =>
      'El GPS está apagado. Enciéndelo para ubicarte.';

  @override
  String get mapLocateDenied =>
      'Necesitamos el permiso de ubicación para ubicarte.';

  @override
  String get mapLocateDeniedForever =>
      'El permiso de ubicación está bloqueado. Actívalo en Ajustes.';

  @override
  String get mapLocateUnavailable =>
      'No se pudo obtener tu ubicación. Inténtalo de nuevo al aire libre.';

  @override
  String get mapOpenSettings => 'Abrir ajustes';

  @override
  String mapAccuracy(String meters) {
    return 'Precisión ±$meters m';
  }

  @override
  String mapAccuracyLow(String meters, String max) {
    return 'Precisión baja (±$meters m). Para guardar una ubicación se pide $max m o menos.';
  }

  @override
  String get mapMockedLocation =>
      'La ubicación parece simulada: no se usará para guardar datos.';

  @override
  String get mapNearby => 'Cercanos';

  @override
  String get mapNearbyTitle => 'Activos cercanos';

  @override
  String get mapNearbyRadius => 'Radio';

  @override
  String mapNearbyEmpty(String radius) {
    return 'No hay activos a menos de $radius de ti.';
  }

  @override
  String get mapNearbyNeedLocation =>
      'Toca «Ubicarme» para ver los activos cercanos.';

  @override
  String get mapNearbyLoading => 'Cargando el inventario…';

  @override
  String mapDistanceMeters(String value) {
    return '$value m';
  }

  @override
  String mapDistanceKm(String value) {
    return '$value km';
  }

  @override
  String get mapDetailReference => 'Referencia';

  @override
  String mapDetailDistance(String distance) {
    return 'A $distance de ti';
  }

  @override
  String get mapDetailClose => 'Cerrar';

  @override
  String get mapActionsSoon =>
      'Crear un ticket, una inspección o un mantenimiento desde aquí se habilitará cuando esos módulos estén disponibles.';

  @override
  String get mapPacksTitle => 'Mapas sin conexión';

  @override
  String get mapPacksAction => 'Mapas sin conexión';

  @override
  String get mapPacksIntro =>
      'Descarga el mapa de tu concesión para verlo sin internet. Se recomienda usar Wi-Fi: los paquetes pesan decenas de megabytes. Se borran al cambiar de concesión o cerrar sesión.';

  @override
  String get mapPacksEmpty =>
      'El servidor no tiene mapas para descargar en esta concesión.';

  @override
  String get mapPacksUnavailableTitle =>
      'Los mapas sin conexión aún no están disponibles';

  @override
  String get mapPacksUnavailableBody =>
      'El servidor todavía no los publica para tu concesión.';

  @override
  String get mapPacksNoPermissionTitle => 'Sin permiso para descargar mapas';

  @override
  String get mapPacksNoPermissionBody =>
      'Tu perfil no puede descargar mapas. Pide acceso a un administrador.';

  @override
  String get mapPacksErrorTitle => 'No se pudieron cargar los mapas';

  @override
  String get mapPacksErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get mapPacksListOffline =>
      'Sin conexión: se muestran solo los mapas guardados en el teléfono.';

  @override
  String mapPackVersion(int version) {
    return 'Versión $version';
  }

  @override
  String mapPackZoom(int min, int max) {
    return 'Acercamiento $min a $max';
  }

  @override
  String get mapPackInstalled => 'Guardado en el teléfono';

  @override
  String get mapPackUpdateAvailable => 'Hay una versión nueva';

  @override
  String mapPackPaused(String size) {
    return 'Pausado · $size bajados';
  }

  @override
  String mapPackDownloading(int percent) {
    return 'Bajando… $percent %';
  }

  @override
  String get mapPackVerifying => 'Comprobando el archivo…';

  @override
  String get mapPackDownload => 'Descargar';

  @override
  String get mapPackResume => 'Reanudar';

  @override
  String get mapPackUpdate => 'Actualizar';

  @override
  String get mapPackPause => 'Pausar';

  @override
  String get mapPackDiscard => 'Descartar lo bajado';

  @override
  String get mapPackDelete => 'Borrar';

  @override
  String get mapPackDeleteTitle => '¿Borrar el mapa sin conexión?';

  @override
  String mapPackDeleteBody(String size) {
    return 'Se liberan $size del teléfono. Podrás volver a descargarlo.';
  }

  @override
  String get mapPackCancel => 'Cancelar';

  @override
  String get mapPackErrNetwork =>
      'Se cortó la conexión. Puedes reanudar la descarga.';

  @override
  String get mapPackErrCorrupt =>
      'El archivo descargado no coincide con el original y se descartó. Inténtalo de nuevo.';

  @override
  String get mapPackErrNoSpace => 'No hay espacio suficiente en el teléfono.';

  @override
  String get mapPackErrNotFound =>
      'Este mapa ya no está disponible en el servidor.';

  @override
  String get mapPackErrServer =>
      'El servidor no pudo entregar el mapa. Inténtalo más tarde.';

  @override
  String get mapPackErrPermission => 'Tu perfil no puede descargar mapas.';

  @override
  String mapOfflineBadge(String name) {
    return 'Mapa sin conexión · $name';
  }

  @override
  String get navTabMap => 'Mapa';

  @override
  String get navTabTicket => 'Ticket';

  @override
  String get navTabMenu => 'Menú';

  @override
  String get navTabInventory => 'Inventario';

  @override
  String get navTabMaintenance => 'Mantenimiento';

  @override
  String mapLayerSubtitle(String layer) {
    return 'Capa: $layer';
  }

  @override
  String mapResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos encontrados',
      one: '1 elemento encontrado',
      zero: 'Ningún elemento encontrado',
    );
    return '$_temp0';
  }

  @override
  String get mapRefine => 'Refinar búsqueda';

  @override
  String get ticketsTitle => 'Historial de tickets';

  @override
  String get ticketsSubtitle => 'Consulta de tickets';

  @override
  String get ticketsSearchHint => 'Buscar por título, ID, km…';

  @override
  String get ticketsSearchTooltip => 'Buscar';

  @override
  String get ticketsFilterTooltip => 'Filtrar';

  @override
  String get ticketsFilterTitle => 'Filtrar tickets';

  @override
  String get ticketsFilterStatus => 'Estado';

  @override
  String get ticketsFilterClear => 'Quitar filtros';

  @override
  String get ticketsFilterDone => 'Listo';

  @override
  String get ticketsDueSort => 'Vencimiento';

  @override
  String get ticketsFilterAll => 'Todos';

  @override
  String get ticketsFilterOpen => 'Abiertos';

  @override
  String get ticketsFilterAttended => 'Atendidos';

  @override
  String get ticketsNew => 'Nuevo ticket';

  @override
  String get ticketStatusOpen => 'Abierto';

  @override
  String get ticketStatusAttended => 'Atendido';

  @override
  String get ticketsEmpty => 'Ningún ticket coincide con los filtros.';

  @override
  String get ticketsEmptyAll => 'Aún no hay tickets.';

  @override
  String get ticketsUnavailableTitle => 'Tickets aún no disponibles';

  @override
  String get ticketsUnavailableBody =>
      'El servidor todavía no publica los tickets de esta concesión.';

  @override
  String get ticketsErrorTitle => 'No se pudieron cargar los tickets';

  @override
  String get ticketsErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get ticketsNoPermissionTitle => 'Sin acceso a tickets';

  @override
  String get ticketsNoPermissionBody => 'Tu perfil no puede ver los tickets.';

  @override
  String get ticketsRetry => 'Reintentar';

  @override
  String get ticketsSampleBanner => 'Datos de ejemplo: no son tickets reales.';

  @override
  String ticketDueHours(int n) {
    return '$n h';
  }

  @override
  String ticketDueDays(int n) {
    return '$n d';
  }

  @override
  String get ticketDueCaption => 'para vencimiento';

  @override
  String get ticketOverdueCaption => 'vencido';

  @override
  String get ticketBack => 'Volver';

  @override
  String ticketIdLabel(String code) {
    return 'ID TICKET #$code';
  }

  @override
  String ticketCreatedOn(String date) {
    return 'Creado el $date';
  }

  @override
  String get ticketInfoGeneratedBy => 'Generado por';

  @override
  String get ticketInfoProfile => 'Perfil de usuario';

  @override
  String get ticketInfoConcession => 'Concesionaria';

  @override
  String get ticketInfoCompany => 'Empresa de usuario';

  @override
  String get ticketInfoLatitude => 'Latitud';

  @override
  String get ticketInfoLongitude => 'Longitud';

  @override
  String get ticketInfoChainage => 'Cadenamiento';

  @override
  String get ticketInfoBody => 'Cuerpo';

  @override
  String get ticketTypeTitle => 'Tipo de ticket';

  @override
  String get ticketDescriptionTitle => 'Descripción';

  @override
  String get ticketFollowUpsTitle => 'Seguimientos';

  @override
  String get ticketFollowUpsEmpty => 'Aún no hay seguimientos.';

  @override
  String get ticketActionDownload => 'Descargar';

  @override
  String get ticketActionEdit => 'Editar';

  @override
  String get ticketActionFollowUp => 'Agregar seguimiento';

  @override
  String get ticketActionSoon => 'Esta acción estará disponible pronto.';

  @override
  String get ticketNotFound => 'No se encontró el ticket.';

  @override
  String get followUpTitle => 'Seguimiento de ticket';

  @override
  String get followUpDate => 'Fecha';

  @override
  String get followUpTime => 'Hora';

  @override
  String get followUpStatus => 'Estado del ticket';

  @override
  String get followUpSelect => 'Seleccionar';

  @override
  String get followUpDescription => 'Descripción';

  @override
  String get followUpFillIn => 'Complete información';

  @override
  String get followUpPhotos => 'Fotografías';

  @override
  String followUpPhoto(int n) {
    return 'Foto $n';
  }

  @override
  String get followUpPhotoRemove => 'Quitar foto';

  @override
  String get followUpSave => 'Guardar seguimiento';

  @override
  String get followUpSaved => 'Seguimiento guardado.';

  @override
  String get followUpErrorStatus => 'Elige el estado del ticket.';

  @override
  String get followUpErrorDescription => 'Escribe una descripción.';

  @override
  String get ticketSaveFailed => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get newTicketTitle => 'Nuevo ticket';

  @override
  String get newTicketName => 'Título';

  @override
  String get newTicketCategory => 'Tipo de ticket';

  @override
  String get newTicketChainage => 'Cadenamiento (km)';

  @override
  String get newTicketCreate => 'Crear ticket';

  @override
  String get newTicketCreated => 'Ticket creado.';

  @override
  String get newTicketErrorTitle => 'Escribe un título.';

  @override
  String get newTicketErrorCategory => 'Elige el tipo de ticket.';

  @override
  String get accidentsTitle => 'Accidentes';

  @override
  String get accidentsSearchHint => 'Buscar por título, ID, km…';

  @override
  String get accidentsSearchTooltip => 'Buscar';

  @override
  String get accidentsFilterTooltip => 'Filtrar';

  @override
  String get accidentsNew => 'Nuevo accidente';

  @override
  String get accidentsEmpty => 'Ningún accidente coincide con los filtros.';

  @override
  String get accidentsEmptyAll => 'Aún no hay accidentes registrados.';

  @override
  String get accidentsUnavailableTitle => 'Accidentes aún no disponibles';

  @override
  String get accidentsUnavailableBody =>
      'El servidor todavía no publica los accidentes de esta concesión.';

  @override
  String get accidentsErrorTitle => 'No se pudieron cargar los accidentes';

  @override
  String get accidentsErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get accidentsNoPermissionTitle => 'Sin acceso a accidentes';

  @override
  String get accidentsNoPermissionBody =>
      'Tu perfil no puede ver los accidentes.';

  @override
  String get accidentsRetry => 'Reintentar';

  @override
  String get accidentsSampleBanner =>
      'Datos de ejemplo: no son accidentes reales.';

  @override
  String get accidentsStatTotal => 'Total';

  @override
  String get accidentsStatTotalShare => '100% total';

  @override
  String accidentsStatShare(String percent) {
    return '$percent%';
  }

  @override
  String get accidentsFilterAll => 'Todos';

  @override
  String get accidentsFilterTitle => 'Filtrar accidentes';

  @override
  String get accidentsFilterSeverity => 'Gravedad';

  @override
  String get accidentTypeCollision => 'Choque';

  @override
  String get accidentTypeRollover => 'Volcamiento';

  @override
  String get accidentTypeFire => 'Incendio';

  @override
  String get accidentSeverityLow => 'Baja';

  @override
  String get accidentSeverityMedium => 'Media';

  @override
  String get accidentSeverityHigh => 'Alta';

  @override
  String get accidentStatusRegistered => 'Registrado';

  @override
  String get accidentStatusInProgress => 'En proceso';

  @override
  String get accidentStatusClosed => 'Cerrado';

  @override
  String accidentIdLabel(String code) {
    return 'ID ACCIDENTE #$code';
  }

  @override
  String get accidentTypeTitle => 'Tipo de accidente';

  @override
  String get accidentSeverityTitle => 'Gravedad';

  @override
  String get accidentNotFound => 'No se encontró el accidente.';

  @override
  String get newAccidentTitle => 'Nuevo accidente';

  @override
  String get newAccidentCreate => 'Registrar accidente';

  @override
  String get newAccidentCreated => 'Accidente registrado.';

  @override
  String get newAccidentErrorType => 'Elige el tipo de accidente.';

  @override
  String get newAccidentErrorSeverity => 'Elige la gravedad.';

  @override
  String get maintIndicatorsTitle => 'Seleccione un indicador';

  @override
  String get maintIndSgp => 'Pavimentos';

  @override
  String get maintIndSgs => 'Señalización';

  @override
  String get maintIndSgoae => 'OAEs';

  @override
  String get maintIndSgoac => 'OACs';

  @override
  String get maintIndSgits => 'Equipos ITS';

  @override
  String get maintIndSgf => 'Faixa de dominio';

  @override
  String get maintIndSgtec => 'Terraplenos y estructuras';

  @override
  String get maintIndSge => 'Edificaciones e instalaciones';

  @override
  String get maintTitle => 'Mantenimiento';

  @override
  String get maintSubtitle =>
      'Consulta y gestión de infraestructura de concesión';

  @override
  String get maintStatusOpen => 'Abierto';

  @override
  String get maintStatusInProgress => 'Proceso';

  @override
  String get maintStatusClosed => 'Cerrado';

  @override
  String get maintStatTotal => 'Total';

  @override
  String get maintStatTotalCaption => '100% total';

  @override
  String get maintStatOpen => 'Abiertos';

  @override
  String get maintStatInProgress => 'Proceso';

  @override
  String get maintStatClosed => 'Cerrados';

  @override
  String maintStatShare(String percent) {
    return '$percent% del total';
  }

  @override
  String get maintFilterState => 'Estado';

  @override
  String get maintFilterAllStates => 'Todos';

  @override
  String get maintDateHint => 'DD/MM/AAAA';

  @override
  String get maintDateFrom => 'Fecha inicial';

  @override
  String get maintDateTo => 'Fecha final';

  @override
  String get maintFilterClear => 'Quitar filtros';

  @override
  String get maintSearchTooltip => 'Buscar';

  @override
  String get maintSearchHint => 'Buscar por ubicación o actividad…';

  @override
  String get maintFilterTooltip => 'Filtrar';

  @override
  String get maintEmpty => 'Ningún mantenimiento coincide con los filtros.';

  @override
  String get maintEmptyAll => 'No hay mantenimientos para este indicador.';

  @override
  String get maintUnavailableTitle => 'Mantenimiento aún no disponible';

  @override
  String get maintUnavailableBody =>
      'El servidor todavía no publica el mantenimiento de esta concesión.';

  @override
  String get maintErrorTitle => 'No se pudo cargar el mantenimiento';

  @override
  String get maintErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get maintNoPermissionTitle => 'Sin acceso a mantenimiento';

  @override
  String get maintNoPermissionBody => 'Tu perfil no puede ver este indicador.';

  @override
  String get maintRetry => 'Reintentar';

  @override
  String get maintSampleBanner =>
      'Datos de ejemplo: no son mantenimientos reales.';

  @override
  String maintTotalVolume(String value) {
    return 'Volumen Total: $value';
  }

  @override
  String maintUnitDescription(String unit) {
    return 'Descripción: $unit';
  }

  @override
  String get maintProgress => 'Avance';

  @override
  String maintActivity(String activity) {
    return 'Actividad: $activity';
  }

  @override
  String get maintProjectProgress => 'Avance del proyecto';

  @override
  String get maintExecutedAmount => 'Importe Ejec.';

  @override
  String get maintPendingAmount => 'Por Ejecutar';

  @override
  String get maintDetailsTitle => 'Detalles de mantenimiento';

  @override
  String get maintKmStart => 'Km inicial';

  @override
  String get maintKmEnd => 'Km final';

  @override
  String get maintDirection => 'Dirección';

  @override
  String get maintSense => 'Sentido';

  @override
  String get maintVolumeTotal => 'Volumen total';

  @override
  String get maintVolumeExecuted => 'Volumen ejecutado';

  @override
  String get maintUnitCost => 'Costo unitario';

  @override
  String get maintProgrammedAmount => 'Importe programado';

  @override
  String get maintStartDate => 'Fecha inicio';

  @override
  String get maintEndDate => 'Fecha fin';

  @override
  String get maintNotFound => 'No se encontró el mantenimiento.';
}
