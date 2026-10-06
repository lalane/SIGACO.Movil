// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTagline => 'Sistema de Gestão de Ativos de Concessão';

  @override
  String get loginWelcome => 'Bem-vindo';

  @override
  String get loginSubtitle => 'Faça login para continuar';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get fieldPassword => 'Senha';

  @override
  String get rememberCredentials => 'Lembrar e-mail e senha';

  @override
  String get forgotPassword => 'Esqueceu sua senha?';

  @override
  String get signIn => 'Entrar';

  @override
  String get biometricAccess => 'Entrar com biometria';

  @override
  String get biometricReason => 'Confirme sua identidade para entrar';

  @override
  String get biometricEnableTitle => 'Ativar acesso com biometria';

  @override
  String get biometricEnableBody =>
      'Na próxima vez você poderá entrar com sua digital ou rosto. Seus dados ficam criptografados neste dispositivo.';

  @override
  String get biometricEnable => 'Ativar';

  @override
  String get biometricNotNow => 'Agora não';

  @override
  String get biometricUnavailable =>
      'A biometria não está disponível ou não está ativada neste dispositivo.';

  @override
  String get biometricNoCredentials =>
      'A biometria ainda não está ativada. Faça login com e-mail e senha e será oferecida a ativação.';

  @override
  String get biometricSettingTitle => 'Acesso com biometria';

  @override
  String get biometricSettingOn =>
      'Ativo: você entra com sua digital ou rosto.';

  @override
  String get biometricSettingOff =>
      'Inativo. Ative para entrar com sua digital ou rosto.';

  @override
  String get biometricEnabledDone => 'Acesso com biometria ativado.';

  @override
  String get biometricDisabledDone => 'Acesso com biometria desativado.';

  @override
  String get valueSecure => 'Seguro';

  @override
  String get valueReliable => 'Confiável';

  @override
  String get valueCollaborative => 'Colaborativo';

  @override
  String get valueEfficient => 'Eficiente';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get contactAdmin => 'Contato com o administrador';

  @override
  String get errEmailRequired => 'Informe seu e-mail.';

  @override
  String get errEmailInvalid => 'Informe um e-mail válido.';

  @override
  String get errPasswordRequired => 'Informe sua senha.';

  @override
  String get errInvalidCredentials =>
      'E-mail ou senha incorretos. Após várias tentativas falhas consecutivas, a conta é bloqueada.';

  @override
  String get errAccountBlocked =>
      'Seu acesso foi bloqueado por tentativas falhas. Entre em contato com o administrador do sistema para solicitar a reativação da sua conta.';

  @override
  String get errNetwork =>
      'Sem conexão com o servidor. Verifique sua rede e tente novamente.';

  @override
  String get errServer => 'Ocorreu um erro no servidor. Tente mais tarde.';

  @override
  String get errSessionExpired => 'Sua sessão terminou. Faça login novamente.';

  @override
  String get mfaTitle => 'Verificação em duas etapas';

  @override
  String get mfaSubtitle =>
      'Informe o código de 6 dígitos do seu app autenticador.';

  @override
  String get mfaCode => 'Código';

  @override
  String get mfaVerify => 'Verificar';

  @override
  String get mfaCodeInvalid => 'O código não é válido.';

  @override
  String get mfaEnrollTitle => 'Configure sua verificação em duas etapas';

  @override
  String get mfaEnrollBody =>
      'Adicione esta chave ao seu app autenticador e digite o primeiro código gerado.';

  @override
  String get mfaEnrollSecret => 'Chave';

  @override
  String get mfaCopied => 'Chave copiada';

  @override
  String get changePasswordTitle => 'Altere sua senha';

  @override
  String get changePasswordSubtitle =>
      'Por segurança, você deve definir uma nova senha para continuar.';

  @override
  String get currentPassword => 'Senha atual';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get changePasswordAction => 'Alterar senha';

  @override
  String get passwordMismatch => 'As senhas não coincidem.';

  @override
  String get concessionTitle => 'Selecione sua concessão';

  @override
  String get concessionSubtitle =>
      'Você tem acesso a mais de uma concessão. Escolha com qual trabalhar.';

  @override
  String get recoveryTitle => 'Recuperar senha';

  @override
  String get recoveryBody =>
      'Informe seu e-mail. Se corresponder a uma conta ativa, você receberá um link para definir sua senha.';

  @override
  String get recoverySend => 'Enviar link';

  @override
  String get recoverySent =>
      'Se o e-mail corresponder a uma conta ativa, você receberá um link para definir sua senha.';

  @override
  String get recoveryStepsTitle => 'O que fazer agora';

  @override
  String get recoveryStep1 => 'Abra o e-mail que enviamos.';

  @override
  String get recoveryStep2 =>
      'Toque no link: ele abre no navegador. Lá você define sua nova senha.';

  @override
  String get recoveryStep3 =>
      'Ao terminar, toque em «Voltar ao aplicativo» e faça login.';

  @override
  String get recoveryResend => 'Reenviar link';

  @override
  String get recoveryBackToLogin => 'Voltar ao login';

  @override
  String get passwordResetDone =>
      'Senha atualizada. Faça login com sua nova senha.';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get appearanceLabel => 'Aparência';

  @override
  String get appearanceOriginal => 'Original';

  @override
  String get appearanceDay => 'Dia';

  @override
  String get appearanceNight => 'Noite';

  @override
  String get preferencesTitle => 'Preferências';

  @override
  String get preferencesSubtitle => 'Ficam salvas neste dispositivo.';

  @override
  String get useConcessionColors => 'Cores da minha concessão';

  @override
  String get useConcessionColorsOn => 'Usa as cores da sua concessão.';

  @override
  String get useConcessionColorsOff => 'Usa as cores do SIGACO.';

  @override
  String get securityTitle => 'Segurança';

  @override
  String get mfaSettingTitle => 'Verificação em duas etapas';

  @override
  String get mfaSettingOn =>
      'Ativa. Seu código é gerado pelo app autenticador. Toque para configurá-la de novo.';

  @override
  String get mfaSettingOff =>
      'Não está habilitada para sua conta. Um administrador a ativa.';

  @override
  String get mfaAdminManaged =>
      'A verificação em duas etapas é ativada ou desativada por um administrador do sistema.';

  @override
  String get mfaReconfigureBody =>
      'Será gerada uma nova chave e a do seu app autenticador atual deixará de funcionar. Se você não terminar, precisará configurá-la de novo ao entrar.';

  @override
  String get mfaReconfigureAction => 'Gerar nova chave';

  @override
  String get mfaReconfigureDone => 'Verificação em duas etapas atualizada.';

  @override
  String get homePlaceholderTitle => 'Início';

  @override
  String get homePlaceholderBody =>
      'Aqui ficará o menu de módulos (design v2).';

  @override
  String welcomeUser(String name) {
    return 'Bem-vindo, $name';
  }

  @override
  String get signOut => 'Sair';

  @override
  String get cancel => 'Cancelar';

  @override
  String get greetingMorning => 'Bom dia,';

  @override
  String get greetingAfternoon => 'Boa tarde,';

  @override
  String get greetingEvening => 'Boa noite,';

  @override
  String get homeQuestion => 'O que você deseja fazer hoje?';

  @override
  String get modulesTitle => 'MÓDULOS';

  @override
  String get moduleMap => 'Mapa';

  @override
  String get moduleMapSub => 'Localização de ativos';

  @override
  String get moduleDashboard => 'Dashboard';

  @override
  String get moduleDashboardSub => 'Resumo geral';

  @override
  String get moduleAccidents => 'Acidentes';

  @override
  String get moduleAccidentsSub => 'Incidentes graves';

  @override
  String get moduleMaintenance => 'Manutenções';

  @override
  String get moduleMaintenanceSub => 'Ordens de serviço';

  @override
  String get moduleInventory => 'Inventário';

  @override
  String get moduleInventorySub => 'Controle de ativos e faixa';

  @override
  String get moduleReports => 'Relatórios';

  @override
  String get moduleReportsSub => 'Consulta e exportação';

  @override
  String get moduleTickets => 'Tickets';

  @override
  String get moduleTicketsSub => 'Acompanhamento e registro';

  @override
  String get moduleAlerts => 'Alertas';

  @override
  String get moduleAlertsSub => 'Eventos operacionais';

  @override
  String get moduleComingSoon => 'Este módulo está em desenvolvimento.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navHome => 'Início';

  @override
  String get navAlerts => 'Alertas';

  @override
  String get navReports => 'Relatórios';

  @override
  String get menuLoadError => 'Não foi possível carregar seu menu.';

  @override
  String get menuEmpty =>
      'Seu perfil não tem módulos habilitados nesta concessão. Se acredita que é um erro, entre em contato com o administrador da sua concessão.';

  @override
  String get accessNoPermissionTitle => 'Sem permissão';

  @override
  String get accessNoPermissionBody =>
      'Seu perfil não tem permissão para ver esta informação. Se acredita que é um erro, entre em contato com o administrador da sua concessão.';

  @override
  String get accessErrorTitle => 'Não foi possível verificar seus acessos';

  @override
  String get accessErrorBody =>
      'Ocorreu um problema ao validar suas permissões. Tente novamente; se continuar, entre em contato com o administrador da sua concessão.';

  @override
  String get accessChangedNotice =>
      'Seus acessos mudaram. O menu foi atualizado.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get accountTitle => 'Configurações do usuário';

  @override
  String get accountInfoTitle => 'Informações da conta';

  @override
  String get accountInfoSubtitle =>
      'Estes são os dados associados ao seu perfil no SIGACO.';

  @override
  String get fieldUser => 'Usuário';

  @override
  String get fieldEmailShort => 'E-mail';

  @override
  String get fieldProfile => 'Perfil';

  @override
  String get fieldArea => 'Área';

  @override
  String get fieldConcession => 'Concessionária';

  @override
  String get fieldRoads => 'Rodovias';

  @override
  String get fieldAppVersion => 'Versão do app';

  @override
  String get fieldDevice => 'Dispositivo';

  @override
  String get fieldLastConnection => 'Última conexão';

  @override
  String get connectionOffline => 'Sem conexão';

  @override
  String connectionOfflineSince(String time) {
    return 'Sem conexão · última conexão $time';
  }

  @override
  String get connectionRestored => 'Conexão restabelecida';

  @override
  String get actionChangePasswordSub => 'Atualize sua senha de acesso';

  @override
  String get actionSwitchConcession => 'Trocar de concessão';

  @override
  String get actionSwitchConcessionSub =>
      'Escolha outra concessão para trabalhar';

  @override
  String get switchConcessionWarning =>
      'Ao trocar de concessão, uma nova sessão é aberta e o que foi carregado da anterior é descartado.';

  @override
  String get passwordChanged =>
      'Senha atualizada. Suas outras sessões foram encerradas.';

  @override
  String get sessionExpiringTitle => 'Sua sessão está para expirar';

  @override
  String get sessionContinue => 'Continuar';

  @override
  String sessionExpiringBody(int seconds) {
    return 'Por inatividade será encerrada em $seconds segundos.';
  }

  @override
  String get appTaglineShort => 'Sistema de Gestão de Ativos';
}
