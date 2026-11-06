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
  String get errValidation =>
      'No se pudo guardar. Revisa los datos e inténtalo de nuevo.';

  @override
  String get passwordRulesTitle => 'La contraseña debe tener:';

  @override
  String passwordRuleLength(int min) {
    return 'Al menos $min caracteres';
  }

  @override
  String get passwordRuleUppercase => 'Una letra mayúscula';

  @override
  String get passwordRuleLowercase => 'Una letra minúscula';

  @override
  String get passwordRuleDigit => 'Un número';

  @override
  String get passwordRuleSpecial =>
      'Un carácter especial (por ejemplo ! # \$ %)';

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
  String get demoModeTitle => 'Datos de ejemplo';

  @override
  String get demoModeOn =>
      'Todo se ve con datos inventados; no se consulta el servidor';

  @override
  String get demoModeOff =>
      'Ver la app con datos inventados para conocer cómo está armada';

  @override
  String get demoModeSnackOn => 'Datos de ejemplo activados';

  @override
  String get demoModeSnackOff => 'Datos reales';

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
  String get moduleInventory => 'Catálogo';

  @override
  String get moduleInventorySub => 'Control de activos y faja';

  @override
  String get moduleReports => 'Reportes';

  @override
  String get moduleReportsSub => 'Consulta y exportación';

  @override
  String get moduleTickets => 'Registros';

  @override
  String get moduleTicketsSub => 'Seguimiento y registro';

  @override
  String get moduleAlerts => 'Alertas';

  @override
  String get moduleAlertsSub => 'Eventos operativos';

  @override
  String get moduleComingSoon => 'Este módulo está en desarrollo.';

  @override
  String get navTickets => 'Registros';

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
  String get fieldJobTitle => 'Cargo';

  @override
  String get fieldCompany => 'Empresa';

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
  String get profilePhotoTitle => 'Foto de perfil';

  @override
  String get profilePhotoTake => 'Tomar una foto';

  @override
  String get profilePhotoGallery => 'Elegir de la galería';

  @override
  String get profilePhotoRemove => 'Quitar la foto';

  @override
  String get profilePhotoFailed => 'No se pudo guardar la foto';

  @override
  String get actionSwitchConcessionSub => 'Elige otra concesión para trabajar';

  @override
  String get switchConcessionWarning =>
      'Al cambiar de concesión se abre una sesión nueva y se descarta lo cargado de la anterior.';

  @override
  String get passwordChanged =>
      'Contraseña actualizada. Se cerraron tus otras sesiones.';

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
  String get syncEntityTicket => 'Registro';

  @override
  String get syncEntityInspection => 'Monitoreo';

  @override
  String get syncEntityEvent => 'Evento';

  @override
  String get syncEntityAsset => 'Activo';

  @override
  String get syncEntitySurvey => 'Levantamiento';

  @override
  String get syncEntityMedia => 'Archivo';

  @override
  String get syncEntityMaintenanceProgress => 'Avance de mantenimiento';

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
  String get mapTabTickets => 'Registros';

  @override
  String get mapTabInventory => 'Catálogo';

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
  String get mapNearbyLoading => 'Cargando el catálogo…';

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
      'Crear un registro, un monitoreo o un mantenimiento desde aquí se habilitará cuando esos módulos estén disponibles.';

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
  String get navTabTicket => 'Registro';

  @override
  String get navTabMenu => 'Menú';

  @override
  String get navTabInventory => 'Catálogo';

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
  String get ticketsTitle => 'Historial de registros';

  @override
  String get ticketsSubtitle => 'Consulta de registros';

  @override
  String get ticketsSearchHint => 'Buscar por título, ID, km…';

  @override
  String get ticketsSearchTooltip => 'Buscar';

  @override
  String get ticketsFilterTooltip => 'Filtrar';

  @override
  String get ticketsFilterTitle => 'Filtrar registros';

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
  String get ticketsNew => 'Nuevo registro';

  @override
  String get ticketStatusOpen => 'Abierto';

  @override
  String get ticketStatusAttended => 'Atendido';

  @override
  String get ticketsEmpty => 'Ningún registro coincide con los filtros.';

  @override
  String get ticketsEmptyAll => 'Aún no hay registros.';

  @override
  String get ticketsUnavailableTitle => 'Registros aún no disponibles';

  @override
  String get ticketsUnavailableBody =>
      'El servidor todavía no publica los registros de esta concesión.';

  @override
  String get ticketsErrorTitle => 'No se pudieron cargar los registros';

  @override
  String get ticketsErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get ticketsNoPermissionTitle => 'Sin acceso a registros';

  @override
  String get ticketsNoPermissionBody => 'Tu perfil no puede ver los registros.';

  @override
  String get ticketsRetry => 'Reintentar';

  @override
  String get ticketsSampleBanner =>
      'Datos de ejemplo: no son registros reales.';

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
    return 'ID REGISTRO #$code';
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
  String get ticketTypeTitle => 'Tipo de registro';

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
  String get ticketNotFound => 'No se encontró el registro.';

  @override
  String get followUpTitle => 'Seguimiento de registro';

  @override
  String get followUpDate => 'Fecha';

  @override
  String get followUpTime => 'Hora';

  @override
  String get followUpStatus => 'Estado del registro';

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
  String get followUpErrorStatus => 'Elige el estado del registro.';

  @override
  String get followUpErrorDescription => 'Escribe una descripción.';

  @override
  String ticketSavedPartly(String reason) {
    return 'El registro se guardó, pero faltó una parte: $reason';
  }

  @override
  String get ticketSaveFailed => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get newTicketPriority => 'Prioridad';

  @override
  String get ticketPriorityLow => 'Baja';

  @override
  String get ticketPriorityMedium => 'Media';

  @override
  String get ticketPriorityHigh => 'Alta';

  @override
  String get ticketPriorityCritical => 'Crítica';

  @override
  String get newTicketTitle => 'Nuevo registro';

  @override
  String get newTicketName => 'Título';

  @override
  String get newTicketCategory => 'Tipo de registro';

  @override
  String get newTicketChainage => 'Cadenamiento (km)';

  @override
  String get newTicketCreate => 'Crear registro';

  @override
  String get newTicketCreated => 'Registro creado.';

  @override
  String get newTicketErrorTitle => 'Escribe un título.';

  @override
  String get newTicketErrorCategory => 'Elige el tipo de registro.';

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
  String get fieldTeam => 'Equipo';

  @override
  String get profilePhotoChange => 'Cambiar foto';

  @override
  String get accountPanelTitle => 'Configuraciones de la cuenta';

  @override
  String get accountMyAccount => 'Mi cuenta';

  @override
  String get accountSettingsTitle => 'Configuración';

  @override
  String get accountSettingsSub => 'Seguridad, preferencias y dispositivo';

  @override
  String get accountDeviceSection => 'Acerca del dispositivo';

  @override
  String get indicatorsPanelTitle => 'Indicadores';

  @override
  String get indicatorsPanelSubtitle => 'Mantenimiento y conservación';

  @override
  String get indicatorsSearchHint => 'Buscar indicador';

  @override
  String get indicatorsNoMatch => 'Ningún indicador coincide.';

  @override
  String get homeOpenMenu => 'Abrir menú';

  @override
  String get homeSummaryTickets => 'Registros abiertos';

  @override
  String homeSummaryOverdue(int count) {
    return '$count vencidos';
  }

  @override
  String get homeSummaryOnTime => 'Al día';

  @override
  String get homeSummaryAssets => 'Activos';

  @override
  String get homeSummaryAccidents => 'Accidentes';

  @override
  String get homeSummaryAlerts => 'Alertas';

  @override
  String homeSummaryUnread(int count) {
    return '$count sin leer';
  }

  @override
  String homeSummaryInProgress(int count) {
    return '$count en proceso';
  }

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
  String get maintProgressTitle => 'Registrar avance';

  @override
  String get maintProgressPercent =>
      'Avance acumulado (%), si no conoces el volumen';

  @override
  String get maintProgressVolume => 'Volumen ejecutado en este seguimiento';

  @override
  String maintProgressVolumeUnit(String unit) {
    return 'Volumen ejecutado en este seguimiento ($unit)';
  }

  @override
  String get maintProgressNotes => 'Notas';

  @override
  String get maintProgressOptional => 'Opcional';

  @override
  String get maintProgressSave => 'Guardar avance';

  @override
  String get maintProgressSaved => 'Avance guardado.';

  @override
  String get maintProgressErrorPercent => 'Escribe un avance entre 0 y 100.';

  @override
  String get maintProgressErrorVolume => 'Escribe un volumen mayor que 0.';

  @override
  String get maintProgressNetwork =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get maintProgressNoPermission =>
      'Tu perfil no puede registrar avances.';

  @override
  String get maintProgressFailed =>
      'No se pudo guardar el avance. Inténtalo de nuevo.';

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

  @override
  String get invTitle => 'Catálogo';

  @override
  String get invSubtitle => 'Activos de la concesión';

  @override
  String get invSearchTooltip => 'Buscar';

  @override
  String get invSearchHint => 'Buscar activo, tramo o kilómetro';

  @override
  String get invFilterClear => 'Quitar filtros';

  @override
  String get invSampleBanner => 'Datos de ejemplo: no son activos reales.';

  @override
  String get invStatTotal => 'Total';

  @override
  String get invStatTotalCaption => '100% total';

  @override
  String invStatShare(String percent) {
    return '$percent% del total';
  }

  @override
  String get invStatGood => 'Buenos';

  @override
  String get invStatRegular => 'Regulares';

  @override
  String get invStatPoor => 'Malos';

  @override
  String get invConditionGood => 'Bueno';

  @override
  String get invConditionRegular => 'Regular';

  @override
  String get invConditionPoor => 'Malo';

  @override
  String get invConditionUnknown => 'Sin evaluar';

  @override
  String get invSitePhoto => 'Vista en sitio';

  @override
  String get invFilterCondition => 'Estado';

  @override
  String get invFilterAllConditions => 'Todos los estados';

  @override
  String get invFilterCategory => 'Tipo';

  @override
  String get invFilterAllCategories => 'Todos los tipos';

  @override
  String get invInspectedFrom => 'Monitoreo desde';

  @override
  String get invInspectedTo => 'Monitoreo hasta';

  @override
  String get invDateHint => 'Fecha';

  @override
  String get invEmptyAll => 'Aún no hay activos registrados.';

  @override
  String get invEmpty => 'Ningún activo coincide con los filtros.';

  @override
  String get invUnavailableTitle => 'Catálogo no disponible';

  @override
  String get invUnavailableBody =>
      'Esta concesión todavía no publica su catálogo en la app.';

  @override
  String get invNoPermissionTitle => 'Sin acceso al catálogo';

  @override
  String get invNoPermissionBody => 'Tu perfil no puede consultar el catálogo.';

  @override
  String get invNotFound => 'El activo ya no existe.';

  @override
  String get invErrorTitle => 'No se pudo cargar el catálogo';

  @override
  String get invErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get invRetry => 'Reintentar';

  @override
  String get invDetailTitle => 'Activo';

  @override
  String get invDetailsTitle => 'Datos del activo';

  @override
  String get invCategoryLabel => 'Tipo';

  @override
  String get invKm => 'Kilómetro';

  @override
  String get invSegment => 'Tramo';

  @override
  String get invDirection => 'Sentido';

  @override
  String get invInstalled => 'Instalación';

  @override
  String get invLastInspection => 'Último monitoreo';

  @override
  String get invCoordinates => 'Coordenadas';

  @override
  String get invNotes => 'Observaciones';

  @override
  String get invViewOnMap => 'Ver en mapa';

  @override
  String get invNoLocation => 'Este activo no tiene ubicación.';

  @override
  String invCardInspected(String date) {
    return 'Monitoreo: $date';
  }

  @override
  String get repTitle => 'Indicadores y reportes';

  @override
  String get repSelectTitle => 'Seleccione un indicador';

  @override
  String get repReportSubtitle => 'Reporte del indicador';

  @override
  String get repSampleBanner =>
      'Datos de ejemplo: el reporte sale de mantenimientos de ejemplo.';

  @override
  String get repFrom => 'Desde';

  @override
  String get repTo => 'Hasta';

  @override
  String get repDateHint => 'Fecha';

  @override
  String get repGenerate => 'Generar reporte';

  @override
  String get repRegenerate => 'Actualizar reporte';

  @override
  String get repNotGenerated =>
      'Elige el periodo y genera el reporte. Sin fechas, incluye todo el historial.';

  @override
  String repGeneratedAt(String date) {
    return 'Generado: $date';
  }

  @override
  String get repPeriodAll => 'Todo el historial';

  @override
  String repPeriodRange(String from, String to) {
    return 'Del $from al $to';
  }

  @override
  String repPeriodFrom(String from) {
    return 'Desde el $from';
  }

  @override
  String repPeriodUntil(String to) {
    return 'Hasta el $to';
  }

  @override
  String get repStale => 'Cambiaste el periodo: actualiza el reporte.';

  @override
  String get repSummaryTitle => 'Resumen';

  @override
  String get repTotal => 'Total';

  @override
  String get repStatusOpen => 'Abiertos';

  @override
  String get repStatusInProgress => 'En proceso';

  @override
  String get repStatusClosed => 'Cerrados';

  @override
  String get repExecution => 'Ejecución del importe';

  @override
  String get repProgrammedAmount => 'Programado';

  @override
  String get repExecutedAmount => 'Ejecutado';

  @override
  String get repPendingAmount => 'Por ejecutar';

  @override
  String get repOrdersTitle => 'Mantenimientos del periodo';

  @override
  String get repEmpty =>
      'No hay mantenimientos de este indicador en el periodo.';

  @override
  String get repUnavailableTitle => 'Reportes no disponibles';

  @override
  String get repUnavailableBody =>
      'Esta concesión todavía no publica los datos para los reportes.';

  @override
  String get repNoPermissionTitle => 'Sin acceso al reporte';

  @override
  String get repNoPermissionBody =>
      'Tu perfil no puede consultar este indicador.';

  @override
  String get repErrorTitle => 'No se pudo generar el reporte';

  @override
  String get repErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get repRetry => 'Reintentar';

  @override
  String get dashTitle => 'Dashboard';

  @override
  String get dashSubtitle => 'Resumen operativo';

  @override
  String get dashSampleBanner =>
      'Datos de ejemplo: el resumen sale de los módulos de ejemplo.';

  @override
  String dashUpdated(String date) {
    return 'Actualizado: $date';
  }

  @override
  String get dashViewMap => 'Ver mapa';

  @override
  String get dashTickets => 'Registros';

  @override
  String get dashTicketsOpen => 'Abiertos';

  @override
  String get dashTicketsAttended => 'Atendidos';

  @override
  String get dashTicketsOverdue => 'Vencidos';

  @override
  String get dashAccidents => 'Accidentes';

  @override
  String dashAccidentsPeriod(int days) {
    return 'Últimos $days días';
  }

  @override
  String get dashAccidentsTotal => 'Registrados';

  @override
  String get dashAccidentsSevere => 'Graves';

  @override
  String get dashAccidentsOpen => 'En seguimiento';

  @override
  String get dashMaintenance => 'Mantenimiento';

  @override
  String get dashMaintOpen => 'Abiertos';

  @override
  String get dashMaintInProgress => 'En proceso';

  @override
  String get dashMaintClosed => 'Cerrados';

  @override
  String dashMaintExecution(String percent) {
    return 'Ejecución del importe: $percent';
  }

  @override
  String get dashInventory => 'Catálogo';

  @override
  String dashInventoryTotal(int count) {
    return '$count activos';
  }

  @override
  String get dashInvGood => 'Buenos';

  @override
  String get dashInvRegular => 'Regulares';

  @override
  String get dashInvPoor => 'Malos';

  @override
  String get dashSectionUnavailable => 'Aún no disponible en esta concesión.';

  @override
  String get dashSectionNoPermission =>
      'Tu perfil no tiene acceso a este módulo.';

  @override
  String get dashSectionError => 'No se pudo cargar esta información.';

  @override
  String get dashRetry => 'Reintentar';

  @override
  String get dashErrorTitle => 'No se pudo cargar el dashboard';

  @override
  String get dashErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get dashUnavailableTitle => 'Dashboard no disponible';

  @override
  String get dashUnavailableBody =>
      'Esta concesión todavía no publica datos para el resumen.';

  @override
  String get workTitle => 'Obras';

  @override
  String get workSubtitle => 'Avance de obras y conservación';

  @override
  String get workSearchTooltip => 'Buscar';

  @override
  String get workSearchHint => 'Buscar obra, contratista o tramo';

  @override
  String get workFilterClear => 'Quitar filtros';

  @override
  String get workSampleBanner => 'Datos de ejemplo: no son obras reales.';

  @override
  String get workStatTotal => 'Total';

  @override
  String get workStatTotalCaption => 'obras';

  @override
  String get workStatNotStarted => 'Por iniciar';

  @override
  String get workStatInProgress => 'En ejecución';

  @override
  String get workStatDelayed => 'Con atraso';

  @override
  String get workStatFinished => 'Terminadas';

  @override
  String get workStatusNotStarted => 'Por iniciar';

  @override
  String get workStatusInProgress => 'En ejecución';

  @override
  String get workStatusDelayed => 'Con atraso';

  @override
  String get workStatusFinished => 'Terminada';

  @override
  String get workFilterState => 'Estado';

  @override
  String get workFilterAllStates => 'Todos los estados';

  @override
  String get workEmptyAll => 'Aún no hay obras registradas.';

  @override
  String get workEmpty => 'Ninguna obra coincide con los filtros.';

  @override
  String get workUnavailableTitle => 'Obras no disponibles';

  @override
  String get workUnavailableBody =>
      'Esta concesión todavía no publica sus obras en la app.';

  @override
  String get workNoPermissionTitle => 'Sin acceso a las obras';

  @override
  String get workNoPermissionBody => 'Tu perfil no puede consultar las obras.';

  @override
  String get workNotFound => 'La obra ya no existe.';

  @override
  String get workErrorTitle => 'No se pudieron cargar las obras';

  @override
  String get workErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get workRetry => 'Reintentar';

  @override
  String get workDetailTitle => 'Obra';

  @override
  String get workPhysical => 'Avance físico';

  @override
  String get workProgrammed => 'Avance programado';

  @override
  String workLag(String percent) {
    return 'Atraso: $percent';
  }

  @override
  String get workOnTrack => 'Al día con el programa';

  @override
  String get workBudget => 'Presupuesto';

  @override
  String get workExecutedAmount => 'Ejercido';

  @override
  String get workPendingAmount => 'Por ejercer';

  @override
  String get workDetailsTitle => 'Datos de la obra';

  @override
  String get workContractor => 'Contratista';

  @override
  String get workKmStart => 'Km inicial';

  @override
  String get workKmEnd => 'Km final';

  @override
  String get workSegment => 'Tramo';

  @override
  String get workDirection => 'Sentido';

  @override
  String get workStartDate => 'Inicio';

  @override
  String get workEndDate => 'Fin';

  @override
  String get workViewOnMap => 'Ver en mapa';

  @override
  String get workNoLocation => 'Esta obra no tiene ubicación.';

  @override
  String get inspTitle => 'Monitoreo';

  @override
  String get inspSubtitle => 'Asignadas y en campo';

  @override
  String get inspSearchTooltip => 'Buscar';

  @override
  String get inspSearchHint => 'Buscar monitoreo, activo o tramo';

  @override
  String get inspFilterClear => 'Quitar filtros';

  @override
  String get inspSampleBanner => 'Datos de ejemplo: no son monitoreos reales.';

  @override
  String get inspStatPending => 'Pendientes';

  @override
  String get inspStatInProgress => 'En proceso';

  @override
  String get inspStatAttended => 'Atendidas';

  @override
  String get inspStatClosed => 'Cerradas';

  @override
  String get inspStatCaption => 'monitoreos';

  @override
  String get inspStatusPending => 'Pendiente';

  @override
  String get inspStatusInProgress => 'En proceso';

  @override
  String get inspStatusAttended => 'Atendida';

  @override
  String get inspStatusClosed => 'Cerrada';

  @override
  String get inspStatusCancelled => 'Cancelada';

  @override
  String get inspFilterState => 'Estado';

  @override
  String get inspFilterAllStates => 'Todos los estados';

  @override
  String get inspEmptyAll => 'Aún no tienes monitoreos asignados.';

  @override
  String get inspEmpty => 'Ningún monitoreo coincide con los filtros.';

  @override
  String get inspUnavailableTitle => 'Monitoreo no disponible';

  @override
  String get inspUnavailableBody =>
      'Esta concesión todavía no publica su monitoreo en la app.';

  @override
  String get inspNoPermissionTitle => 'Sin acceso al monitoreo';

  @override
  String get inspNoPermissionBody =>
      'Tu perfil no puede consultar el monitoreo.';

  @override
  String get inspNotFound => 'El monitoreo ya no existe.';

  @override
  String get inspErrorTitle => 'No se pudo cargar el monitoreo';

  @override
  String get inspErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get inspRetry => 'Reintentar';

  @override
  String get inspDetailTitle => 'Monitoreo';

  @override
  String get inspChecklistTitle => 'Checklist';

  @override
  String inspChecklistProgress(int done, int total) {
    return '$done de $total puntos';
  }

  @override
  String get inspResultOk => 'Cumple';

  @override
  String get inspResultFinding => 'Hallazgo';

  @override
  String get inspCritical => 'Crítico';

  @override
  String inspFindings(int count) {
    return '$count hallazgos';
  }

  @override
  String inspCriticalFindings(int count) {
    return '$count críticos';
  }

  @override
  String get inspScheduled => 'Programada';

  @override
  String get inspCompletedOn => 'Terminada';

  @override
  String get inspAssignee => 'Responsable';

  @override
  String get inspType => 'Tipo';

  @override
  String get inspAsset => 'Activo';

  @override
  String get inspKm => 'Kilómetro';

  @override
  String get inspSegment => 'Tramo';

  @override
  String get inspDirection => 'Sentido';

  @override
  String get inspComplete => 'Finalizar monitoreo';

  @override
  String get inspCompleteHint =>
      'Responde todos los puntos para poder finalizar.';

  @override
  String get inspCompleted => 'Monitoreo finalizado.';

  @override
  String get inspCompletedCritical =>
      'Monitoreo finalizado. Hay hallazgos críticos: deben generar un registro o una alerta.';

  @override
  String get inspNotEditable => 'Este monitoreo ya no se puede modificar.';

  @override
  String get inspIncomplete => 'Faltan puntos del checklist por responder.';

  @override
  String get inspSaveError => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get inspViewAsset => 'Ver activo';

  @override
  String get inspNoAsset => 'Este monitoreo no tiene un activo del catálogo.';

  @override
  String get inspNew => 'Nuevo monitoreo';

  @override
  String get inspNewCreate => 'Crear monitoreo';

  @override
  String get inspNewType => 'Tipo de monitoreo';

  @override
  String get inspNewName => 'Nombre';

  @override
  String get inspNewNameHint => 'Opcional: si lo dejas vacío se usa el tipo';

  @override
  String get inspNewErrorType => 'Elige el tipo de monitoreo.';

  @override
  String get inspNewCreated => 'Monitoreo creado.';

  @override
  String get inspNewNoTemplates => 'No hay tipos de monitoreo disponibles.';

  @override
  String get inspEvidenceTitle => 'Hallazgos y evidencias';

  @override
  String get inspEvidenceAdd => 'Agregar hallazgo';

  @override
  String get inspEvidenceEmpty => 'Aún no hay hallazgos capturados.';

  @override
  String get inspEvidenceNote => 'Descripción del hallazgo';

  @override
  String get inspEvidenceItem => 'Punto del checklist';

  @override
  String get inspEvidenceNoItem => 'Sin punto del checklist';

  @override
  String get inspEvidenceSave => 'Guardar hallazgo';

  @override
  String get inspEvidenceErrorEmpty =>
      'Escribe una descripción o toma una foto.';

  @override
  String get inspEvidenceSaved => 'Hallazgo guardado.';

  @override
  String inspEvidencePhotos(int count) {
    return '$count fotos';
  }

  @override
  String inspEvidencePosition(String lat, String lon, String accuracy) {
    return 'Posición $lat, $lon (±$accuracy m)';
  }

  @override
  String get inspEvidenceNoPosition => 'Sin posición (GPS no disponible)';

  @override
  String get inspDraftSaved =>
      'Borrador guardado: tus respuestas se guardan solas.';

  @override
  String get moduleInspections => 'Monitoreo';

  @override
  String get moduleInspectionsSub => 'Checklists en campo';

  @override
  String get moduleWorks => 'Obras';

  @override
  String get moduleWorksSub => 'Avance y programas';

  @override
  String get cfgGateTitle => 'Sin configuración de la concesión';

  @override
  String get cfgGateBody =>
      'Para registrar necesitas la configuración de la concesión y su zona horaria. Conéctate a internet y sincroniza.';

  @override
  String get cfgGateRetry => 'Sincronizar ahora';

  @override
  String get cfgGateInspection =>
      'Sin la configuración de la concesión no puedes responder el monitoreo. Conéctate y sincroniza.';

  @override
  String get mapFilterOperating => 'Estado del equipo';

  @override
  String get mapOpInOperation => 'En operación';

  @override
  String get mapOpInMaintenance => 'En mantenimiento';

  @override
  String get mapOpOutOfService => 'Fuera de servicio';

  @override
  String get ticketLocationTitle => 'Ubicación';

  @override
  String ticketLocationAccuracy(String meters) {
    return 'Precisión ±$meters m';
  }

  @override
  String get ticketLocOriginGps => 'Lectura del GPS';

  @override
  String get ticketLocOriginLastKnown => 'Última posición conocida';

  @override
  String get ticketLocOriginMapPoint => 'Punto elegido en el mapa';

  @override
  String get ticketLocOriginAsset => 'Ubicación del activo';

  @override
  String ticketLocationAgo(int minutes) {
    return 'de hace $minutes min';
  }

  @override
  String ticketLocationAsset(String id) {
    return 'Activo $id';
  }

  @override
  String get ticketLocationIssueTitle => 'Revisa la ubicación';

  @override
  String ticketLocationLowAccuracy(String meters, String min) {
    return 'La precisión es de ±$meters m y el mínimo es de $min m. ¿Guardar de todos modos?';
  }

  @override
  String get ticketLocationLastKnownWarn =>
      'Es la última posición conocida, no una lectura actual. ¿Guardar de todos modos?';

  @override
  String get ticketLocationSaveAnyway => 'Guardar de todos modos';

  @override
  String get ticketLocationCancel => 'Cancelar';

  @override
  String get mapRecordHere => 'Registrar aquí';

  @override
  String get mapOpenRecord => 'Abrir ficha';

  @override
  String get mapCreateRecord => 'Crear registro';

  @override
  String get mapNavigate => 'Navegar';

  @override
  String get mapPickedTitle => 'Punto elegido';

  @override
  String get mapPickedClose => 'Quitar punto';

  @override
  String get mapPickHint => 'Mantén presionado el mapa para elegir un punto.';

  @override
  String get mapNavigateFailed =>
      'No se pudo abrir la navegación del teléfono.';

  @override
  String get mapRecordMocked =>
      'La ubicación es simulada: no se puede usar para registrar.';

  @override
  String get sessionLockedTitle => 'Sesión bloqueada';

  @override
  String sessionLockedBody(int minutes) {
    return 'Pasaron $minutes minutos sin actividad. Confirma tu identidad para continuar.';
  }

  @override
  String get sessionUnlock => 'Desbloquear';

  @override
  String get sessionUnlockReason =>
      'Confirma tu identidad para desbloquear SIGACO';

  @override
  String get sessionUnlockUnavailable =>
      'Este teléfono no tiene un bloqueo de pantalla para confirmar tu identidad. Cierra la sesión y vuelve a entrar.';

  @override
  String get mfaRecoveryTitle => 'Guarda tus códigos de recuperación';

  @override
  String get mfaRecoveryBody =>
      'Si pierdes tu teléfono o la app autenticadora, cada uno de estos códigos te deja entrar una sola vez. Guárdalos en un lugar seguro: no se volverán a mostrar.';

  @override
  String get mfaRecoveryCopy => 'Copiar todos';

  @override
  String get mfaRecoveryCopied => 'Códigos copiados';

  @override
  String get mfaRecoverySaved => 'Ya los guardé';

  @override
  String get mfaUseRecoveryCode => 'Usar un código de recuperación';

  @override
  String get mfaUseAppCode => 'Usar el código de la app';

  @override
  String get mfaRecoveryCodeHint => 'Código de recuperación';

  @override
  String mfaRecoveryRemaining(int count) {
    return 'Te quedan $count códigos de recuperación sin usar';
  }

  @override
  String get mfaRecoveryGenerate => 'Generar códigos nuevos';

  @override
  String get mfaRecoveryGenerateBody =>
      'Los códigos anteriores dejarán de servir. Escribe el código de tu app autenticadora para confirmar.';

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get alertsSubtitle => 'Avisos de tu concesión';

  @override
  String get alertsMarkAll => 'Marcar todas como leídas';

  @override
  String get alertsFilterAll => 'Todas';

  @override
  String get alertsFilterUnread => 'Sin leer';

  @override
  String get alertsEmptyAll => 'No tienes alertas.';

  @override
  String get alertsEmptyUnread => 'No tienes alertas sin leer.';

  @override
  String get alertsUnavailableTitle => 'Alertas aún no disponibles';

  @override
  String get alertsUnavailableBody =>
      'El servidor todavía no publica tus alertas. Cuando estén listas aparecerán aquí.';

  @override
  String get alertsErrorTitle => 'No se pudieron cargar las alertas';

  @override
  String get alertsErrorBody => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get alertsRetry => 'Reintentar';

  @override
  String get alertsNoPermissionTitle => 'Sin permiso para ver alertas';

  @override
  String get alertsNoPermissionBody =>
      'Tu perfil no incluye las alertas de esta concesión.';

  @override
  String get alertsSampleBanner =>
      'Alertas de ejemplo: aún no vienen del servidor.';

  @override
  String get alertsSeverityInfo => 'Informativa';

  @override
  String get alertsSeverityWarning => 'Atención';

  @override
  String get alertsSeverityCritical => 'Urgente';

  @override
  String get alertsSeeDetail => 'Ver detalle';

  @override
  String alertsUnreadSemantic(int count) {
    return '$count alertas sin leer';
  }

  @override
  String get maintIndConservacion => 'Conservación';

  @override
  String get maintIndSgsei => 'Sistemas eléctricos e iluminación';

  @override
  String get maintIndSgost => 'Túneles';

  @override
  String get accidentTypeRunOver => 'Atropello';

  @override
  String get accidentTypeOther => 'Otro';

  @override
  String get accidentSeverityUnharmed => 'Ileso';

  @override
  String get accidentSeverityMinor => 'Lesiones menores';

  @override
  String get accidentSeverityFatal => 'Deceso';

  @override
  String get accidentZoneTitle => 'Zona';

  @override
  String get accidentZoneRural => 'Rural';

  @override
  String get accidentZoneSuburban => 'Suburbana';

  @override
  String get accidentZoneUrban => 'Urbana';

  @override
  String get accidentWeatherTitle => 'Clima';

  @override
  String get accidentWeatherWind => 'Viento';

  @override
  String get accidentWeatherRain => 'Lluvia';

  @override
  String get accidentWeatherFog => 'Niebla';

  @override
  String get accidentWeatherNormal => 'Normal';

  @override
  String get accidentPavementConditionTitle => 'Estado del pavimento';

  @override
  String get accidentSignageConditionTitle => 'Estado del señalamiento';

  @override
  String get accidentConditionGood => 'Buena';

  @override
  String get accidentConditionFair => 'Regular';

  @override
  String get accidentConditionPoor => 'Mala';

  @override
  String get accidentLayoutTitle => 'Trazado';

  @override
  String get accidentLayoutStraight => 'Recta';

  @override
  String get accidentLayoutVerticalCurve => 'Curva vertical';

  @override
  String get accidentLayoutHorizontalCurve => 'Curva horizontal';

  @override
  String get accidentPavementTypeTitle => 'Tipo de pavimento';

  @override
  String get accidentPavementRigid => 'Rígido';

  @override
  String get accidentPavementFlexible => 'Flexible';

  @override
  String get accidentCauseTitle => 'Causa';

  @override
  String get accidentCauseSpeeding => 'Exceso de velocidad';

  @override
  String get accidentCauseLaneInvasion => 'Invasión de carril';

  @override
  String get accidentCauseOther => 'Otra';

  @override
  String get accidentPlaceTitle => 'Lugar del accidente';

  @override
  String get accidentPlacePavement => 'Pavimento';

  @override
  String get accidentPlaceSignage => 'Señalamiento';

  @override
  String get accidentPlaceTollBooth => 'Casetas';

  @override
  String get accidentPlaceOther => 'Otros';

  @override
  String get accidentVehiclesTitle => 'Vehículos involucrados';

  @override
  String get accidentVehiclesCount => 'Cantidad de vehículos';

  @override
  String accidentVehicleTitle(int n) {
    return 'Vehículo $n';
  }

  @override
  String get accidentVehicleTypeTitle => 'Tipo de vehículo';

  @override
  String get accidentVehicleCar => 'Vehículo';

  @override
  String get accidentVehicleMotorcycle => 'Motocicleta';

  @override
  String get accidentVehicleLivestock => 'Semoviente';

  @override
  String get accidentVehicleFixedObject => 'Objeto fijo';

  @override
  String get accidentVictimsTitle => 'Víctimas';

  @override
  String get accidentVictimsCount => 'Cantidad de víctimas';

  @override
  String accidentVictimTitle(int n) {
    return 'Víctima $n';
  }

  @override
  String get accidentSexTitle => 'Sexo';

  @override
  String get accidentSexFemale => 'Femenino';

  @override
  String get accidentSexMale => 'Masculino';

  @override
  String get accidentSexUnspecified => 'No especificado';

  @override
  String get accidentSeverityDerived =>
      'La gravedad del accidente es la de la víctima más grave.';

  @override
  String get newAccidentErrorVehicle => 'Elige el tipo de vehículo.';

  @override
  String get newAccidentErrorVictim => 'Elige la gravedad de la víctima.';

  @override
  String get accidentConditionsTitle => 'Condiciones del lugar';

  @override
  String get accidentSeveritySerious => 'Heridas graves';

  @override
  String get dashCompliance => 'Cumplimiento';

  @override
  String get dashComplianceUnavailable =>
      'El cumplimiento por indicador aún no está disponible.';

  @override
  String dashComplianceMet(int met, int total) {
    return 'Indicadores cumplidos: $met de $total';
  }

  @override
  String get dashStatusInProcess => 'En proceso';

  @override
  String get dashStatusGood => 'Buen estado';

  @override
  String get dashStatusIntermediate => 'Estado intermedio';

  @override
  String get dashStatusBad => 'Mal estado';

  @override
  String get dashTicketsBySubsystem => 'Indicadores con más tickets';

  @override
  String get dashTopCreators => 'Usuarios que más tickets han generado';

  @override
  String maintProgressStatus(
    String executed,
    String total,
    String unit,
    String percent,
    String remaining,
  ) {
    return 'Llevas $executed de $total $unit ($percent %). Faltan $remaining.';
  }

  @override
  String maintProgressResult(String percent) {
    return 'Quedará en $percent %.';
  }

  @override
  String get maintProgressVolumeRules =>
      'Se suma a lo ya ejecutado. Con volumen, el avance se calcula solo.';

  @override
  String get maintProgressErrorMissing =>
      'Escribe el volumen ejecutado o el avance acumulado.';

  @override
  String maintProgressErrorVolumeOver(String remaining) {
    return 'Supera lo que falta: quedan $remaining.';
  }

  @override
  String maintProgressErrorPercentBelow(String percent) {
    return 'El avance no puede bajar: ya va en $percent %.';
  }

  @override
  String get maintProgressPhotosFailed =>
      'El avance se guardó, pero no todas las fotos. Vuelve a intentarlo desde la web.';

  @override
  String get maintIndicatorsNone =>
      'No tienes indicadores asignados en esta concesión. Pide a tu administrador que te los asigne.';

  @override
  String get maintIndicatorsFailed => 'No se pudieron cargar tus indicadores.';

  @override
  String get newTicketIndicator => 'Indicador';

  @override
  String get newTicketGroup => 'Subclasificación';

  @override
  String get newTicketFailure => 'Falla';

  @override
  String get newTicketAttention => 'Plazo de atención';

  @override
  String get newTicketAttentionPending => 'Sale de la falla elegida';

  @override
  String newTicketAttentionValue(String value) {
    return '$value · fijo, corre 24×7';
  }

  @override
  String get newTicketAttentionImmediate => 'Inmediato';

  @override
  String newTicketAttentionDays(int days) {
    return '$days días';
  }

  @override
  String newTicketAttentionHours(int hours) {
    return '$hours horas';
  }

  @override
  String get newTicketErrorFailure =>
      'Elige el indicador, la subclasificación y la falla.';

  @override
  String ticketPlacementSegment(String code) {
    return 'tramo $code';
  }

  @override
  String ticketPlacementDistance(int meters) {
    return 'a $meters m de la carretera';
  }

  @override
  String ticketPlacementOffRoad(int meters) {
    return 'El punto está a más de $meters m de la carretera: márquelo sobre la carretera de la concesión.';
  }

  @override
  String get newTicketKmEnd => 'Km final';

  @override
  String get newTicketKmEndHint => 'Opcional, si la falla ocupa un tramo';

  @override
  String get newTicketDirection => 'Sentido';

  @override
  String get newTicketErrorKmEnd =>
      'Va con el km inicial y no puede ser menor que él.';

  @override
  String get newTicketErrorDirection =>
      'Aquí los dos sentidos comparten trazo: elija el sentido.';

  @override
  String get newTicketErrorDescription => 'Describa la falla.';
}
