import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/branding/sigaco_wordmark.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/sigaco_palette.dart';
import '../../../../core/ui/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_extras.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.passwordResetReturned = false});

  /// Se llego por el enlace `sigaco://app/login?reset=ok`: el usuario definio
  /// su nueva contrasena en el navegador y regreso a la aplicacion.
  final bool passwordResetReturned;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _remember = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthBloc>().state;
    _prefill(saved.rememberedEmail, saved.rememberedPassword);
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) setState(() => _version = info.version);
        })
        .catchError((_) {});
    if (widget.passwordResetReturned) _notifyPasswordReset();
  }

  @override
  void didUpdateWidget(LoginPage old) {
    super.didUpdateWidget(old);
    // La pantalla ya estaba abierta cuando llego el enlace de regreso.
    if (widget.passwordResetReturned && !old.passwordResetReturned) {
      _notifyPasswordReset();
    }
  }

  void _notifyPasswordReset() =>
      context.read<AuthBloc>().add(const AuthPasswordResetReturned());

  /// Rellena lo recordado, sin pisar lo que el usuario ya escribio.
  void _prefill(String? email, String? password) {
    if (email != null && _email.text.isEmpty) {
      _email.text = email;
      _remember = true;
    }
    if (password != null && _password.text.isEmpty) {
      _password.text = password;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _email.text,
        password: _password.text,
        remember: _remember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) =>
          a.rememberedEmail != b.rememberedEmail ||
          a.rememberedPassword != b.rememberedPassword ||
          (!a.passwordResetDone && b.passwordResetDone),
      listener: (context, state) => setState(() {
        // La contrasena escrita o recordada ya no es la vigente.
        if (state.passwordResetDone) _password.clear();
        _prefill(state.rememberedEmail, state.rememberedPassword);
      }),
      builder: (context, state) {
        final r = context.responsive;
        final notice = state.error != null
            ? authErrorText(l10n, state.error!)
            : (state.sessionExpired ? l10n.errSessionExpired : null);

        final brand = _Brand(wordmarkSize: r.s(r.isExpanded ? 64 : 50));
        final form = _formCard(context, state, notice);
        final extras = _Extras(
          state: state,
          onBiometric: () => context.read<AuthBloc>().add(
            AuthBiometricLoginRequested(l10n.biometricReason),
          ),
        );
        final footer = Center(child: LoginFooter(version: _version));

        // Expandida: marca a la izquierda y formulario a la derecha.
        // Compacta y media: una sola columna, centrada con ancho maximo.
        final Widget content = r.isExpanded
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Responsive.expandedAuthMaxWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        key: const Key('login-brand-panel'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            brand,
                            SizedBox(height: r.s(40)),
                            const LoginValuesRow(),
                          ],
                        ),
                      ),
                      SizedBox(width: r.s(56)),
                      // Formulario con el ancho del mockup (360 dp) en proporcion.
                      SizedBox(
                        width: r.s(360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [form, extras],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  SizedBox(height: r.s(22)),
                  form,
                  extras,
                  SizedBox(height: r.s(14)),
                  const LoginValuesRow(),
                ],
              );

        return Scaffold(
          body: GradientBackground(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: r
                        .sidePadding(
                          // Expandida: dos paneles; el resto, una columna.
                          maxWidth: r.isExpanded
                              ? Responsive.expandedAuthMaxWidth
                              : Responsive.formMaxWidth,
                          minGutter: r.s(24),
                        )
                        .copyWith(top: r.s(8), bottom: r.s(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // El idioma y la apariencia se cambian solo desde el perfil.
                        SizedBox(height: r.s(44)),
                        if (r.isExpanded) const Spacer(),
                        content,
                        const Spacer(),
                        SizedBox(height: r.s(16)),
                        footer,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _formCard(BuildContext context, AuthState state, String? notice) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return FrostedCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.loginWelcome,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: r.s(24),
                color: p.textOnTop,
              ),
            ),
            SizedBox(height: r.s(4)),
            Text(
              l10n.loginSubtitle,
              style: TextStyle(
                color: p.textOnTop.withValues(alpha: 0.7),
                fontSize: r.s(15),
              ),
            ),
            SizedBox(height: r.s(16)),
            AppTextField(
              controller: _email,
              hint: l10n.fieldEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              textInputAction: TextInputAction.next,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return l10n.errEmailRequired;
                final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!valid.hasMatch(value)) return l10n.errEmailInvalid;
                return null;
              },
            ),
            SizedBox(height: r.s(12)),
            AppTextField(
              controller: _password,
              hint: l10n.fieldPassword,
              obscure: _hidePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.errPasswordRequired : null,
              suffix: IconButton(
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: p.hint,
                  size: r.s(24),
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
            ),
            SizedBox(height: r.s(4)),
            Row(
              children: [
                Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(r.s(8)),
                    onTap: () => setState(() => _remember = !_remember),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: r.s(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _remember
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: p.accentOnDark,
                            size: r.s(22),
                          ),
                          SizedBox(width: r.s(6)),
                          Flexible(
                            child: Text(
                              l10n.rememberCredentials,
                              maxLines: 2,
                              style: TextStyle(
                                color: p.textOnTop,
                                fontSize: r.s(12),
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.s(8)),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.push('/recovery'),
                    style: TextButton.styleFrom(
                      foregroundColor: p.accentOnDark,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, r.s(32)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(fontSize: r.s(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (state.passwordResetDone) ...[
              SizedBox(height: r.s(14)),
              NoticeBanner(l10n.passwordResetDone),
            ],
            if (notice != null) ...[
              SizedBox(height: r.s(14)),
              ErrorBanner(notice),
            ],
            SizedBox(height: r.s(12)),
            PrimaryButton(
              label: l10n.signIn,
              busy: state.busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca y lema del login.
class _Brand extends StatelessWidget {
  const _Brand({required this.wordmarkSize});

  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SigacoWordmark(fontSize: wordmarkSize),
        SizedBox(height: r.s(6)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.appTagline,
            maxLines: 1,
            style: TextStyle(
              color: p.textOnTop.withValues(alpha: 0.85),
              fontSize: r.s(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Acceso biometrico (si el equipo lo permite).
class _Extras extends StatelessWidget {
  const _Extras({required this.state, required this.onBiometric});

  final AuthState state;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    if (!state.biometricAvailable) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.only(top: r.s(16)),
      child: Center(
        child: Column(
          children: [
            InkResponse(
              onTap: state.busy ? null : onBiometric,
              radius: r.s(44),
              child: Container(
                width: r.s(56),
                height: r.s(56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.hint.withValues(alpha: 0.6)),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: r.s(32),
                  color: p.textOnBottom,
                ),
              ),
            ),
            SizedBox(height: r.s(8)),
            Text(
              l10n.biometricAccess,
              style: TextStyle(
                color: p.hint,
                fontSize: r.s(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
