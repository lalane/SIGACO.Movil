import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/sigaco_palette.dart';
import 'widgets.dart';

/// Estado de pantalla cuando el servidor no deja continuar (MQ-MOB-08).
enum AccessIssue {
  /// El usuario no tiene permiso para ver o hacer esto.
  noPermission(Icons.lock_outline),

  /// No se pudieron comprobar los accesos (error del servidor al validarlos).
  authorizationError(Icons.gpp_maybe_outlined);

  const AccessIssue(this.icon);

  final IconData icon;
}

/// Pantalla compartida de "sin permiso" y "error de autorizacion". Cualquier
/// modulo la usa en lugar de armar la suya. Nunca muestra codigos de error ni
/// mensajes tecnicos; ofrece una accion principal y, si hace falta, una segunda.
class AccessStateView extends StatelessWidget {
  const AccessStateView({
    super.key,
    required this.issue,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final AccessIssue issue;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.s(32), vertical: r.s(24)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.s(420)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: r.s(72),
                height: r.s(72),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accentOnBottom.withValues(alpha: 0.12),
                  border: Border.all(
                    color: p.accentOnBottom.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(issue.icon, size: r.s(34), color: p.accentOnBottom),
              ),
              SizedBox(height: r.s(18)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontVariations: const [FontVariation('wght', 800)],
                  fontSize: r.s(20),
                  color: p.textOnBottom,
                ),
              ),
              SizedBox(height: r.s(8)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.s(14),
                  height: 1.4,
                  color: p.textOnBottom.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: r.s(22)),
              PrimaryButton(label: primaryLabel, onPressed: onPrimary),
              if (secondaryLabel != null && onSecondary != null)
                Padding(
                  padding: EdgeInsets.only(top: r.s(6)),
                  child: TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
