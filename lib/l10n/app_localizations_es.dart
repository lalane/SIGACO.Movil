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
  String get docsPreviewPdfPendingBody =>
      'Este dispositivo todavía no muestra documentos PDF.';

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
}
