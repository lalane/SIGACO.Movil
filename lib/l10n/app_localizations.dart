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

  /// No description provided for @errAccessExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso a SIGACO venció. Pide a tu administrador que lo renueve.'**
  String get errAccessExpired;

  /// No description provided for @errValidation.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Revisa los datos e inténtalo de nuevo.'**
  String get errValidation;

  /// No description provided for @passwordRulesTitle.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener:'**
  String get passwordRulesTitle;

  /// No description provided for @passwordRuleLength.
  ///
  /// In es, this message translates to:
  /// **'Al menos {min} caracteres'**
  String passwordRuleLength(int min);

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In es, this message translates to:
  /// **'Una letra mayúscula'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In es, this message translates to:
  /// **'Una letra minúscula'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleDigit.
  ///
  /// In es, this message translates to:
  /// **'Un número'**
  String get passwordRuleDigit;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In es, this message translates to:
  /// **'Un carácter especial (por ejemplo ! # \$ %)'**
  String get passwordRuleSpecial;

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

  /// No description provided for @demoModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo'**
  String get demoModeTitle;

  /// No description provided for @demoModeOn.
  ///
  /// In es, this message translates to:
  /// **'Todo se ve con datos inventados; no se consulta el servidor'**
  String get demoModeOn;

  /// No description provided for @demoModeOff.
  ///
  /// In es, this message translates to:
  /// **'Ver la app con datos inventados para conocer cómo está armada'**
  String get demoModeOff;

  /// No description provided for @demoModeSnackOn.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo activados'**
  String get demoModeSnackOn;

  /// No description provided for @demoModeSnackOff.
  ///
  /// In es, this message translates to:
  /// **'Datos reales'**
  String get demoModeSnackOff;

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
  /// **'Catálogo'**
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
  /// **'Registros'**
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

  /// No description provided for @navTickets.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
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

  /// No description provided for @fieldJobTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargo'**
  String get fieldJobTitle;

  /// No description provided for @fieldCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get fieldCompany;

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

  /// No description provided for @fieldTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria de la concesión'**
  String get fieldTimezone;

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

  /// No description provided for @profilePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoTake.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get profilePhotoTake;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar la foto'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la foto'**
  String get profilePhotoFailed;

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

  /// No description provided for @appTaglineShort.
  ///
  /// In es, this message translates to:
  /// **'Sistema de Gestión de Activos'**
  String get appTaglineShort;

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronización'**
  String get syncTitle;

  /// No description provided for @syncStripPending.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 operación pendiente de enviar} other{{count} operaciones pendientes de enviar}}'**
  String syncStripPending(int count);

  /// No description provided for @syncStripAttention.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 operación necesita tu decisión} other{{count} operaciones necesitan tu decisión}}'**
  String syncStripAttention(int count);

  /// No description provided for @syncLastSync.
  ///
  /// In es, this message translates to:
  /// **'Última sincronización: {time}'**
  String syncLastSync(String time);

  /// No description provided for @syncNever.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha sincronizado'**
  String get syncNever;

  /// No description provided for @syncNow.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get syncNow;

  /// No description provided for @syncRunning.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get syncRunning;

  /// No description provided for @syncOfflineHint.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Se enviará al recuperarla.'**
  String get syncOfflineHint;

  /// No description provided for @syncAllDone.
  ///
  /// In es, this message translates to:
  /// **'Todo está sincronizado'**
  String get syncAllDone;

  /// No description provided for @syncAllDoneBody.
  ///
  /// In es, this message translates to:
  /// **'No hay operaciones pendientes ni que requieran tu decisión.'**
  String get syncAllDoneBody;

  /// No description provided for @syncSectionAttention.
  ///
  /// In es, this message translates to:
  /// **'Requieren tu decisión'**
  String get syncSectionAttention;

  /// No description provided for @syncSectionPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes de enviar'**
  String get syncSectionPending;

  /// No description provided for @syncStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando'**
  String get syncStatusSending;

  /// No description provided for @syncStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get syncStatusRejected;

  /// No description provided for @syncStatusConflict.
  ///
  /// In es, this message translates to:
  /// **'En conflicto'**
  String get syncStatusConflict;

  /// No description provided for @syncCaptured.
  ///
  /// In es, this message translates to:
  /// **'Capturada {time}'**
  String syncCaptured(String time);

  /// No description provided for @syncAttempts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 intento} other{{count} intentos}}'**
  String syncAttempts(int count);

  /// No description provided for @syncActionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get syncActionRetry;

  /// No description provided for @syncActionDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get syncActionDiscard;

  /// No description provided for @syncActionReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get syncActionReview;

  /// No description provided for @syncDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar esta operación?'**
  String get syncDiscardTitle;

  /// No description provided for @syncDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Se perderá lo capturado en este teléfono. Esto no se puede deshacer.'**
  String get syncDiscardBody;

  /// No description provided for @syncEntityDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get syncEntityDocument;

  /// No description provided for @syncEntitySignature.
  ///
  /// In es, this message translates to:
  /// **'Firma de documento'**
  String get syncEntitySignature;

  /// No description provided for @syncEntityTicket.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get syncEntityTicket;

  /// No description provided for @syncEntityInspection.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get syncEntityInspection;

  /// No description provided for @syncEntityEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get syncEntityEvent;

  /// No description provided for @syncEntityAsset.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get syncEntityAsset;

  /// No description provided for @syncEntitySurvey.
  ///
  /// In es, this message translates to:
  /// **'Levantamiento'**
  String get syncEntitySurvey;

  /// No description provided for @syncEntityMedia.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get syncEntityMedia;

  /// No description provided for @syncEntityMaintenanceProgress.
  ///
  /// In es, this message translates to:
  /// **'Avance de mantenimiento'**
  String get syncEntityMaintenanceProgress;

  /// No description provided for @syncEntityOther.
  ///
  /// In es, this message translates to:
  /// **'Operación'**
  String get syncEntityOther;

  /// No description provided for @syncKindInsert.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get syncKindInsert;

  /// No description provided for @syncKindUpdate.
  ///
  /// In es, this message translates to:
  /// **'Cambio'**
  String get syncKindUpdate;

  /// No description provided for @syncKindDelete.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get syncKindDelete;

  /// No description provided for @syncConflictTitle.
  ///
  /// In es, this message translates to:
  /// **'Conflicto de sincronización'**
  String get syncConflictTitle;

  /// No description provided for @syncConflictIntro.
  ///
  /// In es, this message translates to:
  /// **'Este registro cambió en el servidor mientras estabas sin conexión. Elige con cuál quedarte: nada se aplica en silencio.'**
  String get syncConflictIntro;

  /// No description provided for @syncConflictMine.
  ///
  /// In es, this message translates to:
  /// **'Lo que capturaste'**
  String get syncConflictMine;

  /// No description provided for @syncConflictServer.
  ///
  /// In es, this message translates to:
  /// **'Lo que hay en el servidor'**
  String get syncConflictServer;

  /// No description provided for @syncConflictVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String syncConflictVersion(String version);

  /// No description provided for @syncConflictNoDetail.
  ///
  /// In es, this message translates to:
  /// **'Sin detalle disponible'**
  String get syncConflictNoDetail;

  /// No description provided for @syncConflictKeepServer.
  ///
  /// In es, this message translates to:
  /// **'Quedarme con el servidor'**
  String get syncConflictKeepServer;

  /// No description provided for @syncConflictKeepServerBody.
  ///
  /// In es, this message translates to:
  /// **'Se descartará lo capturado en este teléfono.'**
  String get syncConflictKeepServerBody;

  /// No description provided for @syncConflictKeepMine.
  ///
  /// In es, this message translates to:
  /// **'Mantener lo mío'**
  String get syncConflictKeepMine;

  /// No description provided for @syncConflictKeepMineBody.
  ///
  /// In es, this message translates to:
  /// **'Se volverá a enviar sobre la versión actual del servidor, que puede rechazarlo.'**
  String get syncConflictKeepMineBody;

  /// No description provided for @syncConflictMissing.
  ///
  /// In es, this message translates to:
  /// **'Este conflicto ya no existe.'**
  String get syncConflictMissing;

  /// No description provided for @syncMessageFromServer.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {message}'**
  String syncMessageFromServer(String message);

  /// No description provided for @moduleDocuments.
  ///
  /// In es, this message translates to:
  /// **'Gestor documental'**
  String get moduleDocuments;

  /// No description provided for @moduleDocumentsSub.
  ///
  /// In es, this message translates to:
  /// **'Consulta y firma de documentos'**
  String get moduleDocumentsSub;

  /// No description provided for @docsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestor documental'**
  String get docsTitle;

  /// No description provided for @docsViewAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get docsViewAll;

  /// No description provided for @docsViewRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get docsViewRecent;

  /// No description provided for @docsViewFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get docsViewFavorites;

  /// No description provided for @docsViewMine.
  ///
  /// In es, this message translates to:
  /// **'Mis documentos'**
  String get docsViewMine;

  /// No description provided for @docsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, propietario o categoría'**
  String get docsSearchHint;

  /// No description provided for @docsFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get docsFilters;

  /// No description provided for @docsFiltersApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get docsFiltersApply;

  /// No description provided for @docsFiltersClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get docsFiltersClear;

  /// No description provided for @docsFilterType.
  ///
  /// In es, this message translates to:
  /// **'Tipo documental'**
  String get docsFilterType;

  /// No description provided for @docsFilterCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get docsFilterCategory;

  /// No description provided for @docsFilterFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta'**
  String get docsFilterFolder;

  /// No description provided for @docsFilterModifiedBy.
  ///
  /// In es, this message translates to:
  /// **'Modificado por'**
  String get docsFilterModifiedBy;

  /// No description provided for @docsFilterFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get docsFilterFrom;

  /// No description provided for @docsFilterTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get docsFilterTo;

  /// No description provided for @docsFilterAny.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get docsFilterAny;

  /// No description provided for @docsFilterPickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get docsFilterPickDate;

  /// No description provided for @docsRangeInvalid.
  ///
  /// In es, this message translates to:
  /// **'La fecha Desde no puede ser posterior a Hasta.'**
  String get docsRangeInvalid;

  /// No description provided for @docsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando documentos…'**
  String get docsLoading;

  /// No description provided for @docsEmptyAllTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay documentos'**
  String get docsEmptyAllTitle;

  /// No description provided for @docsEmptyAllBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando se carguen documentos de esta concesión aparecerán aquí.'**
  String get docsEmptyAllBody;

  /// No description provided for @docsEmptyRecentTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad reciente'**
  String get docsEmptyRecentTitle;

  /// No description provided for @docsEmptyRecentBody.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecen los documentos que abriste o cargaste en los últimos 30 días.'**
  String get docsEmptyRecentBody;

  /// No description provided for @docsEmptyFavoritesTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin favoritos'**
  String get docsEmptyFavoritesTitle;

  /// No description provided for @docsEmptyFavoritesBody.
  ///
  /// In es, this message translates to:
  /// **'Marca un documento con la estrella para encontrarlo aquí.'**
  String get docsEmptyFavoritesBody;

  /// No description provided for @docsEmptyMineTitle.
  ///
  /// In es, this message translates to:
  /// **'No has cargado documentos'**
  String get docsEmptyMineTitle;

  /// No description provided for @docsEmptyMineBody.
  ///
  /// In es, this message translates to:
  /// **'Los documentos que cargues aparecerán aquí.'**
  String get docsEmptyMineBody;

  /// No description provided for @docsNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get docsNoResultsTitle;

  /// No description provided for @docsNoResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra búsqueda o quita algún filtro.'**
  String get docsNoResultsBody;

  /// No description provided for @docsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los documentos'**
  String get docsErrorTitle;

  /// No description provided for @docsErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo en unos momentos.'**
  String get docsErrorBody;

  /// No description provided for @docsOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get docsOfflineTitle;

  /// No description provided for @docsOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Los documentos necesitan conexión mientras no estén guardados en el teléfono.'**
  String get docsOfflineBody;

  /// No description provided for @docsNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para ver documentos'**
  String get docsNoPermissionTitle;

  /// No description provided for @docsNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar el gestor documental en esta concesión.'**
  String get docsNoPermissionBody;

  /// No description provided for @docsNoRoadTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin carreteras asignadas'**
  String get docsNoRoadTitle;

  /// No description provided for @docsNoRoadBody.
  ///
  /// In es, this message translates to:
  /// **'Tu usuario no tiene carreteras asignadas en esta concesión. Pide al administrador que te las asigne.'**
  String get docsNoRoadBody;

  /// No description provided for @docsNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'El documento ya no está disponible'**
  String get docsNotFoundTitle;

  /// No description provided for @docsNotFoundBody.
  ///
  /// In es, this message translates to:
  /// **'Pudo haberse movido o eliminado.'**
  String get docsNotFoundBody;

  /// No description provided for @docsNotOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Contenido no disponible sin conexión'**
  String get docsNotOfflineTitle;

  /// No description provided for @docsNotOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para consultar este documento.'**
  String get docsNotOfflineBody;

  /// No description provided for @docsSignatureUnsigned.
  ///
  /// In es, this message translates to:
  /// **'Sin firma'**
  String get docsSignatureUnsigned;

  /// No description provided for @docsSignaturePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get docsSignaturePending;

  /// No description provided for @docsSignatureValidated.
  ///
  /// In es, this message translates to:
  /// **'Validado'**
  String get docsSignatureValidated;

  /// No description provided for @docsFavoriteAdd.
  ///
  /// In es, this message translates to:
  /// **'Marcar como favorito'**
  String get docsFavoriteAdd;

  /// No description provided for @docsFavoriteRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get docsFavoriteRemove;

  /// No description provided for @docsFavoriteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el favorito.'**
  String get docsFavoriteFailed;

  /// No description provided for @docsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get docsDetailTitle;

  /// No description provided for @docsFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo documental'**
  String get docsFieldType;

  /// No description provided for @docsFieldCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get docsFieldCategory;

  /// No description provided for @docsFieldDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get docsFieldDescription;

  /// No description provided for @docsFieldFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta'**
  String get docsFieldFolder;

  /// No description provided for @docsFieldOwner.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get docsFieldOwner;

  /// No description provided for @docsFieldVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión vigente'**
  String get docsFieldVersion;

  /// No description provided for @docsFieldModified.
  ///
  /// In es, this message translates to:
  /// **'Última modificación'**
  String get docsFieldModified;

  /// No description provided for @docsFieldModifiedBy.
  ///
  /// In es, this message translates to:
  /// **'Modificado por'**
  String get docsFieldModifiedBy;

  /// No description provided for @docsFieldSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get docsFieldSize;

  /// No description provided for @docsFieldFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get docsFieldFormat;

  /// No description provided for @docsNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get docsNoCategory;

  /// No description provided for @docsFolderRoot.
  ///
  /// In es, this message translates to:
  /// **'Nivel inicial de la concesión'**
  String get docsFolderRoot;

  /// No description provided for @docsNoDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get docsNoDescription;

  /// No description provided for @docsVersion.
  ///
  /// In es, this message translates to:
  /// **'V{number}'**
  String docsVersion(int number);

  /// No description provided for @docsOwnerLine.
  ///
  /// In es, this message translates to:
  /// **'{owner} · {date}'**
  String docsOwnerLine(String owner, String date);

  /// No description provided for @docsZoneLegend.
  ///
  /// In es, this message translates to:
  /// **'Fechas en hora de {zone} ({offset})'**
  String docsZoneLegend(String zone, String offset);

  /// No description provided for @docsPreviewOpen.
  ///
  /// In es, this message translates to:
  /// **'Previsualizar'**
  String get docsPreviewOpen;

  /// No description provided for @docsPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get docsPreviewTitle;

  /// No description provided for @docsPreviewNoneNote.
  ///
  /// In es, this message translates to:
  /// **'Este formato no tiene vista previa en la app.'**
  String get docsPreviewNoneNote;

  /// No description provided for @docsPreviewUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista previa no disponible'**
  String get docsPreviewUnavailableTitle;

  /// No description provided for @docsPreviewUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Este formato no se puede mostrar en la app.'**
  String get docsPreviewUnavailableBody;

  /// No description provided for @docsPreviewPdfError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo mostrar el PDF.'**
  String get docsPreviewPdfError;

  /// No description provided for @docsPdfPageOf.
  ///
  /// In es, this message translates to:
  /// **'Página {page} de {total}'**
  String docsPdfPageOf(int page, int total);

  /// No description provided for @docsPdfZoomIn.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get docsPdfZoomIn;

  /// No description provided for @docsPdfZoomOut.
  ///
  /// In es, this message translates to:
  /// **'Alejar'**
  String get docsPdfZoomOut;

  /// No description provided for @docsFromPhone.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · guardado en el teléfono el {date}'**
  String docsFromPhone(String date);

  /// No description provided for @docsSignAction.
  ///
  /// In es, this message translates to:
  /// **'Firmar'**
  String get docsSignAction;

  /// No description provided for @docsSignConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Firmar este documento?'**
  String get docsSignConfirmTitle;

  /// No description provided for @docsSignConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Vas a firmar «{name}», versión {version}. La firma queda registrada con tu nombre, tu perfil y la fecha, y no se puede deshacer.'**
  String docsSignConfirmBody(String name, String version);

  /// No description provided for @docsSignConfirmOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: la firma quedará pendiente y se aplicará al sincronizar, solo si el documento no cambió.'**
  String get docsSignConfirmOffline;

  /// No description provided for @docsSignConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Firmar'**
  String get docsSignConfirmButton;

  /// No description provided for @docsSignDone.
  ///
  /// In es, this message translates to:
  /// **'Documento firmado.'**
  String get docsSignDone;

  /// No description provided for @docsSignQueued.
  ///
  /// In es, this message translates to:
  /// **'Firma guardada. Se aplicará al sincronizar.'**
  String get docsSignQueued;

  /// No description provided for @docsSignPending.
  ///
  /// In es, this message translates to:
  /// **'Firma pendiente de sincronizar'**
  String get docsSignPending;

  /// No description provided for @docsSignAttention.
  ///
  /// In es, this message translates to:
  /// **'La firma pendiente necesita tu decisión en el centro de sincronización.'**
  String get docsSignAttention;

  /// No description provided for @docsSignAlready.
  ///
  /// In es, this message translates to:
  /// **'Esta versión ya fue firmada por otra persona.'**
  String get docsSignAlready;

  /// No description provided for @docsSignMismatch.
  ///
  /// In es, this message translates to:
  /// **'El archivo no coincide con el hash de la versión: no se puede firmar. Avisa a un administrador.'**
  String get docsSignMismatch;

  /// No description provided for @docsSignProfile.
  ///
  /// In es, this message translates to:
  /// **'Firmar requiere un perfil firmante en esta concesión.'**
  String get docsSignProfile;

  /// No description provided for @docsSignFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo firmar. Inténtalo de nuevo.'**
  String get docsSignFailed;

  /// No description provided for @fieldLastSync.
  ///
  /// In es, this message translates to:
  /// **'Última sincronización'**
  String get fieldLastSync;

  /// No description provided for @docsPreviewImageError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo mostrar la imagen.'**
  String get docsPreviewImageError;

  /// No description provided for @docsUploadAction.
  ///
  /// In es, this message translates to:
  /// **'Cargar documento'**
  String get docsUploadAction;

  /// No description provided for @docsUploadTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargar documento'**
  String get docsUploadTitle;

  /// No description provided for @docsUploadPickFiles.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivos'**
  String get docsUploadPickFiles;

  /// No description provided for @docsUploadTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get docsUploadTakePhoto;

  /// No description provided for @docsUploadNoFiles.
  ///
  /// In es, this message translates to:
  /// **'Elige uno o varios archivos, o toma una foto.'**
  String get docsUploadNoFiles;

  /// No description provided for @docsUploadFileName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get docsUploadFileName;

  /// No description provided for @docsUploadRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar archivo'**
  String get docsUploadRemove;

  /// No description provided for @docsUploadType.
  ///
  /// In es, this message translates to:
  /// **'Tipo documental'**
  String get docsUploadType;

  /// No description provided for @docsUploadCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría (opcional)'**
  String get docsUploadCategory;

  /// No description provided for @docsUploadFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta (opcional)'**
  String get docsUploadFolder;

  /// No description provided for @docsUploadNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get docsUploadNoCategory;

  /// No description provided for @docsUploadRoot.
  ///
  /// In es, this message translates to:
  /// **'Nivel inicial'**
  String get docsUploadRoot;

  /// No description provided for @docsUploadDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get docsUploadDescription;

  /// No description provided for @docsUploadDescriptionOther.
  ///
  /// In es, this message translates to:
  /// **'Descripción (obligatoria para «Otro»)'**
  String get docsUploadDescriptionOther;

  /// No description provided for @docsUploadSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar documento'**
  String get docsUploadSave;

  /// No description provided for @docsUploadSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get docsUploadSaving;

  /// No description provided for @docsUploadOfflineNote.
  ///
  /// In es, this message translates to:
  /// **'Se guarda en el dispositivo y se envía cuando haya conexión. No es un documento del servidor hasta que se confirme.'**
  String get docsUploadOfflineNote;

  /// No description provided for @docsUploadSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'Algunos archivos no se pudieron guardar en el teléfono. Siguen aquí para que lo intentes de nuevo.'**
  String get docsUploadSaveFailed;

  /// No description provided for @docsIssueNoFile.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un archivo.'**
  String get docsIssueNoFile;

  /// No description provided for @docsIssueEmptyFile.
  ///
  /// In es, this message translates to:
  /// **'El archivo está vacío.'**
  String get docsIssueEmptyFile;

  /// No description provided for @docsIssueBlocked.
  ///
  /// In es, this message translates to:
  /// **'Este tipo de archivo no está permitido.'**
  String get docsIssueBlocked;

  /// No description provided for @docsIssueNameEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre.'**
  String get docsIssueNameEmpty;

  /// No description provided for @docsIssueNameInvalid.
  ///
  /// In es, this message translates to:
  /// **'El nombre no puede tener < > : \" / \\ | ? * ni terminar en punto.'**
  String get docsIssueNameInvalid;

  /// No description provided for @docsIssueNameTooLong.
  ///
  /// In es, this message translates to:
  /// **'El nombre pasa de 255 caracteres: acórtalo.'**
  String get docsIssueNameTooLong;

  /// No description provided for @docsIssueTypeMissing.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo documental.'**
  String get docsIssueTypeMissing;

  /// No description provided for @docsIssueDescriptionRequired.
  ///
  /// In es, this message translates to:
  /// **'Para el tipo «Otro» escribe una descripción de al menos 10 caracteres.'**
  String get docsIssueDescriptionRequired;

  /// No description provided for @docsIssueDescriptionTooLong.
  ///
  /// In es, this message translates to:
  /// **'La descripción pasa de 2000 caracteres.'**
  String get docsIssueDescriptionTooLong;

  /// No description provided for @docsUploadDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardado en el dispositivo'**
  String get docsUploadDoneTitle;

  /// No description provided for @docsUploadDoneBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 documento pendiente de sincronización. No estará en el servidor hasta que se confirme.} other{{count} documentos pendientes de sincronización. No estarán en el servidor hasta que se confirmen.}}'**
  String docsUploadDoneBody(int count);

  /// No description provided for @docsUploadDoneSync.
  ///
  /// In es, this message translates to:
  /// **'Ver pendientes'**
  String get docsUploadDoneSync;

  /// No description provided for @docsUploadDoneBack.
  ///
  /// In es, this message translates to:
  /// **'Volver al listado'**
  String get docsUploadDoneBack;

  /// No description provided for @mapTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get mapTitle;

  /// No description provided for @mapTabTickets.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get mapTabTickets;

  /// No description provided for @mapTabInventory.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get mapTabInventory;

  /// No description provided for @mapTabMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get mapTabMaintenance;

  /// No description provided for @mapTabWorks.
  ///
  /// In es, this message translates to:
  /// **'Obras'**
  String get mapTabWorks;

  /// No description provided for @mapFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get mapFilters;

  /// No description provided for @mapFiltersCount.
  ///
  /// In es, this message translates to:
  /// **'Filtros ({count})'**
  String mapFiltersCount(int count);

  /// No description provided for @mapFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar el mapa'**
  String get mapFiltersTitle;

  /// No description provided for @mapFilterCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get mapFilterCategory;

  /// No description provided for @mapFilterStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get mapFilterStatus;

  /// No description provided for @mapFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get mapFilterAll;

  /// No description provided for @mapStatusNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get mapStatusNormal;

  /// No description provided for @mapStatusAttention.
  ///
  /// In es, this message translates to:
  /// **'Atención'**
  String get mapStatusAttention;

  /// No description provided for @mapStatusCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítico'**
  String get mapStatusCritical;

  /// No description provided for @mapFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get mapFilterClear;

  /// No description provided for @mapFilterDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get mapFilterDone;

  /// No description provided for @mapSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: el servidor aún no publica el mapa.'**
  String get mapSampleBanner;

  /// No description provided for @mapSegmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Tramo {code}'**
  String mapSegmentTitle(String code);

  /// No description provided for @mapDirectionIncreasing.
  ///
  /// In es, this message translates to:
  /// **'Sentido creciente'**
  String get mapDirectionIncreasing;

  /// No description provided for @mapDirectionDecreasing.
  ///
  /// In es, this message translates to:
  /// **'Sentido decreciente'**
  String get mapDirectionDecreasing;

  /// No description provided for @mapSegmentRange.
  ///
  /// In es, this message translates to:
  /// **'{from} a {to}'**
  String mapSegmentRange(String from, String to);

  /// No description provided for @mapSegmentLayerCount.
  ///
  /// In es, this message translates to:
  /// **'{layer}: {count} en este tramo'**
  String mapSegmentLayerCount(String layer, int count);

  /// No description provided for @mapFromPhone.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · pines guardados en el teléfono el {date}'**
  String mapFromPhone(String date);

  /// No description provided for @mapNoTiles.
  ///
  /// In es, this message translates to:
  /// **'Sin mapa base configurado'**
  String get mapNoTiles;

  /// No description provided for @mapLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando el mapa'**
  String get mapLoading;

  /// No description provided for @mapEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay elementos en esta pestaña.'**
  String get mapEmpty;

  /// No description provided for @mapEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'Ningún elemento coincide con los filtros.'**
  String get mapEmptyFiltered;

  /// No description provided for @mapAreaEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay activos en esta zona.'**
  String get mapAreaEmpty;

  /// No description provided for @mapAreaEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'Ningún activo de esta zona coincide con los filtros.'**
  String get mapAreaEmptyFiltered;

  /// No description provided for @mapAreaZoomIn.
  ///
  /// In es, this message translates to:
  /// **'Acerca el mapa para ver los activos.'**
  String get mapAreaZoomIn;

  /// No description provided for @mapAreaZoomInAction.
  ///
  /// In es, this message translates to:
  /// **'Acercar'**
  String get mapAreaZoomInAction;

  /// No description provided for @mapAreaTruncated.
  ///
  /// In es, this message translates to:
  /// **'Hay más activos en esta zona de los que se muestran: acerca el mapa para verlos todos.'**
  String get mapAreaTruncated;

  /// No description provided for @mapAreaFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron traer los activos de esta zona.'**
  String get mapAreaFailed;

  /// No description provided for @mapAreaLoading.
  ///
  /// In es, this message translates to:
  /// **'Buscando activos en esta zona'**
  String get mapAreaLoading;

  /// No description provided for @mapErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el mapa'**
  String get mapErrorTitle;

  /// No description provided for @mapErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get mapErrorBody;

  /// No description provided for @mapRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get mapRetry;

  /// No description provided for @mapUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'El mapa aún no está disponible'**
  String get mapUnavailableTitle;

  /// No description provided for @mapUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Tu concesión todavía no tiene el mapa publicado. Se activará cuando el servidor lo ofrezca.'**
  String get mapUnavailableBody;

  /// No description provided for @mapNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para ver esta pestaña'**
  String get mapNoPermissionTitle;

  /// No description provided for @mapNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar esta información. Pide acceso a un administrador.'**
  String get mapNoPermissionBody;

  /// No description provided for @mapLocate.
  ///
  /// In es, this message translates to:
  /// **'Ubicarme'**
  String get mapLocate;

  /// No description provided for @mapLocating.
  ///
  /// In es, this message translates to:
  /// **'Buscando tu ubicación…'**
  String get mapLocating;

  /// No description provided for @mapLocateServiceOff.
  ///
  /// In es, this message translates to:
  /// **'El GPS está apagado. Enciéndelo para ubicarte.'**
  String get mapLocateServiceOff;

  /// No description provided for @mapLocateDenied.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos el permiso de ubicación para ubicarte.'**
  String get mapLocateDenied;

  /// No description provided for @mapLocateDeniedForever.
  ///
  /// In es, this message translates to:
  /// **'El permiso de ubicación está bloqueado. Actívalo en Ajustes.'**
  String get mapLocateDeniedForever;

  /// No description provided for @mapLocateUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener tu ubicación. Inténtalo de nuevo al aire libre.'**
  String get mapLocateUnavailable;

  /// No description provided for @mapOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get mapOpenSettings;

  /// No description provided for @mapAccuracy.
  ///
  /// In es, this message translates to:
  /// **'Precisión ±{meters} m'**
  String mapAccuracy(String meters);

  /// No description provided for @mapAccuracyLow.
  ///
  /// In es, this message translates to:
  /// **'Precisión baja (±{meters} m). Para guardar una ubicación se pide {max} m o menos.'**
  String mapAccuracyLow(String meters, String max);

  /// No description provided for @mapMockedLocation.
  ///
  /// In es, this message translates to:
  /// **'La ubicación parece simulada: no se usará para guardar datos.'**
  String get mapMockedLocation;

  /// No description provided for @mapNearby.
  ///
  /// In es, this message translates to:
  /// **'Cercanos'**
  String get mapNearby;

  /// No description provided for @mapNearbyTitle.
  ///
  /// In es, this message translates to:
  /// **'Activos cercanos'**
  String get mapNearbyTitle;

  /// No description provided for @mapNearbyRadius.
  ///
  /// In es, this message translates to:
  /// **'Radio'**
  String get mapNearbyRadius;

  /// No description provided for @mapNearbyEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay activos a menos de {radius} de ti.'**
  String mapNearbyEmpty(String radius);

  /// No description provided for @mapNearbyNeedLocation.
  ///
  /// In es, this message translates to:
  /// **'Toca «Ubicarme» para ver los activos cercanos.'**
  String get mapNearbyNeedLocation;

  /// No description provided for @mapNearbyLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando el catálogo…'**
  String get mapNearbyLoading;

  /// No description provided for @mapDistanceMeters.
  ///
  /// In es, this message translates to:
  /// **'{value} m'**
  String mapDistanceMeters(String value);

  /// No description provided for @mapDistanceKm.
  ///
  /// In es, this message translates to:
  /// **'{value} km'**
  String mapDistanceKm(String value);

  /// No description provided for @mapLayerPavement.
  ///
  /// In es, this message translates to:
  /// **'Pavimento (IRI) por tramo'**
  String get mapLayerPavement;

  /// No description provided for @mapPavementGood.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get mapPavementGood;

  /// No description provided for @mapPavementFair.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get mapPavementFair;

  /// No description provided for @mapPavementBad.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get mapPavementBad;

  /// No description provided for @mapPavementNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin mediciones'**
  String get mapPavementNoData;

  /// No description provided for @mapPavementLegend.
  ///
  /// In es, this message translates to:
  /// **'{label} por tramo · {cycle} · umbrales provisionales'**
  String mapPavementLegend(String label, String cycle);

  /// No description provided for @mapPavementSavedAt.
  ///
  /// In es, this message translates to:
  /// **'Pavimento guardado el {date}'**
  String mapPavementSavedAt(String date);

  /// No description provided for @mapPavementUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Su perfil no ve la capa de indicadores y pavimento.'**
  String get mapPavementUnavailable;

  /// No description provided for @mapPavementFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el pavimento. Intente de nuevo.'**
  String get mapPavementFailed;

  /// No description provided for @mapPavementSegment.
  ///
  /// In es, this message translates to:
  /// **'{label}: {value} {unit} · {level} · {coverage} % del tramo medido'**
  String mapPavementSegment(
    String label,
    String value,
    String unit,
    String level,
    String coverage,
  );

  /// No description provided for @mapDetailReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get mapDetailReference;

  /// No description provided for @mapDetailDistance.
  ///
  /// In es, this message translates to:
  /// **'A {distance} de ti'**
  String mapDetailDistance(String distance);

  /// No description provided for @mapDetailClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get mapDetailClose;

  /// No description provided for @mapActionsSoon.
  ///
  /// In es, this message translates to:
  /// **'Crear un registro, un monitoreo o un mantenimiento desde aquí se habilitará cuando esos módulos estén disponibles.'**
  String get mapActionsSoon;

  /// No description provided for @mapPacksTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapas sin conexión'**
  String get mapPacksTitle;

  /// No description provided for @mapPacksAction.
  ///
  /// In es, this message translates to:
  /// **'Mapas sin conexión'**
  String get mapPacksAction;

  /// No description provided for @mapPacksIntro.
  ///
  /// In es, this message translates to:
  /// **'Descarga el mapa de tu concesión para verlo sin internet. Se recomienda usar Wi-Fi: los paquetes pesan decenas de megabytes. Se borran al cambiar de concesión o cerrar sesión.'**
  String get mapPacksIntro;

  /// No description provided for @mapPacksEmpty.
  ///
  /// In es, this message translates to:
  /// **'El servidor no tiene mapas para descargar en esta concesión.'**
  String get mapPacksEmpty;

  /// No description provided for @mapPacksUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Los mapas sin conexión aún no están disponibles'**
  String get mapPacksUnavailableTitle;

  /// No description provided for @mapPacksUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no los publica para tu concesión.'**
  String get mapPacksUnavailableBody;

  /// No description provided for @mapPacksNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para descargar mapas'**
  String get mapPacksNoPermissionTitle;

  /// No description provided for @mapPacksNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede descargar mapas. Pide acceso a un administrador.'**
  String get mapPacksNoPermissionBody;

  /// No description provided for @mapPacksErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los mapas'**
  String get mapPacksErrorTitle;

  /// No description provided for @mapPacksErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get mapPacksErrorBody;

  /// No description provided for @mapPacksListOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: se muestran solo los mapas guardados en el teléfono.'**
  String get mapPacksListOffline;

  /// No description provided for @mapPackVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String mapPackVersion(int version);

  /// No description provided for @mapPackZoom.
  ///
  /// In es, this message translates to:
  /// **'Acercamiento {min} a {max}'**
  String mapPackZoom(int min, int max);

  /// No description provided for @mapPackInstalled.
  ///
  /// In es, this message translates to:
  /// **'Guardado en el teléfono'**
  String get mapPackInstalled;

  /// No description provided for @mapPackUpdateAvailable.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva'**
  String get mapPackUpdateAvailable;

  /// No description provided for @mapPackPaused.
  ///
  /// In es, this message translates to:
  /// **'Pausado · {size} bajados'**
  String mapPackPaused(String size);

  /// No description provided for @mapPackDownloading.
  ///
  /// In es, this message translates to:
  /// **'Bajando… {percent} %'**
  String mapPackDownloading(int percent);

  /// No description provided for @mapPackVerifying.
  ///
  /// In es, this message translates to:
  /// **'Comprobando el archivo…'**
  String get mapPackVerifying;

  /// No description provided for @mapPackDownload.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get mapPackDownload;

  /// No description provided for @mapPackResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get mapPackResume;

  /// No description provided for @mapPackUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get mapPackUpdate;

  /// No description provided for @mapPackPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get mapPackPause;

  /// No description provided for @mapPackDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar lo bajado'**
  String get mapPackDiscard;

  /// No description provided for @mapPackDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get mapPackDelete;

  /// No description provided for @mapPackDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar el mapa sin conexión?'**
  String get mapPackDeleteTitle;

  /// No description provided for @mapPackDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se liberan {size} del teléfono. Podrás volver a descargarlo.'**
  String mapPackDeleteBody(String size);

  /// No description provided for @mapPackCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get mapPackCancel;

  /// No description provided for @mapPackErrNetwork.
  ///
  /// In es, this message translates to:
  /// **'Se cortó la conexión. Puedes reanudar la descarga.'**
  String get mapPackErrNetwork;

  /// No description provided for @mapPackErrCorrupt.
  ///
  /// In es, this message translates to:
  /// **'El archivo descargado no coincide con el original y se descartó. Inténtalo de nuevo.'**
  String get mapPackErrCorrupt;

  /// No description provided for @mapPackErrNoSpace.
  ///
  /// In es, this message translates to:
  /// **'No hay espacio suficiente en el teléfono.'**
  String get mapPackErrNoSpace;

  /// No description provided for @mapPackErrNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este mapa ya no está disponible en el servidor.'**
  String get mapPackErrNotFound;

  /// No description provided for @mapPackErrServer.
  ///
  /// In es, this message translates to:
  /// **'El servidor no pudo entregar el mapa. Inténtalo más tarde.'**
  String get mapPackErrServer;

  /// No description provided for @mapPackErrPermission.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede descargar mapas.'**
  String get mapPackErrPermission;

  /// No description provided for @mapOfflineBadge.
  ///
  /// In es, this message translates to:
  /// **'Mapa sin conexión · {name}'**
  String mapOfflineBadge(String name);

  /// No description provided for @navTabMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navTabMap;

  /// No description provided for @navTabTicket.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get navTabTicket;

  /// No description provided for @navTabMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get navTabMenu;

  /// No description provided for @navTabInventory.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get navTabInventory;

  /// No description provided for @navTabMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get navTabMaintenance;

  /// No description provided for @mapLayerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Capa: {layer}'**
  String mapLayerSubtitle(String layer);

  /// No description provided for @mapResultsFound.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ningún elemento encontrado} =1{1 elemento encontrado} other{{count} elementos encontrados}}'**
  String mapResultsFound(int count);

  /// No description provided for @mapRefine.
  ///
  /// In es, this message translates to:
  /// **'Refinar búsqueda'**
  String get mapRefine;

  /// No description provided for @ticketsTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de registros'**
  String get ticketsTitle;

  /// No description provided for @ticketsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta de registros'**
  String get ticketsSubtitle;

  /// No description provided for @ticketsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título, ID, km…'**
  String get ticketsSearchHint;

  /// No description provided for @ticketsSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get ticketsSearchTooltip;

  /// No description provided for @ticketsFilterTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get ticketsFilterTooltip;

  /// No description provided for @ticketsFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar registros'**
  String get ticketsFilterTitle;

  /// No description provided for @ticketsFilterStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get ticketsFilterStatus;

  /// No description provided for @ticketsFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get ticketsFilterClear;

  /// No description provided for @ticketsFilterDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get ticketsFilterDone;

  /// No description provided for @ticketsDueSort.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento'**
  String get ticketsDueSort;

  /// No description provided for @ticketsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get ticketsFilterAll;

  /// No description provided for @ticketsFilterOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get ticketsFilterOpen;

  /// No description provided for @ticketsFilterAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendidos'**
  String get ticketsFilterAttended;

  /// No description provided for @ticketsNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo registro'**
  String get ticketsNew;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierto'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendido'**
  String get ticketStatusAttended;

  /// No description provided for @ticketsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún registro coincide con los filtros.'**
  String get ticketsEmpty;

  /// No description provided for @ticketsEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay registros.'**
  String get ticketsEmptyAll;

  /// No description provided for @ticketsUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Registros aún no disponibles'**
  String get ticketsUnavailableTitle;

  /// No description provided for @ticketsUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no publica los registros de esta concesión.'**
  String get ticketsUnavailableBody;

  /// No description provided for @ticketsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los registros'**
  String get ticketsErrorTitle;

  /// No description provided for @ticketsErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get ticketsErrorBody;

  /// No description provided for @ticketsNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a registros'**
  String get ticketsNoPermissionTitle;

  /// No description provided for @ticketsNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede ver los registros.'**
  String get ticketsNoPermissionBody;

  /// No description provided for @ticketsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get ticketsRetry;

  /// No description provided for @ticketsSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son registros reales.'**
  String get ticketsSampleBanner;

  /// No description provided for @ticketDueHours.
  ///
  /// In es, this message translates to:
  /// **'{n} h'**
  String ticketDueHours(int n);

  /// No description provided for @ticketDueDays.
  ///
  /// In es, this message translates to:
  /// **'{n} d'**
  String ticketDueDays(int n);

  /// No description provided for @ticketDueCaption.
  ///
  /// In es, this message translates to:
  /// **'para vencimiento'**
  String get ticketDueCaption;

  /// No description provided for @ticketOverdueCaption.
  ///
  /// In es, this message translates to:
  /// **'vencido'**
  String get ticketOverdueCaption;

  /// No description provided for @ticketBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get ticketBack;

  /// No description provided for @ticketIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID REGISTRO #{code}'**
  String ticketIdLabel(String code);

  /// No description provided for @ticketCreatedOn.
  ///
  /// In es, this message translates to:
  /// **'Creado el {date}'**
  String ticketCreatedOn(String date);

  /// No description provided for @ticketInfoGeneratedBy.
  ///
  /// In es, this message translates to:
  /// **'Generado por'**
  String get ticketInfoGeneratedBy;

  /// No description provided for @ticketInfoProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de usuario'**
  String get ticketInfoProfile;

  /// No description provided for @ticketInfoConcession.
  ///
  /// In es, this message translates to:
  /// **'Concesionaria'**
  String get ticketInfoConcession;

  /// No description provided for @ticketInfoCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa de usuario'**
  String get ticketInfoCompany;

  /// No description provided for @ticketInfoLatitude.
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get ticketInfoLatitude;

  /// No description provided for @ticketInfoLongitude.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get ticketInfoLongitude;

  /// No description provided for @ticketInfoChainage.
  ///
  /// In es, this message translates to:
  /// **'Cadenamiento'**
  String get ticketInfoChainage;

  /// No description provided for @ticketInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo'**
  String get ticketInfoBody;

  /// No description provided for @ticketTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de registro'**
  String get ticketTypeTitle;

  /// No description provided for @ticketDescriptionTitle.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get ticketDescriptionTitle;

  /// No description provided for @ticketFollowUpsTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimientos'**
  String get ticketFollowUpsTitle;

  /// No description provided for @ticketFollowUpsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay seguimientos.'**
  String get ticketFollowUpsEmpty;

  /// No description provided for @ticketActionDownload.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get ticketActionDownload;

  /// No description provided for @ticketActionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get ticketActionEdit;

  /// No description provided for @ticketActionFollowUp.
  ///
  /// In es, this message translates to:
  /// **'Agregar seguimiento'**
  String get ticketActionFollowUp;

  /// No description provided for @ticketActionSoon.
  ///
  /// In es, this message translates to:
  /// **'Esta acción estará disponible pronto.'**
  String get ticketActionSoon;

  /// No description provided for @ticketNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el registro.'**
  String get ticketNotFound;

  /// No description provided for @followUpTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de registro'**
  String get followUpTitle;

  /// No description provided for @followUpDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get followUpDate;

  /// No description provided for @followUpTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get followUpTime;

  /// No description provided for @followUpStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del registro'**
  String get followUpStatus;

  /// No description provided for @followUpSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get followUpSelect;

  /// No description provided for @followUpDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get followUpDescription;

  /// No description provided for @followUpFillIn.
  ///
  /// In es, this message translates to:
  /// **'Complete información'**
  String get followUpFillIn;

  /// No description provided for @followUpPhotos.
  ///
  /// In es, this message translates to:
  /// **'Fotografías'**
  String get followUpPhotos;

  /// No description provided for @followUpPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto {n}'**
  String followUpPhoto(int n);

  /// No description provided for @followUpPhotoRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get followUpPhotoRemove;

  /// No description provided for @followUpSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar seguimiento'**
  String get followUpSave;

  /// No description provided for @followUpSaved.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento guardado.'**
  String get followUpSaved;

  /// No description provided for @followUpErrorStatus.
  ///
  /// In es, this message translates to:
  /// **'Elige el estado del registro.'**
  String get followUpErrorStatus;

  /// No description provided for @followUpErrorDescription.
  ///
  /// In es, this message translates to:
  /// **'Escribe una descripción.'**
  String get followUpErrorDescription;

  /// No description provided for @ticketSavedPartly.
  ///
  /// In es, this message translates to:
  /// **'El registro se guardó, pero faltó una parte: {reason}'**
  String ticketSavedPartly(String reason);

  /// No description provided for @ticketSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Inténtalo de nuevo.'**
  String get ticketSaveFailed;

  /// No description provided for @newTicketPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get newTicketPriority;

  /// No description provided for @ticketPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get ticketPriorityLow;

  /// No description provided for @ticketPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get ticketPriorityMedium;

  /// No description provided for @ticketPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get ticketPriorityHigh;

  /// No description provided for @ticketPriorityCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítica'**
  String get ticketPriorityCritical;

  /// No description provided for @newTicketTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo registro'**
  String get newTicketTitle;

  /// No description provided for @newTicketName.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get newTicketName;

  /// No description provided for @newTicketCategory.
  ///
  /// In es, this message translates to:
  /// **'Tipo de registro'**
  String get newTicketCategory;

  /// No description provided for @newTicketChainage.
  ///
  /// In es, this message translates to:
  /// **'Cadenamiento (km)'**
  String get newTicketChainage;

  /// No description provided for @newTicketCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear registro'**
  String get newTicketCreate;

  /// No description provided for @newTicketCreated.
  ///
  /// In es, this message translates to:
  /// **'Registro creado.'**
  String get newTicketCreated;

  /// No description provided for @newTicketErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe un título.'**
  String get newTicketErrorTitle;

  /// No description provided for @newTicketErrorCategory.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo de registro.'**
  String get newTicketErrorCategory;

  /// No description provided for @accidentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Accidentes'**
  String get accidentsTitle;

  /// No description provided for @accidentsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título, ID, km…'**
  String get accidentsSearchHint;

  /// No description provided for @accidentsSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get accidentsSearchTooltip;

  /// No description provided for @accidentsFilterTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get accidentsFilterTooltip;

  /// No description provided for @accidentsNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo accidente'**
  String get accidentsNew;

  /// No description provided for @accidentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún accidente coincide con los filtros.'**
  String get accidentsEmpty;

  /// No description provided for @accidentsEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay accidentes registrados.'**
  String get accidentsEmptyAll;

  /// No description provided for @accidentsUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Accidentes aún no disponibles'**
  String get accidentsUnavailableTitle;

  /// No description provided for @accidentsUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no publica los accidentes de esta concesión.'**
  String get accidentsUnavailableBody;

  /// No description provided for @accidentsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los accidentes'**
  String get accidentsErrorTitle;

  /// No description provided for @accidentsErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get accidentsErrorBody;

  /// No description provided for @accidentsNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a accidentes'**
  String get accidentsNoPermissionTitle;

  /// No description provided for @accidentsNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede ver los accidentes.'**
  String get accidentsNoPermissionBody;

  /// No description provided for @accidentsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get accidentsRetry;

  /// No description provided for @accidentsSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son accidentes reales.'**
  String get accidentsSampleBanner;

  /// No description provided for @accidentsStatTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get accidentsStatTotal;

  /// No description provided for @accidentsStatTotalShare.
  ///
  /// In es, this message translates to:
  /// **'100% total'**
  String get accidentsStatTotalShare;

  /// No description provided for @accidentsStatShare.
  ///
  /// In es, this message translates to:
  /// **'{percent}%'**
  String accidentsStatShare(String percent);

  /// No description provided for @accidentsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get accidentsFilterAll;

  /// No description provided for @accidentsFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar accidentes'**
  String get accidentsFilterTitle;

  /// No description provided for @accidentsFilterSeverity.
  ///
  /// In es, this message translates to:
  /// **'Gravedad'**
  String get accidentsFilterSeverity;

  /// No description provided for @accidentTypeCollision.
  ///
  /// In es, this message translates to:
  /// **'Choque'**
  String get accidentTypeCollision;

  /// No description provided for @accidentTypeRollover.
  ///
  /// In es, this message translates to:
  /// **'Volcamiento'**
  String get accidentTypeRollover;

  /// No description provided for @accidentTypeFire.
  ///
  /// In es, this message translates to:
  /// **'Incendio'**
  String get accidentTypeFire;

  /// No description provided for @accidentStatusRegistered.
  ///
  /// In es, this message translates to:
  /// **'Registrado'**
  String get accidentStatusRegistered;

  /// No description provided for @accidentStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get accidentStatusInProgress;

  /// No description provided for @accidentStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get accidentStatusClosed;

  /// No description provided for @accidentIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID ACCIDENTE #{code}'**
  String accidentIdLabel(String code);

  /// No description provided for @accidentTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de accidente'**
  String get accidentTypeTitle;

  /// No description provided for @accidentSeverityTitle.
  ///
  /// In es, this message translates to:
  /// **'Gravedad'**
  String get accidentSeverityTitle;

  /// No description provided for @accidentNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el accidente.'**
  String get accidentNotFound;

  /// No description provided for @newAccidentTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo accidente'**
  String get newAccidentTitle;

  /// No description provided for @newAccidentCreate.
  ///
  /// In es, this message translates to:
  /// **'Registrar accidente'**
  String get newAccidentCreate;

  /// No description provided for @newAccidentCreated.
  ///
  /// In es, this message translates to:
  /// **'Accidente registrado.'**
  String get newAccidentCreated;

  /// No description provided for @newAccidentErrorType.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo de accidente.'**
  String get newAccidentErrorType;

  /// No description provided for @newAccidentErrorSeverity.
  ///
  /// In es, this message translates to:
  /// **'Elige la gravedad.'**
  String get newAccidentErrorSeverity;

  /// No description provided for @maintIndicatorsTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un indicador'**
  String get maintIndicatorsTitle;

  /// No description provided for @fieldTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get fieldTeam;

  /// No description provided for @fieldAccessValidUntil.
  ///
  /// In es, this message translates to:
  /// **'Acceso vigente hasta'**
  String get fieldAccessValidUntil;

  /// No description provided for @profilePhotoChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get profilePhotoChange;

  /// No description provided for @accountPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones de la cuenta'**
  String get accountPanelTitle;

  /// No description provided for @accountMyAccount.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get accountMyAccount;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get accountSettingsTitle;

  /// No description provided for @accountSettingsSub.
  ///
  /// In es, this message translates to:
  /// **'Seguridad, preferencias y dispositivo'**
  String get accountSettingsSub;

  /// No description provided for @accountDeviceSection.
  ///
  /// In es, this message translates to:
  /// **'Acerca del dispositivo'**
  String get accountDeviceSection;

  /// No description provided for @indicatorsPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Indicadores'**
  String get indicatorsPanelTitle;

  /// No description provided for @indicatorsPanelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento y conservación'**
  String get indicatorsPanelSubtitle;

  /// No description provided for @indicatorsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar indicador'**
  String get indicatorsSearchHint;

  /// No description provided for @indicatorsNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún indicador coincide.'**
  String get indicatorsNoMatch;

  /// No description provided for @homeOpenMenu.
  ///
  /// In es, this message translates to:
  /// **'Abrir menú'**
  String get homeOpenMenu;

  /// No description provided for @homeSummaryTickets.
  ///
  /// In es, this message translates to:
  /// **'Registros abiertos'**
  String get homeSummaryTickets;

  /// No description provided for @homeSummaryOverdue.
  ///
  /// In es, this message translates to:
  /// **'{count} vencidos'**
  String homeSummaryOverdue(int count);

  /// No description provided for @homeSummaryOnTime.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get homeSummaryOnTime;

  /// No description provided for @homeSummaryAssets.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get homeSummaryAssets;

  /// No description provided for @homeSummaryAccidents.
  ///
  /// In es, this message translates to:
  /// **'Accidentes'**
  String get homeSummaryAccidents;

  /// No description provided for @homeSummaryAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get homeSummaryAlerts;

  /// No description provided for @homeSummaryUnread.
  ///
  /// In es, this message translates to:
  /// **'{count} sin leer'**
  String homeSummaryUnread(int count);

  /// No description provided for @homeSummaryInProgress.
  ///
  /// In es, this message translates to:
  /// **'{count} en proceso'**
  String homeSummaryInProgress(int count);

  /// No description provided for @maintIndSgp.
  ///
  /// In es, this message translates to:
  /// **'Pavimentos'**
  String get maintIndSgp;

  /// No description provided for @maintIndSgs.
  ///
  /// In es, this message translates to:
  /// **'Señalización'**
  String get maintIndSgs;

  /// No description provided for @maintIndSgoae.
  ///
  /// In es, this message translates to:
  /// **'OAEs'**
  String get maintIndSgoae;

  /// No description provided for @maintIndSgoac.
  ///
  /// In es, this message translates to:
  /// **'OACs'**
  String get maintIndSgoac;

  /// No description provided for @maintIndSgits.
  ///
  /// In es, this message translates to:
  /// **'Equipos ITS'**
  String get maintIndSgits;

  /// No description provided for @maintIndSgf.
  ///
  /// In es, this message translates to:
  /// **'Faixa de dominio'**
  String get maintIndSgf;

  /// No description provided for @maintIndSgtec.
  ///
  /// In es, this message translates to:
  /// **'Terraplenos y estructuras'**
  String get maintIndSgtec;

  /// No description provided for @maintIndSge.
  ///
  /// In es, this message translates to:
  /// **'Edificaciones e instalaciones'**
  String get maintIndSge;

  /// No description provided for @maintTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintTitle;

  /// No description provided for @maintSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta y gestión de infraestructura de concesión'**
  String get maintSubtitle;

  /// No description provided for @maintStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierto'**
  String get maintStatusOpen;

  /// No description provided for @maintStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'Proceso'**
  String get maintStatusInProgress;

  /// No description provided for @maintStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get maintStatusClosed;

  /// No description provided for @maintStatTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get maintStatTotal;

  /// No description provided for @maintStatTotalCaption.
  ///
  /// In es, this message translates to:
  /// **'100% total'**
  String get maintStatTotalCaption;

  /// No description provided for @maintStatOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get maintStatOpen;

  /// No description provided for @maintStatInProgress.
  ///
  /// In es, this message translates to:
  /// **'Proceso'**
  String get maintStatInProgress;

  /// No description provided for @maintStatClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get maintStatClosed;

  /// No description provided for @maintStatShare.
  ///
  /// In es, this message translates to:
  /// **'{percent}% del total'**
  String maintStatShare(String percent);

  /// No description provided for @maintTicketsTotal.
  ///
  /// In es, this message translates to:
  /// **'Tickets'**
  String get maintTicketsTotal;

  /// No description provided for @maintTicketsPeriod.
  ///
  /// In es, this message translates to:
  /// **'Del periodo'**
  String get maintTicketsPeriod;

  /// No description provided for @maintTicketsOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get maintTicketsOpen;

  /// No description provided for @maintTicketsAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendidos'**
  String get maintTicketsAttended;

  /// No description provided for @maintTicketsClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get maintTicketsClosed;

  /// No description provided for @maintTicketsCaption.
  ///
  /// In es, this message translates to:
  /// **'Tickets (M11)'**
  String get maintTicketsCaption;

  /// No description provided for @maintPerCompliance.
  ///
  /// In es, this message translates to:
  /// **'PER {percent}% · año {year}'**
  String maintPerCompliance(String percent, String year);

  /// No description provided for @maintFilterState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get maintFilterState;

  /// No description provided for @maintFilterAllStates.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get maintFilterAllStates;

  /// No description provided for @maintDateHint.
  ///
  /// In es, this message translates to:
  /// **'DD/MM/AAAA'**
  String get maintDateHint;

  /// No description provided for @maintDateFrom.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicial'**
  String get maintDateFrom;

  /// No description provided for @maintDateTo.
  ///
  /// In es, this message translates to:
  /// **'Fecha final'**
  String get maintDateTo;

  /// No description provided for @maintFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get maintFilterClear;

  /// No description provided for @maintSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get maintSearchTooltip;

  /// No description provided for @maintSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por ubicación o actividad…'**
  String get maintSearchHint;

  /// No description provided for @maintFilterTooltip.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get maintFilterTooltip;

  /// No description provided for @maintEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún mantenimiento coincide con los filtros.'**
  String get maintEmpty;

  /// No description provided for @maintEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'No hay mantenimientos para este indicador.'**
  String get maintEmptyAll;

  /// No description provided for @maintUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento aún no disponible'**
  String get maintUnavailableTitle;

  /// No description provided for @maintUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no publica el mantenimiento de esta concesión.'**
  String get maintUnavailableBody;

  /// No description provided for @maintErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el mantenimiento'**
  String get maintErrorTitle;

  /// No description provided for @maintErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get maintErrorBody;

  /// No description provided for @maintNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a mantenimiento'**
  String get maintNoPermissionTitle;

  /// No description provided for @maintNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede ver este indicador.'**
  String get maintNoPermissionBody;

  /// No description provided for @maintRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get maintRetry;

  /// No description provided for @maintProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar avance'**
  String get maintProgressTitle;

  /// No description provided for @maintProgressPercent.
  ///
  /// In es, this message translates to:
  /// **'Avance acumulado (%), si no conoces el volumen'**
  String get maintProgressPercent;

  /// No description provided for @maintProgressVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen ejecutado en este seguimiento'**
  String get maintProgressVolume;

  /// No description provided for @maintProgressVolumeUnit.
  ///
  /// In es, this message translates to:
  /// **'Volumen ejecutado en este seguimiento ({unit})'**
  String maintProgressVolumeUnit(String unit);

  /// No description provided for @maintProgressNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get maintProgressNotes;

  /// No description provided for @maintProgressOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get maintProgressOptional;

  /// No description provided for @maintProgressSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar avance'**
  String get maintProgressSave;

  /// No description provided for @maintProgressSaved.
  ///
  /// In es, this message translates to:
  /// **'Avance guardado.'**
  String get maintProgressSaved;

  /// No description provided for @maintProgressErrorPercent.
  ///
  /// In es, this message translates to:
  /// **'Escribe un avance entre 0 y 100.'**
  String get maintProgressErrorPercent;

  /// No description provided for @maintProgressErrorVolume.
  ///
  /// In es, this message translates to:
  /// **'Escribe un volumen mayor que 0.'**
  String get maintProgressErrorVolume;

  /// No description provided for @maintProgressNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e inténtalo de nuevo.'**
  String get maintProgressNetwork;

  /// No description provided for @maintProgressNoPermission.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede registrar avances.'**
  String get maintProgressNoPermission;

  /// No description provided for @maintProgressFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el avance. Inténtalo de nuevo.'**
  String get maintProgressFailed;

  /// No description provided for @maintSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son mantenimientos reales.'**
  String get maintSampleBanner;

  /// No description provided for @maintTotalVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen Total: {value}'**
  String maintTotalVolume(String value);

  /// No description provided for @maintUnitDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción: {unit}'**
  String maintUnitDescription(String unit);

  /// No description provided for @maintProgress.
  ///
  /// In es, this message translates to:
  /// **'Avance'**
  String get maintProgress;

  /// No description provided for @maintActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad: {activity}'**
  String maintActivity(String activity);

  /// No description provided for @maintProjectProgress.
  ///
  /// In es, this message translates to:
  /// **'Avance del proyecto'**
  String get maintProjectProgress;

  /// No description provided for @maintExecutedAmount.
  ///
  /// In es, this message translates to:
  /// **'Importe Ejec.'**
  String get maintExecutedAmount;

  /// No description provided for @maintPendingAmount.
  ///
  /// In es, this message translates to:
  /// **'Por Ejecutar'**
  String get maintPendingAmount;

  /// No description provided for @maintDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles de mantenimiento'**
  String get maintDetailsTitle;

  /// No description provided for @maintKmStart.
  ///
  /// In es, this message translates to:
  /// **'Km inicial'**
  String get maintKmStart;

  /// No description provided for @maintKmEnd.
  ///
  /// In es, this message translates to:
  /// **'Km final'**
  String get maintKmEnd;

  /// No description provided for @maintDirection.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get maintDirection;

  /// No description provided for @maintSense.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get maintSense;

  /// No description provided for @maintVolumeTotal.
  ///
  /// In es, this message translates to:
  /// **'Volumen total'**
  String get maintVolumeTotal;

  /// No description provided for @maintVolumeExecuted.
  ///
  /// In es, this message translates to:
  /// **'Volumen ejecutado'**
  String get maintVolumeExecuted;

  /// No description provided for @maintUnitCost.
  ///
  /// In es, this message translates to:
  /// **'Costo unitario'**
  String get maintUnitCost;

  /// No description provided for @maintProgrammedAmount.
  ///
  /// In es, this message translates to:
  /// **'Importe programado'**
  String get maintProgrammedAmount;

  /// No description provided for @maintStartDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicio'**
  String get maintStartDate;

  /// No description provided for @maintEndDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha fin'**
  String get maintEndDate;

  /// No description provided for @maintNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el mantenimiento.'**
  String get maintNotFound;

  /// No description provided for @invTitle.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get invTitle;

  /// No description provided for @invSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activos de la concesión'**
  String get invSubtitle;

  /// No description provided for @invSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get invSearchTooltip;

  /// No description provided for @invSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Código, descripción, marca o serie'**
  String get invSearchHint;

  /// No description provided for @invFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get invFilterClear;

  /// No description provided for @invSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son activos reales.'**
  String get invSampleBanner;

  /// No description provided for @invStatTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get invStatTotal;

  /// No description provided for @invStatTotalCaption.
  ///
  /// In es, this message translates to:
  /// **'100% total'**
  String get invStatTotalCaption;

  /// No description provided for @invStatShare.
  ///
  /// In es, this message translates to:
  /// **'{percent}% del total'**
  String invStatShare(String percent);

  /// No description provided for @invStatGood.
  ///
  /// In es, this message translates to:
  /// **'Buenos'**
  String get invStatGood;

  /// No description provided for @invStatRegular.
  ///
  /// In es, this message translates to:
  /// **'Regulares'**
  String get invStatRegular;

  /// No description provided for @invStatPoor.
  ///
  /// In es, this message translates to:
  /// **'Malos'**
  String get invStatPoor;

  /// No description provided for @invConditionGood.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get invConditionGood;

  /// No description provided for @invConditionRegular.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get invConditionRegular;

  /// No description provided for @invConditionPoor.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get invConditionPoor;

  /// No description provided for @invConditionUnknown.
  ///
  /// In es, this message translates to:
  /// **'Sin evaluar'**
  String get invConditionUnknown;

  /// No description provided for @invSitePhoto.
  ///
  /// In es, this message translates to:
  /// **'Vista en sitio'**
  String get invSitePhoto;

  /// No description provided for @invFilterCondition.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get invFilterCondition;

  /// No description provided for @invFilterAllConditions.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get invFilterAllConditions;

  /// No description provided for @invFilterCategory.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get invFilterCategory;

  /// No description provided for @invFilterAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todos los tipos'**
  String get invFilterAllCategories;

  /// No description provided for @invInspectedFrom.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo desde'**
  String get invInspectedFrom;

  /// No description provided for @invInspectedTo.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo hasta'**
  String get invInspectedTo;

  /// No description provided for @invDateHint.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get invDateHint;

  /// No description provided for @invEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay activos registrados.'**
  String get invEmptyAll;

  /// No description provided for @invEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún activo coincide con los filtros.'**
  String get invEmpty;

  /// No description provided for @invUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Catálogo no disponible'**
  String get invUnavailableTitle;

  /// No description provided for @invUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Esta concesión todavía no publica su catálogo en la app.'**
  String get invUnavailableBody;

  /// No description provided for @invNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso al catálogo'**
  String get invNoPermissionTitle;

  /// No description provided for @invNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar el catálogo.'**
  String get invNoPermissionBody;

  /// No description provided for @invNotFound.
  ///
  /// In es, this message translates to:
  /// **'El activo ya no existe.'**
  String get invNotFound;

  /// No description provided for @invErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo'**
  String get invErrorTitle;

  /// No description provided for @invErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get invErrorBody;

  /// No description provided for @invRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get invRetry;

  /// No description provided for @invOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get invOfflineTitle;

  /// No description provided for @invOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Sin señal solo se ve lo que ya consultaste. Conéctate e inténtalo de nuevo.'**
  String get invOfflineBody;

  /// No description provided for @invMoreError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron traer más activos.'**
  String get invMoreError;

  /// No description provided for @invDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get invDetailTitle;

  /// No description provided for @invDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del activo'**
  String get invDetailsTitle;

  /// No description provided for @invCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get invCategoryLabel;

  /// No description provided for @invKm.
  ///
  /// In es, this message translates to:
  /// **'Kilómetro'**
  String get invKm;

  /// No description provided for @invSegment.
  ///
  /// In es, this message translates to:
  /// **'Tramo'**
  String get invSegment;

  /// No description provided for @invDirection.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get invDirection;

  /// No description provided for @invInstalled.
  ///
  /// In es, this message translates to:
  /// **'Instalación'**
  String get invInstalled;

  /// No description provided for @invLastInspection.
  ///
  /// In es, this message translates to:
  /// **'Último monitoreo'**
  String get invLastInspection;

  /// No description provided for @invNextInspection.
  ///
  /// In es, this message translates to:
  /// **'Próximo monitoreo'**
  String get invNextInspection;

  /// No description provided for @invConditionNotApplicable.
  ///
  /// In es, this message translates to:
  /// **'No aplica'**
  String get invConditionNotApplicable;

  /// No description provided for @invConditionOrigin.
  ///
  /// In es, this message translates to:
  /// **'Origen de la condición'**
  String get invConditionOrigin;

  /// No description provided for @invOpenFindings.
  ///
  /// In es, this message translates to:
  /// **'Hallazgos abiertos'**
  String get invOpenFindings;

  /// No description provided for @invNotLocated.
  ///
  /// In es, this message translates to:
  /// **'Reportado no localizado en campo el {date}'**
  String invNotLocated(String date);

  /// No description provided for @invConditionSourceWebgis.
  ///
  /// In es, this message translates to:
  /// **'WebGIS'**
  String get invConditionSourceWebgis;

  /// No description provided for @invConditionSourceInspection.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get invConditionSourceInspection;

  /// No description provided for @invConditionSourceManual.
  ///
  /// In es, this message translates to:
  /// **'Ajuste a mano'**
  String get invConditionSourceManual;

  /// No description provided for @invConditionSourceTicket.
  ///
  /// In es, this message translates to:
  /// **'Cierre de registro'**
  String get invConditionSourceTicket;

  /// No description provided for @invConditionSourceMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get invConditionSourceMaintenance;

  /// No description provided for @invConditionSourceInitial.
  ///
  /// In es, this message translates to:
  /// **'Carga inicial'**
  String get invConditionSourceInitial;

  /// No description provided for @invCoordinates.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas'**
  String get invCoordinates;

  /// No description provided for @invNotes.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get invNotes;

  /// No description provided for @invViewOnMap.
  ///
  /// In es, this message translates to:
  /// **'Ver en mapa'**
  String get invViewOnMap;

  /// No description provided for @invNoLocation.
  ///
  /// In es, this message translates to:
  /// **'Este activo no tiene ubicación.'**
  String get invNoLocation;

  /// No description provided for @invCardInspected.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo: {date}'**
  String invCardInspected(String date);

  /// No description provided for @repTitle.
  ///
  /// In es, this message translates to:
  /// **'Indicadores y reportes'**
  String get repTitle;

  /// No description provided for @repSelectTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un indicador'**
  String get repSelectTitle;

  /// No description provided for @repReportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reporte del indicador'**
  String get repReportSubtitle;

  /// No description provided for @repSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: el reporte sale de mantenimientos de ejemplo.'**
  String get repSampleBanner;

  /// No description provided for @repFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get repFrom;

  /// No description provided for @repTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get repTo;

  /// No description provided for @repDateHint.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get repDateHint;

  /// No description provided for @repGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar reporte'**
  String get repGenerate;

  /// No description provided for @repRegenerate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar reporte'**
  String get repRegenerate;

  /// No description provided for @repNotGenerated.
  ///
  /// In es, this message translates to:
  /// **'Elige el periodo y genera el reporte. Sin fechas, incluye todo el historial.'**
  String get repNotGenerated;

  /// No description provided for @repGeneratedAt.
  ///
  /// In es, this message translates to:
  /// **'Generado: {date}'**
  String repGeneratedAt(String date);

  /// No description provided for @repPeriodAll.
  ///
  /// In es, this message translates to:
  /// **'Todo el historial'**
  String get repPeriodAll;

  /// No description provided for @repPeriodRange.
  ///
  /// In es, this message translates to:
  /// **'Del {from} al {to}'**
  String repPeriodRange(String from, String to);

  /// No description provided for @repPeriodFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde el {from}'**
  String repPeriodFrom(String from);

  /// No description provided for @repPeriodUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta el {to}'**
  String repPeriodUntil(String to);

  /// No description provided for @repStale.
  ///
  /// In es, this message translates to:
  /// **'Cambiaste el periodo: actualiza el reporte.'**
  String get repStale;

  /// No description provided for @repSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get repSummaryTitle;

  /// No description provided for @repTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get repTotal;

  /// No description provided for @repStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get repStatusOpen;

  /// No description provided for @repStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get repStatusInProgress;

  /// No description provided for @repStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get repStatusClosed;

  /// No description provided for @repExecution.
  ///
  /// In es, this message translates to:
  /// **'Ejecución del importe'**
  String get repExecution;

  /// No description provided for @repProgrammedAmount.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get repProgrammedAmount;

  /// No description provided for @repExecutedAmount.
  ///
  /// In es, this message translates to:
  /// **'Ejecutado'**
  String get repExecutedAmount;

  /// No description provided for @repPendingAmount.
  ///
  /// In es, this message translates to:
  /// **'Por ejecutar'**
  String get repPendingAmount;

  /// No description provided for @repOrdersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos del periodo'**
  String get repOrdersTitle;

  /// No description provided for @repEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay mantenimientos de este indicador en el periodo.'**
  String get repEmpty;

  /// No description provided for @repUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportes no disponibles'**
  String get repUnavailableTitle;

  /// No description provided for @repUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Esta concesión todavía no publica los datos para los reportes.'**
  String get repUnavailableBody;

  /// No description provided for @repNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso al reporte'**
  String get repNoPermissionTitle;

  /// No description provided for @repNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar este indicador.'**
  String get repNoPermissionBody;

  /// No description provided for @repErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el reporte'**
  String get repErrorTitle;

  /// No description provided for @repErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get repErrorBody;

  /// No description provided for @repRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get repRetry;

  /// No description provided for @dashTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get dashTitle;

  /// No description provided for @dashSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen operativo'**
  String get dashSubtitle;

  /// No description provided for @dashSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: el resumen sale de los módulos de ejemplo.'**
  String get dashSampleBanner;

  /// No description provided for @dashUpdated.
  ///
  /// In es, this message translates to:
  /// **'Actualizado: {date}'**
  String dashUpdated(String date);

  /// No description provided for @dashViewMap.
  ///
  /// In es, this message translates to:
  /// **'Ver mapa'**
  String get dashViewMap;

  /// No description provided for @dashTickets.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get dashTickets;

  /// No description provided for @dashTicketsOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get dashTicketsOpen;

  /// No description provided for @dashTicketsAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendidos'**
  String get dashTicketsAttended;

  /// No description provided for @dashTicketsOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencidos'**
  String get dashTicketsOverdue;

  /// No description provided for @dashAccidents.
  ///
  /// In es, this message translates to:
  /// **'Accidentes'**
  String get dashAccidents;

  /// No description provided for @dashAccidentsPeriod.
  ///
  /// In es, this message translates to:
  /// **'Últimos {days} días'**
  String dashAccidentsPeriod(int days);

  /// No description provided for @dashAccidentsTotal.
  ///
  /// In es, this message translates to:
  /// **'Registrados'**
  String get dashAccidentsTotal;

  /// No description provided for @dashAccidentsSevere.
  ///
  /// In es, this message translates to:
  /// **'Graves'**
  String get dashAccidentsSevere;

  /// No description provided for @dashAccidentsOpen.
  ///
  /// In es, this message translates to:
  /// **'En seguimiento'**
  String get dashAccidentsOpen;

  /// No description provided for @dashMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get dashMaintenance;

  /// No description provided for @dashMaintOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertos'**
  String get dashMaintOpen;

  /// No description provided for @dashMaintInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get dashMaintInProgress;

  /// No description provided for @dashMaintClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get dashMaintClosed;

  /// No description provided for @dashMaintExecution.
  ///
  /// In es, this message translates to:
  /// **'Ejecución del importe: {percent}'**
  String dashMaintExecution(String percent);

  /// No description provided for @dashInventory.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get dashInventory;

  /// No description provided for @dashInventoryTotal.
  ///
  /// In es, this message translates to:
  /// **'{count} activos'**
  String dashInventoryTotal(int count);

  /// No description provided for @dashInvGood.
  ///
  /// In es, this message translates to:
  /// **'Buenos'**
  String get dashInvGood;

  /// No description provided for @dashInvRegular.
  ///
  /// In es, this message translates to:
  /// **'Regulares'**
  String get dashInvRegular;

  /// No description provided for @dashInvPoor.
  ///
  /// In es, this message translates to:
  /// **'Malos'**
  String get dashInvPoor;

  /// No description provided for @dashSectionUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Aún no disponible en esta concesión.'**
  String get dashSectionUnavailable;

  /// No description provided for @dashSectionNoPermission.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no tiene acceso a este módulo.'**
  String get dashSectionNoPermission;

  /// No description provided for @dashSectionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar esta información.'**
  String get dashSectionError;

  /// No description provided for @dashRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get dashRetry;

  /// No description provided for @dashErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el dashboard'**
  String get dashErrorTitle;

  /// No description provided for @dashErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get dashErrorBody;

  /// No description provided for @dashUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard no disponible'**
  String get dashUnavailableTitle;

  /// No description provided for @dashUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Esta concesión todavía no publica datos para el resumen.'**
  String get dashUnavailableBody;

  /// No description provided for @workTitle.
  ///
  /// In es, this message translates to:
  /// **'Obras'**
  String get workTitle;

  /// No description provided for @workSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avance de obras y conservación'**
  String get workSubtitle;

  /// No description provided for @workSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get workSearchTooltip;

  /// No description provided for @workSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar obra, contratista o tramo'**
  String get workSearchHint;

  /// No description provided for @workFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get workFilterClear;

  /// No description provided for @workSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son obras reales.'**
  String get workSampleBanner;

  /// No description provided for @workStatTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get workStatTotal;

  /// No description provided for @workStatTotalCaption.
  ///
  /// In es, this message translates to:
  /// **'obras'**
  String get workStatTotalCaption;

  /// No description provided for @workStatNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Por iniciar'**
  String get workStatNotStarted;

  /// No description provided for @workStatInProgress.
  ///
  /// In es, this message translates to:
  /// **'En ejecución'**
  String get workStatInProgress;

  /// No description provided for @workStatDelayed.
  ///
  /// In es, this message translates to:
  /// **'Con atraso'**
  String get workStatDelayed;

  /// No description provided for @workStatFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminadas'**
  String get workStatFinished;

  /// No description provided for @workStatusNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Por iniciar'**
  String get workStatusNotStarted;

  /// No description provided for @workStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En ejecución'**
  String get workStatusInProgress;

  /// No description provided for @workStatusDelayed.
  ///
  /// In es, this message translates to:
  /// **'Con atraso'**
  String get workStatusDelayed;

  /// No description provided for @workStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get workStatusFinished;

  /// No description provided for @workFilterState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get workFilterState;

  /// No description provided for @workFilterAllStates.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get workFilterAllStates;

  /// No description provided for @workEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay obras registradas.'**
  String get workEmptyAll;

  /// No description provided for @workEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ninguna obra coincide con los filtros.'**
  String get workEmpty;

  /// No description provided for @workUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Obras no disponibles'**
  String get workUnavailableTitle;

  /// No description provided for @workUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Esta concesión todavía no publica sus obras en la app.'**
  String get workUnavailableBody;

  /// No description provided for @workNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a las obras'**
  String get workNoPermissionTitle;

  /// No description provided for @workNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar las obras.'**
  String get workNoPermissionBody;

  /// No description provided for @workNotFound.
  ///
  /// In es, this message translates to:
  /// **'La obra ya no existe.'**
  String get workNotFound;

  /// No description provided for @workErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las obras'**
  String get workErrorTitle;

  /// No description provided for @workErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get workErrorBody;

  /// No description provided for @workRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get workRetry;

  /// No description provided for @workDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Obra'**
  String get workDetailTitle;

  /// No description provided for @workPhysical.
  ///
  /// In es, this message translates to:
  /// **'Avance físico'**
  String get workPhysical;

  /// No description provided for @workProgrammed.
  ///
  /// In es, this message translates to:
  /// **'Avance programado'**
  String get workProgrammed;

  /// No description provided for @workLag.
  ///
  /// In es, this message translates to:
  /// **'Atraso: {percent}'**
  String workLag(String percent);

  /// No description provided for @workOnTrack.
  ///
  /// In es, this message translates to:
  /// **'Al día con el programa'**
  String get workOnTrack;

  /// No description provided for @workBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get workBudget;

  /// No description provided for @workExecutedAmount.
  ///
  /// In es, this message translates to:
  /// **'Ejercido'**
  String get workExecutedAmount;

  /// No description provided for @workPendingAmount.
  ///
  /// In es, this message translates to:
  /// **'Por ejercer'**
  String get workPendingAmount;

  /// No description provided for @workDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de la obra'**
  String get workDetailsTitle;

  /// No description provided for @workContractor.
  ///
  /// In es, this message translates to:
  /// **'Contratista'**
  String get workContractor;

  /// No description provided for @workKmStart.
  ///
  /// In es, this message translates to:
  /// **'Km inicial'**
  String get workKmStart;

  /// No description provided for @workKmEnd.
  ///
  /// In es, this message translates to:
  /// **'Km final'**
  String get workKmEnd;

  /// No description provided for @workSegment.
  ///
  /// In es, this message translates to:
  /// **'Tramo'**
  String get workSegment;

  /// No description provided for @workDirection.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get workDirection;

  /// No description provided for @workStartDate.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get workStartDate;

  /// No description provided for @workEndDate.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get workEndDate;

  /// No description provided for @workViewOnMap.
  ///
  /// In es, this message translates to:
  /// **'Ver en mapa'**
  String get workViewOnMap;

  /// No description provided for @workNoLocation.
  ///
  /// In es, this message translates to:
  /// **'Esta obra no tiene ubicación.'**
  String get workNoLocation;

  /// No description provided for @inspTitle.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get inspTitle;

  /// No description provided for @inspSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Asignadas y en campo'**
  String get inspSubtitle;

  /// No description provided for @inspSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get inspSearchTooltip;

  /// No description provided for @inspSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar monitoreo, activo o tramo'**
  String get inspSearchHint;

  /// No description provided for @inspFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get inspFilterClear;

  /// No description provided for @inspSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Datos de ejemplo: no son monitoreos reales.'**
  String get inspSampleBanner;

  /// No description provided for @inspStatPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get inspStatPending;

  /// No description provided for @inspStatInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get inspStatInProgress;

  /// No description provided for @inspStatAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendidas'**
  String get inspStatAttended;

  /// No description provided for @inspStatClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get inspStatClosed;

  /// No description provided for @inspStatCaption.
  ///
  /// In es, this message translates to:
  /// **'monitoreos'**
  String get inspStatCaption;

  /// No description provided for @inspStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get inspStatusPending;

  /// No description provided for @inspStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get inspStatusInProgress;

  /// No description provided for @inspStatusAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendida'**
  String get inspStatusAttended;

  /// No description provided for @inspStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get inspStatusClosed;

  /// No description provided for @inspStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get inspStatusCancelled;

  /// No description provided for @inspFilterState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get inspFilterState;

  /// No description provided for @inspFilterAllStates.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get inspFilterAllStates;

  /// No description provided for @inspEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes monitoreos asignados.'**
  String get inspEmptyAll;

  /// No description provided for @inspEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ningún monitoreo coincide con los filtros.'**
  String get inspEmpty;

  /// No description provided for @inspUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo no disponible'**
  String get inspUnavailableTitle;

  /// No description provided for @inspUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'Esta concesión todavía no publica su monitoreo en la app.'**
  String get inspUnavailableBody;

  /// No description provided for @inspNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso al monitoreo'**
  String get inspNoPermissionTitle;

  /// No description provided for @inspNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede consultar el monitoreo.'**
  String get inspNoPermissionBody;

  /// No description provided for @inspNotFound.
  ///
  /// In es, this message translates to:
  /// **'El monitoreo ya no existe.'**
  String get inspNotFound;

  /// No description provided for @inspErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el monitoreo'**
  String get inspErrorTitle;

  /// No description provided for @inspErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get inspErrorBody;

  /// No description provided for @inspRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get inspRetry;

  /// No description provided for @inspDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get inspDetailTitle;

  /// No description provided for @inspChecklistTitle.
  ///
  /// In es, this message translates to:
  /// **'Checklist'**
  String get inspChecklistTitle;

  /// No description provided for @inspChecklistProgress.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} puntos'**
  String inspChecklistProgress(int done, int total);

  /// No description provided for @inspResultOk.
  ///
  /// In es, this message translates to:
  /// **'Cumple'**
  String get inspResultOk;

  /// No description provided for @inspResultFinding.
  ///
  /// In es, this message translates to:
  /// **'Hallazgo'**
  String get inspResultFinding;

  /// No description provided for @inspCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítico'**
  String get inspCritical;

  /// No description provided for @inspFindings.
  ///
  /// In es, this message translates to:
  /// **'{count} hallazgos'**
  String inspFindings(int count);

  /// No description provided for @inspCriticalFindings.
  ///
  /// In es, this message translates to:
  /// **'{count} críticos'**
  String inspCriticalFindings(int count);

  /// No description provided for @inspScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programada'**
  String get inspScheduled;

  /// No description provided for @inspCompletedOn.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get inspCompletedOn;

  /// No description provided for @inspAssignee.
  ///
  /// In es, this message translates to:
  /// **'Responsable'**
  String get inspAssignee;

  /// No description provided for @inspType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get inspType;

  /// No description provided for @inspAsset.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get inspAsset;

  /// No description provided for @inspKm.
  ///
  /// In es, this message translates to:
  /// **'Kilómetro'**
  String get inspKm;

  /// No description provided for @inspSegment.
  ///
  /// In es, this message translates to:
  /// **'Tramo'**
  String get inspSegment;

  /// No description provided for @inspDirection.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get inspDirection;

  /// No description provided for @inspComplete.
  ///
  /// In es, this message translates to:
  /// **'Finalizar monitoreo'**
  String get inspComplete;

  /// No description provided for @inspCompleteHint.
  ///
  /// In es, this message translates to:
  /// **'Responde todos los puntos para poder finalizar.'**
  String get inspCompleteHint;

  /// No description provided for @inspCompleted.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo finalizado.'**
  String get inspCompleted;

  /// No description provided for @inspCompletedCritical.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo finalizado. Hay hallazgos críticos: deben generar un registro o una alerta.'**
  String get inspCompletedCritical;

  /// No description provided for @inspNotEditable.
  ///
  /// In es, this message translates to:
  /// **'Este monitoreo ya no se puede modificar.'**
  String get inspNotEditable;

  /// No description provided for @inspIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Faltan puntos del checklist por responder.'**
  String get inspIncomplete;

  /// No description provided for @inspSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Inténtalo de nuevo.'**
  String get inspSaveError;

  /// No description provided for @inspViewAsset.
  ///
  /// In es, this message translates to:
  /// **'Ver activo'**
  String get inspViewAsset;

  /// No description provided for @inspNoAsset.
  ///
  /// In es, this message translates to:
  /// **'Este monitoreo no tiene un activo del catálogo.'**
  String get inspNoAsset;

  /// No description provided for @inspNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo monitoreo'**
  String get inspNew;

  /// No description provided for @inspNewCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear monitoreo'**
  String get inspNewCreate;

  /// No description provided for @inspNewType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de monitoreo'**
  String get inspNewType;

  /// No description provided for @inspNewName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get inspNewName;

  /// No description provided for @inspNewNameHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional: si lo dejas vacío se usa el tipo'**
  String get inspNewNameHint;

  /// No description provided for @inspNewErrorType.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo de monitoreo.'**
  String get inspNewErrorType;

  /// No description provided for @inspNewCreated.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo creado.'**
  String get inspNewCreated;

  /// No description provided for @inspNewNoTemplates.
  ///
  /// In es, this message translates to:
  /// **'No hay tipos de monitoreo disponibles.'**
  String get inspNewNoTemplates;

  /// No description provided for @inspEvidenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Hallazgos y evidencias'**
  String get inspEvidenceTitle;

  /// No description provided for @inspEvidenceAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar hallazgo'**
  String get inspEvidenceAdd;

  /// No description provided for @inspEvidenceEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay hallazgos capturados.'**
  String get inspEvidenceEmpty;

  /// No description provided for @inspEvidenceNote.
  ///
  /// In es, this message translates to:
  /// **'Descripción del hallazgo'**
  String get inspEvidenceNote;

  /// No description provided for @inspEvidenceItem.
  ///
  /// In es, this message translates to:
  /// **'Punto del checklist'**
  String get inspEvidenceItem;

  /// No description provided for @inspEvidenceNoItem.
  ///
  /// In es, this message translates to:
  /// **'Sin punto del checklist'**
  String get inspEvidenceNoItem;

  /// No description provided for @inspEvidenceSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar hallazgo'**
  String get inspEvidenceSave;

  /// No description provided for @inspEvidenceErrorEmpty.
  ///
  /// In es, this message translates to:
  /// **'Escribe una descripción o toma una foto.'**
  String get inspEvidenceErrorEmpty;

  /// No description provided for @inspEvidenceSaved.
  ///
  /// In es, this message translates to:
  /// **'Hallazgo guardado.'**
  String get inspEvidenceSaved;

  /// No description provided for @inspEvidencePhotos.
  ///
  /// In es, this message translates to:
  /// **'{count} fotos'**
  String inspEvidencePhotos(int count);

  /// No description provided for @inspEvidencePosition.
  ///
  /// In es, this message translates to:
  /// **'Posición {lat}, {lon} (±{accuracy} m)'**
  String inspEvidencePosition(String lat, String lon, String accuracy);

  /// No description provided for @inspEvidenceNoPosition.
  ///
  /// In es, this message translates to:
  /// **'Sin posición (GPS no disponible)'**
  String get inspEvidenceNoPosition;

  /// No description provided for @inspDraftSaved.
  ///
  /// In es, this message translates to:
  /// **'Borrador guardado: tus respuestas se guardan solas.'**
  String get inspDraftSaved;

  /// No description provided for @moduleInspections.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get moduleInspections;

  /// No description provided for @moduleInspectionsSub.
  ///
  /// In es, this message translates to:
  /// **'Checklists en campo'**
  String get moduleInspectionsSub;

  /// No description provided for @moduleWorks.
  ///
  /// In es, this message translates to:
  /// **'Obras'**
  String get moduleWorks;

  /// No description provided for @moduleWorksSub.
  ///
  /// In es, this message translates to:
  /// **'Avance y programas'**
  String get moduleWorksSub;

  /// No description provided for @cfgGateTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin configuración de la concesión'**
  String get cfgGateTitle;

  /// No description provided for @cfgGateBody.
  ///
  /// In es, this message translates to:
  /// **'Para registrar necesitas la configuración de la concesión y su zona horaria. Conéctate a internet y sincroniza.'**
  String get cfgGateBody;

  /// No description provided for @cfgGateRetry.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get cfgGateRetry;

  /// No description provided for @cfgGateInspection.
  ///
  /// In es, this message translates to:
  /// **'Sin la configuración de la concesión no puedes responder el monitoreo. Conéctate y sincroniza.'**
  String get cfgGateInspection;

  /// No description provided for @mapFilterOperating.
  ///
  /// In es, this message translates to:
  /// **'Estado del equipo'**
  String get mapFilterOperating;

  /// No description provided for @mapOpInOperation.
  ///
  /// In es, this message translates to:
  /// **'En operación'**
  String get mapOpInOperation;

  /// No description provided for @mapOpInMaintenance.
  ///
  /// In es, this message translates to:
  /// **'En mantenimiento'**
  String get mapOpInMaintenance;

  /// No description provided for @mapOpOutOfService.
  ///
  /// In es, this message translates to:
  /// **'Fuera de servicio'**
  String get mapOpOutOfService;

  /// No description provided for @ticketLocationTitle.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get ticketLocationTitle;

  /// No description provided for @ticketLocationAccuracy.
  ///
  /// In es, this message translates to:
  /// **'Precisión ±{meters} m'**
  String ticketLocationAccuracy(String meters);

  /// No description provided for @ticketLocOriginGps.
  ///
  /// In es, this message translates to:
  /// **'Lectura del GPS'**
  String get ticketLocOriginGps;

  /// No description provided for @ticketLocOriginLastKnown.
  ///
  /// In es, this message translates to:
  /// **'Última posición conocida'**
  String get ticketLocOriginLastKnown;

  /// No description provided for @ticketLocOriginMapPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto elegido en el mapa'**
  String get ticketLocOriginMapPoint;

  /// No description provided for @ticketLocOriginAsset.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del activo'**
  String get ticketLocOriginAsset;

  /// No description provided for @ticketLocationAgo.
  ///
  /// In es, this message translates to:
  /// **'de hace {minutes} min'**
  String ticketLocationAgo(int minutes);

  /// No description provided for @ticketLocationAsset.
  ///
  /// In es, this message translates to:
  /// **'Activo {id}'**
  String ticketLocationAsset(String id);

  /// No description provided for @ticketLocationIssueTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa la ubicación'**
  String get ticketLocationIssueTitle;

  /// No description provided for @ticketLocationLowAccuracy.
  ///
  /// In es, this message translates to:
  /// **'La precisión es de ±{meters} m y el mínimo es de {min} m. ¿Guardar de todos modos?'**
  String ticketLocationLowAccuracy(String meters, String min);

  /// No description provided for @ticketLocationLastKnownWarn.
  ///
  /// In es, this message translates to:
  /// **'Es la última posición conocida, no una lectura actual. ¿Guardar de todos modos?'**
  String get ticketLocationLastKnownWarn;

  /// No description provided for @ticketLocationSaveAnyway.
  ///
  /// In es, this message translates to:
  /// **'Guardar de todos modos'**
  String get ticketLocationSaveAnyway;

  /// No description provided for @ticketLocationCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get ticketLocationCancel;

  /// No description provided for @mapRecordHere.
  ///
  /// In es, this message translates to:
  /// **'Registrar aquí'**
  String get mapRecordHere;

  /// No description provided for @mapOpenRecord.
  ///
  /// In es, this message translates to:
  /// **'Abrir ficha'**
  String get mapOpenRecord;

  /// No description provided for @mapCreateRecord.
  ///
  /// In es, this message translates to:
  /// **'Crear registro'**
  String get mapCreateRecord;

  /// No description provided for @mapNavigate.
  ///
  /// In es, this message translates to:
  /// **'Navegar'**
  String get mapNavigate;

  /// No description provided for @mapPickedTitle.
  ///
  /// In es, this message translates to:
  /// **'Punto elegido'**
  String get mapPickedTitle;

  /// No description provided for @mapPickedClose.
  ///
  /// In es, this message translates to:
  /// **'Quitar punto'**
  String get mapPickedClose;

  /// No description provided for @mapPickHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado el mapa para elegir un punto.'**
  String get mapPickHint;

  /// No description provided for @mapNavigateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la navegación del teléfono.'**
  String get mapNavigateFailed;

  /// No description provided for @mapRecordMocked.
  ///
  /// In es, this message translates to:
  /// **'La ubicación es simulada: no se puede usar para registrar.'**
  String get mapRecordMocked;

  /// No description provided for @sessionLockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Sesión bloqueada'**
  String get sessionLockedTitle;

  /// No description provided for @sessionLockedBody.
  ///
  /// In es, this message translates to:
  /// **'Pasaron {minutes} minutos sin actividad. Confirma tu identidad para continuar.'**
  String sessionLockedBody(int minutes);

  /// No description provided for @sessionUnlock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get sessionUnlock;

  /// No description provided for @sessionUnlockReason.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para desbloquear SIGACO'**
  String get sessionUnlockReason;

  /// No description provided for @sessionUnlockUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este teléfono no tiene un bloqueo de pantalla para confirmar tu identidad. Cierra la sesión y vuelve a entrar.'**
  String get sessionUnlockUnavailable;

  /// No description provided for @mfaRecoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus códigos de recuperación'**
  String get mfaRecoveryTitle;

  /// No description provided for @mfaRecoveryBody.
  ///
  /// In es, this message translates to:
  /// **'Si pierdes tu teléfono o la app autenticadora, cada uno de estos códigos te deja entrar una sola vez. Guárdalos en un lugar seguro: no se volverán a mostrar.'**
  String get mfaRecoveryBody;

  /// No description provided for @mfaRecoveryCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar todos'**
  String get mfaRecoveryCopy;

  /// No description provided for @mfaRecoveryCopied.
  ///
  /// In es, this message translates to:
  /// **'Códigos copiados'**
  String get mfaRecoveryCopied;

  /// No description provided for @mfaRecoverySaved.
  ///
  /// In es, this message translates to:
  /// **'Ya los guardé'**
  String get mfaRecoverySaved;

  /// No description provided for @mfaUseRecoveryCode.
  ///
  /// In es, this message translates to:
  /// **'Usar un código de recuperación'**
  String get mfaUseRecoveryCode;

  /// No description provided for @mfaUseAppCode.
  ///
  /// In es, this message translates to:
  /// **'Usar el código de la app'**
  String get mfaUseAppCode;

  /// No description provided for @mfaRecoveryCodeHint.
  ///
  /// In es, this message translates to:
  /// **'Código de recuperación'**
  String get mfaRecoveryCodeHint;

  /// No description provided for @mfaRecoveryRemaining.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {count} códigos de recuperación sin usar'**
  String mfaRecoveryRemaining(int count);

  /// No description provided for @mfaRecoveryGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar códigos nuevos'**
  String get mfaRecoveryGenerate;

  /// No description provided for @mfaRecoveryGenerateBody.
  ///
  /// In es, this message translates to:
  /// **'Los códigos anteriores dejarán de servir. Escribe el código de tu app autenticadora para confirmar.'**
  String get mfaRecoveryGenerateBody;

  /// No description provided for @alertsTitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get alertsTitle;

  /// No description provided for @alertsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tu concesión'**
  String get alertsSubtitle;

  /// No description provided for @alertsMarkAll.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get alertsMarkAll;

  /// No description provided for @alertsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get alertsFilterAll;

  /// No description provided for @alertsFilterUnread.
  ///
  /// In es, this message translates to:
  /// **'Sin leer'**
  String get alertsFilterUnread;

  /// No description provided for @alertsEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'No tienes alertas.'**
  String get alertsEmptyAll;

  /// No description provided for @alertsEmptyUnread.
  ///
  /// In es, this message translates to:
  /// **'No tienes alertas sin leer.'**
  String get alertsEmptyUnread;

  /// No description provided for @alertsUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas aún no disponibles'**
  String get alertsUnavailableTitle;

  /// No description provided for @alertsUnavailableBody.
  ///
  /// In es, this message translates to:
  /// **'El servidor todavía no publica tus alertas. Cuando estén listas aparecerán aquí.'**
  String get alertsUnavailableBody;

  /// No description provided for @alertsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las alertas'**
  String get alertsErrorTitle;

  /// No description provided for @alertsErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get alertsErrorBody;

  /// No description provided for @alertsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get alertsRetry;

  /// No description provided for @alertsNoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para ver alertas'**
  String get alertsNoPermissionTitle;

  /// No description provided for @alertsNoPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no incluye las alertas de esta concesión.'**
  String get alertsNoPermissionBody;

  /// No description provided for @alertsSampleBanner.
  ///
  /// In es, this message translates to:
  /// **'Alertas de ejemplo: aún no vienen del servidor.'**
  String get alertsSampleBanner;

  /// No description provided for @alertsSeverityInfo.
  ///
  /// In es, this message translates to:
  /// **'Informativa'**
  String get alertsSeverityInfo;

  /// No description provided for @alertsSeverityWarning.
  ///
  /// In es, this message translates to:
  /// **'Atención'**
  String get alertsSeverityWarning;

  /// No description provided for @alertsSeverityCritical.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get alertsSeverityCritical;

  /// No description provided for @alertsSeeDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get alertsSeeDetail;

  /// No description provided for @alertsUnreadSemantic.
  ///
  /// In es, this message translates to:
  /// **'{count} alertas sin leer'**
  String alertsUnreadSemantic(int count);

  /// No description provided for @maintIndConservacion.
  ///
  /// In es, this message translates to:
  /// **'Conservación'**
  String get maintIndConservacion;

  /// No description provided for @maintIndSgsei.
  ///
  /// In es, this message translates to:
  /// **'Sistemas eléctricos e iluminación'**
  String get maintIndSgsei;

  /// No description provided for @maintIndSgost.
  ///
  /// In es, this message translates to:
  /// **'Túneles'**
  String get maintIndSgost;

  /// No description provided for @accidentTypeRunOver.
  ///
  /// In es, this message translates to:
  /// **'Atropello'**
  String get accidentTypeRunOver;

  /// No description provided for @accidentTypeOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get accidentTypeOther;

  /// No description provided for @accidentSeverityUnharmed.
  ///
  /// In es, this message translates to:
  /// **'Ileso'**
  String get accidentSeverityUnharmed;

  /// No description provided for @accidentSeverityMinor.
  ///
  /// In es, this message translates to:
  /// **'Lesiones menores'**
  String get accidentSeverityMinor;

  /// No description provided for @accidentSeverityFatal.
  ///
  /// In es, this message translates to:
  /// **'Deceso'**
  String get accidentSeverityFatal;

  /// No description provided for @accidentZoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Zona'**
  String get accidentZoneTitle;

  /// No description provided for @accidentZoneRural.
  ///
  /// In es, this message translates to:
  /// **'Rural'**
  String get accidentZoneRural;

  /// No description provided for @accidentZoneSuburban.
  ///
  /// In es, this message translates to:
  /// **'Suburbana'**
  String get accidentZoneSuburban;

  /// No description provided for @accidentZoneUrban.
  ///
  /// In es, this message translates to:
  /// **'Urbana'**
  String get accidentZoneUrban;

  /// No description provided for @accidentWeatherTitle.
  ///
  /// In es, this message translates to:
  /// **'Clima'**
  String get accidentWeatherTitle;

  /// No description provided for @accidentWeatherWind.
  ///
  /// In es, this message translates to:
  /// **'Viento'**
  String get accidentWeatherWind;

  /// No description provided for @accidentWeatherRain.
  ///
  /// In es, this message translates to:
  /// **'Lluvia'**
  String get accidentWeatherRain;

  /// No description provided for @accidentWeatherFog.
  ///
  /// In es, this message translates to:
  /// **'Niebla'**
  String get accidentWeatherFog;

  /// No description provided for @accidentWeatherNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get accidentWeatherNormal;

  /// No description provided for @accidentPavementConditionTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado del pavimento'**
  String get accidentPavementConditionTitle;

  /// No description provided for @accidentSignageConditionTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado del señalamiento'**
  String get accidentSignageConditionTitle;

  /// No description provided for @accidentConditionGood.
  ///
  /// In es, this message translates to:
  /// **'Buena'**
  String get accidentConditionGood;

  /// No description provided for @accidentConditionFair.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get accidentConditionFair;

  /// No description provided for @accidentConditionPoor.
  ///
  /// In es, this message translates to:
  /// **'Mala'**
  String get accidentConditionPoor;

  /// No description provided for @accidentLayoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Trazado'**
  String get accidentLayoutTitle;

  /// No description provided for @accidentLayoutStraight.
  ///
  /// In es, this message translates to:
  /// **'Recta'**
  String get accidentLayoutStraight;

  /// No description provided for @accidentLayoutVerticalCurve.
  ///
  /// In es, this message translates to:
  /// **'Curva vertical'**
  String get accidentLayoutVerticalCurve;

  /// No description provided for @accidentLayoutHorizontalCurve.
  ///
  /// In es, this message translates to:
  /// **'Curva horizontal'**
  String get accidentLayoutHorizontalCurve;

  /// No description provided for @accidentPavementTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de pavimento'**
  String get accidentPavementTypeTitle;

  /// No description provided for @accidentPavementRigid.
  ///
  /// In es, this message translates to:
  /// **'Rígido'**
  String get accidentPavementRigid;

  /// No description provided for @accidentPavementFlexible.
  ///
  /// In es, this message translates to:
  /// **'Flexible'**
  String get accidentPavementFlexible;

  /// No description provided for @accidentCauseTitle.
  ///
  /// In es, this message translates to:
  /// **'Causa'**
  String get accidentCauseTitle;

  /// No description provided for @accidentCauseSpeeding.
  ///
  /// In es, this message translates to:
  /// **'Exceso de velocidad'**
  String get accidentCauseSpeeding;

  /// No description provided for @accidentCauseLaneInvasion.
  ///
  /// In es, this message translates to:
  /// **'Invasión de carril'**
  String get accidentCauseLaneInvasion;

  /// No description provided for @accidentCauseOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get accidentCauseOther;

  /// No description provided for @accidentPlaceTitle.
  ///
  /// In es, this message translates to:
  /// **'Lugar del accidente'**
  String get accidentPlaceTitle;

  /// No description provided for @accidentPlacePavement.
  ///
  /// In es, this message translates to:
  /// **'Pavimento'**
  String get accidentPlacePavement;

  /// No description provided for @accidentPlaceSignage.
  ///
  /// In es, this message translates to:
  /// **'Señalamiento'**
  String get accidentPlaceSignage;

  /// No description provided for @accidentPlaceTollBooth.
  ///
  /// In es, this message translates to:
  /// **'Casetas'**
  String get accidentPlaceTollBooth;

  /// No description provided for @accidentPlaceOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get accidentPlaceOther;

  /// No description provided for @accidentVehiclesTitle.
  ///
  /// In es, this message translates to:
  /// **'Vehículos involucrados'**
  String get accidentVehiclesTitle;

  /// No description provided for @accidentVehiclesCount.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de vehículos'**
  String get accidentVehiclesCount;

  /// No description provided for @accidentVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo {n}'**
  String accidentVehicleTitle(int n);

  /// No description provided for @accidentVehicleTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get accidentVehicleTypeTitle;

  /// No description provided for @accidentVehicleCar.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get accidentVehicleCar;

  /// No description provided for @accidentVehicleMotorcycle.
  ///
  /// In es, this message translates to:
  /// **'Motocicleta'**
  String get accidentVehicleMotorcycle;

  /// No description provided for @accidentVehicleLivestock.
  ///
  /// In es, this message translates to:
  /// **'Semoviente'**
  String get accidentVehicleLivestock;

  /// No description provided for @accidentVehicleFixedObject.
  ///
  /// In es, this message translates to:
  /// **'Objeto fijo'**
  String get accidentVehicleFixedObject;

  /// No description provided for @accidentVictimsTitle.
  ///
  /// In es, this message translates to:
  /// **'Víctimas'**
  String get accidentVictimsTitle;

  /// No description provided for @accidentVictimsCount.
  ///
  /// In es, this message translates to:
  /// **'Cantidad de víctimas'**
  String get accidentVictimsCount;

  /// No description provided for @accidentVictimTitle.
  ///
  /// In es, this message translates to:
  /// **'Víctima {n}'**
  String accidentVictimTitle(int n);

  /// No description provided for @accidentSexTitle.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get accidentSexTitle;

  /// No description provided for @accidentSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get accidentSexFemale;

  /// No description provided for @accidentSexMale.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get accidentSexMale;

  /// No description provided for @accidentSexUnspecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get accidentSexUnspecified;

  /// No description provided for @accidentSeverityDerived.
  ///
  /// In es, this message translates to:
  /// **'La gravedad del accidente es la de la víctima más grave.'**
  String get accidentSeverityDerived;

  /// No description provided for @newAccidentErrorVehicle.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo de vehículo.'**
  String get newAccidentErrorVehicle;

  /// No description provided for @newAccidentErrorVictim.
  ///
  /// In es, this message translates to:
  /// **'Elige la gravedad de la víctima.'**
  String get newAccidentErrorVictim;

  /// No description provided for @accidentConditionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Condiciones del lugar'**
  String get accidentConditionsTitle;

  /// No description provided for @accidentSeveritySerious.
  ///
  /// In es, this message translates to:
  /// **'Heridas graves'**
  String get accidentSeveritySerious;

  /// No description provided for @dashCompliance.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento'**
  String get dashCompliance;

  /// No description provided for @dashComplianceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El cumplimiento por indicador aún no está disponible.'**
  String get dashComplianceUnavailable;

  /// No description provided for @dashComplianceMet.
  ///
  /// In es, this message translates to:
  /// **'Indicadores cumplidos: {met} de {total}'**
  String dashComplianceMet(int met, int total);

  /// No description provided for @dashStatusInProcess.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get dashStatusInProcess;

  /// No description provided for @dashStatusGood.
  ///
  /// In es, this message translates to:
  /// **'Buen estado'**
  String get dashStatusGood;

  /// No description provided for @dashStatusIntermediate.
  ///
  /// In es, this message translates to:
  /// **'Estado intermedio'**
  String get dashStatusIntermediate;

  /// No description provided for @dashStatusBad.
  ///
  /// In es, this message translates to:
  /// **'Mal estado'**
  String get dashStatusBad;

  /// No description provided for @dashTicketsBySubsystem.
  ///
  /// In es, this message translates to:
  /// **'Indicadores con más tickets'**
  String get dashTicketsBySubsystem;

  /// No description provided for @dashTopCreators.
  ///
  /// In es, this message translates to:
  /// **'Usuarios que más tickets han generado'**
  String get dashTopCreators;

  /// No description provided for @maintProgressStatus.
  ///
  /// In es, this message translates to:
  /// **'Llevas {executed} de {total} {unit} ({percent} %). Faltan {remaining}.'**
  String maintProgressStatus(
    String executed,
    String total,
    String unit,
    String percent,
    String remaining,
  );

  /// No description provided for @maintProgressResult.
  ///
  /// In es, this message translates to:
  /// **'Quedará en {percent} %.'**
  String maintProgressResult(String percent);

  /// No description provided for @maintProgressVolumeRules.
  ///
  /// In es, this message translates to:
  /// **'Se suma a lo ya ejecutado. Con volumen, el avance se calcula solo.'**
  String get maintProgressVolumeRules;

  /// No description provided for @maintProgressErrorMissing.
  ///
  /// In es, this message translates to:
  /// **'Escribe el volumen ejecutado o el avance acumulado.'**
  String get maintProgressErrorMissing;

  /// No description provided for @maintProgressErrorVolumeOver.
  ///
  /// In es, this message translates to:
  /// **'Supera lo que falta: quedan {remaining}.'**
  String maintProgressErrorVolumeOver(String remaining);

  /// No description provided for @maintProgressErrorPercentBelow.
  ///
  /// In es, this message translates to:
  /// **'El avance no puede bajar: ya va en {percent} %.'**
  String maintProgressErrorPercentBelow(String percent);

  /// No description provided for @maintProgressPhotosFailed.
  ///
  /// In es, this message translates to:
  /// **'El avance se guardó, pero no todas las fotos. Vuelve a intentarlo desde la web.'**
  String get maintProgressPhotosFailed;

  /// No description provided for @maintIndicatorsNone.
  ///
  /// In es, this message translates to:
  /// **'No tienes indicadores asignados en esta concesión. Pide a tu administrador que te los asigne.'**
  String get maintIndicatorsNone;

  /// No description provided for @maintIndicatorsFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus indicadores.'**
  String get maintIndicatorsFailed;

  /// No description provided for @newTicketIndicator.
  ///
  /// In es, this message translates to:
  /// **'Indicador'**
  String get newTicketIndicator;

  /// No description provided for @newTicketGroup.
  ///
  /// In es, this message translates to:
  /// **'Subclasificación'**
  String get newTicketGroup;

  /// No description provided for @newTicketFailure.
  ///
  /// In es, this message translates to:
  /// **'Falla'**
  String get newTicketFailure;

  /// No description provided for @newTicketAttention.
  ///
  /// In es, this message translates to:
  /// **'Plazo de atención'**
  String get newTicketAttention;

  /// No description provided for @newTicketAttentionPending.
  ///
  /// In es, this message translates to:
  /// **'Sale de la falla elegida'**
  String get newTicketAttentionPending;

  /// No description provided for @newTicketAttentionValue.
  ///
  /// In es, this message translates to:
  /// **'{value} · fijo, corre 24×7'**
  String newTicketAttentionValue(String value);

  /// No description provided for @newTicketAttentionImmediate.
  ///
  /// In es, this message translates to:
  /// **'Inmediato'**
  String get newTicketAttentionImmediate;

  /// No description provided for @newTicketAttentionDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String newTicketAttentionDays(int days);

  /// No description provided for @newTicketAttentionHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} horas'**
  String newTicketAttentionHours(int hours);

  /// No description provided for @newTicketErrorFailure.
  ///
  /// In es, this message translates to:
  /// **'Elige el indicador, la subclasificación y la falla.'**
  String get newTicketErrorFailure;

  /// No description provided for @ticketPlacementSegment.
  ///
  /// In es, this message translates to:
  /// **'tramo {code}'**
  String ticketPlacementSegment(String code);

  /// No description provided for @ticketPlacementDistance.
  ///
  /// In es, this message translates to:
  /// **'a {meters} m de la carretera'**
  String ticketPlacementDistance(int meters);

  /// No description provided for @ticketPlacementOffRoad.
  ///
  /// In es, this message translates to:
  /// **'El punto está a más de {meters} m de la carretera: márquelo sobre la carretera de la concesión.'**
  String ticketPlacementOffRoad(int meters);

  /// No description provided for @newTicketKmEnd.
  ///
  /// In es, this message translates to:
  /// **'Km final'**
  String get newTicketKmEnd;

  /// No description provided for @newTicketKmEndHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional, si la falla ocupa un tramo'**
  String get newTicketKmEndHint;

  /// No description provided for @newTicketDirection.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get newTicketDirection;

  /// No description provided for @newTicketErrorKmEnd.
  ///
  /// In es, this message translates to:
  /// **'Va con el km inicial y no puede ser menor que él.'**
  String get newTicketErrorKmEnd;

  /// No description provided for @newTicketErrorDirection.
  ///
  /// In es, this message translates to:
  /// **'Aquí los dos sentidos comparten trazo: elija el sentido.'**
  String get newTicketErrorDirection;

  /// No description provided for @newTicketErrorDescription.
  ///
  /// In es, this message translates to:
  /// **'Describa la falla.'**
  String get newTicketErrorDescription;

  /// No description provided for @invLifecyclePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get invLifecyclePending;

  /// No description provided for @invLifecycleActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get invLifecycleActive;

  /// No description provided for @invLifecycleOutOfService.
  ///
  /// In es, this message translates to:
  /// **'Fuera de servicio'**
  String get invLifecycleOutOfService;

  /// No description provided for @invLifecycleInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get invLifecycleInactive;

  /// No description provided for @invLifecycleDecommissioned.
  ///
  /// In es, this message translates to:
  /// **'Dado de baja'**
  String get invLifecycleDecommissioned;

  /// No description provided for @invLifecycleDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get invLifecycleDiscarded;

  /// No description provided for @invInMaintenance.
  ///
  /// In es, this message translates to:
  /// **'En mantenimiento'**
  String get invInMaintenance;

  /// No description provided for @invNotSynced.
  ///
  /// In es, this message translates to:
  /// **'Sin enviar'**
  String get invNotSynced;

  /// No description provided for @invPendingSyncBody.
  ///
  /// In es, this message translates to:
  /// **'Se capturó sin conexión: se enviará al servidor cuando vuelva la señal.'**
  String get invPendingSyncBody;

  /// No description provided for @invStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get invStatusLabel;

  /// No description provided for @invConditionLabel.
  ///
  /// In es, this message translates to:
  /// **'Conservación'**
  String get invConditionLabel;

  /// No description provided for @invRoad.
  ///
  /// In es, this message translates to:
  /// **'Carretera'**
  String get invRoad;

  /// No description provided for @invOpenTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets abiertos'**
  String get invOpenTickets;

  /// No description provided for @invStatusReasonLayerRemoved.
  ///
  /// In es, this message translates to:
  /// **'Su capa del WebGIS dejó de alimentar este tipo.'**
  String get invStatusReasonLayerRemoved;

  /// No description provided for @invStatusReasonGone.
  ///
  /// In es, this message translates to:
  /// **'Su elemento desapareció del WebGIS.'**
  String get invStatusReasonGone;

  /// No description provided for @invTemplateTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de la ficha'**
  String get invTemplateTitle;

  /// No description provided for @invTemplateVersion.
  ///
  /// In es, this message translates to:
  /// **'Ficha v{number}'**
  String invTemplateVersion(int number);

  /// No description provided for @invWebGisTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del WebGIS'**
  String get invWebGisTitle;

  /// No description provided for @invWebGisSource.
  ///
  /// In es, this message translates to:
  /// **'Capa {layer} · elemento {id}'**
  String invWebGisSource(String layer, String id);

  /// No description provided for @invManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión'**
  String get invManagementTitle;

  /// No description provided for @invDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get invDescription;

  /// No description provided for @invBrand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get invBrand;

  /// No description provided for @invModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get invModel;

  /// No description provided for @invSerial.
  ///
  /// In es, this message translates to:
  /// **'Número de serie'**
  String get invSerial;

  /// No description provided for @invUsefulLife.
  ///
  /// In es, this message translates to:
  /// **'Vida útil'**
  String get invUsefulLife;

  /// No description provided for @invUsefulLifeMonths.
  ///
  /// In es, this message translates to:
  /// **'{months} meses'**
  String invUsefulLifeMonths(int months);

  /// No description provided for @invSource.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get invSource;

  /// No description provided for @invSourceMobile.
  ///
  /// In es, this message translates to:
  /// **'App'**
  String get invSourceMobile;

  /// No description provided for @invSourceWeb.
  ///
  /// In es, this message translates to:
  /// **'Web'**
  String get invSourceWeb;

  /// No description provided for @invSourceBulk.
  ///
  /// In es, this message translates to:
  /// **'Carga masiva'**
  String get invSourceBulk;

  /// No description provided for @invSourceWebGis.
  ///
  /// In es, this message translates to:
  /// **'WebGIS'**
  String get invSourceWebGis;

  /// No description provided for @invPhotosTitle.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get invPhotosTitle;

  /// No description provided for @invYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get invYes;

  /// No description provided for @invNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get invNo;

  /// No description provided for @invNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo activo'**
  String get invNew;

  /// No description provided for @invScanTooltip.
  ///
  /// In es, this message translates to:
  /// **'Leer QR'**
  String get invScanTooltip;

  /// No description provided for @invNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Alta de activo'**
  String get invNewTitle;

  /// No description provided for @invNewSave.
  ///
  /// In es, this message translates to:
  /// **'Dar de alta'**
  String get invNewSave;

  /// No description provided for @invNewType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de activo'**
  String get invNewType;

  /// No description provided for @invNewTypeError.
  ///
  /// In es, this message translates to:
  /// **'Elija el tipo de activo.'**
  String get invNewTypeError;

  /// No description provided for @invNewTypesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay tipos de activo que se puedan dar de alta desde la app.'**
  String get invNewTypesEmpty;

  /// No description provided for @invNewTypesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron traer los tipos de activo. Revise su conexión.'**
  String get invNewTypesError;

  /// No description provided for @invNewTemplateLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando la ficha del tipo…'**
  String get invNewTemplateLoading;

  /// No description provided for @invNewTemplateMissing.
  ///
  /// In es, this message translates to:
  /// **'Este tipo no tiene una ficha vigente: todavía no se puede dar de alta.'**
  String get invNewTemplateMissing;

  /// No description provided for @invNewTemplateError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo traer la ficha del tipo.'**
  String get invNewTemplateError;

  /// No description provided for @invNewNoFields.
  ///
  /// In es, this message translates to:
  /// **'La ficha de este tipo no tiene campos propios.'**
  String get invNewNoFields;

  /// No description provided for @invNewGpsReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo el GPS…'**
  String get invNewGpsReading;

  /// No description provided for @invNewGpsUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el GPS: escriba el km.'**
  String get invNewGpsUnavailable;

  /// No description provided for @invNewGpsRetry.
  ///
  /// In es, this message translates to:
  /// **'Volver a leer el GPS'**
  String get invNewGpsRetry;

  /// No description provided for @invNewGpsOrigin.
  ///
  /// In es, this message translates to:
  /// **'GPS del teléfono'**
  String get invNewGpsOrigin;

  /// No description provided for @invNewOffRoad.
  ///
  /// In es, this message translates to:
  /// **'El punto queda lejos de la carretera: escriba el km.'**
  String get invNewOffRoad;

  /// No description provided for @invNewPlacementUnknown.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular el km del punto: escríbalo si lo conoce.'**
  String get invNewPlacementUnknown;

  /// No description provided for @invNewPointOnlyKm.
  ///
  /// In es, this message translates to:
  /// **'Este tipo se dibuja como línea o polígono: se ubica por km.'**
  String get invNewPointOnlyKm;

  /// No description provided for @invNewKm.
  ///
  /// In es, this message translates to:
  /// **'Km'**
  String get invNewKm;

  /// No description provided for @invNewKmEnd.
  ///
  /// In es, this message translates to:
  /// **'Km final'**
  String get invNewKmEnd;

  /// No description provided for @invNewKmEndHint.
  ///
  /// In es, this message translates to:
  /// **'Solo si ocupa un tramo'**
  String get invNewKmEndHint;

  /// No description provided for @invNewKmError.
  ///
  /// In es, this message translates to:
  /// **'Escriba el km como 150+200.'**
  String get invNewKmError;

  /// No description provided for @invNewKmEndError.
  ///
  /// In es, this message translates to:
  /// **'Va con el km inicial y no puede ser menor que él.'**
  String get invNewKmEndError;

  /// No description provided for @invNewKmEndRequired.
  ///
  /// In es, this message translates to:
  /// **'Este tipo se ubica por rango: indique el km final.'**
  String get invNewKmEndRequired;

  /// No description provided for @invNewLocationError.
  ///
  /// In es, this message translates to:
  /// **'Indique el km o lea el GPS.'**
  String get invNewLocationError;

  /// No description provided for @invNewDirection.
  ///
  /// In es, this message translates to:
  /// **'Sentido'**
  String get invNewDirection;

  /// No description provided for @invNewDirectionError.
  ///
  /// In es, this message translates to:
  /// **'Aquí los dos sentidos comparten trazo: elija el sentido.'**
  String get invNewDirectionError;

  /// No description provided for @invNewDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get invNewDescriptionHint;

  /// No description provided for @invNewRequired.
  ///
  /// In es, this message translates to:
  /// **'Es obligatorio.'**
  String get invNewRequired;

  /// No description provided for @invNewNotNumber.
  ///
  /// In es, this message translates to:
  /// **'Debe ser un número.'**
  String get invNewNotNumber;

  /// No description provided for @invNewNotInteger.
  ///
  /// In es, this message translates to:
  /// **'Debe ser un número entero.'**
  String get invNewNotInteger;

  /// No description provided for @invNewBelowMin.
  ///
  /// In es, this message translates to:
  /// **'El mínimo es {min}.'**
  String invNewBelowMin(String min);

  /// No description provided for @invNewAboveMax.
  ///
  /// In es, this message translates to:
  /// **'El máximo es {max}.'**
  String invNewAboveMax(String max);

  /// No description provided for @invNewTooLong.
  ///
  /// In es, this message translates to:
  /// **'Admite como máximo 500 caracteres.'**
  String get invNewTooLong;

  /// No description provided for @invNewInvalid.
  ///
  /// In es, this message translates to:
  /// **'Valor inválido.'**
  String get invNewInvalid;

  /// No description provided for @invNewRange.
  ///
  /// In es, this message translates to:
  /// **'De {min} a {max}'**
  String invNewRange(String min, String max);

  /// No description provided for @invNewMin.
  ///
  /// In es, this message translates to:
  /// **'Desde {min}'**
  String invNewMin(String min);

  /// No description provided for @invNewMax.
  ///
  /// In es, this message translates to:
  /// **'Hasta {max}'**
  String invNewMax(String max);

  /// No description provided for @invNewDateHint.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get invNewDateHint;

  /// No description provided for @invNewDateTimeHint.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha y hora'**
  String get invNewDateTimeHint;

  /// No description provided for @invNewFromLayer.
  ///
  /// In es, this message translates to:
  /// **'En el WebGIS lo llena su capa; aquí se captura a mano.'**
  String get invNewFromLayer;

  /// No description provided for @invNewSaved.
  ///
  /// In es, this message translates to:
  /// **'Activo {code} dado de alta: queda pendiente de validación.'**
  String invNewSaved(String code);

  /// No description provided for @invNewQueued.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: el activo quedó en el teléfono y se enviará al volver la señal.'**
  String get invNewQueued;

  /// No description provided for @invNewSavedPartly.
  ///
  /// In es, this message translates to:
  /// **'El activo se dio de alta, pero faltaron las fotos: {reason}'**
  String invNewSavedPartly(String reason);

  /// No description provided for @invNewFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo dar de alta el activo. Inténtelo de nuevo.'**
  String get invNewFailed;

  /// No description provided for @invNewFailedReason.
  ///
  /// In es, this message translates to:
  /// **'El servidor no aceptó el alta: {reason}'**
  String invNewFailedReason(String reason);

  /// No description provided for @invNewOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión y sin la carretera de la concesión: conéctese una vez para poder dar de alta sin señal.'**
  String get invNewOffline;

  /// No description provided for @invNewNoPermission.
  ///
  /// In es, this message translates to:
  /// **'Su perfil no puede dar de alta activos.'**
  String get invNewNoPermission;

  /// No description provided for @invNewChannel.
  ///
  /// In es, this message translates to:
  /// **'Este tipo de activo no puede darse de alta desde la app.'**
  String get invNewChannel;

  /// No description provided for @invQrTitle.
  ///
  /// In es, this message translates to:
  /// **'Leer QR del activo'**
  String get invQrTitle;

  /// No description provided for @invQrHint.
  ///
  /// In es, this message translates to:
  /// **'Apunte la cámara al código QR del activo.'**
  String get invQrHint;

  /// No description provided for @invQrResolving.
  ///
  /// In es, this message translates to:
  /// **'Buscando el activo…'**
  String get invQrResolving;

  /// No description provided for @invQrInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ese código no es de un activo de SIGACO.'**
  String get invQrInvalid;

  /// No description provided for @invQrNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hay un activo con ese QR en esta concesión.'**
  String get invQrNotFound;

  /// No description provided for @invQrFailure.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar el activo. Revise su conexión.'**
  String get invQrFailure;

  /// No description provided for @invQrRetry.
  ///
  /// In es, this message translates to:
  /// **'Leer otro'**
  String get invQrRetry;

  /// No description provided for @invQrManual.
  ///
  /// In es, this message translates to:
  /// **'Escribir el código'**
  String get invQrManual;

  /// No description provided for @invQrManualHint.
  ///
  /// In es, this message translates to:
  /// **'Código del QR'**
  String get invQrManualHint;

  /// No description provided for @invQrManualGo.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get invQrManualGo;

  /// No description provided for @invQrCameraError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Puede escribir el código.'**
  String get invQrCameraError;

  /// No description provided for @invHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historia operativa'**
  String get invHistoryTitle;

  /// No description provided for @invHistoryTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets'**
  String get invHistoryTickets;

  /// No description provided for @invHistoryInspections.
  ///
  /// In es, this message translates to:
  /// **'Inspecciones'**
  String get invHistoryInspections;

  /// No description provided for @invHistoryMaintenances.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos'**
  String get invHistoryMaintenances;

  /// No description provided for @invHistoryCount.
  ///
  /// In es, this message translates to:
  /// **'{open} sin cerrar · {total} en total'**
  String invHistoryCount(int open, int total);

  /// No description provided for @invHistoryEmptyTickets.
  ///
  /// In es, this message translates to:
  /// **'Este activo no tiene tickets.'**
  String get invHistoryEmptyTickets;

  /// No description provided for @invHistoryEmptyInspections.
  ///
  /// In es, this message translates to:
  /// **'Este activo no tiene inspecciones.'**
  String get invHistoryEmptyInspections;

  /// No description provided for @invHistoryEmptyMaintenances.
  ///
  /// In es, this message translates to:
  /// **'Este activo no tiene mantenimientos.'**
  String get invHistoryEmptyMaintenances;

  /// No description provided for @invHistoryMore.
  ///
  /// In es, this message translates to:
  /// **'Últimos {shown} de {total}.'**
  String invHistoryMore(int shown, int total);

  /// No description provided for @invHistoryFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron traer los registros. Revise su conexión.'**
  String get invHistoryFailed;

  /// No description provided for @invHistoryOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get invHistoryOverdue;

  /// No description provided for @invCreateTicket.
  ///
  /// In es, this message translates to:
  /// **'Crear ticket'**
  String get invCreateTicket;

  /// No description provided for @invHistTkNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get invHistTkNew;

  /// No description provided for @invHistTkAssigned.
  ///
  /// In es, this message translates to:
  /// **'Asignado'**
  String get invHistTkAssigned;

  /// No description provided for @invHistTkInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get invHistTkInProgress;

  /// No description provided for @invHistTkOnHold.
  ///
  /// In es, this message translates to:
  /// **'En espera'**
  String get invHistTkOnHold;

  /// No description provided for @invHistTkReopened.
  ///
  /// In es, this message translates to:
  /// **'Reabierto'**
  String get invHistTkReopened;

  /// No description provided for @invHistTkResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelto'**
  String get invHistTkResolved;

  /// No description provided for @invHistTkClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get invHistTkClosed;

  /// No description provided for @invHistTkCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get invHistTkCancelled;

  /// No description provided for @invHistTkUnvalidated.
  ///
  /// In es, this message translates to:
  /// **'Sin validar'**
  String get invHistTkUnvalidated;

  /// No description provided for @invHistTkOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierto'**
  String get invHistTkOpen;

  /// No description provided for @invHistTkAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendido'**
  String get invHistTkAttended;

  /// No description provided for @invHistInPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get invHistInPending;

  /// No description provided for @invHistInAssigned.
  ///
  /// In es, this message translates to:
  /// **'Asignada'**
  String get invHistInAssigned;

  /// No description provided for @invHistInInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get invHistInInProgress;

  /// No description provided for @invHistInAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendida'**
  String get invHistInAttended;

  /// No description provided for @invHistInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get invHistInReview;

  /// No description provided for @invHistInClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get invHistInClosed;

  /// No description provided for @invHistInCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get invHistInCancelled;

  /// No description provided for @invHistMpScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get invHistMpScheduled;

  /// No description provided for @invHistMpInExecution.
  ///
  /// In es, this message translates to:
  /// **'En ejecución'**
  String get invHistMpInExecution;

  /// No description provided for @invHistMpCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get invHistMpCompleted;

  /// No description provided for @invHistMpCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get invHistMpCancelled;

  /// No description provided for @ticketAssetLocationHint.
  ///
  /// In es, this message translates to:
  /// **'La carretera, el km, el sentido y la geometría salen del activo.'**
  String get ticketAssetLocationHint;

  /// No description provided for @mapFilterSubsystem.
  ///
  /// In es, this message translates to:
  /// **'Subsistema'**
  String get mapFilterSubsystem;

  /// No description provided for @defTitle.
  ///
  /// In es, this message translates to:
  /// **'Definiciones pendientes'**
  String get defTitle;

  /// No description provided for @defSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Supuestos con los que SIGACO ya funciona y TEKIA debe confirmar'**
  String get defSubtitle;

  /// No description provided for @defFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Sin veredicto'**
  String get defFilterPending;

  /// No description provided for @defFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get defFilterAll;

  /// No description provided for @defFilterModule.
  ///
  /// In es, this message translates to:
  /// **'Solo de este módulo'**
  String get defFilterModule;

  /// No description provided for @defSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Código, pregunta o supuesto'**
  String get defSearchHint;

  /// No description provided for @defSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get defSearchTooltip;

  /// No description provided for @defEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay definiciones con este filtro.'**
  String get defEmpty;

  /// No description provided for @defEmptyAll.
  ///
  /// In es, this message translates to:
  /// **'No hay definiciones pendientes.'**
  String get defEmptyAll;

  /// No description provided for @defQuestion.
  ///
  /// In es, this message translates to:
  /// **'Pregunta'**
  String get defQuestion;

  /// No description provided for @defAssumption.
  ///
  /// In es, this message translates to:
  /// **'Lo que hace hoy SIGACO'**
  String get defAssumption;

  /// No description provided for @defIfVetoed.
  ///
  /// In es, this message translates to:
  /// **'Si TEKIA dice otra cosa'**
  String get defIfVetoed;

  /// No description provided for @defSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get defSource;

  /// No description provided for @defHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get defHistory;

  /// No description provided for @defNoAnswers.
  ///
  /// In es, this message translates to:
  /// **'Nadie la ha contestado todavía.'**
  String get defNoAnswers;

  /// No description provided for @defAgree.
  ///
  /// In es, this message translates to:
  /// **'De acuerdo'**
  String get defAgree;

  /// No description provided for @defChange.
  ///
  /// In es, this message translates to:
  /// **'No: así es…'**
  String get defChange;

  /// No description provided for @defComment.
  ///
  /// In es, this message translates to:
  /// **'Comentar'**
  String get defComment;

  /// No description provided for @defChangeHint.
  ///
  /// In es, this message translates to:
  /// **'Así es como debe funcionar'**
  String get defChangeHint;

  /// No description provided for @defCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get defCommentHint;

  /// No description provided for @defSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get defSend;

  /// No description provided for @defSaved.
  ///
  /// In es, this message translates to:
  /// **'Respuesta guardada'**
  String get defSaved;

  /// No description provided for @defDecideHint.
  ///
  /// In es, this message translates to:
  /// **'Aceptar el supuesto o pedir el cambio lo hace quien administra; usted puede comentarla.'**
  String get defDecideHint;

  /// No description provided for @defRetiredNote.
  ///
  /// In es, this message translates to:
  /// **'Retirada: ya no aplica y no se contesta.'**
  String get defRetiredNote;

  /// No description provided for @defTextRequired.
  ///
  /// In es, this message translates to:
  /// **'Escriba el texto.'**
  String get defTextRequired;

  /// No description provided for @defStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get defStatusOpen;

  /// No description provided for @defStatusAnswered.
  ///
  /// In es, this message translates to:
  /// **'Respondida'**
  String get defStatusAnswered;

  /// No description provided for @defStatusAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptada'**
  String get defStatusAccepted;

  /// No description provided for @defStatusChangeRequested.
  ///
  /// In es, this message translates to:
  /// **'Cambio solicitado'**
  String get defStatusChangeRequested;

  /// No description provided for @defStatusRetired.
  ///
  /// In es, this message translates to:
  /// **'Retirada'**
  String get defStatusRetired;

  /// No description provided for @defPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get defPriorityHigh;

  /// No description provided for @defPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get defPriorityMedium;

  /// No description provided for @defPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get defPriorityLow;

  /// No description provided for @defKindAgree.
  ///
  /// In es, this message translates to:
  /// **'De acuerdo con el supuesto'**
  String get defKindAgree;

  /// No description provided for @defKindChange.
  ///
  /// In es, this message translates to:
  /// **'No: así es…'**
  String get defKindChange;

  /// No description provided for @defKindComment.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get defKindComment;

  /// No description provided for @defKindReopen.
  ///
  /// In es, this message translates to:
  /// **'Reabierta'**
  String get defKindReopen;

  /// No description provided for @defKindUpdated.
  ///
  /// In es, this message translates to:
  /// **'Supuesto actualizado'**
  String get defKindUpdated;

  /// No description provided for @defKindRetired.
  ///
  /// In es, this message translates to:
  /// **'Retirada'**
  String get defKindRetired;

  /// No description provided for @defKindRestored.
  ///
  /// In es, this message translates to:
  /// **'Reincorporada'**
  String get defKindRestored;

  /// No description provided for @defSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get defSystem;

  /// No description provided for @defFromApp.
  ///
  /// In es, this message translates to:
  /// **'desde la app'**
  String get defFromApp;

  /// No description provided for @defModuleNotice.
  ///
  /// In es, this message translates to:
  /// **'Hay {count} definiciones sin veredicto de este módulo'**
  String defModuleNotice(int count);

  /// No description provided for @defView.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get defView;

  /// No description provided for @defErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión con SIGACO. Revise su red e intente de nuevo.'**
  String get defErrorNetwork;

  /// No description provided for @defErrorPermission.
  ///
  /// In es, this message translates to:
  /// **'Su perfil no puede hacer eso.'**
  String get defErrorPermission;

  /// No description provided for @defErrorNotFound.
  ///
  /// In es, this message translates to:
  /// **'La definición ya no existe.'**
  String get defErrorNotFound;

  /// No description provided for @defErrorRetired.
  ///
  /// In es, this message translates to:
  /// **'La definición está retirada: ya no se contesta.'**
  String get defErrorRetired;

  /// No description provided for @defErrorServer.
  ///
  /// In es, this message translates to:
  /// **'SIGACO no pudo responder. Intente de nuevo.'**
  String get defErrorServer;

  /// No description provided for @maintPerformanceAction.
  ///
  /// In es, this message translates to:
  /// **'Desempeño del indicador'**
  String get maintPerformanceAction;

  /// No description provided for @maintPerformanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Desempeño'**
  String get maintPerformanceTitle;

  /// No description provided for @maintPerformanceHint.
  ///
  /// In es, this message translates to:
  /// **'Cálculo del indicador a hoy con los datos de SIGACO. Aprobar eventos, expurgos y cierres se hace en la web.'**
  String get maintPerformanceHint;

  /// No description provided for @maintEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eventos de indisponibilidad'**
  String get maintEventsTitle;

  /// No description provided for @maintEventsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos registrados.'**
  String get maintEventsEmpty;

  /// No description provided for @maintEventsOpen.
  ///
  /// In es, this message translates to:
  /// **'abierto'**
  String get maintEventsOpen;

  /// No description provided for @maintEventsCreate.
  ///
  /// In es, this message translates to:
  /// **'Registrar indisponibilidad'**
  String get maintEventsCreate;

  /// No description provided for @maintEventsAsset.
  ///
  /// In es, this message translates to:
  /// **'Equipo o sistema (código)'**
  String get maintEventsAsset;

  /// No description provided for @maintEventsStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio de la indisponibilidad'**
  String get maintEventsStart;

  /// No description provided for @maintEventsCause.
  ///
  /// In es, this message translates to:
  /// **'Causa'**
  String get maintEventsCause;

  /// No description provided for @maintEventsApprovalHint.
  ///
  /// In es, this message translates to:
  /// **'El evento queda pendiente hasta que el supervisor lo apruebe con la evidencia en la web.'**
  String get maintEventsApprovalHint;

  /// No description provided for @maintEventsRequired.
  ///
  /// In es, this message translates to:
  /// **'Elija el equipo y escriba la causa.'**
  String get maintEventsRequired;

  /// No description provided for @maintEventsFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar el evento.'**
  String get maintEventsFailed;

  /// No description provided for @maintEventsSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get maintEventsSave;

  /// No description provided for @maintStatusComplies.
  ///
  /// In es, this message translates to:
  /// **'Cumple'**
  String get maintStatusComplies;

  /// No description provided for @maintStatusNotComplies.
  ///
  /// In es, this message translates to:
  /// **'No cumple'**
  String get maintStatusNotComplies;

  /// No description provided for @maintStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de validación'**
  String get maintStatusPending;

  /// No description provided for @maintStatusNotYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no exigible'**
  String get maintStatusNotYet;

  /// No description provided for @maintStatusNotEvaluated.
  ///
  /// In es, this message translates to:
  /// **'No evaluado'**
  String get maintStatusNotEvaluated;

  /// No description provided for @captSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get captSave;

  /// No description provided for @captFinalize.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get captFinalize;

  /// No description provided for @captStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar captura'**
  String get captStart;

  /// No description provided for @captAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get captAccept;

  /// No description provided for @captReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get captReject;

  /// No description provided for @captRejectReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get captRejectReason;

  /// No description provided for @captMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta para finalizar ({count})'**
  String captMissing(int count);

  /// No description provided for @captCondition.
  ///
  /// In es, this message translates to:
  /// **'Condición'**
  String get captCondition;

  /// No description provided for @captUnrated.
  ///
  /// In es, this message translates to:
  /// **'Sin evaluar'**
  String get captUnrated;

  /// No description provided for @captPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior: {value}'**
  String captPrevious(String value);

  /// No description provided for @captFromAsset.
  ///
  /// In es, this message translates to:
  /// **'Dato del activo'**
  String get captFromAsset;

  /// No description provided for @captAddPhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get captAddPhoto;

  /// No description provided for @captPhotoPending.
  ///
  /// In es, this message translates to:
  /// **'Por enviar'**
  String get captPhotoPending;

  /// No description provided for @captNoPhotos.
  ///
  /// In es, this message translates to:
  /// **'Sin fotos'**
  String get captNoPhotos;

  /// No description provided for @captAddRow.
  ///
  /// In es, this message translates to:
  /// **'Agregar fila'**
  String get captAddRow;

  /// No description provided for @captRemoveRow.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get captRemoveRow;

  /// No description provided for @captFindings.
  ///
  /// In es, this message translates to:
  /// **'Hallazgos'**
  String get captFindings;

  /// No description provided for @captAddFinding.
  ///
  /// In es, this message translates to:
  /// **'Registrar hallazgo'**
  String get captAddFinding;

  /// No description provided for @captFindingDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get captFindingDescription;

  /// No description provided for @captFindingFailure.
  ///
  /// In es, this message translates to:
  /// **'Falla de la Matriz'**
  String get captFindingFailure;

  /// No description provided for @captFindingNoFailure.
  ///
  /// In es, this message translates to:
  /// **'Sin falla (elige la severidad)'**
  String get captFindingNoFailure;

  /// No description provided for @captFindingSeverity.
  ///
  /// In es, this message translates to:
  /// **'Severidad'**
  String get captFindingSeverity;

  /// No description provided for @captImmediate.
  ///
  /// In es, this message translates to:
  /// **'Plazo «Imediato»: al finalizar se crea el ticket.'**
  String get captImmediate;

  /// No description provided for @captPendingSync.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios guardados en el teléfono: se envían solos al volver la señal.'**
  String get captPendingSync;

  /// No description provided for @captSavedOffline.
  ///
  /// In es, this message translates to:
  /// **'Guardado en el teléfono: se enviará al volver la señal.'**
  String get captSavedOffline;

  /// No description provided for @captSaved.
  ///
  /// In es, this message translates to:
  /// **'Borrador guardado.'**
  String get captSaved;

  /// No description provided for @captFinalized.
  ///
  /// In es, this message translates to:
  /// **'Inspección finalizada.'**
  String get captFinalized;

  /// No description provided for @captFinalizedOffline.
  ///
  /// In es, this message translates to:
  /// **'Finalizada en el teléfono: se enviará al volver la señal.'**
  String get captFinalizedOffline;

  /// No description provided for @captJustifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ubicación fuera de la tolerancia'**
  String get captJustifyTitle;

  /// No description provided for @captConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get captConfirm;

  /// No description provided for @captCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get captCancel;

  /// No description provided for @captYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get captYes;

  /// No description provided for @captNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get captNo;

  /// No description provided for @captError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción.'**
  String get captError;

  /// No description provided for @captOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión y sin copia en el teléfono: abre la inspección una vez con señal.'**
  String get captOffline;

  /// No description provided for @captTemplateVersion.
  ///
  /// In es, this message translates to:
  /// **'Plantilla v{version}'**
  String captTemplateVersion(int version);

  /// No description provided for @captCorrection.
  ///
  /// In es, this message translates to:
  /// **'Corrección pedida: {reason}'**
  String captCorrection(String reason);

  /// No description provided for @captNotEditable.
  ///
  /// In es, this message translates to:
  /// **'La inspección ya no se puede modificar.'**
  String get captNotEditable;

  /// No description provided for @captPermission.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no permite esta acción.'**
  String get captPermission;

  /// No description provided for @captDone.
  ///
  /// In es, this message translates to:
  /// **'Listo.'**
  String get captDone;

  /// No description provided for @captRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazaste la inspección: vuelve a pendiente.'**
  String get captRejected;

  /// No description provided for @captRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get captRetry;

  /// No description provided for @captRoadSection.
  ///
  /// In es, this message translates to:
  /// **'Inspección de tramo'**
  String get captRoadSection;

  /// No description provided for @captConform.
  ///
  /// In es, this message translates to:
  /// **'Conforme'**
  String get captConform;

  /// No description provided for @captNonConform.
  ///
  /// In es, this message translates to:
  /// **'No conforme'**
  String get captNonConform;

  /// No description provided for @captNotApplicable.
  ///
  /// In es, this message translates to:
  /// **'No aplica'**
  String get captNotApplicable;

  /// No description provided for @captWithTicket.
  ///
  /// In es, this message translates to:
  /// **'Con ticket'**
  String get captWithTicket;

  /// No description provided for @captStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get captStatusPending;

  /// No description provided for @captStatusAssigned.
  ///
  /// In es, this message translates to:
  /// **'Asignada'**
  String get captStatusAssigned;

  /// No description provided for @captStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get captStatusInProgress;

  /// No description provided for @captStatusAttended.
  ///
  /// In es, this message translates to:
  /// **'Atendida'**
  String get captStatusAttended;

  /// No description provided for @captStatusInReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get captStatusInReview;

  /// No description provided for @captStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get captStatusClosed;

  /// No description provided for @captStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get captStatusCancelled;

  /// No description provided for @ticketsFilterUnvalidated.
  ///
  /// In es, this message translates to:
  /// **'Sin validar'**
  String get ticketsFilterUnvalidated;

  /// No description provided for @ticketsFilterClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrados'**
  String get ticketsFilterClosed;

  /// No description provided for @ticketsFilterCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelados'**
  String get ticketsFilterCancelled;

  /// No description provided for @ticketStageUnvalidated.
  ///
  /// In es, this message translates to:
  /// **'Sin validar'**
  String get ticketStageUnvalidated;

  /// No description provided for @ticketStageClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get ticketStageClosed;

  /// No description provided for @ticketStageCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get ticketStageCancelled;

  /// No description provided for @ticketInfoAssignedCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa asignada'**
  String get ticketInfoAssignedCompany;

  /// No description provided for @ticketInfoAssignedTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo asignado'**
  String get ticketInfoAssignedTeam;

  /// No description provided for @ticketSupervisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Supervisión'**
  String get ticketSupervisionTitle;

  /// No description provided for @ticketActionAssign.
  ///
  /// In es, this message translates to:
  /// **'Asignar'**
  String get ticketActionAssign;

  /// No description provided for @ticketActionReassign.
  ///
  /// In es, this message translates to:
  /// **'Reasignar'**
  String get ticketActionReassign;

  /// No description provided for @ticketActionClose.
  ///
  /// In es, this message translates to:
  /// **'Validar y cerrar'**
  String get ticketActionClose;

  /// No description provided for @ticketActionReturn.
  ///
  /// In es, this message translates to:
  /// **'Regresar a Abierto'**
  String get ticketActionReturn;

  /// No description provided for @ticketActionReopen.
  ///
  /// In es, this message translates to:
  /// **'Reabrir'**
  String get ticketActionReopen;

  /// No description provided for @ticketActionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar registro'**
  String get ticketActionCancel;

  /// No description provided for @ticketActionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get ticketActionSave;

  /// No description provided for @ticketAssignTitle.
  ///
  /// In es, this message translates to:
  /// **'Asignar a empresa y equipo'**
  String get ticketAssignTitle;

  /// No description provided for @ticketReassignTitle.
  ///
  /// In es, this message translates to:
  /// **'Reasignar a otra empresa o equipo'**
  String get ticketReassignTitle;

  /// No description provided for @ticketAssignCompany.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get ticketAssignCompany;

  /// No description provided for @ticketAssignTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get ticketAssignTeam;

  /// No description provided for @ticketAssignPerson.
  ///
  /// In es, this message translates to:
  /// **'Persona de referencia (opcional)'**
  String get ticketAssignPerson;

  /// No description provided for @ticketAssignNoPerson.
  ///
  /// In es, this message translates to:
  /// **'Sin persona de referencia'**
  String get ticketAssignNoPerson;

  /// No description provided for @ticketAssignSelect.
  ///
  /// In es, this message translates to:
  /// **'Selecciona'**
  String get ticketAssignSelect;

  /// No description provided for @ticketAssignNoTeams.
  ///
  /// In es, this message translates to:
  /// **'No hay empresas con equipos activos para asignar.'**
  String get ticketAssignNoTeams;

  /// No description provided for @ticketAssignLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron traer las empresas y los equipos.'**
  String get ticketAssignLoadFailed;

  /// No description provided for @ticketAssignMissing.
  ///
  /// In es, this message translates to:
  /// **'Elige la empresa y el equipo.'**
  String get ticketAssignMissing;

  /// No description provided for @ticketReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get ticketReasonLabel;

  /// No description provided for @ticketReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Explica el motivo'**
  String get ticketReasonHint;

  /// No description provided for @ticketReasonRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo.'**
  String get ticketReasonRequired;

  /// No description provided for @ticketCloseTitle.
  ///
  /// In es, this message translates to:
  /// **'Validar y cerrar el registro'**
  String get ticketCloseTitle;

  /// No description provided for @ticketCloseCondition.
  ///
  /// In es, this message translates to:
  /// **'Condición del activo'**
  String get ticketCloseCondition;

  /// No description provided for @ticketCloseNotes.
  ///
  /// In es, this message translates to:
  /// **'Observación (opcional)'**
  String get ticketCloseNotes;

  /// No description provided for @ticketConditionUnchanged.
  ///
  /// In es, this message translates to:
  /// **'Sin cambio'**
  String get ticketConditionUnchanged;

  /// No description provided for @ticketConditionGood.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get ticketConditionGood;

  /// No description provided for @ticketConditionFair.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get ticketConditionFair;

  /// No description provided for @ticketConditionPoor.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get ticketConditionPoor;

  /// No description provided for @ticketConditionVeryPoor.
  ///
  /// In es, this message translates to:
  /// **'Pésimo'**
  String get ticketConditionVeryPoor;

  /// No description provided for @ticketReturnTitle.
  ///
  /// In es, this message translates to:
  /// **'Regresar a Abierto'**
  String get ticketReturnTitle;

  /// No description provided for @ticketReopenTitle.
  ///
  /// In es, this message translates to:
  /// **'Reabrir el registro'**
  String get ticketReopenTitle;

  /// No description provided for @ticketCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar el registro'**
  String get ticketCancelTitle;

  /// No description provided for @ticketCancelReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo de cancelación'**
  String get ticketCancelReason;

  /// No description provided for @ticketCancelDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicado'**
  String get ticketCancelDuplicate;

  /// No description provided for @ticketCancelImproper.
  ///
  /// In es, this message translates to:
  /// **'Improcedente'**
  String get ticketCancelImproper;

  /// No description provided for @ticketCancelOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get ticketCancelOther;

  /// No description provided for @ticketCancelFolio.
  ///
  /// In es, this message translates to:
  /// **'Folio del registro original'**
  String get ticketCancelFolio;

  /// No description provided for @ticketCancelFolioRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el folio del registro original.'**
  String get ticketCancelFolioRequired;

  /// No description provided for @ticketCancelNotes.
  ///
  /// In es, this message translates to:
  /// **'Detalle del motivo'**
  String get ticketCancelNotes;

  /// No description provided for @ticketCancelNotesRequired.
  ///
  /// In es, this message translates to:
  /// **'Con «Otro», explica el motivo.'**
  String get ticketCancelNotesRequired;

  /// No description provided for @ticketDoneAssign.
  ///
  /// In es, this message translates to:
  /// **'Registro asignado.'**
  String get ticketDoneAssign;

  /// No description provided for @ticketDoneReassign.
  ///
  /// In es, this message translates to:
  /// **'Registro reasignado.'**
  String get ticketDoneReassign;

  /// No description provided for @ticketDoneClose.
  ///
  /// In es, this message translates to:
  /// **'Registro validado y cerrado.'**
  String get ticketDoneClose;

  /// No description provided for @ticketDoneReturn.
  ///
  /// In es, this message translates to:
  /// **'Registro regresado a Abierto.'**
  String get ticketDoneReturn;

  /// No description provided for @ticketDoneReopen.
  ///
  /// In es, this message translates to:
  /// **'Registro reabierto.'**
  String get ticketDoneReopen;

  /// No description provided for @ticketDoneCancel.
  ///
  /// In es, this message translates to:
  /// **'Registro cancelado.'**
  String get ticketDoneCancel;

  /// No description provided for @ticketActionRejected.
  ///
  /// In es, this message translates to:
  /// **'No se aplicó el cambio: {reason}'**
  String ticketActionRejected(String reason);

  /// No description provided for @ticketActionOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: esta acción necesita red.'**
  String get ticketActionOffline;

  /// No description provided for @ticketActionDenied.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil no puede hacer esta acción.'**
  String get ticketActionDenied;

  /// No description provided for @ticketActionFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción. Inténtalo de nuevo.'**
  String get ticketActionFailed;

  /// No description provided for @ticketCancelledInfo.
  ///
  /// In es, this message translates to:
  /// **'Cancelado: {reason}'**
  String ticketCancelledInfo(String reason);

  /// No description provided for @ticketCancelledDuplicateOf.
  ///
  /// In es, this message translates to:
  /// **'Duplicado de {folio}'**
  String ticketCancelledDuplicateOf(String folio);

  /// No description provided for @ticketClosedCondition.
  ///
  /// In es, this message translates to:
  /// **'Condición del activo al cerrar: {condition}'**
  String ticketClosedCondition(String condition);

  /// No description provided for @newTicketRoad.
  ///
  /// In es, this message translates to:
  /// **'Carretera'**
  String get newTicketRoad;

  /// No description provided for @newTicketErrorRoad.
  ///
  /// In es, this message translates to:
  /// **'Elige la carretera: la concesión tiene varias.'**
  String get newTicketErrorRoad;

  /// No description provided for @maintEventsRejected.
  ///
  /// In es, this message translates to:
  /// **'No se registró el evento: {reason}'**
  String maintEventsRejected(String reason);
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
