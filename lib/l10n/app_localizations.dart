import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Sistema de Gestión de Activos de Concesión'**
  String get appTagline;

  /// No description provided for @loginWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get loginSubtitle;

  /// No description provided for @fieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPassword;

  /// No description provided for @rememberCredentials.
  ///
  /// In es, this message translates to:
  /// **'Recordar correo y contraseña'**
  String get rememberCredentials;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @biometricAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceder con biometría'**
  String get biometricAccess;

  /// No description provided for @biometricReason.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para iniciar sesión'**
  String get biometricReason;

  /// No description provided for @biometricEnableTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar acceso con biometría'**
  String get biometricEnableTitle;

  /// No description provided for @biometricEnableBody.
  ///
  /// In es, this message translates to:
  /// **'La próxima vez podrás entrar con tu huella o rostro. Tus datos se guardan cifrados en este dispositivo.'**
  String get biometricEnableBody;

  /// No description provided for @biometricEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get biometricEnable;

  /// No description provided for @biometricNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get biometricNotNow;

  /// No description provided for @biometricUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La biometría no está disponible o no está activada en este dispositivo.'**
  String get biometricUnavailable;

  /// No description provided for @biometricNoCredentials.
  ///
  /// In es, this message translates to:
  /// **'La biometría aún no está activada. Inicia sesión con tu correo y contraseña y se te ofrecerá activarla.'**
  String get biometricNoCredentials;

  /// No description provided for @biometricSettingTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso con biometría'**
  String get biometricSettingTitle;

  /// No description provided for @biometricSettingOn.
  ///
  /// In es, this message translates to:
  /// **'Activo: entras con tu huella o rostro.'**
  String get biometricSettingOn;

  /// No description provided for @biometricSettingOff.
  ///
  /// In es, this message translates to:
  /// **'Inactivo. Actívalo para entrar con tu huella o rostro.'**
  String get biometricSettingOff;

  /// No description provided for @biometricEnabledDone.
  ///
  /// In es, this message translates to:
  /// **'Acceso con biometría activado.'**
  String get biometricEnabledDone;

  /// No description provided for @biometricDisabledDone.
  ///
  /// In es, this message translates to:
  /// **'Acceso con biometría desactivado.'**
  String get biometricDisabledDone;

  /// No description provided for @valueSecure.
  ///
  /// In es, this message translates to:
  /// **'Seguro'**
  String get valueSecure;

  /// No description provided for @valueReliable.
  ///
  /// In es, this message translates to:
  /// **'Confiable'**
  String get valueReliable;

  /// No description provided for @valueCollaborative.
  ///
  /// In es, this message translates to:
  /// **'Colaborativo'**
  String get valueCollaborative;

  /// No description provided for @valueEfficient.
  ///
  /// In es, this message translates to:
  /// **'Eficiente'**
  String get valueEfficient;

  /// No description provided for @versionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String versionLabel(String version);

  /// No description provided for @contactAdmin.
  ///
  /// In es, this message translates to:
  /// **'Contacto al administrador'**
  String get contactAdmin;

  /// No description provided for @errEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo electrónico.'**
  String get errEmailRequired;

  /// No description provided for @errEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get errEmailInvalid;

  /// No description provided for @errPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña.'**
  String get errPasswordRequired;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos. Tras varios intentos fallidos consecutivos la cuenta se bloquea.'**
  String get errInvalidCredentials;

  /// No description provided for @errAccountBlocked.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso ha sido bloqueado por intentos fallidos. Contacta al administrador del sistema para solicitar la reactivación de tu cuenta.'**
  String get errAccountBlocked;

  /// No description provided for @errNetwork.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión con el servidor. Revisa tu red e inténtalo de nuevo.'**
  String get errNetwork;

  /// No description provided for @errServer.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error en el servidor. Inténtalo más tarde.'**
  String get errServer;

  /// No description provided for @errSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión terminó. Inicia sesión de nuevo.'**
  String get errSessionExpired;

  /// No description provided for @mfaTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get mfaTitle;

  /// No description provided for @mfaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de 6 dígitos de tu app autenticadora.'**
  String get mfaSubtitle;

  /// No description provided for @mfaCode.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get mfaCode;

  /// No description provided for @mfaVerify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get mfaVerify;

  /// No description provided for @mfaCodeInvalid.
  ///
  /// In es, this message translates to:
  /// **'El código no es válido.'**
  String get mfaCodeInvalid;

  /// No description provided for @mfaEnrollTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu verificación en dos pasos'**
  String get mfaEnrollTitle;

  /// No description provided for @mfaEnrollBody.
  ///
  /// In es, this message translates to:
  /// **'Agrega esta clave a tu app autenticadora y escribe el primer código que genere.'**
  String get mfaEnrollBody;

  /// No description provided for @mfaEnrollSecret.
  ///
  /// In es, this message translates to:
  /// **'Clave'**
  String get mfaEnrollSecret;

  /// No description provided for @mfaCopied.
  ///
  /// In es, this message translates to:
  /// **'Clave copiada'**
  String get mfaCopied;

  /// No description provided for @changePasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambia tu contraseña'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad debes definir una contraseña nueva para continuar.'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña nueva'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @changePasswordAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordAction;

  /// No description provided for @passwordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get passwordMismatch;

  /// No description provided for @concessionTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu concesión'**
  String get concessionTitle;

  /// No description provided for @concessionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tienes acceso a más de una concesión. Elige con cuál trabajar.'**
  String get concessionSubtitle;

  /// No description provided for @recoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recoveryTitle;

  /// No description provided for @recoveryBody.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo. Si corresponde a una cuenta activa, recibirás un enlace para definir tu contraseña.'**
  String get recoveryBody;

  /// No description provided for @recoverySend.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get recoverySend;

  /// No description provided for @recoverySent.
  ///
  /// In es, this message translates to:
  /// **'Si el correo corresponde a una cuenta activa, recibirás un enlace para definir tu contraseña.'**
  String get recoverySent;

  /// No description provided for @recoveryStepsTitle.
  ///
  /// In es, this message translates to:
  /// **'Qué hacer ahora'**
  String get recoveryStepsTitle;

  /// No description provided for @recoveryStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre el correo que te enviamos.'**
  String get recoveryStep1;

  /// No description provided for @recoveryStep2.
  ///
  /// In es, this message translates to:
  /// **'Toca el enlace: se abre en el navegador. Ahí defines tu nueva contraseña.'**
  String get recoveryStep2;

  /// No description provided for @recoveryStep3.
  ///
  /// In es, this message translates to:
  /// **'Al terminar, toca «Volver a la aplicación» e inicia sesión.'**
  String get recoveryStep3;

  /// No description provided for @recoveryResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar enlace'**
  String get recoveryResend;

  /// No description provided for @recoveryBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get recoveryBackToLogin;

  /// No description provided for @passwordResetDone.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Inicia sesión con tu nueva contraseña.'**
  String get passwordResetDone;

  /// No description provided for @languageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languagePortuguese.
  ///
  /// In es, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @appearanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearanceLabel;

  /// No description provided for @appearanceOriginal.
  ///
  /// In es, this message translates to:
  /// **'Original'**
  String get appearanceOriginal;

  /// No description provided for @appearanceDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get appearanceDay;

  /// No description provided for @appearanceNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get appearanceNight;

  /// No description provided for @preferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se guardan en este dispositivo.'**
  String get preferencesSubtitle;

  /// No description provided for @useConcessionColors.
  ///
  /// In es, this message translates to:
  /// **'Colores de mi concesión'**
  String get useConcessionColors;

  /// No description provided for @useConcessionColorsOn.
  ///
  /// In es, this message translates to:
  /// **'Se usan los colores de tu concesión.'**
  String get useConcessionColorsOn;

  /// No description provided for @useConcessionColorsOff.
  ///
  /// In es, this message translates to:
  /// **'Se usan los colores de SIGACO.'**
  String get useConcessionColorsOff;

  /// No description provided for @securityTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get securityTitle;

  /// No description provided for @mfaSettingTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get mfaSettingTitle;

  /// No description provided for @mfaSettingOn.
  ///
  /// In es, this message translates to:
  /// **'Activa. Tu código lo genera tu app autenticadora. Toca para configurarla de nuevo.'**
  String get mfaSettingOn;

  /// No description provided for @mfaSettingOff.
  ///
  /// In es, this message translates to:
  /// **'No está habilitada para tu cuenta. La activa un administrador.'**
  String get mfaSettingOff;

  /// No description provided for @mfaAdminManaged.
  ///
  /// In es, this message translates to:
  /// **'La verificación en dos pasos la activa o desactiva un administrador del sistema.'**
  String get mfaAdminManaged;

  /// No description provided for @mfaReconfigureBody.
  ///
  /// In es, this message translates to:
  /// **'Se generará una clave nueva y la de tu app autenticadora actual dejará de funcionar. Si no terminas, tendrás que configurarla de nuevo al iniciar sesión.'**
  String get mfaReconfigureBody;

  /// No description provided for @mfaReconfigureAction.
  ///
  /// In es, this message translates to:
  /// **'Generar clave nueva'**
  String get mfaReconfigureAction;

  /// No description provided for @mfaReconfigureDone.
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos actualizada.'**
  String get mfaReconfigureDone;

  /// No description provided for @homePlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homePlaceholderTitle;

  /// No description provided for @homePlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'Aquí irá el menú de módulos (diseño v2).'**
  String get homePlaceholderBody;

  /// No description provided for @welcomeUser.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido, {name}'**
  String welcomeUser(String name);

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @greetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches,'**
  String get greetingEvening;

  /// No description provided for @homeQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué deseas realizar hoy?'**
  String get homeQuestion;

  /// No description provided for @modulesTitle.
  ///
  /// In es, this message translates to:
  /// **'MÓDULOS'**
  String get modulesTitle;

  /// No description provided for @moduleMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get moduleMap;

  /// No description provided for @moduleMapSub.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de activos'**
  String get moduleMapSub;

  /// No description provided for @moduleDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get moduleDashboard;

  /// No description provided for @moduleDashboardSub.
  ///
  /// In es, this message translates to:
  /// **'Resumen general'**
  String get moduleDashboardSub;

  /// No description provided for @moduleAccidents.
  ///
  /// In es, this message translates to:
  /// **'Accidentes'**
  String get moduleAccidents;

  /// No description provided for @moduleAccidentsSub.
  ///
  /// In es, this message translates to:
  /// **'Incidentes graves'**
  String get moduleAccidentsSub;

  /// No description provided for @moduleMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos'**
  String get moduleMaintenance;

  /// No description provided for @moduleMaintenanceSub.
  ///
  /// In es, this message translates to:
  /// **'Órdenes de trabajo'**
  String get moduleMaintenanceSub;

  /// No description provided for @moduleInventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get moduleInventory;

  /// No description provided for @moduleInventorySub.
  ///
  /// In es, this message translates to:
  /// **'Control de activos y faja'**
  String get moduleInventorySub;

  /// No description provided for @moduleReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get moduleReports;

  /// No description provided for @moduleReportsSub.
  ///
  /// In es, this message translates to:
  /// **'Consulta y exportación'**
  String get moduleReportsSub;

  /// No description provided for @moduleTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets'**
  String get moduleTickets;

  /// No description provided for @moduleTicketsSub.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento y registro'**
  String get moduleTicketsSub;

  /// No description provided for @moduleAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get moduleAlerts;

  /// No description provided for @moduleAlertsSub.
  ///
  /// In es, this message translates to:
  /// **'Eventos operativos'**
  String get moduleAlertsSub;

  /// No description provided for @moduleComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Este módulo está en desarrollo.'**
  String get moduleComingSoon;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets'**
  String get navTickets;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get navAlerts;

  /// No description provided for @navReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get navReports;

  /// No description provided for @menuLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu menú.'**
  String get menuLoadError;

  /// No description provided for @menuEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no tiene módulos habilitados en esta concesión. Si crees que es un error, contacta al administrador de tu concesión.'**
  String get menuEmpty;

  /// No description provided for @accessNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso'**
  String get accessNoPermissionTitle;

  /// No description provided for @accessNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no tiene permiso para ver esta información. Si crees que es un error, contacta al administrador de tu concesión.'**
  String get accessNoPermissionBody;

  /// No description provided for @accessErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tus accesos'**
  String get accessErrorTitle;

  /// No description provided for @accessErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema al validar tus permisos. Intenta de nuevo; si continúa, contacta al administrador de tu concesión.'**
  String get accessErrorBody;

  /// No description provided for @accessChangedNotice.
  ///
  /// In es, this message translates to:
  /// **'Tus accesos cambiaron. Se actualizó el menú.'**
  String get accessChangedNotice;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @accountTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración de usuario'**
  String get accountTitle;

  /// No description provided for @accountInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Información de la cuenta'**
  String get accountInfoTitle;

  /// No description provided for @accountInfoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estos son los datos asociados a tu perfil en SIGACO.'**
  String get accountInfoSubtitle;

  /// No description provided for @fieldUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get fieldUser;

  /// No description provided for @fieldEmailShort.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get fieldEmailShort;

  /// No description provided for @fieldProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get fieldProfile;

  /// No description provided for @fieldArea.
  ///
  /// In es, this message translates to:
  /// **'Área'**
  String get fieldArea;

  /// No description provided for @fieldConcession.
  ///
  /// In es, this message translates to:
  /// **'Concesionaria'**
  String get fieldConcession;

  /// No description provided for @fieldRoads.
  ///
  /// In es, this message translates to:
  /// **'Carreteras'**
  String get fieldRoads;

  /// No description provided for @fieldAppVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de la app'**
  String get fieldAppVersion;

  /// No description provided for @fieldDevice.
  ///
  /// In es, this message translates to:
  /// **'Dispositivo'**
  String get fieldDevice;

  /// No description provided for @fieldLastConnection.
  ///
  /// In es, this message translates to:
  /// **'Última conexión'**
  String get fieldLastConnection;

  /// No description provided for @connectionOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get connectionOffline;

  /// No description provided for @connectionOfflineSince.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · última conexión {time}'**
  String connectionOfflineSince(String time);

  /// No description provided for @connectionRestored.
  ///
  /// In es, this message translates to:
  /// **'Conexión restablecida'**
  String get connectionRestored;

  /// No description provided for @actionChangePasswordSub.
  ///
  /// In es, this message translates to:
  /// **'Actualiza tu contraseña de acceso'**
  String get actionChangePasswordSub;

  /// No description provided for @actionSwitchConcession.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de concesión'**
  String get actionSwitchConcession;

  /// No description provided for @actionSwitchConcessionSub.
  ///
  /// In es, this message translates to:
  /// **'Elige otra concesión para trabajar'**
  String get actionSwitchConcessionSub;

  /// No description provided for @switchConcessionWarning.
  ///
  /// In es, this message translates to:
  /// **'Al cambiar de concesión se abre una sesión nueva y se descarta lo cargado de la anterior.'**
  String get switchConcessionWarning;

  /// No description provided for @passwordChanged.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada. Se cerraron tus otras sesiones.'**
  String get passwordChanged;

  /// No description provided for @sessionExpiringTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión está por vencer'**
  String get sessionExpiringTitle;

  /// No description provided for @sessionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get sessionContinue;

  /// No description provided for @sessionExpiringBody.
  ///
  /// In es, this message translates to:
  /// **'Por inactividad se cerrará en {seconds} segundos.'**
  String sessionExpiringBody(int seconds);

  /// No description provided for @appTaglineShort.
  ///
  /// In es, this message translates to:
  /// **'Sistema de Gestión de Activos'**
  String get appTaglineShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
