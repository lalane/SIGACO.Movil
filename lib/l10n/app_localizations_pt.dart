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
  String get errValidation =>
      'Não foi possível salvar. Revise os dados e tente novamente.';

  @override
  String get passwordRulesTitle => 'A senha deve ter:';

  @override
  String passwordRuleLength(int min) {
    return 'Pelo menos $min caracteres';
  }

  @override
  String get passwordRuleUppercase => 'Uma letra maiúscula';

  @override
  String get passwordRuleLowercase => 'Uma letra minúscula';

  @override
  String get passwordRuleDigit => 'Um número';

  @override
  String get passwordRuleSpecial =>
      'Um caractere especial (por exemplo ! # \$ %)';

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
  String get demoModeTitle => 'Dados de exemplo';

  @override
  String get demoModeOn =>
      'Tudo aparece com dados inventados; o servidor não é consultado';

  @override
  String get demoModeOff =>
      'Ver o app com dados inventados para conhecer a estrutura';

  @override
  String get demoModeSnackOn => 'Dados de exemplo ativados';

  @override
  String get demoModeSnackOff => 'Dados reais';

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
  String get moduleInventory => 'Cadastro';

  @override
  String get moduleInventorySub => 'Controle de ativos e faixa';

  @override
  String get moduleReports => 'Relatórios';

  @override
  String get moduleReportsSub => 'Consulta e exportação';

  @override
  String get moduleTickets => 'Registros';

  @override
  String get moduleTicketsSub => 'Acompanhamento e registro';

  @override
  String get moduleAlerts => 'Alertas';

  @override
  String get moduleAlertsSub => 'Eventos operacionais';

  @override
  String get moduleComingSoon => 'Este módulo está em desenvolvimento.';

  @override
  String get navTickets => 'Registros';

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
  String get fieldJobTitle => 'Cargo';

  @override
  String get fieldCompany => 'Empresa';

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
  String get fieldTimezone => 'Fuso horário da concessão';

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
  String get profilePhotoTitle => 'Foto de perfil';

  @override
  String get profilePhotoTake => 'Tirar uma foto';

  @override
  String get profilePhotoGallery => 'Escolher da galeria';

  @override
  String get profilePhotoRemove => 'Remover a foto';

  @override
  String get profilePhotoFailed => 'Não foi possível salvar a foto';

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
  String get appTaglineShort => 'Sistema de Gestão de Ativos';

  @override
  String get syncTitle => 'Sincronização';

  @override
  String syncStripPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações pendentes de envio',
      one: '1 operação pendente de envio',
    );
    return '$_temp0';
  }

  @override
  String syncStripAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações precisam da sua decisão',
      one: '1 operação precisa da sua decisão',
    );
    return '$_temp0';
  }

  @override
  String syncLastSync(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get syncNever => 'Ainda não foi sincronizado';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncRunning => 'Sincronizando…';

  @override
  String get syncOfflineHint => 'Sem conexão. Será enviado ao recuperá-la.';

  @override
  String get syncAllDone => 'Tudo está sincronizado';

  @override
  String get syncAllDoneBody =>
      'Não há operações pendentes nem que precisem da sua decisão.';

  @override
  String get syncSectionAttention => 'Precisam da sua decisão';

  @override
  String get syncSectionPending => 'Pendentes de envio';

  @override
  String get syncStatusPending => 'Pendente';

  @override
  String get syncStatusSending => 'Enviando';

  @override
  String get syncStatusRejected => 'Rejeitada';

  @override
  String get syncStatusConflict => 'Em conflito';

  @override
  String syncCaptured(String time) {
    return 'Capturada $time';
  }

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentativas',
      one: '1 tentativa',
    );
    return '$_temp0';
  }

  @override
  String get syncActionRetry => 'Tentar de novo';

  @override
  String get syncActionDiscard => 'Descartar';

  @override
  String get syncActionReview => 'Revisar';

  @override
  String get syncDiscardTitle => 'Descartar esta operação?';

  @override
  String get syncDiscardBody =>
      'O que foi capturado neste telefone será perdido. Isso não pode ser desfeito.';

  @override
  String get syncEntityDocument => 'Documento';

  @override
  String get syncEntitySignature => 'Assinatura de documento';

  @override
  String get syncEntityTicket => 'Registro';

  @override
  String get syncEntityInspection => 'Monitoração';

  @override
  String get syncEntityEvent => 'Evento';

  @override
  String get syncEntityAsset => 'Ativo';

  @override
  String get syncEntitySurvey => 'Levantamento';

  @override
  String get syncEntityMedia => 'Arquivo';

  @override
  String get syncEntityMaintenanceProgress => 'Avanço de manutenção';

  @override
  String get syncEntityOther => 'Operação';

  @override
  String get syncKindInsert => 'Inclusão';

  @override
  String get syncKindUpdate => 'Alteração';

  @override
  String get syncKindDelete => 'Exclusão';

  @override
  String get syncConflictTitle => 'Conflito de sincronização';

  @override
  String get syncConflictIntro =>
      'Este registro mudou no servidor enquanto você estava sem conexão. Escolha com qual ficar: nada é aplicado em silêncio.';

  @override
  String get syncConflictMine => 'O que você capturou';

  @override
  String get syncConflictServer => 'O que há no servidor';

  @override
  String syncConflictVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get syncConflictNoDetail => 'Sem detalhe disponível';

  @override
  String get syncConflictKeepServer => 'Ficar com o servidor';

  @override
  String get syncConflictKeepServerBody =>
      'O que foi capturado neste telefone será descartado.';

  @override
  String get syncConflictKeepMine => 'Manter o meu';

  @override
  String get syncConflictKeepMineBody =>
      'Será enviado de novo sobre a versão atual do servidor, que pode rejeitá-lo.';

  @override
  String get syncConflictMissing => 'Este conflito não existe mais.';

  @override
  String syncMessageFromServer(String message) {
    return 'Motivo: $message';
  }

  @override
  String get moduleDocuments => 'Gestor documental';

  @override
  String get moduleDocumentsSub => 'Consulta e assinatura de documentos';

  @override
  String get docsTitle => 'Gestor documental';

  @override
  String get docsViewAll => 'Todos';

  @override
  String get docsViewRecent => 'Recentes';

  @override
  String get docsViewFavorites => 'Favoritos';

  @override
  String get docsViewMine => 'Meus documentos';

  @override
  String get docsSearchHint => 'Buscar por nome, proprietário ou categoria';

  @override
  String get docsFilters => 'Filtros';

  @override
  String get docsFiltersApply => 'Aplicar';

  @override
  String get docsFiltersClear => 'Limpar filtros';

  @override
  String get docsFilterType => 'Tipo documental';

  @override
  String get docsFilterCategory => 'Categoria';

  @override
  String get docsFilterFolder => 'Pasta';

  @override
  String get docsFilterModifiedBy => 'Modificado por';

  @override
  String get docsFilterFrom => 'De';

  @override
  String get docsFilterTo => 'Até';

  @override
  String get docsFilterAny => 'Qualquer';

  @override
  String get docsFilterPickDate => 'Escolher data';

  @override
  String get docsRangeInvalid => 'A data De não pode ser posterior a Até.';

  @override
  String get docsLoading => 'Carregando documentos…';

  @override
  String get docsEmptyAllTitle => 'Ainda não há documentos';

  @override
  String get docsEmptyAllBody =>
      'Quando documentos desta concessão forem carregados, aparecerão aqui.';

  @override
  String get docsEmptyRecentTitle => 'Sem atividade recente';

  @override
  String get docsEmptyRecentBody =>
      'Aqui aparecem os documentos que você abriu ou carregou nos últimos 30 dias.';

  @override
  String get docsEmptyFavoritesTitle => 'Sem favoritos';

  @override
  String get docsEmptyFavoritesBody =>
      'Marque um documento com a estrela para encontrá-lo aqui.';

  @override
  String get docsEmptyMineTitle => 'Você ainda não carregou documentos';

  @override
  String get docsEmptyMineBody =>
      'Os documentos que você carregar aparecerão aqui.';

  @override
  String get docsNoResultsTitle => 'Sem resultados';

  @override
  String get docsNoResultsBody => 'Tente outra busca ou remova algum filtro.';

  @override
  String get docsErrorTitle => 'Não foi possível carregar os documentos';

  @override
  String get docsErrorBody => 'Tente novamente em instantes.';

  @override
  String get docsOfflineTitle => 'Sem conexão';

  @override
  String get docsOfflineBody =>
      'Os documentos precisam de conexão enquanto não estiverem salvos no telefone.';

  @override
  String get docsNoPermissionTitle => 'Sem permissão para ver documentos';

  @override
  String get docsNoPermissionBody =>
      'Seu perfil não pode consultar o gestor documental nesta concessão.';

  @override
  String get docsNoRoadTitle => 'Sem rodovias atribuídas';

  @override
  String get docsNoRoadBody =>
      'Seu usuário não tem rodovias atribuídas nesta concessão. Peça ao administrador que as atribua.';

  @override
  String get docsNotFoundTitle => 'O documento não está mais disponível';

  @override
  String get docsNotFoundBody => 'Ele pode ter sido movido ou excluído.';

  @override
  String get docsNotOfflineTitle => 'Conteúdo indisponível sem conexão';

  @override
  String get docsNotOfflineBody => 'Conecte-se para consultar este documento.';

  @override
  String get docsSignatureUnsigned => 'Sem assinatura';

  @override
  String get docsSignaturePending => 'Pendente de validação';

  @override
  String get docsSignatureValidated => 'Validado';

  @override
  String get docsFavoriteAdd => 'Marcar como favorito';

  @override
  String get docsFavoriteRemove => 'Remover dos favoritos';

  @override
  String get docsFavoriteFailed => 'Não foi possível atualizar o favorito.';

  @override
  String get docsDetailTitle => 'Documento';

  @override
  String get docsFieldType => 'Tipo documental';

  @override
  String get docsFieldCategory => 'Categoria';

  @override
  String get docsFieldDescription => 'Descrição';

  @override
  String get docsFieldFolder => 'Pasta';

  @override
  String get docsFieldOwner => 'Proprietário';

  @override
  String get docsFieldVersion => 'Versão vigente';

  @override
  String get docsFieldModified => 'Última modificação';

  @override
  String get docsFieldModifiedBy => 'Modificado por';

  @override
  String get docsFieldSize => 'Tamanho';

  @override
  String get docsFieldFormat => 'Formato';

  @override
  String get docsNoCategory => 'Sem categoria';

  @override
  String get docsFolderRoot => 'Nível inicial da concessão';

  @override
  String get docsNoDescription => 'Sem descrição';

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
    return 'Datas no horário de $zone ($offset)';
  }

  @override
  String get docsPreviewOpen => 'Visualizar';

  @override
  String get docsPreviewTitle => 'Pré-visualização';

  @override
  String get docsPreviewNoneNote =>
      'Este formato não tem pré-visualização no app.';

  @override
  String get docsPreviewUnavailableTitle => 'Pré-visualização indisponível';

  @override
  String get docsPreviewUnavailableBody =>
      'Este formato não pode ser exibido no app.';

  @override
  String get docsPreviewPdfError => 'Não foi possível exibir o PDF.';

  @override
  String docsPdfPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get docsPdfZoomIn => 'Aproximar';

  @override
  String get docsPdfZoomOut => 'Afastar';

  @override
  String docsFromPhone(String date) {
    return 'Sem conexão · salvo no telefone em $date';
  }

  @override
  String get docsSignAction => 'Assinar';

  @override
  String get docsSignConfirmTitle => 'Assinar este documento?';

  @override
  String docsSignConfirmBody(String name, String version) {
    return 'Você vai assinar «$name», versão $version. A assinatura fica registrada com seu nome, seu perfil e a data, e não pode ser desfeita.';
  }

  @override
  String get docsSignConfirmOffline =>
      'Sem conexão: a assinatura ficará pendente e será aplicada ao sincronizar, somente se o documento não mudou.';

  @override
  String get docsSignConfirmButton => 'Assinar';

  @override
  String get docsSignDone => 'Documento assinado.';

  @override
  String get docsSignQueued =>
      'Assinatura salva. Será aplicada ao sincronizar.';

  @override
  String get docsSignPending => 'Assinatura pendente de sincronização';

  @override
  String get docsSignAttention =>
      'A assinatura pendente precisa da sua decisão na central de sincronização.';

  @override
  String get docsSignAlready => 'Esta versão já foi assinada por outra pessoa.';

  @override
  String get docsSignMismatch =>
      'O arquivo não corresponde ao hash da versão: não é possível assinar. Avise um administrador.';

  @override
  String get docsSignProfile =>
      'Assinar exige um perfil assinante nesta concessão.';

  @override
  String get docsSignFailed => 'Não foi possível assinar. Tente novamente.';

  @override
  String get fieldLastSync => 'Última sincronização';

  @override
  String get docsPreviewImageError => 'Não foi possível exibir a imagem.';

  @override
  String get docsUploadAction => 'Carregar documento';

  @override
  String get docsUploadTitle => 'Carregar documento';

  @override
  String get docsUploadPickFiles => 'Escolher arquivos';

  @override
  String get docsUploadTakePhoto => 'Tirar foto';

  @override
  String get docsUploadNoFiles =>
      'Escolha um ou vários arquivos, ou tire uma foto.';

  @override
  String get docsUploadFileName => 'Nome';

  @override
  String get docsUploadRemove => 'Remover arquivo';

  @override
  String get docsUploadType => 'Tipo documental';

  @override
  String get docsUploadCategory => 'Categoria (opcional)';

  @override
  String get docsUploadFolder => 'Pasta (opcional)';

  @override
  String get docsUploadNoCategory => 'Sem categoria';

  @override
  String get docsUploadRoot => 'Nível inicial';

  @override
  String get docsUploadDescription => 'Descrição (opcional)';

  @override
  String get docsUploadDescriptionOther =>
      'Descrição (obrigatória para «Outro»)';

  @override
  String get docsUploadSave => 'Salvar documento';

  @override
  String get docsUploadSaving => 'Salvando…';

  @override
  String get docsUploadOfflineNote =>
      'É salvo no dispositivo e enviado quando houver conexão. Não é um documento do servidor até ser confirmado.';

  @override
  String get docsUploadSaveFailed =>
      'Alguns arquivos não puderam ser salvos no telefone. Continuam aqui para você tentar novamente.';

  @override
  String get docsIssueNoFile => 'Escolha pelo menos um arquivo.';

  @override
  String get docsIssueEmptyFile => 'O arquivo está vazio.';

  @override
  String get docsIssueBlocked => 'Este tipo de arquivo não é permitido.';

  @override
  String get docsIssueNameEmpty => 'Digite um nome.';

  @override
  String get docsIssueNameInvalid =>
      'O nome não pode ter < > : \" / \\ | ? * nem terminar em ponto.';

  @override
  String get docsIssueNameTooLong =>
      'O nome passa de 255 caracteres: encurte-o.';

  @override
  String get docsIssueTypeMissing => 'Escolha o tipo documental.';

  @override
  String get docsIssueDescriptionRequired =>
      'Para o tipo «Outro», escreva uma descrição de pelo menos 10 caracteres.';

  @override
  String get docsIssueDescriptionTooLong =>
      'A descrição passa de 2000 caracteres.';

  @override
  String get docsUploadDoneTitle => 'Salvo no dispositivo';

  @override
  String docsUploadDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos pendentes de sincronização. Não estarão no servidor até serem confirmados.',
      one:
          '1 documento pendente de sincronização. Não estará no servidor até ser confirmado.',
    );
    return '$_temp0';
  }

  @override
  String get docsUploadDoneSync => 'Ver pendentes';

  @override
  String get docsUploadDoneBack => 'Voltar à lista';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get mapTabTickets => 'Registros';

  @override
  String get mapTabInventory => 'Cadastro';

  @override
  String get mapTabMaintenance => 'Manutenção';

  @override
  String get mapTabWorks => 'Obras';

  @override
  String get mapFilters => 'Filtros';

  @override
  String mapFiltersCount(int count) {
    return 'Filtros ($count)';
  }

  @override
  String get mapFiltersTitle => 'Filtrar o mapa';

  @override
  String get mapFilterCategory => 'Categoria';

  @override
  String get mapFilterStatus => 'Situação';

  @override
  String get mapFilterAll => 'Todos';

  @override
  String get mapStatusNormal => 'Normal';

  @override
  String get mapStatusAttention => 'Atenção';

  @override
  String get mapStatusCritical => 'Crítico';

  @override
  String get mapFilterClear => 'Limpar filtros';

  @override
  String get mapFilterDone => 'Pronto';

  @override
  String get mapSampleBanner =>
      'Dados de exemplo: o servidor ainda não publica o mapa.';

  @override
  String mapSegmentTitle(String code) {
    return 'Trecho $code';
  }

  @override
  String get mapDirectionIncreasing => 'Sentido crescente';

  @override
  String get mapDirectionDecreasing => 'Sentido decrescente';

  @override
  String mapSegmentRange(String from, String to) {
    return '$from a $to';
  }

  @override
  String mapSegmentLayerCount(String layer, int count) {
    return '$layer: $count neste trecho';
  }

  @override
  String mapFromPhone(String date) {
    return 'Sem conexão · pins salvos no telefone em $date';
  }

  @override
  String get mapNoTiles => 'Sem mapa base configurado';

  @override
  String get mapLoading => 'Carregando o mapa';

  @override
  String get mapEmpty => 'Não há itens nesta aba.';

  @override
  String get mapEmptyFiltered => 'Nenhum item corresponde aos filtros.';

  @override
  String get mapErrorTitle => 'Não foi possível carregar o mapa';

  @override
  String get mapErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get mapRetry => 'Tentar novamente';

  @override
  String get mapUnavailableTitle => 'O mapa ainda não está disponível';

  @override
  String get mapUnavailableBody =>
      'Sua concessão ainda não tem o mapa publicado. Será ativado quando o servidor o oferecer.';

  @override
  String get mapNoPermissionTitle => 'Sem permissão para ver esta aba';

  @override
  String get mapNoPermissionBody =>
      'Seu perfil não pode consultar esta informação. Peça acesso a um administrador.';

  @override
  String get mapLocate => 'Minha localização';

  @override
  String get mapLocating => 'Buscando sua localização…';

  @override
  String get mapLocateServiceOff =>
      'O GPS está desligado. Ligue-o para se localizar.';

  @override
  String get mapLocateDenied =>
      'Precisamos da permissão de localização para localizar você.';

  @override
  String get mapLocateDeniedForever =>
      'A permissão de localização está bloqueada. Ative-a em Configurações.';

  @override
  String get mapLocateUnavailable =>
      'Não foi possível obter sua localização. Tente novamente ao ar livre.';

  @override
  String get mapOpenSettings => 'Abrir configurações';

  @override
  String mapAccuracy(String meters) {
    return 'Precisão ±$meters m';
  }

  @override
  String mapAccuracyLow(String meters, String max) {
    return 'Precisão baixa (±$meters m). Para salvar uma localização é preciso $max m ou menos.';
  }

  @override
  String get mapMockedLocation =>
      'A localização parece simulada: não será usada para salvar dados.';

  @override
  String get mapNearby => 'Próximos';

  @override
  String get mapNearbyTitle => 'Ativos próximos';

  @override
  String get mapNearbyRadius => 'Raio';

  @override
  String mapNearbyEmpty(String radius) {
    return 'Não há ativos a menos de $radius de você.';
  }

  @override
  String get mapNearbyNeedLocation =>
      'Toque em «Minha localização» para ver os ativos próximos.';

  @override
  String get mapNearbyLoading => 'Carregando o cadastro…';

  @override
  String mapDistanceMeters(String value) {
    return '$value m';
  }

  @override
  String mapDistanceKm(String value) {
    return '$value km';
  }

  @override
  String get mapDetailReference => 'Referência';

  @override
  String mapDetailDistance(String distance) {
    return 'A $distance de você';
  }

  @override
  String get mapDetailClose => 'Fechar';

  @override
  String get mapActionsSoon =>
      'Criar um registro, uma monitoração ou uma manutenção a partir daqui será habilitado quando esses módulos estiverem disponíveis.';

  @override
  String get mapPacksTitle => 'Mapas sem conexão';

  @override
  String get mapPacksAction => 'Mapas sem conexão';

  @override
  String get mapPacksIntro =>
      'Baixe o mapa da sua concessão para vê-lo sem internet. Recomenda-se usar Wi-Fi: os pacotes pesam dezenas de megabytes. São apagados ao trocar de concessão ou encerrar a sessão.';

  @override
  String get mapPacksEmpty =>
      'O servidor não tem mapas para baixar nesta concessão.';

  @override
  String get mapPacksUnavailableTitle =>
      'Os mapas sem conexão ainda não estão disponíveis';

  @override
  String get mapPacksUnavailableBody =>
      'O servidor ainda não os publica para a sua concessão.';

  @override
  String get mapPacksNoPermissionTitle => 'Sem permissão para baixar mapas';

  @override
  String get mapPacksNoPermissionBody =>
      'Seu perfil não pode baixar mapas. Peça acesso a um administrador.';

  @override
  String get mapPacksErrorTitle => 'Não foi possível carregar os mapas';

  @override
  String get mapPacksErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get mapPacksListOffline =>
      'Sem conexão: são exibidos apenas os mapas salvos no telefone.';

  @override
  String mapPackVersion(int version) {
    return 'Versão $version';
  }

  @override
  String mapPackZoom(int min, int max) {
    return 'Aproximação $min a $max';
  }

  @override
  String get mapPackInstalled => 'Salvo no telefone';

  @override
  String get mapPackUpdateAvailable => 'Há uma versão nova';

  @override
  String mapPackPaused(String size) {
    return 'Pausado · $size baixados';
  }

  @override
  String mapPackDownloading(int percent) {
    return 'Baixando… $percent %';
  }

  @override
  String get mapPackVerifying => 'Verificando o arquivo…';

  @override
  String get mapPackDownload => 'Baixar';

  @override
  String get mapPackResume => 'Retomar';

  @override
  String get mapPackUpdate => 'Atualizar';

  @override
  String get mapPackPause => 'Pausar';

  @override
  String get mapPackDiscard => 'Descartar o baixado';

  @override
  String get mapPackDelete => 'Apagar';

  @override
  String get mapPackDeleteTitle => 'Apagar o mapa sem conexão?';

  @override
  String mapPackDeleteBody(String size) {
    return 'Serão liberados $size do telefone. Você poderá baixá-lo novamente.';
  }

  @override
  String get mapPackCancel => 'Cancelar';

  @override
  String get mapPackErrNetwork =>
      'A conexão caiu. Você pode retomar o download.';

  @override
  String get mapPackErrCorrupt =>
      'O arquivo baixado não corresponde ao original e foi descartado. Tente novamente.';

  @override
  String get mapPackErrNoSpace => 'Não há espaço suficiente no telefone.';

  @override
  String get mapPackErrNotFound =>
      'Este mapa não está mais disponível no servidor.';

  @override
  String get mapPackErrServer =>
      'O servidor não conseguiu entregar o mapa. Tente mais tarde.';

  @override
  String get mapPackErrPermission => 'Seu perfil não pode baixar mapas.';

  @override
  String mapOfflineBadge(String name) {
    return 'Mapa sem conexão · $name';
  }

  @override
  String get navTabMap => 'Mapa';

  @override
  String get navTabTicket => 'Registro';

  @override
  String get navTabMenu => 'Menu';

  @override
  String get navTabInventory => 'Cadastro';

  @override
  String get navTabMaintenance => 'Manutenção';

  @override
  String mapLayerSubtitle(String layer) {
    return 'Camada: $layer';
  }

  @override
  String mapResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos encontrados',
      one: '1 elemento encontrado',
      zero: 'Nenhum elemento encontrado',
    );
    return '$_temp0';
  }

  @override
  String get mapRefine => 'Refinar busca';

  @override
  String get ticketsTitle => 'Histórico de registros';

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
  String get ticketsFilterStatus => 'Status';

  @override
  String get ticketsFilterClear => 'Limpar filtros';

  @override
  String get ticketsFilterDone => 'Pronto';

  @override
  String get ticketsDueSort => 'Vencimento';

  @override
  String get ticketsFilterAll => 'Todos';

  @override
  String get ticketsFilterOpen => 'Abertos';

  @override
  String get ticketsFilterAttended => 'Atendidos';

  @override
  String get ticketsNew => 'Novo registro';

  @override
  String get ticketStatusOpen => 'Aberto';

  @override
  String get ticketStatusAttended => 'Atendido';

  @override
  String get ticketsEmpty => 'Nenhum registro corresponde aos filtros.';

  @override
  String get ticketsEmptyAll => 'Ainda não há registros.';

  @override
  String get ticketsUnavailableTitle => 'Registros ainda não disponíveis';

  @override
  String get ticketsUnavailableBody =>
      'O servidor ainda não publica os registros desta concessão.';

  @override
  String get ticketsErrorTitle => 'Não foi possível carregar os registros';

  @override
  String get ticketsErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get ticketsNoPermissionTitle => 'Sem acesso a registros';

  @override
  String get ticketsNoPermissionBody => 'Seu perfil não pode ver os registros.';

  @override
  String get ticketsRetry => 'Tentar novamente';

  @override
  String get ticketsSampleBanner =>
      'Dados de exemplo: não são registros reais.';

  @override
  String ticketDueHours(int n) {
    return '$n h';
  }

  @override
  String ticketDueDays(int n) {
    return '$n d';
  }

  @override
  String get ticketDueCaption => 'para vencer';

  @override
  String get ticketOverdueCaption => 'vencido';

  @override
  String get ticketBack => 'Voltar';

  @override
  String ticketIdLabel(String code) {
    return 'ID REGISTRO #$code';
  }

  @override
  String ticketCreatedOn(String date) {
    return 'Criado em $date';
  }

  @override
  String get ticketInfoGeneratedBy => 'Gerado por';

  @override
  String get ticketInfoProfile => 'Perfil do usuário';

  @override
  String get ticketInfoConcession => 'Concessionária';

  @override
  String get ticketInfoCompany => 'Empresa do usuário';

  @override
  String get ticketInfoLatitude => 'Latitude';

  @override
  String get ticketInfoLongitude => 'Longitude';

  @override
  String get ticketInfoChainage => 'Quilometragem';

  @override
  String get ticketInfoBody => 'Pista';

  @override
  String get ticketTypeTitle => 'Tipo de registro';

  @override
  String get ticketDescriptionTitle => 'Descrição';

  @override
  String get ticketFollowUpsTitle => 'Acompanhamentos';

  @override
  String get ticketFollowUpsEmpty => 'Ainda não há acompanhamentos.';

  @override
  String get ticketActionDownload => 'Baixar';

  @override
  String get ticketActionEdit => 'Editar';

  @override
  String get ticketActionFollowUp => 'Adicionar acompanhamento';

  @override
  String get ticketActionSoon => 'Esta ação estará disponível em breve.';

  @override
  String get ticketNotFound => 'Registro não encontrado.';

  @override
  String get followUpTitle => 'Acompanhamento do registro';

  @override
  String get followUpDate => 'Data';

  @override
  String get followUpTime => 'Hora';

  @override
  String get followUpStatus => 'Status do registro';

  @override
  String get followUpSelect => 'Selecionar';

  @override
  String get followUpDescription => 'Descrição';

  @override
  String get followUpFillIn => 'Preencha as informações';

  @override
  String get followUpPhotos => 'Fotografias';

  @override
  String followUpPhoto(int n) {
    return 'Foto $n';
  }

  @override
  String get followUpPhotoRemove => 'Remover foto';

  @override
  String get followUpSave => 'Salvar acompanhamento';

  @override
  String get followUpSaved => 'Acompanhamento salvo.';

  @override
  String get followUpErrorStatus => 'Escolha o status do registro.';

  @override
  String get followUpErrorDescription => 'Escreva uma descrição.';

  @override
  String ticketSavedPartly(String reason) {
    return 'O registro foi salvo, mas faltou uma parte: $reason';
  }

  @override
  String get ticketSaveFailed => 'Não foi possível salvar. Tente novamente.';

  @override
  String get newTicketPriority => 'Prioridade';

  @override
  String get ticketPriorityLow => 'Baixa';

  @override
  String get ticketPriorityMedium => 'Média';

  @override
  String get ticketPriorityHigh => 'Alta';

  @override
  String get ticketPriorityCritical => 'Crítica';

  @override
  String get newTicketTitle => 'Novo registro';

  @override
  String get newTicketName => 'Título';

  @override
  String get newTicketCategory => 'Tipo de registro';

  @override
  String get newTicketChainage => 'Quilometragem (km)';

  @override
  String get newTicketCreate => 'Criar registro';

  @override
  String get newTicketCreated => 'Registro criado.';

  @override
  String get newTicketErrorTitle => 'Escreva um título.';

  @override
  String get newTicketErrorCategory => 'Escolha o tipo de registro.';

  @override
  String get accidentsTitle => 'Acidentes';

  @override
  String get accidentsSearchHint => 'Buscar por título, ID, km…';

  @override
  String get accidentsSearchTooltip => 'Buscar';

  @override
  String get accidentsFilterTooltip => 'Filtrar';

  @override
  String get accidentsNew => 'Novo acidente';

  @override
  String get accidentsEmpty => 'Nenhum acidente corresponde aos filtros.';

  @override
  String get accidentsEmptyAll => 'Ainda não há acidentes registrados.';

  @override
  String get accidentsUnavailableTitle => 'Acidentes ainda não disponíveis';

  @override
  String get accidentsUnavailableBody =>
      'O servidor ainda não publica os acidentes desta concessão.';

  @override
  String get accidentsErrorTitle => 'Não foi possível carregar os acidentes';

  @override
  String get accidentsErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get accidentsNoPermissionTitle => 'Sem acesso a acidentes';

  @override
  String get accidentsNoPermissionBody =>
      'Seu perfil não pode ver os acidentes.';

  @override
  String get accidentsRetry => 'Tentar novamente';

  @override
  String get accidentsSampleBanner =>
      'Dados de exemplo: não são acidentes reais.';

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
  String get accidentsFilterTitle => 'Filtrar acidentes';

  @override
  String get accidentsFilterSeverity => 'Gravidade';

  @override
  String get accidentTypeCollision => 'Colisão';

  @override
  String get accidentTypeRollover => 'Capotamento';

  @override
  String get accidentTypeFire => 'Incêndio';

  @override
  String get accidentStatusRegistered => 'Registrado';

  @override
  String get accidentStatusInProgress => 'Em andamento';

  @override
  String get accidentStatusClosed => 'Fechado';

  @override
  String accidentIdLabel(String code) {
    return 'ID ACIDENTE #$code';
  }

  @override
  String get accidentTypeTitle => 'Tipo de acidente';

  @override
  String get accidentSeverityTitle => 'Gravidade';

  @override
  String get accidentNotFound => 'Acidente não encontrado.';

  @override
  String get newAccidentTitle => 'Novo acidente';

  @override
  String get newAccidentCreate => 'Registrar acidente';

  @override
  String get newAccidentCreated => 'Acidente registrado.';

  @override
  String get newAccidentErrorType => 'Escolha o tipo de acidente.';

  @override
  String get newAccidentErrorSeverity => 'Escolha a gravidade.';

  @override
  String get maintIndicatorsTitle => 'Selecione um indicador';

  @override
  String get fieldTeam => 'Equipe';

  @override
  String get profilePhotoChange => 'Alterar foto';

  @override
  String get accountPanelTitle => 'Configurações da conta';

  @override
  String get accountMyAccount => 'Minha conta';

  @override
  String get accountSettingsTitle => 'Configuração';

  @override
  String get accountSettingsSub => 'Segurança, preferências e dispositivo';

  @override
  String get accountDeviceSection => 'Sobre o dispositivo';

  @override
  String get indicatorsPanelTitle => 'Indicadores';

  @override
  String get indicatorsPanelSubtitle => 'Manutenção e conservação';

  @override
  String get indicatorsSearchHint => 'Buscar indicador';

  @override
  String get indicatorsNoMatch => 'Nenhum indicador corresponde.';

  @override
  String get homeOpenMenu => 'Abrir menu';

  @override
  String get homeSummaryTickets => 'Registros abertos';

  @override
  String homeSummaryOverdue(int count) {
    return '$count vencidos';
  }

  @override
  String get homeSummaryOnTime => 'Em dia';

  @override
  String get homeSummaryAssets => 'Ativos';

  @override
  String get homeSummaryAccidents => 'Acidentes';

  @override
  String get homeSummaryAlerts => 'Alertas';

  @override
  String homeSummaryUnread(int count) {
    return '$count não lidos';
  }

  @override
  String homeSummaryInProgress(int count) {
    return '$count em andamento';
  }

  @override
  String get maintIndSgp => 'Pavimentos';

  @override
  String get maintIndSgs => 'Sinalização';

  @override
  String get maintIndSgoae => 'OAEs';

  @override
  String get maintIndSgoac => 'OACs';

  @override
  String get maintIndSgits => 'Equipamentos ITS';

  @override
  String get maintIndSgf => 'Faixa de domínio';

  @override
  String get maintIndSgtec => 'Terraplenos e estruturas';

  @override
  String get maintIndSge => 'Edificações e instalações';

  @override
  String get maintTitle => 'Manutenção';

  @override
  String get maintSubtitle =>
      'Consulta e gestão da infraestrutura da concessão';

  @override
  String get maintStatusOpen => 'Aberto';

  @override
  String get maintStatusInProgress => 'Em andamento';

  @override
  String get maintStatusClosed => 'Fechado';

  @override
  String get maintStatTotal => 'Total';

  @override
  String get maintStatTotalCaption => '100% total';

  @override
  String get maintStatOpen => 'Abertos';

  @override
  String get maintStatInProgress => 'Em andamento';

  @override
  String get maintStatClosed => 'Fechados';

  @override
  String maintStatShare(String percent) {
    return '$percent% do total';
  }

  @override
  String get maintFilterState => 'Status';

  @override
  String get maintFilterAllStates => 'Todos';

  @override
  String get maintDateHint => 'DD/MM/AAAA';

  @override
  String get maintDateFrom => 'Data inicial';

  @override
  String get maintDateTo => 'Data final';

  @override
  String get maintFilterClear => 'Limpar filtros';

  @override
  String get maintSearchTooltip => 'Buscar';

  @override
  String get maintSearchHint => 'Buscar por local ou atividade…';

  @override
  String get maintFilterTooltip => 'Filtrar';

  @override
  String get maintEmpty => 'Nenhuma manutenção corresponde aos filtros.';

  @override
  String get maintEmptyAll => 'Não há manutenções para este indicador.';

  @override
  String get maintUnavailableTitle => 'Manutenção ainda não disponível';

  @override
  String get maintUnavailableBody =>
      'O servidor ainda não publica a manutenção desta concessão.';

  @override
  String get maintErrorTitle => 'Não foi possível carregar a manutenção';

  @override
  String get maintErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get maintNoPermissionTitle => 'Sem acesso a manutenção';

  @override
  String get maintNoPermissionBody => 'Seu perfil não pode ver este indicador.';

  @override
  String get maintRetry => 'Tentar novamente';

  @override
  String get maintProgressTitle => 'Registrar avanço';

  @override
  String get maintProgressPercent =>
      'Avanço acumulado (%), se não souber o volume';

  @override
  String get maintProgressVolume => 'Volume executado neste acompanhamento';

  @override
  String maintProgressVolumeUnit(String unit) {
    return 'Volume executado neste acompanhamento ($unit)';
  }

  @override
  String get maintProgressNotes => 'Notas';

  @override
  String get maintProgressOptional => 'Opcional';

  @override
  String get maintProgressSave => 'Salvar avanço';

  @override
  String get maintProgressSaved => 'Avanço salvo.';

  @override
  String get maintProgressErrorPercent => 'Digite um avanço entre 0 e 100.';

  @override
  String get maintProgressErrorVolume => 'Digite um volume maior que 0.';

  @override
  String get maintProgressNetwork =>
      'Sem conexão. Verifique sua rede e tente novamente.';

  @override
  String get maintProgressNoPermission =>
      'Seu perfil não pode registrar avanços.';

  @override
  String get maintProgressFailed =>
      'Não foi possível salvar o avanço. Tente novamente.';

  @override
  String get maintSampleBanner =>
      'Dados de exemplo: não são manutenções reais.';

  @override
  String maintTotalVolume(String value) {
    return 'Volume Total: $value';
  }

  @override
  String maintUnitDescription(String unit) {
    return 'Descrição: $unit';
  }

  @override
  String get maintProgress => 'Avanço';

  @override
  String maintActivity(String activity) {
    return 'Atividade: $activity';
  }

  @override
  String get maintProjectProgress => 'Avanço do projeto';

  @override
  String get maintExecutedAmount => 'Valor Exec.';

  @override
  String get maintPendingAmount => 'A Executar';

  @override
  String get maintDetailsTitle => 'Detalhes da manutenção';

  @override
  String get maintKmStart => 'Km inicial';

  @override
  String get maintKmEnd => 'Km final';

  @override
  String get maintDirection => 'Direção';

  @override
  String get maintSense => 'Sentido';

  @override
  String get maintVolumeTotal => 'Volume total';

  @override
  String get maintVolumeExecuted => 'Volume executado';

  @override
  String get maintUnitCost => 'Custo unitário';

  @override
  String get maintProgrammedAmount => 'Valor programado';

  @override
  String get maintStartDate => 'Data início';

  @override
  String get maintEndDate => 'Data fim';

  @override
  String get maintNotFound => 'Manutenção não encontrada.';

  @override
  String get invTitle => 'Cadastro';

  @override
  String get invSubtitle => 'Ativos da concessão';

  @override
  String get invSearchTooltip => 'Buscar';

  @override
  String get invSearchHint => 'Buscar ativo, trecho ou quilômetro';

  @override
  String get invFilterClear => 'Limpar filtros';

  @override
  String get invSampleBanner => 'Dados de exemplo: não são ativos reais.';

  @override
  String get invStatTotal => 'Total';

  @override
  String get invStatTotalCaption => '100% total';

  @override
  String invStatShare(String percent) {
    return '$percent% do total';
  }

  @override
  String get invStatGood => 'Bons';

  @override
  String get invStatRegular => 'Regulares';

  @override
  String get invStatPoor => 'Ruins';

  @override
  String get invConditionGood => 'Bom';

  @override
  String get invConditionRegular => 'Regular';

  @override
  String get invConditionPoor => 'Ruim';

  @override
  String get invConditionUnknown => 'Não avaliado';

  @override
  String get invSitePhoto => 'Vista no local';

  @override
  String get invFilterCondition => 'Estado';

  @override
  String get invFilterAllConditions => 'Todos os estados';

  @override
  String get invFilterCategory => 'Tipo';

  @override
  String get invFilterAllCategories => 'Todos os tipos';

  @override
  String get invInspectedFrom => 'Monitoração desde';

  @override
  String get invInspectedTo => 'Monitoração até';

  @override
  String get invDateHint => 'Data';

  @override
  String get invEmptyAll => 'Ainda não há ativos registrados.';

  @override
  String get invEmpty => 'Nenhum ativo corresponde aos filtros.';

  @override
  String get invUnavailableTitle => 'Cadastro indisponível';

  @override
  String get invUnavailableBody =>
      'Esta concessão ainda não publica seu cadastro no app.';

  @override
  String get invNoPermissionTitle => 'Sem acesso ao cadastro';

  @override
  String get invNoPermissionBody => 'Seu perfil não pode consultar o cadastro.';

  @override
  String get invNotFound => 'O ativo não existe mais.';

  @override
  String get invErrorTitle => 'Não foi possível carregar o cadastro';

  @override
  String get invErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get invRetry => 'Tentar novamente';

  @override
  String get invDetailTitle => 'Ativo';

  @override
  String get invDetailsTitle => 'Dados do ativo';

  @override
  String get invCategoryLabel => 'Tipo';

  @override
  String get invKm => 'Quilômetro';

  @override
  String get invSegment => 'Trecho';

  @override
  String get invDirection => 'Sentido';

  @override
  String get invInstalled => 'Instalação';

  @override
  String get invLastInspection => 'Última monitoração';

  @override
  String get invCoordinates => 'Coordenadas';

  @override
  String get invNotes => 'Observações';

  @override
  String get invViewOnMap => 'Ver no mapa';

  @override
  String get invNoLocation => 'Este ativo não tem localização.';

  @override
  String invCardInspected(String date) {
    return 'Monitoração: $date';
  }

  @override
  String get repTitle => 'Indicadores e relatórios';

  @override
  String get repSelectTitle => 'Selecione um indicador';

  @override
  String get repReportSubtitle => 'Relatório do indicador';

  @override
  String get repSampleBanner =>
      'Dados de exemplo: o relatório sai de manutenções de exemplo.';

  @override
  String get repFrom => 'De';

  @override
  String get repTo => 'Até';

  @override
  String get repDateHint => 'Data';

  @override
  String get repGenerate => 'Gerar relatório';

  @override
  String get repRegenerate => 'Atualizar relatório';

  @override
  String get repNotGenerated =>
      'Escolha o período e gere o relatório. Sem datas, inclui todo o histórico.';

  @override
  String repGeneratedAt(String date) {
    return 'Gerado: $date';
  }

  @override
  String get repPeriodAll => 'Todo o histórico';

  @override
  String repPeriodRange(String from, String to) {
    return 'De $from a $to';
  }

  @override
  String repPeriodFrom(String from) {
    return 'Desde $from';
  }

  @override
  String repPeriodUntil(String to) {
    return 'Até $to';
  }

  @override
  String get repStale => 'Você mudou o período: atualize o relatório.';

  @override
  String get repSummaryTitle => 'Resumo';

  @override
  String get repTotal => 'Total';

  @override
  String get repStatusOpen => 'Abertos';

  @override
  String get repStatusInProgress => 'Em andamento';

  @override
  String get repStatusClosed => 'Encerrados';

  @override
  String get repExecution => 'Execução do valor';

  @override
  String get repProgrammedAmount => 'Programado';

  @override
  String get repExecutedAmount => 'Executado';

  @override
  String get repPendingAmount => 'A executar';

  @override
  String get repOrdersTitle => 'Manutenções do período';

  @override
  String get repEmpty => 'Não há manutenções deste indicador no período.';

  @override
  String get repUnavailableTitle => 'Relatórios indisponíveis';

  @override
  String get repUnavailableBody =>
      'Esta concessão ainda não publica os dados para os relatórios.';

  @override
  String get repNoPermissionTitle => 'Sem acesso ao relatório';

  @override
  String get repNoPermissionBody =>
      'Seu perfil não pode consultar este indicador.';

  @override
  String get repErrorTitle => 'Não foi possível gerar o relatório';

  @override
  String get repErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get repRetry => 'Tentar novamente';

  @override
  String get dashTitle => 'Dashboard';

  @override
  String get dashSubtitle => 'Resumo operacional';

  @override
  String get dashSampleBanner =>
      'Dados de exemplo: o resumo sai dos módulos de exemplo.';

  @override
  String dashUpdated(String date) {
    return 'Atualizado: $date';
  }

  @override
  String get dashViewMap => 'Ver mapa';

  @override
  String get dashTickets => 'Registros';

  @override
  String get dashTicketsOpen => 'Abertos';

  @override
  String get dashTicketsAttended => 'Atendidos';

  @override
  String get dashTicketsOverdue => 'Vencidos';

  @override
  String get dashAccidents => 'Acidentes';

  @override
  String dashAccidentsPeriod(int days) {
    return 'Últimos $days dias';
  }

  @override
  String get dashAccidentsTotal => 'Registrados';

  @override
  String get dashAccidentsSevere => 'Graves';

  @override
  String get dashAccidentsOpen => 'Em acompanhamento';

  @override
  String get dashMaintenance => 'Manutenção';

  @override
  String get dashMaintOpen => 'Abertas';

  @override
  String get dashMaintInProgress => 'Em andamento';

  @override
  String get dashMaintClosed => 'Encerradas';

  @override
  String dashMaintExecution(String percent) {
    return 'Execução do valor: $percent';
  }

  @override
  String get dashInventory => 'Cadastro';

  @override
  String dashInventoryTotal(int count) {
    return '$count ativos';
  }

  @override
  String get dashInvGood => 'Bons';

  @override
  String get dashInvRegular => 'Regulares';

  @override
  String get dashInvPoor => 'Ruins';

  @override
  String get dashSectionUnavailable => 'Ainda não disponível nesta concessão.';

  @override
  String get dashSectionNoPermission =>
      'Seu perfil não tem acesso a este módulo.';

  @override
  String get dashSectionError => 'Não foi possível carregar esta informação.';

  @override
  String get dashRetry => 'Tentar novamente';

  @override
  String get dashErrorTitle => 'Não foi possível carregar o dashboard';

  @override
  String get dashErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get dashUnavailableTitle => 'Dashboard indisponível';

  @override
  String get dashUnavailableBody =>
      'Esta concessão ainda não publica dados para o resumo.';

  @override
  String get workTitle => 'Obras';

  @override
  String get workSubtitle => 'Andamento de obras e conservação';

  @override
  String get workSearchTooltip => 'Buscar';

  @override
  String get workSearchHint => 'Buscar obra, empreiteira ou trecho';

  @override
  String get workFilterClear => 'Limpar filtros';

  @override
  String get workSampleBanner => 'Dados de exemplo: não são obras reais.';

  @override
  String get workStatTotal => 'Total';

  @override
  String get workStatTotalCaption => 'obras';

  @override
  String get workStatNotStarted => 'A iniciar';

  @override
  String get workStatInProgress => 'Em execução';

  @override
  String get workStatDelayed => 'Atrasadas';

  @override
  String get workStatFinished => 'Concluídas';

  @override
  String get workStatusNotStarted => 'A iniciar';

  @override
  String get workStatusInProgress => 'Em execução';

  @override
  String get workStatusDelayed => 'Atrasada';

  @override
  String get workStatusFinished => 'Concluída';

  @override
  String get workFilterState => 'Estado';

  @override
  String get workFilterAllStates => 'Todos os estados';

  @override
  String get workEmptyAll => 'Ainda não há obras registradas.';

  @override
  String get workEmpty => 'Nenhuma obra corresponde aos filtros.';

  @override
  String get workUnavailableTitle => 'Obras indisponíveis';

  @override
  String get workUnavailableBody =>
      'Esta concessão ainda não publica suas obras no app.';

  @override
  String get workNoPermissionTitle => 'Sem acesso às obras';

  @override
  String get workNoPermissionBody => 'Seu perfil não pode consultar as obras.';

  @override
  String get workNotFound => 'A obra não existe mais.';

  @override
  String get workErrorTitle => 'Não foi possível carregar as obras';

  @override
  String get workErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get workRetry => 'Tentar novamente';

  @override
  String get workDetailTitle => 'Obra';

  @override
  String get workPhysical => 'Avanço físico';

  @override
  String get workProgrammed => 'Avanço programado';

  @override
  String workLag(String percent) {
    return 'Atraso: $percent';
  }

  @override
  String get workOnTrack => 'Em dia com o cronograma';

  @override
  String get workBudget => 'Orçamento';

  @override
  String get workExecutedAmount => 'Executado';

  @override
  String get workPendingAmount => 'A executar';

  @override
  String get workDetailsTitle => 'Dados da obra';

  @override
  String get workContractor => 'Empreiteira';

  @override
  String get workKmStart => 'Km inicial';

  @override
  String get workKmEnd => 'Km final';

  @override
  String get workSegment => 'Trecho';

  @override
  String get workDirection => 'Sentido';

  @override
  String get workStartDate => 'Início';

  @override
  String get workEndDate => 'Fim';

  @override
  String get workViewOnMap => 'Ver no mapa';

  @override
  String get workNoLocation => 'Esta obra não tem localização.';

  @override
  String get inspTitle => 'Monitoração';

  @override
  String get inspSubtitle => 'Atribuídas e em campo';

  @override
  String get inspSearchTooltip => 'Buscar';

  @override
  String get inspSearchHint => 'Buscar monitoração, ativo ou trecho';

  @override
  String get inspFilterClear => 'Limpar filtros';

  @override
  String get inspSampleBanner =>
      'Dados de exemplo: não são monitorações reais.';

  @override
  String get inspStatPending => 'Pendentes';

  @override
  String get inspStatInProgress => 'Em andamento';

  @override
  String get inspStatAttended => 'Atendidas';

  @override
  String get inspStatClosed => 'Encerradas';

  @override
  String get inspStatCaption => 'monitorações';

  @override
  String get inspStatusPending => 'Pendente';

  @override
  String get inspStatusInProgress => 'Em andamento';

  @override
  String get inspStatusAttended => 'Atendida';

  @override
  String get inspStatusClosed => 'Encerrada';

  @override
  String get inspStatusCancelled => 'Cancelada';

  @override
  String get inspFilterState => 'Estado';

  @override
  String get inspFilterAllStates => 'Todos os estados';

  @override
  String get inspEmptyAll => 'Você ainda não tem monitorações atribuídas.';

  @override
  String get inspEmpty => 'Nenhuma monitoração corresponde aos filtros.';

  @override
  String get inspUnavailableTitle => 'Monitoração indisponível';

  @override
  String get inspUnavailableBody =>
      'Esta concessão ainda não publica sua monitoração no app.';

  @override
  String get inspNoPermissionTitle => 'Sem acesso à monitoração';

  @override
  String get inspNoPermissionBody =>
      'Seu perfil não pode consultar a monitoração.';

  @override
  String get inspNotFound => 'A monitoração não existe mais.';

  @override
  String get inspErrorTitle => 'Não foi possível carregar a monitoração';

  @override
  String get inspErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get inspRetry => 'Tentar novamente';

  @override
  String get inspDetailTitle => 'Monitoração';

  @override
  String get inspChecklistTitle => 'Checklist';

  @override
  String inspChecklistProgress(int done, int total) {
    return '$done de $total pontos';
  }

  @override
  String get inspResultOk => 'Conforme';

  @override
  String get inspResultFinding => 'Achado';

  @override
  String get inspCritical => 'Crítico';

  @override
  String inspFindings(int count) {
    return '$count achados';
  }

  @override
  String inspCriticalFindings(int count) {
    return '$count críticos';
  }

  @override
  String get inspScheduled => 'Programada';

  @override
  String get inspCompletedOn => 'Concluída';

  @override
  String get inspAssignee => 'Responsável';

  @override
  String get inspType => 'Tipo';

  @override
  String get inspAsset => 'Ativo';

  @override
  String get inspKm => 'Quilômetro';

  @override
  String get inspSegment => 'Trecho';

  @override
  String get inspDirection => 'Sentido';

  @override
  String get inspComplete => 'Finalizar monitoração';

  @override
  String get inspCompleteHint =>
      'Responda todos os pontos para poder finalizar.';

  @override
  String get inspCompleted => 'Monitoração finalizada.';

  @override
  String get inspCompletedCritical =>
      'Monitoração finalizada. Há achados críticos: devem gerar um registro ou um alerta.';

  @override
  String get inspNotEditable =>
      'Esta monitoração não pode mais ser modificada.';

  @override
  String get inspIncomplete => 'Faltam pontos do checklist por responder.';

  @override
  String get inspSaveError => 'Não foi possível salvar. Tente novamente.';

  @override
  String get inspViewAsset => 'Ver ativo';

  @override
  String get inspNoAsset => 'Esta monitoração não tem um ativo do cadastro.';

  @override
  String get inspNew => 'Nova monitoração';

  @override
  String get inspNewCreate => 'Criar monitoração';

  @override
  String get inspNewType => 'Tipo de monitoração';

  @override
  String get inspNewName => 'Nome';

  @override
  String get inspNewNameHint => 'Opcional: se ficar vazio, usa-se o tipo';

  @override
  String get inspNewErrorType => 'Escolha o tipo de monitoração.';

  @override
  String get inspNewCreated => 'Monitoração criada.';

  @override
  String get inspNewNoTemplates => 'Não há tipos de monitoração disponíveis.';

  @override
  String get inspEvidenceTitle => 'Achados e evidências';

  @override
  String get inspEvidenceAdd => 'Adicionar achado';

  @override
  String get inspEvidenceEmpty => 'Ainda não há achados registrados.';

  @override
  String get inspEvidenceNote => 'Descrição do achado';

  @override
  String get inspEvidenceItem => 'Ponto do checklist';

  @override
  String get inspEvidenceNoItem => 'Sem ponto do checklist';

  @override
  String get inspEvidenceSave => 'Salvar achado';

  @override
  String get inspEvidenceErrorEmpty =>
      'Escreva uma descrição ou tire uma foto.';

  @override
  String get inspEvidenceSaved => 'Achado salvo.';

  @override
  String inspEvidencePhotos(int count) {
    return '$count fotos';
  }

  @override
  String inspEvidencePosition(String lat, String lon, String accuracy) {
    return 'Posição $lat, $lon (±$accuracy m)';
  }

  @override
  String get inspEvidenceNoPosition => 'Sem posição (GPS indisponível)';

  @override
  String get inspDraftSaved =>
      'Rascunho salvo: suas respostas são salvas automaticamente.';

  @override
  String get moduleInspections => 'Monitoração';

  @override
  String get moduleInspectionsSub => 'Checklists em campo';

  @override
  String get moduleWorks => 'Obras';

  @override
  String get moduleWorksSub => 'Andamento e programas';

  @override
  String get cfgGateTitle => 'Sem configuração da concessão';

  @override
  String get cfgGateBody =>
      'Para registrar você precisa da configuração da concessão e do seu fuso horário. Conecte-se à internet e sincronize.';

  @override
  String get cfgGateRetry => 'Sincronizar agora';

  @override
  String get cfgGateInspection =>
      'Sem a configuração da concessão você não pode responder a monitoração. Conecte-se e sincronize.';

  @override
  String get mapFilterOperating => 'Estado do equipamento';

  @override
  String get mapOpInOperation => 'Em operação';

  @override
  String get mapOpInMaintenance => 'Em manutenção';

  @override
  String get mapOpOutOfService => 'Fora de serviço';

  @override
  String get ticketLocationTitle => 'Localização';

  @override
  String ticketLocationAccuracy(String meters) {
    return 'Precisão ±$meters m';
  }

  @override
  String get ticketLocOriginGps => 'Leitura do GPS';

  @override
  String get ticketLocOriginLastKnown => 'Última posição conhecida';

  @override
  String get ticketLocOriginMapPoint => 'Ponto escolhido no mapa';

  @override
  String get ticketLocOriginAsset => 'Localização do ativo';

  @override
  String ticketLocationAgo(int minutes) {
    return 'de $minutes min atrás';
  }

  @override
  String ticketLocationAsset(String id) {
    return 'Ativo $id';
  }

  @override
  String get ticketLocationIssueTitle => 'Revise a localização';

  @override
  String ticketLocationLowAccuracy(String meters, String min) {
    return 'A precisão é de ±$meters m e o mínimo é de $min m. Salvar mesmo assim?';
  }

  @override
  String get ticketLocationLastKnownWarn =>
      'É a última posição conhecida, não uma leitura atual. Salvar mesmo assim?';

  @override
  String get ticketLocationSaveAnyway => 'Salvar mesmo assim';

  @override
  String get ticketLocationCancel => 'Cancelar';

  @override
  String get mapRecordHere => 'Registrar aqui';

  @override
  String get mapOpenRecord => 'Abrir ficha';

  @override
  String get mapCreateRecord => 'Criar registro';

  @override
  String get mapNavigate => 'Navegar';

  @override
  String get mapPickedTitle => 'Ponto escolhido';

  @override
  String get mapPickedClose => 'Remover ponto';

  @override
  String get mapPickHint =>
      'Mantenha pressionado o mapa para escolher um ponto.';

  @override
  String get mapNavigateFailed =>
      'Não foi possível abrir a navegação do telefone.';

  @override
  String get mapRecordMocked =>
      'A localização é simulada: não pode ser usada para registrar.';

  @override
  String get sessionLockedTitle => 'Sessão bloqueada';

  @override
  String sessionLockedBody(int minutes) {
    return 'Passaram $minutes minutos sem atividade. Confirme sua identidade para continuar.';
  }

  @override
  String get sessionUnlock => 'Desbloquear';

  @override
  String get sessionUnlockReason =>
      'Confirme sua identidade para desbloquear o SIGACO';

  @override
  String get sessionUnlockUnavailable =>
      'Este telefone não tem um bloqueio de tela para confirmar sua identidade. Encerre a sessão e entre novamente.';

  @override
  String get mfaRecoveryTitle => 'Guarde seus códigos de recuperação';

  @override
  String get mfaRecoveryBody =>
      'Se perder o telefone ou o aplicativo autenticador, cada um destes códigos permite entrar uma única vez. Guarde-os em local seguro: não serão exibidos novamente.';

  @override
  String get mfaRecoveryCopy => 'Copiar todos';

  @override
  String get mfaRecoveryCopied => 'Códigos copiados';

  @override
  String get mfaRecoverySaved => 'Já guardei';

  @override
  String get mfaUseRecoveryCode => 'Usar um código de recuperação';

  @override
  String get mfaUseAppCode => 'Usar o código do aplicativo';

  @override
  String get mfaRecoveryCodeHint => 'Código de recuperação';

  @override
  String mfaRecoveryRemaining(int count) {
    return 'Restam $count códigos de recuperação sem uso';
  }

  @override
  String get mfaRecoveryGenerate => 'Gerar novos códigos';

  @override
  String get mfaRecoveryGenerateBody =>
      'Os códigos anteriores deixarão de funcionar. Digite o código do seu aplicativo autenticador para confirmar.';

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get alertsSubtitle => 'Avisos da sua concessão';

  @override
  String get alertsMarkAll => 'Marcar todas como lidas';

  @override
  String get alertsFilterAll => 'Todas';

  @override
  String get alertsFilterUnread => 'Não lidas';

  @override
  String get alertsEmptyAll => 'Você não tem alertas.';

  @override
  String get alertsEmptyUnread => 'Você não tem alertas não lidos.';

  @override
  String get alertsUnavailableTitle => 'Alertas ainda não disponíveis';

  @override
  String get alertsUnavailableBody =>
      'O servidor ainda não publica seus alertas. Quando estiverem prontos, aparecerão aqui.';

  @override
  String get alertsErrorTitle => 'Não foi possível carregar os alertas';

  @override
  String get alertsErrorBody => 'Verifique sua conexão e tente novamente.';

  @override
  String get alertsRetry => 'Tentar novamente';

  @override
  String get alertsNoPermissionTitle => 'Sem permissão para ver alertas';

  @override
  String get alertsNoPermissionBody =>
      'Seu perfil não inclui os alertas desta concessão.';

  @override
  String get alertsSampleBanner =>
      'Alertas de exemplo: ainda não vêm do servidor.';

  @override
  String get alertsSeverityInfo => 'Informativa';

  @override
  String get alertsSeverityWarning => 'Atenção';

  @override
  String get alertsSeverityCritical => 'Urgente';

  @override
  String get alertsSeeDetail => 'Ver detalhe';

  @override
  String alertsUnreadSemantic(int count) {
    return '$count alertas não lidos';
  }

  @override
  String get maintIndConservacion => 'Conservação';

  @override
  String get maintIndSgsei => 'Sistemas elétricos e iluminação';

  @override
  String get maintIndSgost => 'Túneis';

  @override
  String get accidentTypeRunOver => 'Atropelamento';

  @override
  String get accidentTypeOther => 'Outro';

  @override
  String get accidentSeverityUnharmed => 'Ileso';

  @override
  String get accidentSeverityMinor => 'Lesões leves';

  @override
  String get accidentSeverityFatal => 'Óbito';

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
  String get accidentWeatherWind => 'Vento';

  @override
  String get accidentWeatherRain => 'Chuva';

  @override
  String get accidentWeatherFog => 'Neblina';

  @override
  String get accidentWeatherNormal => 'Normal';

  @override
  String get accidentPavementConditionTitle => 'Estado do pavimento';

  @override
  String get accidentSignageConditionTitle => 'Estado da sinalização';

  @override
  String get accidentConditionGood => 'Boa';

  @override
  String get accidentConditionFair => 'Regular';

  @override
  String get accidentConditionPoor => 'Ruim';

  @override
  String get accidentLayoutTitle => 'Traçado';

  @override
  String get accidentLayoutStraight => 'Reta';

  @override
  String get accidentLayoutVerticalCurve => 'Curva vertical';

  @override
  String get accidentLayoutHorizontalCurve => 'Curva horizontal';

  @override
  String get accidentPavementTypeTitle => 'Tipo de pavimento';

  @override
  String get accidentPavementRigid => 'Rígido';

  @override
  String get accidentPavementFlexible => 'Flexível';

  @override
  String get accidentCauseTitle => 'Causa';

  @override
  String get accidentCauseSpeeding => 'Excesso de velocidade';

  @override
  String get accidentCauseLaneInvasion => 'Invasão de faixa';

  @override
  String get accidentCauseOther => 'Outra';

  @override
  String get accidentPlaceTitle => 'Local do acidente';

  @override
  String get accidentPlacePavement => 'Pavimento';

  @override
  String get accidentPlaceSignage => 'Sinalização';

  @override
  String get accidentPlaceTollBooth => 'Praças de pedágio';

  @override
  String get accidentPlaceOther => 'Outros';

  @override
  String get accidentVehiclesTitle => 'Veículos envolvidos';

  @override
  String get accidentVehiclesCount => 'Quantidade de veículos';

  @override
  String accidentVehicleTitle(int n) {
    return 'Veículo $n';
  }

  @override
  String get accidentVehicleTypeTitle => 'Tipo de veículo';

  @override
  String get accidentVehicleCar => 'Veículo';

  @override
  String get accidentVehicleMotorcycle => 'Motocicleta';

  @override
  String get accidentVehicleLivestock => 'Semovente';

  @override
  String get accidentVehicleFixedObject => 'Objeto fixo';

  @override
  String get accidentVictimsTitle => 'Vítimas';

  @override
  String get accidentVictimsCount => 'Quantidade de vítimas';

  @override
  String accidentVictimTitle(int n) {
    return 'Vítima $n';
  }

  @override
  String get accidentSexTitle => 'Sexo';

  @override
  String get accidentSexFemale => 'Feminino';

  @override
  String get accidentSexMale => 'Masculino';

  @override
  String get accidentSexUnspecified => 'Não especificado';

  @override
  String get accidentSeverityDerived =>
      'A gravidade do acidente é a da vítima mais grave.';

  @override
  String get newAccidentErrorVehicle => 'Escolha o tipo de veículo.';

  @override
  String get newAccidentErrorVictim => 'Escolha a gravidade da vítima.';

  @override
  String get accidentConditionsTitle => 'Condições do local';

  @override
  String get accidentSeveritySerious => 'Feridas graves';

  @override
  String get dashCompliance => 'Cumprimento';

  @override
  String get dashComplianceUnavailable =>
      'O cumprimento por indicador ainda não está disponível.';

  @override
  String dashComplianceMet(int met, int total) {
    return 'Indicadores cumpridos: $met de $total';
  }

  @override
  String get dashStatusInProcess => 'Em andamento';

  @override
  String get dashStatusGood => 'Bom estado';

  @override
  String get dashStatusIntermediate => 'Estado intermediário';

  @override
  String get dashStatusBad => 'Mau estado';

  @override
  String get dashTicketsBySubsystem => 'Indicadores com mais tickets';

  @override
  String get dashTopCreators => 'Usuários que mais geraram tickets';

  @override
  String maintProgressStatus(
    String executed,
    String total,
    String unit,
    String percent,
    String remaining,
  ) {
    return 'Executado $executed de $total $unit ($percent %). Faltam $remaining.';
  }

  @override
  String maintProgressResult(String percent) {
    return 'Ficará em $percent %.';
  }

  @override
  String get maintProgressVolumeRules =>
      'É somado ao já executado. Com volume, o avanço é calculado automaticamente.';

  @override
  String get maintProgressErrorMissing =>
      'Digite o volume executado ou o avanço acumulado.';

  @override
  String maintProgressErrorVolumeOver(String remaining) {
    return 'Excede o que falta: restam $remaining.';
  }

  @override
  String maintProgressErrorPercentBelow(String percent) {
    return 'O avanço não pode diminuir: já está em $percent %.';
  }

  @override
  String get maintProgressPhotosFailed =>
      'O avanço foi salvo, mas nem todas as fotos. Tente novamente pela web.';

  @override
  String get maintIndicatorsNone =>
      'Você não tem indicadores atribuídos nesta concessão. Peça ao seu administrador.';

  @override
  String get maintIndicatorsFailed =>
      'Não foi possível carregar seus indicadores.';

  @override
  String get newTicketIndicator => 'Indicador';

  @override
  String get newTicketGroup => 'Subclassificação';

  @override
  String get newTicketFailure => 'Falha';

  @override
  String get newTicketAttention => 'Prazo de atendimento';

  @override
  String get newTicketAttentionPending => 'Vem da falha escolhida';

  @override
  String newTicketAttentionValue(String value) {
    return '$value · fixo, corre 24×7';
  }

  @override
  String get newTicketAttentionImmediate => 'Imediato';

  @override
  String newTicketAttentionDays(int days) {
    return '$days dias';
  }

  @override
  String newTicketAttentionHours(int hours) {
    return '$hours horas';
  }

  @override
  String get newTicketErrorFailure =>
      'Escolha o indicador, a subclassificação e a falha.';

  @override
  String ticketPlacementSegment(String code) {
    return 'trecho $code';
  }

  @override
  String ticketPlacementDistance(int meters) {
    return 'a $meters m da rodovia';
  }

  @override
  String ticketPlacementOffRoad(int meters) {
    return 'O ponto está a mais de $meters m da rodovia: marque-o sobre a rodovia da concessão.';
  }
}
