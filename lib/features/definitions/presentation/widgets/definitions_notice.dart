import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/definitions_repository.dart';

/// Envuelve la pantalla de un modulo de la app (tanda 4): al abrirla, si hay
/// definiciones sin veredicto de ese modulo (`mobileModule`), avisa una vez por
/// sesion con un mensaje que lleva a ellas. No toca la pantalla del modulo ni
/// tapa sus botones: el aviso se va solo.
class DefinitionsNotice extends StatefulWidget {
  const DefinitionsNotice({
    super.key,
    required this.repository,
    required this.mobileModule,
    required this.child,
  });

  final DefinitionsRepository repository;

  /// `tickets`, `inventory`, `inspections`...
  final String mobileModule;
  final Widget child;

  /// Modulos ya avisados en esta sesion de la app.
  static final _shown = <String>{};

  /// Para las pruebas: vuelve a avisar.
  @visibleForTesting
  static void reset() => _shown.clear();

  @override
  State<DefinitionsNotice> createState() => _DefinitionsNoticeState();
}

class _DefinitionsNoticeState extends State<DefinitionsNotice> {
  @override
  void initState() {
    super.initState();
    // Se aparta antes de preguntar: si la pantalla se arma dos veces, un solo aviso.
    if (!DefinitionsNotice._shown.add(widget.mobileModule)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final page = await widget.repository.list(
        mobileModule: widget.mobileModule,
      );
      final pending = page.items.where((d) => d.status.pending).length;
      if (!mounted || pending == 0) {
        DefinitionsNotice._shown.remove(widget.mobileModule);
        return;
      }
      final l10n = AppLocalizations.of(context);
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('definitions-notice'),
          duration: const Duration(seconds: 6),
          // Con accion, un SnackBar se queda hasta que lo toquen (Flutter
          // 3.3x) y tapa los botones de abajo de la pantalla: este se va solo.
          persist: false,
          content: Text(l10n.defModuleNotice(pending)),
          action: SnackBarAction(
            label: l10n.defView,
            onPressed: () =>
                router.push('/definitions?module=${widget.mobileModule}'),
          ),
        ),
      );
    } on DefinitionsException {
      // Sin red o sin servidor no se avisa: la pantalla del modulo sigue igual.
      DefinitionsNotice._shown.remove(widget.mobileModule);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
