import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';

/// Fondo de las pantallas: degradado de la paleta + patron de puntos.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.gradientTop, p.gradientBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/branding/pattern.png',
                // 90 % del ancho del mockup, en proporcion en pantallas grandes.
                width: r.isCompact
                    ? r.width * 0.9
                    : r.s(Responsive.baseWidth * 0.9),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Contenedor translucido de formularios.
class FrostedCard extends StatelessWidget {
  const FrostedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(18), r.s(20), r.s(18)),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(r.s(24)),
      ),
      child: child,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(r.s(16)),
      borderSide: BorderSide(color: c),
    );
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: textColor, fontSize: r.s(15)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.hint, fontSize: r.s(14.5)),
        filled: true,
        fillColor: p.fieldFill,
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.s(20),
          vertical: r.s(15),
        ),
        enabledBorder: border(p.fieldBorder),
        focusedBorder: border(p.accent),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error),
        errorStyle: TextStyle(color: p.error, fontSize: r.s(12)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: r.s(50)),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(r.s(50)),
            backgroundColor: p.accent,
            foregroundColor: p.onAccent,
            disabledBackgroundColor: p.accent.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.s(16)),
            ),
            textStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: r.s(17),
            ),
          ),
          child: busy
              ? SizedBox(
                  width: r.s(22),
                  height: r.s(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: p.onAccent,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.s(12)),
      decoration: BoxDecoration(
        color: p.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(r.s(12)),
        border: Border.all(color: p.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: p.error, size: r.s(20)),
          SizedBox(width: r.s(8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: p.error, fontSize: r.s(13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso informativo o de exito. Sobre el fondo oscuro el texto va en blanco
/// y el color de acento solo en el icono y el borde.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner(this.message, {super.key, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.s(12)),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(r.s(12)),
        border: Border.all(color: p.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.check_circle_outline,
            color: p.accentOnDark,
            size: r.s(20),
          ),
          SizedBox(width: r.s(8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: p.textOnTop, fontSize: r.s(13.5)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla de un solo paso (MFA, cambio de contrasena, etc.).
///
/// En pantallas medias y grandes el contenido se centra con un ancho maximo.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    final side = r.sidePadding(minGutter: r.s(24));
    return Scaffold(
      body: GradientBackground(
        child: ListView(
          padding: side.copyWith(top: r.s(16), bottom: r.s(32)),
          children: [
            // El idioma y la apariencia se cambian solo desde el perfil.
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: BackButton(color: p.textOnTop),
              )
            else
              SizedBox(height: r.s(32)),
            SizedBox(height: r.s(16)),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: r.s(28),
                color: p.textOnTop,
              ),
            ),
            SizedBox(height: r.s(8)),
            Text(
              subtitle,
              style: TextStyle(
                color: p.textOnTop.withValues(alpha: 0.8),
                fontSize: r.s(15),
              ),
            ),
            SizedBox(height: r.s(28)),
            // La tarjeta va sobre la parte oscura del degradado: sus botones de
            // texto usan la variante del acento para fondos oscuros.
            Theme(
              data: Theme.of(context).copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: p.accentOnDark),
                ),
              ),
              child: FrostedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
