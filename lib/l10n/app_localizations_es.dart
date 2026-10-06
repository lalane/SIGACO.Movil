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
}
